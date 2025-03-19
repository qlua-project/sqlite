#
# This file provides various utilities for testing and introspection of
# package windetect. It is also used by any tkwintrack package installed
# alongside windetect.
#

#
# Copyright 2020 Erik Leunissen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This regular expression is used for the expected test result if the
# particular window pathname and screen coordinates are irrelevant.
#
set anyWindowAnywhere {^(?:{}|\.|(?:\.[[:alnum:]]+)+) -?\d+ -?\d+$}


# applyWmAccommodations --
#
#	Determines whether an accommodation for a specific window manager
#	should be applied.
#
# Arguments:
#	args : a list of window managers for which a particular accommodation
#	       is meant
#
# Result : 0 or 1
#
proc applyWmAccommodations {args} {
	expr {$::testconf(-accommodatewm) && (($::Generic(wm) in $args) || ($::Generic(wm) eq "unknown"))}
}

# assert --
#
proc assert {expr} {
	if {! [uplevel 1 [list expr $expr]]} {
		return -code error "assertion failed: \"[uplevel 1 [list subst -nocommands $expr]]\""
	}
}


# checkGlobalsClean --
#
#	Trace callback, called before and after a sequence of tests to determine
#	whether any globals are left behind.
#
proc checkGlobalsClean {mode args} {
	switch -- $mode {
		enter {
			if {[info exists ::__globals]} {
				return -code error "a call to \"checkGlobalsClean report\" was skipped"
			}
			set ::__globals [info globals]
			lappend ::__globals __globals _waitvar
		}
		leave {
			set remains {}
			foreach varName [info globals] {
				if {$varName ni $::__globals} {
					lappend remains $varName
				}
			}
			unset ::__globals
			if {[llength $remains]} {
				return -code error "error: the following variables haven't been cleaned up: [join $remains ", "]"
			}
		}
	}
}

proc checkForEventLeaking {args} {
	array set before [array get ::_waitvar]
	twait 10
	foreach {key value} [array get ::_waitvar] {
		if {(! [info exists before($key)]) || ($value != $before($key))} {
			if {[regexp -- {^drawing\|(.*)} $key -- details]} {
				return -code error "error: drawing events \"$details\" passing through"
			}
			return -code error "error: $key events passing through"
		}
	}
}

proc checkInstrumentationClean {mode args} {
	switch -- $mode {
		enter {
			if {[info procs ::windetect::instrument] eq ""} {
				set ::instrBefore -1
			} else {
				set ::instrBefore [::windetect::instrument]
			}
		}
		leave {
			if {[info procs ::windetect::instrument] eq ""} {
				set instrAfter -1
			} else {
				set instrAfter [::windetect::instrument]
			}
			if {$::instrBefore ne $instrAfter} {
				set before $::instrBefore
				unset ::instrBefore
				return -code error "the instrumentation changed during the test:\n\tbefore: |$before|\n\tafter: $instrAfter"
			}
			unset ::instrBefore
		}
	}
}


# checkTestsClean --
#
#	Activates the checking of tests for incomplete cleanup
#
proc checkTestsClean {} {
	if {[string match "*checkGlobalsClean*" [trace info execution test]]} {
		# prevent traces from being added multiple times
		return -code error "checkTestsClean is already active"
	}
	trace add execution test enter {checkGlobalsClean enter}
	trace add execution test leave {checkGlobalsClean leave}
	if {$::Generic(pkgName) ne "windetect"} {
		return
	}
	switch -- $::Generic(testType) {
		"unit" {
			trace add execution test enter {checkInstrumentationClean enter}
			trace add execution test leave {checkInstrumentationClean leave}
		}
		"gui" {
			set ::_waitvar(reporting) 0
			trace add execution test leave checkForEventLeaking
			trace add execution test leave checkWindowsClean
		}
	}
}


# checkWindowsClean --
#
#	Trace callback, to ensure proper window configuration for gui-integration
#   tests, used by both windetect and tkwintrack.
#
proc checkWindowsClean {args} {
	if {[catch {package present Tk}] || ! [info exists ::Generic(window_setup_gui_done)]} {
		return
	}
	assert {[winfo ismapped .] && ([grab current] eq "")}

	set testWindows [list .f1 .f1.f2 .g .two]
	foreach w [winfo children .] {
		if {[winfo class $w] eq "TkWintrackOutline"} {
			continue
		}
		if {[winfo class $w] eq "Toplevel"} {
			if {! [string match ._wsctrl* $w]} {
				assert {! [winfo ismapped $w]}
			}
		} else {
			assert {[winfo manager $w] eq ""}
		}
	}
	assert {([winfo pointerx .] == [expr {[winfo rootx .]+100}]) && ([winfo pointery .] == [expr {[winfo rooty .]+100}])}
	if {$::Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack {
			assert {([winfo rootx .pnw] == [winfo pointerx .]+5) && ([winfo rooty .pnw] == [winfo pointery .]-5-[winfo reqheight $TkWintrack(pnWidget)])}
		}
	}
}


proc cleanupTests.return {} {
	#
	# cleanupTests calls exit when running Tk non-interactively, but we want
	# to allow the script to proceed after [cleanupTests].
	#
	rename ::exit ::_exit
	proc ::exit {} {}

	# cleanupTestsHook --
	#
	# Retrieves the count of failed tests and stores it
	# in the variable rv
	#
	proc ::tcltest::cleanupTestsHook {} {
		variable numTests
		uplevel 2 [list set rv $numTests(Failed)]
	}
	tcltest::cleanupTests
	rename ::exit {}
	rename ::_exit exit
	return $rv
}


proc createFrames {} {
	if {! [winfo exists .f1]} {
		frame .f1 -width 80 -height 80 -bg blue
		pack propagate .f1 0
	}
	if {! [winfo exists .f1.f2]} {
		frame .f1.f2 -bg yellow -width 30 -height 30
	}
	if {! [winfo exists .g]} {
		frame .g -bg orange -width 30 -height 30
	}
}


# timing procs
proc dt.reset {} {
	set ::_t0 [clock microseconds]
}

proc dt.get {} {
	set now [clock microseconds]
	set dt [expr {$now - $::_t0}]
	set ::_t0 $now
	return $dt
}


# ensureWindowsClean --
#
#	Trace callback, to ensure proper window configuration
#
# Arguments:
#	args : arguments associated with the trace mechanism; not used
#
proc ensureWindowsClean {args} {
	if {[catch {package present Tk}]} {
		return
	}

	set doCorrection [expr {[lindex $args 0] ne "-nocorrect"}]
	set i 0
	if {[set grabWin [grab current]] ne ""} {
		set msg([incr i]) "grab on $grabWin wasn't properly released"
		if {$doCorrection} {
			grab release $grabWin
		}
	}
	if {! [winfo ismapped .]} {
		set msg([incr i]) "root window wasn't properly remapped"
		if {$doCorrection} {
			wm deiconify .
		}
	}
	if {[winfo ismapped .two]} {
		set msg([incr i]) "window .two wasn't properly unmapped"
		if {$doCorrection} {
			wm withdraw .two
		}
	}
	if {[set geom [wm geometry .two]] ne "200x200+180+180"} {
		#
		# We may encounter the following deviations from expected:
		# - a one pixel size toplevel: [string match {1x1*} $geom]
		# - toplevel placed at the screen origin: [string match {*+0+0} $geom]
		# - toplevel shifted by an amount equal to the width of the wm borders
		#   and/or wm decorations. Sometimes this happens incidentally
		#   (with -delay == 0), sometimes on a regular basis, as observed with
		#   TWM and Xfwm4 upon [wm withdraw] (the window manager appears to
		#   forget/miscalculate the position after withdrawing a toplevel).
		#
		set msg([incr i]) "the size and/or position of window .two wasn't properly restored ($geom)"
		if {$doCorrection} {
			wm geometry .two 200x200+180+180
		}
	}
	foreach w {.f1.f2 .f1 .g} {
		if {[winfo ismapped $w]} {
			set msg([incr i]) "window $w wasn't properly unmapped"
			if {$doCorrection} {
				pack forget $w
			}
		}
		if {$doCorrection} {
			update idletasks
		}
	}
	if {([winfo pointerx .] != [expr {[winfo rootx .]+100}]) || ([winfo pointery .] != [expr {[winfo rooty .]+100}])} {
		set msg([incr i]) "the mouse pointer wasn't properly repositioned"
		if {$doCorrection} {
			event generate . <Motion> -warp 1 -x 100 -y 100
			controlPointerWarpTiming
		}
	}
	if {($i > 0) && $doCorrection} {
		for {set j 1} {$j <= $i} {incr j} {
			puts [format "Warning: %s by the previous test" $msg($j)]
		}

		# The corrections may induce detection events. Wait for a possible reporting.
		waitForReporting *
		if {[ensureWindowsClean -nocorrect] == 0} {
			puts [format "The issue%s been corrected to ensure sanity for the next test\n" [expr {$i>1?"s have":" has"}]]
		} else {
			puts stderr [format "The issue%s could not be corrected to ensure sanity for the next test.\
					Test script execution aborted.\n" [expr {$i>1?"s":""}]]
			exit 1
		}
	}
	return $i
}


# getExpectedResult --
#
#	Selects a specific result from a dictionary of scenario-result pairs. The
#	selection is based on:
#	A. the current scenario:
#		- windetect, maybe diversified with the reporting delay:
#			- windetect-noDelay
#			- windetect-defaultDelay,
#		- tkwintrack
#	B. the checking mode: strict or detailed
#
# Arguments:
#	args: the dictionary of scenario-result pairs
#
proc getExpectedResult {args} {
	set scenarios [dict keys $args]
	if {$::Generic(pkgName) eq "windetect"} {
		set scenario "windetect"
		if {"windetect" ni $scenarios} {
			append scenario [expr {$::testconf(-delay)?"-defaultDelay":"-noDelay"}]
		}
	} elseif {$::Generic(pkgName) eq "tkwintrack"} {
		if {"tkwintrack" ni $scenarios} {
			return "invalid"
		}
		set scenario "tkwintrack"
	} else {
		error "invalid value \"$::Generic(pkgName)\" for package name"
	}

	set detectionDetails [dict get $args $scenario]
	if {$::testconf(-detectiondetails)} {
		return $detectionDetails
	} else {
		# strict result matching on the new pointer window only
		set result [list]
		foreach detail $detectionDetails {
			lappend result [lindex $detail end]
		}
		return $result
	}
}


# getPackageInfo --
#
#	Retrieve the name and version of a package from its pkgIndex file
#
proc getPackageInfo {installDir nameVar versionVar} {
	upvar 1 $nameVar pkgName
	upvar 1 $versionVar pkgVersion

	set pkgIndexFile [file join $installDir pkgIndex.tcl]
	set fd [open $pkgIndexFile r]
	set txt [read $fd]
	close $fd
	if {! [regexp {ifneeded (\w+) (\d+\.\d+[.ab]\d+)} $txt -- pkgName pkgVersion]} {
		return -code error "failed to determine package info from $pkgIndexFile"
	}
}


# isBugVersion --
#
# Determines whether the current Tcl or Tk patch level is within a certain
# range (having a bug).
#
# Arguments:
#	component: tcl or tk
#	lastUnAffectedVersions: a list of patch levels that do not yet exhibit the bug [*]
#	firstFixedVersions: a list of patch levels that do not anymore exhibit the bug [*]
#
#	[*] one patch level for each minor version
#
# Result:
#	0 if the current tcl or tk version doesn't exhibit the bug
#	1 if the current tcl or tk version does exhibit the bug
#
proc isBugVersion {component lastUnAffectedVersions firstFixedVersions} {
	set patchLevel [set ::${component}_patchLevel]
	set minorVersion [set ::${component}_version]
	foreach v $lastUnAffectedVersions {
		if {[string match $minorVersion* $v]} {
			if {[expr {[package vcompare $patchLevel $v] <= 0}]} {
				return 0; # doesn't have the bug
			}
			break
			#
			# Check the fixed versions
			#
		}
	}
	foreach v $firstFixedVersions {
		if {[string match $minorVersion* $v]} {
			return [expr {[package vcompare $patchLevel $v] < 0}]
		}
	}

	#
	# No firstFixedVersion was specified for the current minor version.
	#

	if {[llength $firstFixedVersions]} {
		#
		# We assume that minor version numbers higher than the minor version
		# for the highest fixed patch level are all cured. For example:
		# if the last (and highest) patch level in firstFixedVersions
		# is 8.6.14, then we assume that all patch levels for minor releases
		# 8.7+, 9.0+, etc. have been fixed also.
		#
		if {[package vcompare $minorVersion [lindex $firstFixedVersions end]] >= 0} {
			return 0
		}
	}

	# the bug is present
	return 1
}


# logCallbackArgs --
#
#	Records the arguments supplied in a global variable.
#	Used as reporting callback.
#
proc logCallbackArgs {args} {
	set ::callbackArgs $args
}


# logReporting --
#
#	Records a reporting into a log variable. For detailed mode:
#	 - the event window
#	 - the raw Tk event that caused the detection
#	 - the new window under the mouse pointer
#
#	For strict mode, only the new window under the mouse pointer is recorded.
#
#	Used as a reporting callback for windetect, so only *reported* detection
#	events are recorded.
#
proc logReporting {pointerWin args} {
	upvar 1 W W event event; # see [::windetect::report]
	if {$::testconf(-detectiondetails)} {
		lappend ::reportingLog [list $W $event $pointerWin]
	} else {
		# record the new pointer window only
		lappend ::reportingLog $pointerWin
	}
}


# no_leak_drawing_events --
#
# Enforces:
# - (if type = ws) that the windowing system has passed all pending
#   notifications induced by previous Tk commands onto Tk, and
# - that Tk has serviced all window events from the event loop.
#
proc no_leak_drawing_events {type {w invalid}} {
	switch -- $type {
		tk {
			update
		}
		ws {
			if {$w eq ""} {
				#
				# This case is used if:
				# - the last mapped toplevel is withdrawn, and therefore no toplevel
				#   window can be passed as an argument, or
				# - if a toplevel is withdrawn without that leading to window drawing
				#   events.
				#
				# The technique below is based on letting the windowing system generate
				# extra notifications, and wait for the corresponding drawing events
				# to be serviced by the Tk event mechanism. We do this by swapping
				# the stacking order of two toplevels that are under our private control.
				# This makes the windowing system send a VisibilityNotify notification.
				# We wait for the servicing of the corresponding <Visibility> event.
				#
				variable wsCtrlTopmost
				if {! [winfo exists ._wsctrl1]} {
					# create two private windows and make them as inconspicuous
					# as possible.
					for {set i 0} {$i <= 1} {incr i} {
						set t [toplevel ._wsctrl$i -bg {}]
						wm withdraw $t
						wm overrideredirect $t 1; # we don't need to acces the window manager
						wm geometry $t 1x1-100-100
						bindtags $t {}; # render insensitive to standard binding tags
						wm deiconify $t
						tkwait visibility $t
					}
					update
					set wsCtrlTopmost [wm stackorder ._wsctrl1 isabove ._wsctrl0]
					return
				}
				set newOnTop [expr {! $wsCtrlTopmost}]
				raise ._wsctrl$newOnTop ._wsctrl$wsCtrlTopmost
				tkwait visibility ._wsctrl$newOnTop
				set wsCtrlTopmost $newOnTop
			} else {
				catch {waitForWindowEvent $w <Visibility> 1 100}
			}

			#
			# An [update] enforces that drawing events that are queued after
			# <Visibility> events, are serviced. These are <Expose> events,
			# which are the last in sequence when drawing a window to the
			# screen. The [update] drains the event queue from these events.
			#
			update
		}
	}
}


proc notifyExtraWindowEvents {} {
	foreach eventType {<Configure> <Unmap> <Map> <Visibility> <Expose>} {
		bind all $eventType [list signalWindowEvent %W $eventType]
	}
}


# pause --
#
# Halt the process for a specified duration.
# Used as a trace callback for the option -eyefriendly.
#
proc pause {duration args} {
	if {$::Generic(pkgName) eq "tkwintrack"} {
		update; # enforce redraw completion of the pathname widget
	}
	after $duration
}

proc process_cmdline_args {testScript} {
	variable argv
	variable testconf
	variable tcltestconf

	# define command line options
	switch -- $testScript {
		gui {
			set optionList {
				-accommodatewm bool 1
				-checkclean flag 0
				-delay nonnegint 50
				-detectiondetails flag 0
				-extrawindowevents flag 0
				-eyefriendly flag 0
				-nowm flag 0
				-skipintro flag 0
				-timing flag 0
				-wmonly flag 0
				-wsrespite nonnegint 0
			}
		}
		unit {
			set optionList {
				-checkclean flag 0
				-delay nonnegint 50
				-wsrespite nonnegint 0
			}
			array set testconf {
				-timing 0
				-detectiondetails 0
			}
		}
	}
	foreach {name type default} $optionList {
		set option($name,type) $type
		set testconf($name) $default
		lappend option(names) $name
	}

	# process command line arguments as test configuration options
	array set tcltestconf {}
	set index -1
	set skipNext 0
	foreach el $argv {
		incr index
		if {$skipNext} {
			set skipNext 0
			continue
		}
		if {$el in $option(names)} {
			if {$option($el,type) eq "flag"} {
				set testconf($el) 1
			} else {
				set value [lindex $argv [expr {$index+1}]]
				switch -- $option($el,type) {
					"bool" {
						set valid [expr {[string is boolean -strict $value]}]
					}
					"nonnegint" {
						set valid [expr {[string is integer -strict $value] && ($value >= 0)}]
					}
				}
				if {! $valid} {
					set errMsg "error: invalid value \"$value\" for option $el"
					if {$::tcl_interactive} {
						return -code error $errMsg
					} else {
						puts stderr $errMsg
						exit 1
					}
				}
				if {($el in "-delay -wsrespite") && ($value >= 1000)} {
					# the value must be smaller than the timeout value used by [waitForReporting]
					set errMsg "error: for the purpose of testing, the value for option $el must be less than 1000"
					if {$::tcl_interactive} {
						return -code error $errMsg
					} else {
						puts stderr $errMsg
						exit 1
					}
				}
				set testconf($el) $value
				set skipNext 1
			}
		} elseif {[string index $el 0] eq "-"} {
			set testconf($el) [lindex $argv [expr {$index+1}]]
			set tcltestconf($el) $testconf($el)
			set skipNext 1
		} else {
			set errMsg "error: invalid option \"$el\""
			if {$::tcl_interactive} {
				return -code error $errMsg
			} else {
				puts stderr $errMsg
				exit 1
			}
		}
	}
}

# record --
#
# A no-op version of [record] for usage by non-tkwintrack scenario's
#
proc record {args} {}


# setTestConstraintConditionally --
#
#	Set constraint only if [tcltest::configure -constraints] was not set for it
#	(on the command line)
#
proc setTestConstraintConditionally {constraint value} {
	if {$constraint ni [tcltest::configure -constraints]} {
		testConstraint $constraint $value
	}
}


proc setup-foreign {} {
	interp create foreign
	interp eval foreign [subst {
		package require -exact Tk $::tcl_patchLevel
		wm geometry . 100x50+450+400
		wm title . "foreign"
		wm withdraw .
		update idletasks
		bind . <Map> {after idle {unset _canary}}
		set _canary 1
		wm deiconify .
		raise .
		vwait _canary
		bind . <Map> {}
	}]
}


proc signalDetection {args} {
	if {$::testconf(-timing)} {
		puts -nonewline |*:[dt.get]
	}
	if {$::testconf(-detectiondetails)} {
		if {$::testconf(-timing)} {
			puts -nonewline |[lrange [lindex $args 0] 1 end]
		} else {
			puts [lrange [lindex $args 0] 1 end]
		}
	}
	incr ::_waitvar(detection)
}


proc signalReporting {args} {
	if {$::testconf(-timing)} {
		puts -nonewline |r:[dt.get]
	}
	incr ::_waitvar(reporting)
}


proc signalWindowEvent {w event args} {
	if {$::testconf(-extrawindowevents)} {
		puts \t|$w|$event|
	}
	incr ::_waitvar(drawing|$w|$event)
}


# strace --
#
# Invoke the strace facility (Linux/Unix only)
#
# Sample invocation:
#
#    strace attach -e trace=%network
#
proc strace {mode args} {
	if {$::tcl_platform(platform) ne "unix"} {
		return
	}
	switch -- $mode {
		attach {
			puts -nonewline "\n**** "
			exec strace -p [set pid [pid]] {*}$args >&@ stdout &
			after 10
		}
		detach {
			exec killall strace
			puts "\n**** "
		}
		mark {
			flush stdout; puts "*** MARK [lindex $args 0] ***"
		}
	}
}


# tkWithNotifyInferior --
#
#	Determines how the current Tk version handles binding scripts for
#	crossing events with detail "NotifyInferior".
#
# Arguments: none
#
# Results: 0: Tk ignores the script
#          1: Tk invokes the script
#
# Side effects: sets a namespace variable Generic(withNotifyInferior)
#               on first invocation.
#
proc tkWithNotifyInferior {} {
	variable Generic

	if {! [info exists Generic(withNotifyInferior)]} {

		# create a private window and make it as inconspicuous as possible.
		set t [toplevel ._windetect_test_ni -bg {}]
		wm withdraw $t
		wm overrideredirect $t 1
		wm geometry $t 1x1-100-100
		bindtags $t $t
		bind $t <Leave> {set ::Generic(withNotifyInferior) 1}

		set Generic(withNotifyInferior) 0
		set pointerWin [winfo containing [winfo pointerx .] [winfo pointery .]]
		wm deiconify $t
		tkwait visibility $t
		event generate $t <Leave> -mode NotifyNormal -detail NotifyInferior; # *A*
		destroy $t

		if {$pointerWin ne ""} {
			# The [event generate] at *A* has compromised the grab mechanism.
			# The following line restores sanity.
			event generate $pointerWin <Enter>
		}
	}
	return $Generic(withNotifyInferior)
}


# toplevelTwo --
#
# This proc is meant to prepare windows during the setup stage of a test.
# Therefore, it calls [update] at the end to ensure that no window events
# linger around for servicing and thus interfere with the event processing
# during test proper (the body of the test).
#
proc toplevelTwo {subCmd {keepPointerInRoot "keepPointerInRoot"}} {
	switch -- $subCmd {
		create {
			toplevel .two -bg #eeeeee
			#
			# The update after each of the following [wm] commands is needed
			# to ensure that the geometry is truly and timely effectuated.
			#
			wm withdraw .two
			update
			wm geometry .two 200x200+180+180
			update
		}
		map {
			if {$keepPointerInRoot eq "keepPointerInRoot"} {
				wm deiconify .two
				raise .two; # above any toplevels of other applications on the screen
				tkwait visibility .two
			} else {
				event generate . <Motion> -warp 1 -x 40 -y 40 -when now
				controlPointerWarpTiming
				wm deiconify .two
				raise .two; # above any toplevels of other applications on the screen
				waitForReporting 2
			}

			if {[applyWmAccommodations KWin]} {
				# Needed with KWin 5.24.4
				#
				# It seems that KWin lost it completely. Amongst others,
				# [wm geometry .two] returns wrong info, and test pointer_motion-3.1
				# fails. Allowing KWin some respite appears to help.
				#
				after 10
			}
			update
		}
	}
}


# twait --
#
# Wait for a specified duration while allowing events to be processed.
#
proc twait {duration} {
	if {$::testconf(-timing)} {
		dt.reset
		puts -nonewline "<twait|${duration}ms"
	}
	set ::_twait 1; after $duration {unset ::_twait}
	vwait ::_twait
	if {$::testconf(-timing)} {
		puts >
	}
}


proc waitForReporting.init {{doUpdate "doUpdate"}} {
	array set ::_waitvar {
		detection 0
		reporting 0
	}
	if {$doUpdate eq "doUpdate"} {
		update; # ensure that earlier window events have been serviced before we start tracing
	}
	trace add execution ::windetect::handleDetectionEvent enter signalDetection
	trace add execution [::windetect::configure -callback] enter signalReporting
	if {$::testconf(-timing)} {
		dt.reset
	}
}


# waitForReporting --
#
# Wait until a certain number of detection events have been reported
#
# Arguments:
#	detectionCount : the total number of detection events to be reported
#	preCount       : the number of detection events that have already occurred
#	                 before this proc executed, but still need to be reported.
#	                 This is relevant in case of <Destroy> events.
#	doWaitForPnw   : (tkwintrack only) wait for a <Configure> event
#	                 on the pathname widget
#	timeout        : maximum waiting duration for a reporting. The default value
#	                 accommodates high latencies as observed with win32 when the
#	                 pointer leaves the application area.
#
# Results:
#	-1 : timeout
#	 0 : OK
#	 1 : more detections events than requested occurred
#
proc waitForReporting {{detectionCount 1} {preCount 0} {doWaitForPnw 1} {timeout 1000}} {
	if {$::testconf(-timing)} {
		dt.reset
		puts -nonewline "<$detectionCount"
	}
	variable _waitvar
	array set _waitvar {
		detection 0
		reporting 0
	}
	if {$preCount > 0} {
		set _waitvar(detection) $preCount
	}

	set afterID [after $timeout {set _waitvar(reporting) -1}]
	while {true} {
		vwait _waitvar(reporting)
		if {$_waitvar(reporting) == -1} {
			set str "WARN_REPORTING_TIMEOUT"
			if {$::testconf(-timing)} {
				puts "|$str>"
			} elseif {$::testconf(-detectiondetails)} {
				puts $str
			}
			return -1
		}

		# verify that all detection events have been serviced
		if {($detectionCount eq "*") || ($_waitvar(detection) >= $detectionCount)} {
			# we're done
			break
		}
	}
	after cancel $afterID

	if {($::Generic(pkgName) eq "tkwintrack") && ([tk windowingsystem] eq "win32") && $doWaitForPnw} {
		#
		# Most tests require that the redraw of our own widgets (the outline frames
		# and the pathname widget) is completed before we start waiting for another
		# round of detection events. Otherwise window events, especially <Expose>
		# events will carry over from this waiting round to the next. This is
		# confusing at the very least if we do -extrawindowevents, but on win32 it
		# also leads to test failures. Under x11 the completion of screen redraws
		# for toplevels occurs without this extra call.
		#
		update
	}

	set result 0
	if {($detectionCount ne "*") && ($_waitvar(detection) > $detectionCount)} {
		set result 1
		if {$::testconf(-detectiondetails) || $::testconf(-timing)} {
			if {$::testconf(-timing)} {
				append str "|"
			}
			append str "WARN_EXTRA_DETECTS"
		}
	}
	if {$_waitvar(reporting) > 1} {
		if {$::testconf(-detectiondetails) || $::testconf(-timing)} {
			if {[info exists str] || $::testconf(-timing)} {
				append str "|"
			}
			append str "WARN_EXTRA_REPORTINGS"
		}
	}
	if {$::testconf(-timing)} {
		append str ">"
	}
	if {[info exists str]} {
		puts $str
	}
	return $result
}


# waitForWindowEvent --
#
# Wait until a certain number of a specific window event have been delivered to a window
#
# Arguments:
#
# w     : the window
# event : the type of event
# count : the expected number of events
#
proc waitForWindowEvent {w event {count 1} {timeout 1000}} {
	variable _waitvar
	set _waitvar($w|$event) 0
	bind $w $event [list signalWindowEvent $w $event]
	set afterID [after $timeout [list set _waitvar($w|$event) -1]]
	while {true} {
		vwait _waitvar($w|$event)
		if {$_waitvar($w|$event) == -1} {
			bind $w $event {}
			unset _waitvar($w|$event)
			return -code error "waiting for $event event on $w timed out (> 1000 ms)"
		}

		# verify that the expected number of events have been delivered
		if {$_waitvar($w|$event) >= $count} {
			# we're done
			break
		}
	}
	after cancel $afterID
	bind $w $event {}
	unset _waitvar($w|$event)
}


proc window_setup {testType} {
	variable testconf

	switch -- $testType {
		"unit" {
			wm overrideredirect . 1
			wm geometry . 200x200+300+300
			pack propagate . 0
			pack [frame .f -bg #00ee00 -width 80 -height 80]
			update idletasks
			wm deiconify .
			tkwait visibility .
			event generate . <Motion> -warp 1 -x 100 -y 100 -when now
			controlPointerWarpTiming
			update; # enforce completion of screen redraws
			assert {([winfo pointerx .] == 400) && ([winfo pointery .] == 400)}
		}
		"gui" {
			createFrames
			toplevelTwo create
			wm geometry . 200x200+300+300
			pack propagate . 0
			. configure -bg #d0d0d0
			if {! [winfo ismapped .]} {
				wm deiconify .
				tkwait visibility .
			}
			raise .
			update
			set pw [getPointerWin]
			event generate . <Motion> -x 100 -y 100 -warp 1
			if {$pw eq "."} {
				controlPointerWarpTiming
			} else {
				catch {waitForWindowEvent . <Enter>}
			}

			# At the start of each test, before any test setup, ensure that all windows
			# are in their standard initial state as brought about by this proc.
			trace add execution test enter ensureWindowsClean

			set ::Generic(window_setup_gui_done) 1
		}
	}
}

# EOF
