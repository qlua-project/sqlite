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


namespace eval ::windetect {}

# ::windetect::init --
#
#	Checks requirements, provides the package to the interpreter and sources
#	follow-up code for a specific Tk variant.
#
# Arguments: none
#
# Results: none
#
# Side effects:
#	Sets initial values, configurable and not-configurable
#
proc ::windetect::init {} {
	variable Windetect
	set Windetect(version) 2.0.1

	# prerequisites
	set errMsg ""
	if {[catch {package present Tk} result]} {
		set errMsg "windetect requires a running Tk application"
	} elseif {[package vcompare $result 8.5] < 0} {
		set errMsg "windetect $Windetect(version) requires Tk 8.5 or newer"
	} elseif {[tk windowingsystem] ni "x11 win32"} {
		if {[info exists ::env(WINDETECT_NO_RESTRICT_WS)] && ($::env(WINDETECT_NO_RESTRICT_WS) eq "1")} {
			puts stderr "WARNING: bypassing ws restriction on explicit user request (WINDETECT_NO_RESTRICT_WS)"
		} else {
			set errMsg "windetect $Windetect(version) does not support the windowing system \"[tk windowingsystem]\""
		}
	}
	if {$errMsg ne ""} {
		namespace delete ::windetect
		return -code error $errMsg
	}

	# Constants and initial values
	#
	# The default value for -delay is chosen to provide ample room for
	# the screen update of a few simple widgets (as in package tkwintrack),
	# while preventing a sluggish appearance to the human eye.
	#
	set Windetect(installDir) [getScriptDir]
	array set Windetect {
		callback ::windetect::callback.default
		delay 50
		detect 0
		options {callback delay wsrespite}
		pointerWin ""
		sched,report ""
		timeout 1
		wsrespite 0
	}
	variable Instrumentation [dict create]

	if {! [tkWithNotifyInferior]} {
#
# *** FOR TK VARIANT ni0 ONLY. SEE THE FILE README.ni0-ni1 ***
#
# ::windetect::handleGrabTrace --
#
#	(execution trace callback, only used if Tk ignores binding scripts for
#    crossing events with detail field NotifyInferior, see also Tk ticket
#    #47d4f29159)
#
# (De)activiation of grabs results in crossing events if the pointer window is
# an ancestor of the grabbed window. But the binding script for these events is
# not invoked if the detail field for the crossing event is NotifyInferior,
# and therefore "handleDetectionEvent" is not invoked. We compensate for this
# lack by:
# - identifying the relevant situations using an execution trace on the
#   grab command (see [detect]);
# - calling [handleDetectionEvent] outside the event mechanism, thus
#   faking a detection event with detail NotifyInferior.
#
# Note that this hack works only for the (de)activation of grabs using the
# script level command [grab].
#
# Arguments:
#	cmd : the complete command as called
#	code : the return code of the traced command
#	args : supplemental arguments appended by the trace mechanism, not used.
#
# Results: none
#
# Side effects: see description
#
proc ::windetect::handleGrabTrace {cmd code args} {
	if {($code == 0) && [regexp {^(?:::)?grab(?:\s+(set|release))?(?:\s+-global)?\s+(\..+)$} $cmd -- mode grabWin]} {
		set X [winfo pointerx .]; set Y [winfo pointery .]
		set pointerWin [winfo containing $X $Y]

		if {($pointerWin ne "") && ([winfo toplevel $pointerWin] eq [winfo toplevel $grabWin]) \
				&& [isPathNameAncestor $pointerWin $grabWin]} {
			# fake a detection event with detail NotifyInferior if the pointer window is instrumented
			set events [getInstrEventsForWindow $pointerWin]
			if {($mode eq "release") && ("<Enter>" in $events)} {
				handleDetectionEvent <Enter> NotifyUngrab NotifyInferior $X $Y $pointerWin
			} elseif {"<Leave>" in $events} {
				# "grab" or "grab set"
				handleDetectionEvent <Leave> NotifyGrab NotifyInferior $X $Y $pointerWin
			}
		}
	}
}
# *** END TK VARIANT ni0 ONLY ***
	}

	package provide windetect $Windetect(version)
}


# ::windetect::callback.default --
#
#	Writes detection information to stdout
#
# Arguments:
#	W: the pathname for the window
#	X: the X-coordinate of the mouse pointer at the time of the detection event
#	Y: the Y-coordinate of the mouse pointer at the time of the detection event
#
# Results: none
#
# Side effects: as described above
#
proc ::windetect::callback.default {W X Y} {
	if {$W eq ""} {set W "{}"}
	puts "$W $X $Y"
}


# ::windetect::configure --
#
#	Sets or returns values for configurable variables
#
# Arguments: none
#
# Results: none if ok, or an error message
#
# Side effects: as described
#
proc ::windetect::configure {args} {
	variable Windetect

	if {[set nargs [llength $args]] == 0} {
		foreach option $Windetect(options) {
			lappend result -$option $Windetect($option)
		}
		return $result
	} elseif {$nargs == 1} {
		set mode getvalue
	} elseif {[expr {fmod($nargs, 2) != 0}]} {
		return -code error "uneven # arguments"
	} else {
		if {[detect] eq "on"} {
			return -code error "windetect cannot be reconfigured while detection is on"
		}
		set mode setvalue
	}

	foreach {option value} $args {
		switch -- $option {
			-callback {
				if {$mode eq "getvalue"} {
					return $Windetect(callback)
				} else {
					set Windetect(callback) $value
				}
			}
			-delay {
				if {$mode eq "getvalue"} {
					return $Windetect(delay)
				} else {
					if {[string is integer -strict $value] && ($value >= 0)} {
						if {$value != $Windetect(delay)} {
							set Windetect(delay) $value
						}
					} else {
						return -code error "invalid value \"$value\" for option \"$option\""
					}
				}
			}
			-wsrespite {
				if {$mode eq "getvalue"} {
					return $Windetect(wsrespite)
				} else {
					if {[string is integer -strict $value] && ($value >= 0)} {
						if {$value != $Windetect(wsrespite)} {
							set Windetect(wsrespite) $value
							set Windetect(timeout) [expr {$value + 1}]
						}
					} else {
						return -code error "invalid value \"$value\" for option \"$option\""
					}
				}
			}
			default {
				return -code error "invalid option \"$option\""
			}
		}
	}
}


# ::windetect::detect --
#
#	Set or get the detection state. If switched on, report an initial fake
#	detection event, leading to an initial reporting.
#
# Arguments:
#	state: on/off
#
# Results: the detection state if no argument was supplied, otherwise nothing
#
# Side effects: see description
#
proc ::windetect::detect {{state ""}} {
	variable Windetect
	if {$state ni "on off {}"} {
		return -code error "invalid value \"$state\" for argument \"state\""
	}

	if {$state eq "off"} {
		if {$Windetect(detect) == 0} {
			return
		}

		# Cancel any outstanding reporting
		if {$Windetect(sched,report) ne ""} {
			after cancel $Windetect(sched,report)
			set Windetect(sched,report) {}
		}

		#
		# Remove windetect bindings from the instrumentation tags.
		#
		dict for {bt eventList} $::windetect::Instrumentation {
			foreach event $eventList {
				set oldScript [bind $bt $event]
				regsub {(\n)?::windetect::handle(DetectionEvent|WinDestruction)( (<Enter>|<Leave>|<Destroy>) %m %d %X %Y)? %W} $oldScript {} newScript
				bind $bt $event $newScript
			}
		}
		if {! [tkWithNotifyInferior]} {
			trace remove execution grab leave ::windetect::handleGrabTrace
		}

		set Windetect(detect) 0
	} elseif {$state eq "on"} {
		if {$Windetect(detect) == 1} {
			return
		}
		if {[dict size $::windetect::Instrumentation] == 0} {
			return -code error "nothing is instrumented"
		}

		#
		# Install windetect bindings for all instrumentation tags.
		#
		dict for {bt eventList} $::windetect::Instrumentation {
			foreach event $eventList {
				if {$event eq "<Destroy>"} {
					bind $bt <Destroy> {+::windetect::handleWinDestruction %W}
				} else {
					# <Enter> or <Leave>
					bind $bt $event "+::windetect::handleDetectionEvent $event %m %d %X %Y %W"
				}
			}
		}
		if {! [tkWithNotifyInferior]} {
			trace add execution grab leave ::windetect::handleGrabTrace
		}

		set Windetect(detect) 1

		#
		# Induce an initial reporting, as if the mouse pointer just entered
		# the current pointer window. Conditions:
		# - the pointer window, if any, is instrumented with <Enter> events
		# - there is no grab in this application/interpreter, or the pointer is
		#   inside the grab subtree (i.e. including the grab window).
		#
		set X [winfo pointerx .]; set Y [winfo pointery .]
		set pointerWin [winfo containing $X $Y]
		if {$pointerWin eq ""} {
			return
		}
		if {"<Enter>" ni [getInstrEventsForWindow $pointerWin]} {
			return
		}
		set grabWin [grab current]
		if {($grabWin eq "") || (([winfo toplevel $pointerWin] eq [winfo toplevel $grabWin]) \
				&& ! [isPathNameAncestor $pointerWin $grabWin])} {
			#
			# Induce reporting by calling [handleDetectionEvent] directly, passing
			# a fake <Enter> event with detail NotifyNonlinear.
			#
			handleDetectionEvent <Enter> NotifyNormal NotifyNonlinear $X $Y $pointerWin
		}
	} else {
		return [expr {$Windetect(detect)?"on":"off"}]
	}
}


# ::windetect::exit --
#
#	Switches off detection mode, deletes the namespace and removes the package
#
# Arguments: none
#
# Results: none
#
# Side effects: as described
#
proc ::windetect::exit {} {
	detect off
	namespace delete ::windetect
	package forget windetect
}


# ::windetect::getInstrEventsForWindow --
#
#	Returns a list of events used for the instrumentation of a window
#
# Arguments:
#	W : window to get the instrumentation events for
#
# Side effects: none
#
proc ::windetect::getInstrEventsForWindow {W} {
	set winTags [bindtags $W]
	set result [list]
	dict for {bt eventList} $::windetect::Instrumentation {
		if {$bt in $winTags} {
			foreach event $eventList {
				if {$event ni $result} {
					lappend result $event
				}
			}
		}
	}
	return $result
}


# ::windetect::getScriptDir --
#
#	Returns the normalized path of the directory of the currently
#	executing script.
#
# Arguments: none
#
# Side effects: none
#
proc ::windetect::getScriptDir {} {
	set fileName [info script]
	if {$fileName eq ""} {
		return -code error "Called [info level 0] outside the active invocation of a script."
	}
	while {! [catch {file readlink $fileName} result]} {
		if {[file pathtype $result] ne "absolute"} {
			set fileName [file  join [file dirname $fileName] $result]
		} else {
			set fileName $result
		}
	}
	return [file dirname [file normalize $fileName]]
}


# ::windetect::handleDetectionEvent --
#
#	Discards irrelevant events and schedules a reporting as follows:
#
#	For delay == 0:
#		Schedules execution of [report] at idle time.
#
#	For delay > 0:
#		Schedules [report] for execution after the reporting delay, if that hadn't
#		been done already. Detection data are recorded here for reporting later.
#
# Arguments:
#	event  : <Enter>, <Leave> or <Destroy>
#	mode   : the mode field of the crossing event
#	detail : the detail field of the crossing event
#	X      : x screen coordinate
#	Y      : y screen coordinate
#	W      : the event window
#
# Results: none
#
# Side effects: see description
#
proc ::windetect::handleDetectionEvent {event mode detail X Y W} {
	variable Windetect

	# ignore virtual crossings altogether
	if {$detail in "NotifyVirtual NotifyNonlinearVirtual"} {
		return
	}

	if {$event eq "<Enter>"} {
		#
		# The function of the following statement is twofold:
		# - it prevents invoking of [waitForEnterEvent] inside [report], or
		# - it makes [waitForEnterEvent] return if it was already invoked.
		#
		set Windetect(waitForEnterEvent) 0
	} else {
		if {! $Windetect(waitForEnterEvent)} {
			set Windetect(waitForEnterEvent) 1
		}
	}

	if {$Windetect(delay) == 0} {
		#
		# Don't invoke [report] here. That would disregard work that's already been
		# scheduled for execution, some of which is essential for correctly
		# determining the new pointer window (e.g. upon destruction of the pointer
		# window). Beware that some Tk window events are scheduled as idle callbacks.
		#
		# Schedule invocation of [report] as soon as everything on the event queue
		# has been serviced, and all idle callbacks have been invoked.
		#
		after idle [list ::windetect::report $event $mode $detail $X $Y $W]
	} else {
		#
		# If [report] hasn't been scheduled yet, do it now. Schedule it for
		# execution as soon as possible after the reporting delay. If [report]
		# has already been scheduled, only update the last recorded detection
		# event.
		#
		set Windetect(lastRecord) [list $event $mode $detail $X $Y $W]
		if {$Windetect(sched,report) eq ""} {
			set Windetect(sched,report) [after $Windetect(delay) \
					{::windetect::report {*}$::windetect::Windetect(lastRecord)}]
		}
	}
}


# ::windetect::handleWinDestruction --
#
#	Handler for <Destroy> events, acting as a precursor for [handleDetectionEvent].
#	Its function is to discard those cases where the window being destroyed
#	is not the pointer window.
#
#	Note: if the <Destroy> event originates from a call to the Tcl command
#	"destroy", this event handler executes and completes before the command
#	returns. This is in contrast with handler calls for <Leave> and <Enter> events.
#
# Arguments:
#	W : the destroyed window
#
# Results: none
#
# Side effects: see description
#
proc ::windetect::handleWinDestruction {W} {
	variable Windetect

	#
	# Bail out if the window being destroyed isn't the last recorded pointer
	# window (this includes the case where the destroyed window isn't mapped).
	#
	if {($W ne $Windetect(pointerWin)) && ($Windetect(pointerWin) ne "*")} {
		return
	}

	# Mark the pointer window as temporarily undetermined
	set Windetect(pointerWin) *
	handleDetectionEvent <Destroy> NA NA [winfo pointerx .] [winfo pointery .] $W
}


# ::windetect::instrument --
#
#	Handle associations between binding tags and detection events.
#
# Arguments:
#	action    : add, remove or info
#	bt        : the binding tag to associate, which may be a widget pathname
#	eventList : a list containing the events to associate
#
# Results: a list of binding tags or the entire instrumentation dict
#          if the action argument is "info"
#
# Side effects: see description
#
proc ::windetect::instrument {args} {

	# Check the arguments
	set argc [llength $args]
	if {$argc > 2} {
		return -code error "wrong # args: should be \"[lindex [info level 0] 0] ?bindtag? ?eventlist?\""
	}

	set _allEvents [list <Enter> <Leave> <Destroy>]
	if {$argc == 2} {
		if {$::windetect::Windetect(detect)} {
			return -code error "reconfiguring instrumentation is not allowed while detection is on"
		}
		set eventList [lindex $args 1]
		if {$eventList eq "*"} {
			set eventList $_allEvents
		}
		set indices {}
		foreach event $eventList {
			if {[set index [lsearch $_allEvents $event]] < 0} {
				return -code error "invalid value \"$event\" for argument \"eventlist\""
			} else {
				if {[lsearch $indices $index] < 0} {
					lappend indices $index
				} else {
					return -code error "duplicate event \"$event\" for argument \"eventlist\""
				}
			}
		}
	}

	variable Instrumentation
	set bt [lindex $args 0]
	switch -- $argc {
		0 {
			return $Instrumentation
		}
		1 {
			if {$bt ni [dict keys $Instrumentation]} {
				return [list]
			}
			return [dict get $Instrumentation $bt]
		}
		2 {
			#
			# Register the associations between the binding tag and
			# the window events passed on the command line.
			#
			# Note that we don't activate or deactivate the corresponding
			# bindings to the windetect internal event handlers here. That's
			# being done when detection is switched on or off by [detect].
			#
			dict unset Instrumentation $bt
			foreach event $eventList {
				dict lappend Instrumentation $bt $event
			}
		}
	}
}


# ::windetect::isPathNameAncestor --
#
#	Determines whether window win1 is an ancestor of win2 in the pathname
#	hierarchy of Tk windows.
#
# Arguments:
#	win1 : window to test ancestry of
#	win2 : window to test ancestry against
#
# Result: boolean 1 if win1 is an ancestor of win2; otherwise 0.
#
# Side effects: none
#
proc windetect::isPathNameAncestor {win1 win2} {
	if {($win1 eq "") || ($win2 eq "") || ($win1 eq $win2)} {
		return 0
	}
	return [string match $win1* $win2]
}


# ::windetect::report --
#
#	Determines the new pointer window and invokes the reporting
#	callback, passing on the detection information.
#
# Arguments:
#	event  : <Enter>, <Leave> or <Destroy>
#	mode   : the mode field of the crossing event
#	detail : the detail field of the crossing event. Used for debugging.
#	X      : x screen coordinate
#	Y      : y screen coordinate
#	W      : the event window
#
# Results: none
#
# Side effects: see description
#
# See also: https://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.html#events:pointer_window
# for the meaning of the mode and detail fields of crossing events, and their values.
#
proc ::windetect::report {event mode detail X Y W} {
	variable Windetect

	set Windetect(sched,report) {}

	if {$event eq "<Enter>"} {
		set Windetect(pointerWin) $W
		eval [linsert $Windetect(callback) end $W $X $Y]
	} else {
		# <Leave> and <Destroy> events.
		#
		# <Leave> and <Destroy> events are usually followed by a corresponding
		# <Enter> event for the new pointer window, leading to another,
		# successive invocation to this proc "report". We only invoke the
		# reporting callback if no such subsequent <Enter> event occurs within
		# a certain amount of time. This is the case:
		# A. if the mouse pointer destination is outside the grab subtree in
		#    case of grabs: no <Enter> event occurs.
		# B. if the mouse pointer destination is in an area of the screen that
		#    isn't used by the client application: no <Enter> event occurs.
		# C. with many toplevel crossings if the reporting delay is zero or
		#    near zero, because of latency of the windowing system
		#    (display server + window manager). Note that this includes cases
		#    of pointer window destruction where a toplevel window is crossed.
		#    If the subsequent <Enter> event is not detected within time, this
		#    leads to an incorrect double reporting.
		# D. *** FOR TK VARIANT NI0 ONLY ***
		#    if the mouse pointer moved into an ancestor in the pathname
		#    hierarchy of the old pointer window. The <Enter> event for the
		#    ancestor window occurs, but binding scripts are not invoked. This
		#    is the consequence of the Tk variant "ni0" ignoring crossing
		#    events with detail NotifyInferior. See also Tk ticket #47d4f29159.
		#    Note that this case includes mouse pointer transitions induced by
		#    the destruction of the pointer window, except if a toplevel was
		#    crossed.
		#

		# Case A.
		#
		# We only handle grab cases in combination with a <Leave> event here.
		# Combinations with a <Destroy> event are handled as any ordinary
		# <Destroy> event.
		#
		# We need to count with the following cases:
		# - the pointer was moved out of a grabbed window: ($W eq [grab current]).
		#   This also deselects any <Destroy> events.
		# - a grab was set on a window while the mouse pointer resided outside
		#   the grab subtree.
		#
		if {($W eq [grab current]) || ($mode eq "NotifyGrab")} {
			#
			# Report "{}" as the new pointer window in order to prevent the
			# false impression of the mouse having interacted with a window
			# outside the grab subtree.
			#
			set Windetect(pointerWin) {}
			eval [linsert $Windetect(callback) end {} $X $Y]
			return
		}

		#
		# Carry out the reporting of this event if:
		# a. we already received a subsequent <Enter> event in the
		#    meantime, or
		# b. an immediately successive <Enter> event occurred while
		#    waiting.
		#
		if {($Windetect(waitForEnterEvent) == 1) && ([waitForEnterEvent] == 0)} {
			#
			# Case B, C or D.
			#
			# Determine the new pointer window based on the pointer coordinates
			# associated with the detection event, and invoke the reporting
			# callback.
			#
			set Windetect(pointerWin) [winfo containing $X $Y]
			eval [linsert $Windetect(callback) end $Windetect(pointerWin) $X $Y]
			return
		}
		#
		# The subsequent <Enter> event for the mouse pointer transition was
		# serviced in the meantime, possibly by waiting for it.
		#
		# Let the next [report], induced by the <Enter> event that was serviced
		# in the meantime, determine the new pointer window.
		#
	}
}


# ::windetect::tkWithNotifyInferior --
#
#	Determines how the current Tk version handles binding scripts for
#	crossing events with detail field "NotifyInferior".
#
# Arguments: none
#
# Results: 0: Tk ignores the script (ni0)
#          1: Tk invokes the script (ni1)
#
# Side effects: sets a namespace variable Windetect(withNotifyInferior)
#               on first invocation.
#
proc ::windetect::tkWithNotifyInferior {} {
	variable Windetect

	if {! [info exists Windetect(withNotifyInferior)]} {
		#
		# The code in tkWithNotifyInferior.tcl makes a call to "update".
		# That's why we cannot run that code as a proc inside windetect: it
		# could cause unknown effects in the client interpreter, and that's
		# a "NoNo". We need it to be in a separate process.
		#
		set Windetect(withNotifyInferior) [exec [info nameofexecutable] \
				[file join $Windetect(installDir) utils tkWithNotifyInferior.tcl] \
				[package present Tk]]
	}
	return $Windetect(withNotifyInferior)
}


# ::windetect::waitForEnterEvent --
#
#	Waits for a subsequent <Enter> event. The timeout value equals the value
#	for the option -wsrespite + 1. See also [init] and [configure].
#
#	Meaning of values for Windetect(waitForEnterEvent):
#	-1 : WAITING TIMED OUT
#	 0 : [report] SHOULD NOT WAIT / ABORT WAITING, (SUBSEQUENT ENTER EVENT WAS DETECTED)
#	 1 : [report] SHOULD WAIT
#	 2 : WAITING IN PROGRESS
#
# Arguments: none
#
# Results:
#	-1 : waiting was foregone
#	 0 : no <Enter> event occurred while waiting
#	 1 : an <Enter> event occurred while waiting
#
# Side effects: manipulates the wait variable Windetect(waitForEnterEvent)
#
proc ::windetect::waitForEnterEvent {} {
	variable Windetect

	if {$Windetect(waitForEnterEvent) == 2} {
		#
		# A safety catch to prevent starting another wait while waiting
		# is already in progress.
		#
		return -1
	}

	set Windetect(waitForEnterEvent) 2
	set afterID [after $Windetect(timeout) {
		set ::windetect::Windetect(waitForEnterEvent) -1
	}]
	vwait ::windetect::Windetect(waitForEnterEvent)

	if {$Windetect(waitForEnterEvent) != -1} {
		#
		# An <Enter> event occurred while waiting
		#
		after cancel $afterID
		return 1
	}

	#
	# Timeout, no <Enter> event occurred while waiting
	#
	set Windetect(waitForEnterEvent) 0
	return 0
}

::windetect::init

#EOF
