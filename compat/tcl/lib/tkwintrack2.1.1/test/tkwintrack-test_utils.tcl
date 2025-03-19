#
# This file provides various utilities for testing of package tkwintrack.
#

#
# Copyright 2020 Erik Leunissen
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# 	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# A. GENERIC UTILITIES
#

# tcltest::enableOutputFromInterp --
#
#    Makes tcltest capture output (stdout and stderr) from descendant
#    interpreters.
#
# Arguments: args, being the options:
#	"?-auto?"
#	"?-interp interp?": indicating the interpreter to enable
#	These two options are mutually exclusive.
#
# Results: none
#
# Side effects: renames [puts] in the descendant interpreters to [_puts_renamed_by_tcltest_eofi],
#               and installs a replacement. If called with "-auto", it adds
#               instrumentation to the interpreter, being:
#               - one execution trace
#               - three instrumentation commands
#
proc tcltest::enableOutputFromInterp {args} {

	# check parameters passed
	set nargs [llength $args]
	set validOptions [list -auto -interp]
	set errMsg ""
	if {($nargs == 0) || ($nargs > 2)} {
		set errMsg "wrong # parameters. Usage: [lindex [info level 0] 0] (-auto|-interp) ?interp?"
	} elseif {$nargs == 1} {
		set option [lindex $args 0]
		if {$option ne "-auto"} {
			set errMsg "invalid option \"$option\""
		}
	} else {
		# nargs == 2
		set option [lindex $args 0]
		if {$option ne "-interp"} {
			set errMsg "invalid option \"$option\" with value [lindex $args 1]"
		} else {
			set interp [lindex $args 1]
		}
	}
	if {$errMsg ne ""} {
		return -code error $errMsg
	}

	# enableOutputFromInterp.core --
	#
	#    Makes a specific interpreter (any decendant in the interpreter
	#    hierarchy) use [puts] in the current interpreter when writing
	#    to stdout or stderr.
	#
	# Arguments:
	#    interp: the interpreter to enable.
	#
	# Results: none
	#
	# Side effects: renames [puts] in the target interpreter to
	#               [tcltest::puts_orig_renamed_by_eofi], and installs
	#               a replacement that calls [puts] in the current
	#               interpreter instead.
	#
	proc enableOutputFromInterp.core {interp} {

		# reroute output channels through the current interpreter
		interp eval $interp {

			# prevent inadvertent duplicate rename
			if {[info commands tcltest::puts_orig_renamed_by_eofi] ne ""} {
				return -code error "interp has already been enabled by tcltest::enableOutputFromInterp"
			}

			rename puts tcltest::puts_orig_renamed_by_eofi; # creates namespace if it doesn't exist
			proc puts {args} {
				set nargs [llength $args]
				if {$nargs == 3} {
					set channel [lindex $args 1]
				} elseif {($nargs == 2) && ([lindex $args 0] ne "-nonewline")} {
					set channel [lindex $args 0]
				} else {
					set channel stdout
				}

				if {$channel in "stdout stderr"} {
					tcltestMaster.puts {*}$args
				} else {
					tcltest::puts_orig_renamed_by_eofi {*}$args
				}
			}
		}

		# provide [puts] in the master interpreter to the descendant interp
		interp alias $interp tcltestMaster.puts {} puts
	}
	if {$option eq "-interp"} {
		enableOutputFromInterp.core $interp
		return
	}

	#
	# The option -auto was passed.
	#
	# The automatic feature installs an execution trace which acts on
	# [interp create], recursively for each new interpreter.
	#
	proc handleInterpTrace {args} {
		if {([lindex [lindex $args 0] 1] eq "create") && ([lindex $args 1] == 0)} {

			# enable output from the child interpreter
			set childInterp [lindex $args 2]
			enableOutputFromInterp.core $childInterp

			# Be recursive. Instrument the child interpreter, using an absolute namespace ::tcltest
			interp eval $childInterp {namespace eval ::tcltest {}}
			interp eval $childInterp [list proc ::tcltest::enableOutputFromInterp [info args enableOutputFromInterp] [info body enableOutputFromInterp]]
			interp eval $childInterp {::tcltest::enableOutputFromInterp -auto}
		}
	}
	set cmd [namespace code handleInterpTrace]
	if {[list leave $cmd] ni [trace info execution interp]} {
		trace add execution interp leave $cmd
	}
}
namespace eval tcltest {namespace export enableOutputFromInterp}


proc getConfigFile {} {
	if {[info exists ::Generic(configFile)]} {
		return $::Generic(configFile)
	}
	set ::Generic(configFile) [with_cfgDialog on_pkg_load exit {set TkWintrack(config,fileName)}]
}

#
# B. TOOLS FOR THE PRIVATE INTERPRETER
#

proc instrumentPrivateInterp {} {
	if {[info exists ::tkwintrack::TkWintrack(privateInterpInstrumented)]} {
		#
		# Once is enough
		#
		return
	}

	interp eval tkwintrack [subst {

		# copy test configuration
		array set testconf [list [array get ::testconf]]

		# load package gn
		source "[file join $::Dir(install) utils gn.tcl]"
		namespace import gn::*

		# redefine keybord shortcuts to a single key press instead of a key sequence
		array set TkWintrack {
			key,shortcutSeq,toggle F4
			key,shortcutSeq,copy F5
			key,shortcutSeq,recall F6
		}
	}]

	interp eval tkwintrack {

		# used anywhere
		proc assert {expr} {
			if {! [uplevel 1 [list expr $expr]]} {
				return -code error "assertion failed: \"[uplevel 1 [list subst -nocommands $expr]]\""
			}
		}

		# scheduleKeyPress --
		#
		#	Used as a trace handler by tests reconfigure_kbd_shortcut-*
		#
		# Arguments:
		#	args : receive arguments from the tracing mechanism, but otherwise unused
		#
		proc scheduleKeyPress {keySym args} {
			after idle event generate . <KeyPress> -keysym $keySym
		}

		# used by tests reconfigure_(outline|pnw)-*
		proc userSim.setColor {colorObj color} {
			pointer_move .config.${colorObj}_value c

			# after 20 ms because [mouse_button left click] waits 10 ms in between
			# button press and button release.
			after 20 [subst -nocommands {
				#
				# The time needed to map the Tk colorpick dialog can vary wildly, even
				# within a single run of the test script, and I didn't find out what it
				# depends upon. We just wait as many rounds of 10 ms as it happens to take.
				#
				while {[catch {
						winfo ismapped .__tk__color.top.sel.ent
					} result] || (\$result == 0)} {
					twait 10
				}
				update
				.__tk__color.top.sel.ent delete 0 end
				.__tk__color.top.sel.ent insert 0 $color
				pointer_move .__tk__color.top.sel.ent c
				mouse_button left click
				event generate .__tk__color.top.sel.ent <KeyPress> -keysym Return
				.__tk__color.bot.ok invoke
			}]
			mouse_button left click; # induces display of the colour selection dialog
		}
	}

	interp alias tkwintrack applyWmAccommodations {} applyWmAccommodations
	interp alias tkwintrack clientInterp.evalOnCfgDlgDisplay {} evalOnCfgDlgDisplay
	if {$::testconf(-eyefriendly)} {
		interp alias tkwintrack pause {} pause
		interp eval tkwintrack {
			trace add execution ::gn::controlPointerWarpTiming leave {pause 1000}
		}
	}

	# Bindings configured for the waiting procs immediately below.
	interp eval tkwintrack {
		proc pnwBindings {args} {
			bind .pnw <Configure> {set _waitvar(pnwConfigure) 1}
			bind .pnw <Unmap> {set _waitvar(pnwUnmap) 1}
			bindtags .pnw.pathname {.pnw.pathname Label all}; # don't inherit bindings for the toplevel
		}
		trace add execution pnw.create leave pnwBindings
	}

	# waitForPnwUnmap --
	#
	#	Ensures that the the pathname widget is unmapped before
	#	the subsequent command is evaluated.
	#
	proc waitForPnwUnmap {} {
		interp eval tkwintrack {
			if {! [winfo ismapped .pnw]} {
				return
			}
			set afterID [after 1000 {set _waitvar(pnwUnmap) -1}]
			set _waitvar(pnwUnmap) 0
			vwait _waitvar(pnwUnmap)
			after cancel $afterID
			if {$::_waitvar(pnwUnmap) == -1} {
				return -code error "pnw unmap timed out"
			}
		}
		# Ensure that the display server has finished communicating with Tk, and
		# that all window events have been serviced, i.o.w. redraw is completed.
		update
	}

	set ::tkwintrack::TkWintrack(privateInterpInstrumented) 1
}


# evalOnCfgDlgDisplay --
#
# Trace handler, defined by with_cfgDialog, invoked while the config dialog
# is displayed. Schedules the evaluation of the client script and
# the subsequent button click.
#
proc evalOnCfgDlgDisplay {args} {

	# enforce completion of drawing the contents of cfgDialog to the screen.
	if {[applyWmAccommodations Fluxbox]} {
		twait 10
	} else {
		update
	}
	if {$::testconf(-eyefriendly)} {
		after 1000
	}

	# schedule for evaluation after [vwait] in [cfgDialog.show] has created
	# opportunity.
	after idle $::withCfgDlgScript
}


# with_cfgDialog --
#
# Displays the config dialog and simulates a press on one of its buttons.
# While the config dialog is displayed, that is before the button press
# happens, this proc evaluates a script in the private interpreter and
# returns the evaluation result.
#
proc with_cfgDialog {occasion dlgButton clientScript} {
	# extend the client script with a click on the requested button
	set ::withCfgDlgScript [subst -nocommands {
		set ::__result [interp eval tkwintrack {$clientScript}]
		interp eval tkwintrack {
			trace remove variable TkWintrack(dlgChoice) write clientInterp.evalOnCfgDlgDisplay
			pointer_move \$::TkWintrack(button_$dlgButton) c
			if {[applyWmAccommodations Fluxbox]} {
				twait 10
			}
			mouse_button left click
		}
		unset ::withCfgDlgScript; # triggers release of the [vwait] at the end of this proc
	}]

	switch -- $occasion {
		on_pkg_load {
			after idle {
				instrumentPrivateInterp
				interp eval tkwintrack {trace add variable TkWintrack(dlgChoice) write clientInterp.evalOnCfgDlgDisplay}
			}
			#
			# Don't do [package require] because auto_path is probably wide enough to
			# allow loading an elsewhere installed package tkwintrack.
			#
			uplevel #0 {source [file join $Dir(install) tkwintrack.tcl]}
		}
		on_pnw_click {
			instrumentPrivateInterp
			interp eval tkwintrack {
				trace add variable TkWintrack(dlgChoice) write clientInterp.evalOnCfgDlgDisplay
				if {! [winfo ismapped $TkWintrack(pnLabel)]} {
					tkwait visibility $TkWintrack(pnLabel)
				}
			}
			after idle [list interp eval tkwintrack {
				pointer_move $TkWintrack(pnLabel) c
				mouse_button right press
			}]
		}
	}

	# wait for the client script to be evaluated in the private interpreter and return result
	vwait ::withCfgDlgScript
	set result $::__result; unset ::__result; # get rid of global variable
	return $result
}

#
# C. UTILITIES FOR RETRIEVING STATE FROM TKWINTRACK WIDGETS
#

# outlineState --
#
#	Return state of the outline widgets as a list, only for those aspects that
#	do not match the expected state. If everything is as expected, return
#	an empty list.
#
proc outlineState {w} {
	set toplevel [winfo toplevel $w]
	if {$toplevel eq "."} {set toplevel ""}
	set state [list]

	if {! [winfo ismapped $toplevel.tkwintrack_outline_top]} {
		lappend state outline.none; # we don't distinguish from non-existent
		return $state ; # we're done
	}

	# Collect information regarding position, only if there are differences from expected
	if {[winfo rootx $toplevel.tkwintrack_outline_top] != [set rootx [winfo rootx $w]]} {
		lappend state outline_top.rootx [winfo rootx $toplevel.tkwintrack_outline_top]
	}
	if {[winfo rooty $toplevel.tkwintrack_outline_top] != [set rooty [winfo rooty $w]]} {
		lappend state outline_top.rooty [winfo rooty $toplevel.tkwintrack_outline_top]
	}
	if {[winfo height $toplevel.tkwintrack_outline_top] != $::tkwintrack::TkWintrack(outline,width)} {
		lappend state outline_top.height [winfo height $toplevel.tkwintrack_outline_top]
	}
	if {[winfo rootx $toplevel.tkwintrack_outline_left] != $rootx} {
		lappend state outline_left.rootx [winfo rootx $toplevel.tkwintrack_outline_left]
	}
	if {[winfo rooty $toplevel.tkwintrack_outline_left] != $rooty} {
		lappend state outline_left.rooty [winfo rooty $toplevel.tkwintrack_outline_left]
	}
	if {[winfo width $toplevel.tkwintrack_outline_left] != $::tkwintrack::TkWintrack(outline,width)} {
		lappend state outline_left.width [winfo width $toplevel.tkwintrack_outline_left]
	}
	if {[winfo rootx $toplevel.tkwintrack_outline_right] != $rootx + [set width [winfo width $w]] - $::tkwintrack::TkWintrack(outline,width)} {
		lappend state outline_right.rootx [winfo rootx $toplevel.tkwintrack_outline_right]
	}
	if {[winfo rooty $toplevel.tkwintrack_outline_right] != $rooty} {
		lappend state outline_right.rooty [winfo rooty $toplevel.tkwintrack_outline_right]
	}
	if {[winfo width $toplevel.tkwintrack_outline_right] != $::tkwintrack::TkWintrack(outline,width)} {
		lappend state outline_right.width [winfo width $toplevel.tkwintrack_outline_right]
	}
	if {[winfo rootx $toplevel.tkwintrack_outline_bottom] != $rootx} {
		lappend state outline_bottom.rootx [winfo rootx $toplevel.tkwintrack_outline_bottom]
	}
	if {[winfo rooty $toplevel.tkwintrack_outline_bottom] != $rooty + [set height [winfo height $w]] - $::tkwintrack::TkWintrack(outline,width)} {
		lappend state outline_bottom.rooty [winfo rooty $toplevel.tkwintrack_outline_bottom]
	}
	if {[winfo height $toplevel.tkwintrack_outline_bottom] != $::tkwintrack::TkWintrack(outline,width)} {
		lappend state outline_bottom.height [winfo height $toplevel.tkwintrack_outline_bottom]
	}
	if {[winfo width $toplevel.tkwintrack_outline_bottom] != $width} {
		lappend state outline_bottom.width [winfo width $toplevel.tkwintrack_outline_bottom]
	}
	if {[winfo height $toplevel.tkwintrack_outline_right] != $height} {
		lappend state outline_right.height [winfo height $toplevel.tkwintrack_outline_right]
	}

	# Add color information
	if {[$toplevel.tkwintrack_outline_top cget -bg] ne $::tkwintrack::TkWintrack(outline,color)} {
		lappend state outline.color [$toplevel.tkwintrack_outline_top cget -bg]
	}
	return $state
}


proc pnw_follow_pointer {} {
	update
	tkwintrack eval {
		wm geometry $TkWintrack(pnWidget) +[expr {[winfo pointerx .pnw]+$TkWintrack(XOffset)}]+[expr {[winfo pointery .pnw]-$TkWintrack(YOffset)}]
	}
}


# record --
#
#	Record state of our own widgets in a variable specified by the caller
#
# Arguments:
#
# varName : the name of the variable into which the caller wants the result recorded
# what    : the information to record
# w       : the window where the caller believes the outline should be
#
proc record {varName what {w ""}} {
	if {$::Generic(pkgName) ne "tkwintrack"} {
		return
	}
	upvar 1 $varName result

	set result [list]
	switch -- $what {
		outline {
			set toplevel [winfo toplevel $w]
			if {$toplevel eq "."} {set toplevel ""}
			if {[winfo exists $toplevel.tkwintrack_outline_top]} {
				lappend result {*}[outlineState $w]
			} else {
				lappend result outline.none; # we don't distinguish from unmapped
			}
		}
		pnw {
			if {! [interp eval tkwintrack {winfo ismapped $TkWintrack(pnLabel)}]} {
				lappend result pnw.unmapped
			} else {
				set txt [interp eval tkwintrack {$TkWintrack(pnLabel) cget -text}]
				set pointerWin [winfo containing [winfo pointerx .] [winfo pointery .]]
				if {$txt ne $pointerWin} {
					lappend result pnw.pathname $txt
				}
			}
		}
		pnwGeom {
			set result [interp eval tkwintrack {wm geometry $TkWintrack(pnWidget)}]
			return
		}
	}
	if {[llength $result]} {
		scan $varName {state(%[^)(])} element
		set result [linsert $result 0 $element:]
	}
}

proc setup-button_continue {} {
	catch {::tkwintrack::exit}; # ensure a clean environment
	with_cfgDialog on_pkg_load continue {}
	if {$::testconf(-delay) != [::windetect::configure -delay]} {
		::windetect::detect off
		::windetect::configure -delay $::testconf(-delay)
		::windetect::detect on
	}
	update; # let detection events be serviced here
}

# EOF
