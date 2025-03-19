#
# Copyright 2023 Erik Leunissen
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

namespace eval ::osshell {}

proc ::osshell::init {} {
	#
	# Although there may be use cases for retrieving windowing system
	# information from tclsh without Tk being loaded, this isn't yet
	# supported.
	#
	if {[catch {package present Tk}]} {
		namespace delete ::osshell
		return -code error "osshell requires that Tk is loaded beforehand"
	}

	package provide osshell 0.0.0
}


# ::osshell::identify_de --
#
#	Determine the desktop environment
#
# Arguments: none
#
# Results: the name of the desktop environment
#
# Side effects: none
#
proc ::osshell::identify_de {} {
	switch -- [tk windowingsystem] {
		win32 {
			#
			# Method 1: based on the shell window. This can be retrieved
			#           by twapi. This method detects when there is no shell
			#           window, and therefore it is the most reliable method.
			#
			if {[catch {
				package require twapi_ui
				set shell_window [twapi::get_shell_window]
				if {$shell_window eq ""} {
					set de "none"
				} else {
					package require twapi_process
					set de [twapi::get_process_name [twapi::get_window_process $shell_window]]
				}
			} result]} {
				set err_twapi $result
			} else {
				return [file rootname $result]; # strip file name extension
			}

			#
			# Method 2 (fallback): the registry entry for the shell program
			#
			# Retrieving the desktop environment from the registry is not 100%
			# reliable because the desktop program doesn't register *itself* as
			# being the current desktop environment (or the current shell
			# in Microsoft parlance). It's the other way round:
			#
			# Windows OS just invokes at startup as a shell program whatever
			# command has been registered in the registry (see below for the
			# relevant registry keys). So, we never get to know whether:
			# - the registry entry was changed after having launched the
			#   previously registered shell program, or
			# - the desktop environment was replaced, without it having been
			#   registered as the new shell program.
			#
			# Microsoft calls the registered shell program "Windows Shell". The
			# initially registered, os-supplied, system-wide shell program
			# is "explorer.exe".
			# Note aside: explorer.exe is a peculiar program. On the very first
			#	invocation, it launches the desktop environment. If it is
			#	invoked another time while the desktop environment is already
			#	active, it launches the file explorer, i.e. a file manager.
			#
			if {[catch {package require registry} err_registry]} {
				return -code error "$err_twapi and $err_registry"
			}

			#
			# Retrieve the command line for the shell program from the registry.
			# We account for the fact that the user-specific setting in
			# HKEY_CURRENT_USER has prevalence over the system-wide setting in
			# HKEY_LOCAL_MACHINE.
			#
			foreach key [list "HKEY_CURRENT_USER" "HKEY_LOCAL_MACHINE"] {
				append key "\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon"
				if {! [catch {registry get $key Shell} cmdline]} {
					regexp -- {^(.+?) (?:-|/)} $cmdline -- cmdline; # strip command options
					return [file rootname [file tail $cmdline]]; # strip path + file name extension
				} else {
					lappend errMsgs $cmdline
				}
			}

			#
			# There is no shell program, and therefore no desktop environment,
			# which seems to be an erroneous situation on MS Windows. Also,
			# the code is expected to never reach this place because there
			# seems to have been no way for a user to launch the present
			# application.
			#
			puts stderr "Warning:\n[join $errMsgs \n]"
			return "none"
		}
		x11 {
			foreach key [list XDG_SESSION_DESKTOP XDG_CURRENT_DESKTOP] {
				if {[::info exists ::env($key)] && \
						($::env($key) ne "")} {
					return $::env($key)
				}
			}

			#
			# There is no desktop environment.
			#
			return "none"
		}
		aqua {
			#
			# The desktop environment is not replaceable, and its name is unclear.
			# We consider the desktop environment as automatically identified, and
			# return a neutral name. We refer to the background document for
			# considerations regarding the neutral name.
			#
			return "aqua_DE_NR"
		}
	}
}


# ::osshell::identify_wm --
#
#	Determine the window manager
#
# Arguments: none
#
# Results: the name of the window manager
#
# Side effects: none
#
proc ::osshell::identify_wm {} {
	#
	# Don't attempt to cache the result because window managers can be replaced
	# while the application is running.
	#
	switch -- [tk windowingsystem] {
		win32 {
			#
			# The window manager is not replaceable, and its name is unclear.
			# We consider the window manager as automatically identified, and
			# return a neutral name. We refer to the background document for
			# considerations regarding the neutral name.
			#
			return "win32_WM_NR"
		}
		x11 {
			# use xprop to retrieve all properties set on the root window
			if {[catch {exec xprop -root -notype} result1]} {
				if {[string match {couldn't execute "*": no such file or directory} $result1]} {
					return -code error $result1
				}
			} else {
				# check for properties that conform to the EWMH standard
				if {[regexp -line {^_NET_SUPPORTING_WM_CHECK: window id # (0x[[:xdigit:]]+)$} $result1 -- window_id]} {
					if {! [catch {exec xprop -id $window_id -notype _NET_WM_NAME} result2]} {
						if {[regexp -line {^_NET_WM_NAME = \"(.+)\"} $result2 -- wm_name]} {
							return $wm_name
						}
					}
				}

				#
				# There is no window manager running or the window manager
				# did not conform to the EWMH standard. Try other methods.
				#

				#
				# WindowMaker doesn't set the _NET_WM_NAME property on the
				# window identified by _NET_SUPPORTING_WM_CHECK, but it does
				# set several properties on the root window that match
				# *_WINDOWMAKER_*
				#
				if {[string match *WINDOWMAKER* $result1]} {
					return WindowMaker
				}
			}

			#
			# Twm doesn't even set _NET_SUPPORTING_WM_CHECK on the root
			# window. We try to detect whether the twm executable
			# is running. But this method needs to be taken only as
			# last resort.
			#
			if {! [catch {exec ps -C twm} result]} {
				if {[string match {* twm} $result]} {
					return twm
				}
			}

			#
			# We failed to find out the name of the window manager. It is
			# possible that no window manager is running, but only if
			# there also is no desktop environment.
			#
			if {[identify_de] eq "none"} {
				return "none"
			}

			#
			# We have too little information about the window manager.
			#
			return "unknown"
		}
		aqua {
			#
			# The window manager is not replaceable, and its name is unclear.
			# We consider the window manager as automatically identified, and
			# return a neutral name. We refer to the background document for
			# considerations regarding the neutral name.
			#
			return "aqua_WM_NR"
		}
	}
}


# ::osshell::tiling --
#
#	Indicates whether the window manager is (strictly) tiling, i.e.
#	it resists the overlapping of toplevels.
#
# Arguments: none
#
# Results: 0 or 1
#
# Side effects: none
#
proc ::osshell::tiling {} {
	if {[identify_wm] eq "none"} {
		return -code error "there is no window manager active"
	}
	foreach tl {._osshell_a ._osshell_b} {
		toplevel $tl -bg {}
		wm geometry $tl 40x40-100+100
		wm deiconify $tl
		raise $tl
		tkwait visibility $tl
		update
	}

	# Get geometry of the toplevel windows, but not from [wm geometry], because
	# that fails with some window managers, notably KWin.
	foreach tl {a b} {
		set $tl\(rootx) [winfo rootx ._osshell_$tl]
		set $tl\(rooty) [winfo rooty ._osshell_$tl]
		set $tl\(width) [winfo width ._osshell_$tl]
		set $tl\(height) [winfo height ._osshell_$tl]
	}

	foreach tl {._osshell_a ._osshell_b} {
		destroy $tl
	}

	# determine whether windows overlap
	return [expr {(($b(rootx) >= $a(rootx) + $a(width)) || ($a(rootx) >= $b(rootx) + $b(width)) \
			|| ($b(rooty) >= $a(rooty) + $a(height)) || ($a(rooty) >= $b(rooty) + $b(height)))}]
}


# ::osshell::info --
#
#	Return windowing system information
#
# Arguments:
#	component : the windowing system component
#	property  : the component's property
#
# Results: depends on arguments
#
# Side effects: none
#
proc ::osshell::info {component property} {
	# validate supplied values for component and format
	if {$component ni "de wm ws"} {
		return -code error "invalid parameter \"$component\""
	}

	switch -- $property {
		name {
			switch -- $component {
				de {
					if {[catch {identify_de} result]} {
						return -code error $result
					} else {
						return $result
					}
				}
				wm {
					if {[catch {identify_wm} result]} {
						return -code error $result
					} else {
						return $result
					}
				}
				ws {
					return [tk windowingsystem]
				}
			}
		}
		tiling {
			if {$component ne "wm"} {
				return -code error "invalid parameter \"tiling\""
			}
			return [::osshell::tiling]
		}
		default {
			return -code error "invalid parameter \"$property\""
		}
	}
}

::osshell::init

# EOF
