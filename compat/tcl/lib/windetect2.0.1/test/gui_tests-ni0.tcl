#
# GUI integration tests for windetect, specific for Tk versions that skip
# binding scripts for crossing events with detail field NotifyInferior.
# Also used by package tkwintrack if installed alongside windetect.
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
# TEST ORGANIZATION:
#
#  O.   INITIAL DETECTION EVENTS
#  A.   POINTER MOTION
#  B.   MOVING OR RESIZING THE POINTER WINDOW
#  C.   CHANGING THE STACKING ORDER OF THE POINTER WINDOW
#  D.   GRAB ACTIVATION AND DEACTIVATION
#  E.   MAPPING OR UNMAPPING THE POINTER WINDOW
#  F.   DESTRUCTION OF THE POINTER WINDOW
#

#
# THE EXPECTED TEST RESULT WITH MULTIPLE SCENARIO'S
#
# There are two main scenario's, named after the package: windetect and
# tkwintrack. The main scenario windetect may be diversified by the value
# for the reporting delay, resulting in windetect-noDelay and
# windetect-defaultDelay.
#
# There are two modes of result checking:
# 1. strict mode, which tests just the new pointer window. This is the default.
# 2. detailed mode, which tests for a list of detection details consisting of:
#    - the event window,
#    - the raw Tk event,
#    - the new pointer window
#    This mode is meant for detailed inspection. It's activated by supplying
#    the test configuration flag -detectiondetails.
#
# The proc [getExpectedResult] automatically selects the intended result,
# based on the current package name, the setting for the reporting delay,
# and on whether the flag -detectiondetails was set.
#

#
# O. INITIAL DETECTION EVENTS
#
test init_report-1.1 {initial reporting, pointer inside application area, no grab} -constraints {no_tkwintrack includeWmNotInvolved} -setup {
	windetect::detect off
	set reportingLog {}
} -body {
	windetect::detect on; # windetect fakes a detection event leading to ...
	waitForReporting 1 1; # ... initial reporting
	set reportingLog
} -cleanup {
	unset -nocomplain reportingLog
} -result [getExpectedResult \
		windetect "{. <Enter> .}"]

test init_report-1.2 {no initial reporting if pointer outside grab subtree} -constraints {no_tkwintrack includeWmNotInvolved} -setup {
	windetect::detect off
	pack .f1
	grab .f1
	update; # enforce complete effectuation of the grab before switching on detection
	set reportingLog {}
} -body {
	windetect::detect on; # no (fake) detection event
	if {[waitForReporting 1 1 1 10] != -1} {
		error "timeout expected"
	}; # no initial reporting
	set reportingLog
} -cleanup {
	grab release .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pack forget .f1
	no_leak_drawing_events tk
	unset -nocomplain reportingLog
} -result ""

test init_report-1.3 {no initial reporting if pointer outside application area} -constraints {no_tkwintrack includeWmNotInvolved} -setup {
	windetect::detect off
	pointer_move . w out
	if {[tk windowingsystem] eq "win32"} {
		# The pointer leaves the application area. Therefore, extra wm respite
		# is needed. See also the comment to test pointer_motion-3.2.
		after 500
	}
	update; # enforce completion of the interaction with the display server for some window managers
	set reportingLog {}
} -body {
	windetect::detect on; # no (fake) detection event
	if {[waitForReporting 1 1 1 100] != -1} {
		error "timeout expected"
	}; # no initial reporting
	set reportingLog
} -cleanup {
	pointer_move . c
	waitForReporting
	unset -nocomplain reportingLog
} -result ""

if {$Generic(pkgName) eq "windetect"} {
	if {[windetect::detect] eq "off"} {
		windetect::detect on; # windetect fakes a detection event leading to ...
		waitForReporting 1 1; # ... initial reporting
	}
}

#
# A. POINTER MOTION
#    A.1 Without grabs
#
test pointer_motion-1.0 {no reporting takes place if detection is switched off} -constraints includeWmNotInvolved -setup {
	$Generic(pkgName)::detect on
	pack .f1
	update
	set reportingLog {}
} -body {
	$Generic(pkgName)::detect off
	pointer_move .f1 c
	if {[waitForReporting 1 1 0 10] != -1} {
		error "timeout expected"
	}; # no detection events are reported
	record state(outline) outline .f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .f1
	update
	$Generic(pkgName)::detect on
	waitForReporting 1 1; # initial reporting
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect {} \
		tkwintrack {outline: outline.none pnw: pnw.unmapped}]

test pointer_motion-1.1 {into and out of a window, container = parent} -constraints includeWmNotInvolved -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	pointer_move .f1.f2 c
	waitForReporting
	record state(1,outline) outline .f1.f2
	record state(1,pnw) pnw
	pointer_move .f1 c
	waitForReporting
	record state(2,outline) outline .f1
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .f1.f2 .f1
	waitForReporting
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1.f2 <Enter> .f1.f2} {.f1.f2 <Leave> .f1}" \
		tkwintrack {}]

test pointer_motion-1.2 {into a window, container != parent} -constraints includeWmNotInvolved -setup {
	pack .g -in .f1
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	pointer_move .g c
	waitForReporting 2
	record state(outline) outline .g
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	waitForReporting
	pack forget .f1 .g
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.g <Enter> .g}" \
		tkwintrack {}]

test pointer_motion-1.3 {out of a window, container != parent} -constraints includeWmNotInvolved -setup {
	pack .g -in .f1
	pack .f1
	update
	pointer_move .g c
	waitForReporting
	set reportingLog {}
} -body {
	pointer_move .f1 c
	waitForReporting 2
	record state(outline) outline .f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .f1 .g
	waitForReporting
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Enter> .f1}" \
		tkwintrack {}]

test pointer_motion-1.4 {into a grandchild window and back again, include virtual crossing} -constraints includeWmNotInvolved -setup {
	pack .f1.f2
	pack .f1
	update
	set reportingLog {}
} -body {
	pointer_move .f1.f2 c
	waitForReporting 2; # including one virtual crossing <Enter> event
	record state(1,outline) outline .f1.f2
	record state(1,pnw) pnw
	pointer_move . c
	waitForReporting 2; # including one virtual crossing <Leave> event
	record state(2,outline) outline .
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .f1.f2 .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1.f2 <Enter> .f1.f2} {.f1.f2 <Leave> .}" \
		tkwintrack {}]

#
# A. POINTER MOTION
#    A.2 With grabs
#
test pointer_motion-2.1 {out of a grabbed child window} -constraints {includeWmNotInvolved bug_Tk_e3888d5820} -setup {
	pack .f1
	update
	grab .f1
	pointer_move .f1 c
	waitForReporting 2 1
	set reportingLog {}
} -body {
	pointer_move . c
	waitForReporting
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	grab release .f1
	pack forget .f1
	waitForReporting 1 1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Leave> {}}" \
		tkwintrack {outline: outline.none pnw: pnw.unmapped}]

test pointer_motion-2.2 {into and out of a grabbed toplevel} -constraints {includeWmInvolved bug_Tk_e3888d5820} -setup {
	toplevelTwo map
	grab .two; # generates a detection event
	waitForReporting
	set reportingLog {}
} -body {
	pointer_move .two c; # enter grabwin
	waitForReporting
	record state(1,outline,root) outline .
	record state(1,outline,two) outline .two
	record state(1,pnw) pnw
	pointer_move . c; # leave grabwin
	waitForReporting
	record state(2,outline,root) outline .
	record state(2,outline,two) outline .two
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline,root) $state(1,outline,two) $state(1,pnw) $state(2,outline,root) $state(2,outline,two) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	grab release .two
	waitForReporting
	wm withdraw .two
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two <Enter> .two} {.two <Leave> {}}" \
		tkwintrack [list 1,outline,root: outline.none 2,outline,root: outline.none 2,outline,two: outline.none 2,pnw: pnw.unmapped]]

#
# A. POINTER MOTION
#    A.3 Toplevel crossings
#
test pointer_motion-3.1 {into and out of an overlapping toplevel} -constraints includeWmInvolved -setup {
	toplevelTwo map
	set reportingLog {}
} -body {
	pointer_move .two c
	waitForReporting 2
	record state(1,outline,root) outline .
	record state(1,outline,two) outline .two
	record state(1,pnw) pnw
	pointer_move . c
	waitForReporting 2
	record state(2,outline,root) outline .
	record state(2,outline,two) outline .two
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline,root) $state(1,outline,two) $state(1,pnw) $state(2,outline,root) $state(2,outline,two) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm withdraw .two
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two <Enter> .two} {. <Enter> .}" \
		tkwintrack [list 1,outline,root: outline.none 2,outline,two: outline.none]]

test pointer_motion-3.2 {out of the client area and back again} -constraints includeWmInvolved -setup {
	set reportingLog {}
} -body {
	event generate . <Motion> -warp 1 -x -20 -y 100 -when tail
	#
	# Needs an awful 140 milliseconds to deliver the <Leave> event on Windows 7.
	# For reference: up to a few 100 microseconds are typical values for various
	# window managers on Linux-x11 (which is also considerably longer than other
	# cases of detection on Linux-x11). See also Tk ticket ff3580fa5e.
	#
	waitForReporting
	record state(1,outline) outline .
	record state(1,pnw) pnw
	pointer_move . c
	waitForReporting
	record state(2,outline) outline .
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Leave> {}} {. <Enter> .}" \
		tkwintrack [list 1,outline: outline.none 1,pnw: pnw.unmapped]]

test pointer_motion-3.3 {into a window in a foreign interpreter and back again} -constraints includeWmInvolved -setup {
	setup-foreign
	set reportingLog {}
} -body {
	# move into foreign toplevel
	event generate . <Motion> -warp 1 -x 200 -y 125 -when tail
	waitForReporting
	record state(1,outline) outline .
	record state(1,pnw) pnw
	# move back into toplevel
	pointer_move . c
	waitForReporting
	record state(2,outline) outline .
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	interp delete foreign
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Leave> {}} {. <Enter> .}" \
		tkwintrack [list 1,outline: outline.none 1,pnw: pnw.unmapped]]

#
# B. MOVING OR RESIZING THE POINTER WINDOW
#
test pw_move_resize-1.1 {Leave and enter window by moving it} -constraints includeWmNotInvolved -setup {
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	pack configure .f1 -side bottom
	waitForReporting
	record state(1,outline) outline .
	record state(1,pnw) pnw
	pack configure .f1 -side top
	waitForReporting
	record state(2,outline) outline .f1
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .f1
	waitForReporting
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Leave> .} {.f1 <Enter> .f1}" \
		tkwintrack {}]

test pw_move_resize-1.2 {Leave and enter window by resizing it} -constraints includeWmNotInvolved -setup {
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	.f1 configure -width 20 -height 20
	waitForReporting
	record state(outline) outline .
	record state(pnw) pnw
	.f1 configure -width 80 -height 80
	waitForReporting
	record state(outline) outline .f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .f1
	waitForReporting
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Leave> .} {.f1 <Enter> .f1}" \
		tkwintrack {}]

test pw_move_resize-1.3 {Enter sibling non-toplevel window through resizing} -constraints includeWmNotInvolved -setup {
	pack .f1
	pack .g
	waitForReporting
	set reportingLog {}
} -body {
	.f1 configure -height 120
	waitForReporting 2
	record state(outline) outline .f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .g .f1
	waitForReporting
	.f1 configure -height 80
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Enter> .f1}" \
		tkwintrack {}]

test pw_move_resize-2.1 {Leave grabbed window by moving it} -constraints {bug_Tk_e3888d5820 includeWmNotInvolved} -setup {
	pack .f1
	update
	grab .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	pack configure .f1 -side bottom
	waitForReporting
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	#
	# bug_Tk_e3888d5820 prevents the mouse pointer from moving correctly. This
	# results in a sequence of detection events that is very different from
	# what it ought to be.
	#
	pointer_move . c
	grab release .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pack forget .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Leave> {}}" \
		tkwintrack [list outline: outline.none pnw: pnw.unmapped]]

test pw_move_resize-2.2 {Leave grabbed window by resizing it} -constraints {bug_Tk_e3888d5820 includeWmNotInvolved} -setup {
	pack .f1
	update
	grab .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	.f1 configure -width 20 -height 20
	waitForReporting
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	#
	# bug_Tk_e3888d5820 prevents the mouse pointer from moving correctly. This
	# results in a sequence of detection events that is very different from
	# what it ought to be.
	#
	pointer_move . c
	grab release .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pack forget .f1
	.f1 configure -width 80 -height 80
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Leave> {}}" \
		tkwintrack [list outline: outline.none pnw: pnw.unmapped]]

test pw_move_resize-3.1 {Enter another toplevel by moving the pointer window} -constraints includeWmInvolved -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	wm geometry .two +120+120
	waitForReporting 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm geometry .two +180+180
	waitForReporting 2
	pointer_move . c
	wm withdraw .two
	waitForReporting 2
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Enter> .}" \
		tkwintrack {}]

test pw_move_resize-3.2 {Enter another toplevel by resizing the pointer window} -constraints includeWmInvolved -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	wm geometry .two 150x150
	waitForReporting 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm geometry .two 200x200
	waitForReporting 2
	pointer_move . c
	wm withdraw .two
	waitForReporting 2
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Enter> .}" \
		tkwintrack {}]

#
#  C. CHANGING THE STACKING ORDER OF THE POINTER WINDOW
#
#  Note:
#
#  We can't use a pair of windows that are parent and child in the
#  pathname hierarchy, because their stacking order is fixed: a child
#  window is always on top of its parent. To be able to change the stacking
#  order we employ two windows which are siblings in the pathname hierarchy,
#  where one is contained by the other using the option -in to the geometry
#  manager.
#
#  Changing the stacking order of toplevels through [lower] is generally
#  discouraged because it yields unpredictable results if the desktop
#  already has toplevels from other applications displayed in the
#  screen area where our test widgets reside. Use it carefully; best to let
#  any [lower] be followed up by a [raise].
#
test pw_restack-1.1 {non-toplevel, use [lower]} -constraints includeWmNotInvolved -setup {
	pack .f1
	pack .g -in .f1
	raise .g
	update
	pointer_move .g c
	waitForReporting
	set reportingLog {}
} -body {
	lower .g
	waitForReporting 2
	record state(outline) outline .f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .g .f1
	waitForReporting
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Enter> .f1}" \
		tkwintrack {}]

test pw_restack-1.2 {non-toplevel, use [raise]} -constraints includeWmNotInvolved -setup {
	pack .f1
	pack .g -in .f1
	lower .g
	update
	pointer_move .g c
	waitForReporting
	set reportingLog {}
} -body {
	raise .g
	waitForReporting 2
	record state(outline) outline .g
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	waitForReporting
	pack forget .g .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.g <Enter> .g}" \
		tkwintrack {}]

test pw_restack-2.1 {two toplevels} -constraints includeWmInvolved -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	lower .two; # Needed to prevent interference by the pnw of tkwintrack.
	            # This also happens to work around a limitation of icewm.
	raise .; # Prevents interference of toplevel windows from other applications.
	waitForReporting 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		pnw_follow_pointer
	}
	wm withdraw .two
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Enter> .}" \
		tkwintrack {}]

test pw_restack-2.2 {Leave from and return to toplevel by consecutive restacking} -constraints {x11 noPracticalUseCase includeWmInvolved} -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	#
	# Note: this case is useless in reality. We include it only because
	# it gives insight into event generation, queueing and servicing.
	#
	raise .
	raise .two
	#
	# Some windowing system generate four detection events, others (including
	# win32) don't generate any detection events at all. The latter windowing
	# systems probably have some logic to recognize that the effects of the
	# two commands are each others inverse, cancel them out and send no
	# notifications at all. This is observable, even if we halt the process
	# in between the two commands with [after ms]. The expected result of this
	# test reflects this duality in the behaviour of windowing systems.
	#
	# Count of detection events per window manager with -delay 0:
	#
	#	wsinfo				count
	#   _______________________________________________
	#	x11.-.-				4 (2 reportings)
	#	x11.e16.-			0
	#	x11.fluxbox.-		2 (this is a flaw of the wm)
	#	x11.FVWM.-			4 (2 reportings)
	#	x11.IceWM.-			0
	#	x11.KWin.-			4 (2 reportings)
	#	x11.Metacity.-		4 (2 reportings)
	#	x11.Openbox.-		4 (2 reportings)
	#	x11.twm.-			4 (2 reportings)
	#	x11.WindowMaker.-	4 (2 reportings)
	#	x11.Xfwm4.-			4 (2 reportings)
	#	win32.DWM.WE		0
	#
	waitForReporting 4
	record state(outline) outline .two
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	wm withdraw .two
	waitForReporting 2
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result "^[getExpectedResult \
		windetect-noDelay [list {\. <Enter> \.} {\.two <Enter> \.two}] \
		windetect-defaultDelay [list {\.two <Enter> \.two}] \
		tkwintrack [list]]$|^[getExpectedResult \
		windetect [list] \
		tkwintrack [list]]$" -match regexp

#
# D. GRAB ACTIVATION AND DEACTIVATION
#
test grabbing-1.1 {a content window, container = parent} -constraints includeWmNotInvolved -setup {
	pack .f1
	update
	set reportingLog {}
} -body {
	grab .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	record state(1,outline) outline .
	record state(1,pnw) pnw
	grab release .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	record state(2,outline) outline .
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Leave> {}} {. <Enter> .}" \
		tkwintrack [list 1,outline: outline.none 1,pnw: pnw.unmapped]]

test grabbing-1.2 {a content window, container != parent} -constraints includeWmNotInvolved -setup {
	pack .f1
	pack .g -in .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	grab .g
	waitForReporting
	record state(1,outline) outline .f1
	record state(1,pnw) pnw
	grab release .g
	waitForReporting
	record state(2,outline) outline .f1
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .g .f1
	waitForReporting
	unset -nocomplain state reportingLog
	no_leak_drawing_events tk
} -result [getExpectedResult \
		windetect "{.f1 <Leave> {}} {.f1 <Enter> .f1}" \
		tkwintrack [list 1,outline: outline.none 1,pnw: pnw.unmapped]]

test grabbing-1.3 {a toplevel window and next ungrab it} -constraints includeWmInvolved -setup {
	toplevelTwo map
	set reportingLog {}
} -body {
	grab .two
	waitForReporting
	record state(1,outline,root) outline .
	record state(1,outline,two) outline .two
	record state(1,pnw) pnw
	grab release .two
	waitForReporting
	record state(2,outline,root) outline .
	record state(2,outline,two) outline .two
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline,root) $state(1,outline,two) $state(1,pnw) $state(2,outline,root) $state(2,outline,two) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm withdraw .two
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Leave> {}} {. <Enter> .}" \
		tkwintrack [list 1,outline,root: outline.none 1,outline,two: outline.none 1,pnw: pnw.unmapped 2,outline,two: outline.none]]

test grabbing-2.1 {Leave from and return to a contained window through consecutive [grab]+[grab release]} -constraints {noPracticalUseCase includeWmNotInvolved} -setup {
	pack .f1
	update
	set reportingLog {}
} -body {
	grab .f1; # windetect fakes a detection event with detail NotifyInferior
	grab release .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 2 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{. <Leave> {}} {. <Enter> .}" \
		windetect-defaultDelay "{. <Enter> .}" \
		tkwintrack {}]

test grabbing-2.2 {Leave from and return to a toplevel through consecutive [grab]+[grab release]} -constraints {includeWmInvolved noPracticalUseCase} -setup {
	toplevelTwo map
	set reportingLog {}
} -body {
	grab .two
	grab release .two
	waitForReporting 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	event generate . <Motion> -warp 1 -x 40 -y 40 -when tail
	waitForReporting 2
	pointer_move . c
	wm withdraw .two
	waitForReporting 2
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{. <Leave> {}} {. <Enter> .}" \
		windetect-defaultDelay "{. <Enter> .}" \
		tkwintrack {}]

test grabbing-2.3 {Enter and leave a contained window through consecutive [grab release]+[pack forget] (container = parent)} -constraints includeWmNotInvolved -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	grab .f1.f2; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	set reportingLog {}
} -body {
	grab release .f1.f2; # windetect fakes a detection event with detail NotifyInferior
	pack forget .f1
	waitForReporting 2 1
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .f1.f2
	update
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{.f1 <Enter> .f1} {.f1 <Leave> .}" \
		windetect-defaultDelay "{.f1 <Leave> .}" \
		tkwintrack {}]

test grabbing-2.4 {Enter and leave a contained window through consecutive [grab release]+[pack forget] (container != parent)} -constraints includeWmNotInvolved -setup {
	pack .g -in .f1
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	grab .g
	waitForReporting
	set reportingLog {}
} -body {
	grab release .g
	pack forget .f1
	waitForReporting 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .g
	update
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{.f1 <Enter> .f1} {.f1 <Leave> .}" \
		windetect-defaultDelay "{.f1 <Leave> .}" \
		tkwintrack {}]

#
# E. MAPPING OR UNMAPPING THE POINTER WINDOW
#
test pw_mapping-1.1 {map and unmap the pointer window using [pack]} -constraints includeWmNotInvolved -setup {
	event generate . <Motion> -warp 1 -x 100 -y 40 -when now
	controlPointerWarpTiming
	set reportingLog {}
} -body {
	pack .f1
	waitForReporting
	record state(1,outline) outline .f1
	record state(1,pnw) pnw
	pack forget .f1
	waitForReporting
	record state(2,outline) outline .
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Enter> .f1} {.f1 <Leave> .}" \
		tkwintrack {}]

test pw_mapping-2.1 {Enter two packed widgets consecutively through a single [pack]} -constraints includeWmNotInvolved -setup {
	pack .f1.f2
	update
	event generate . <Motion> -x 100 -y 15 -warp 1
	controlPointerWarpTiming
	set reportingLog {}
} -body {
	pack .f1; # A single mouse pointer transition is expected, with source
	          # window ., destination window .f1.f2, and a virtual crossing
	          # of the intermediate window .f1. Instead, we receive events
	          # for two distinct transitions:
	          #    . -> .f1
	          #    .f1 -> .f1.f2.
	          # I don't understand why. Note that the inverse operation in
	          # the next test behaves as expected.
	          # With -delay=0 this leads to two reportings instead of one. All
	          # of this is revealed with the flags -detectiondetails and -timing.
	waitForReporting 2
	record state(outline) outline .f1.f2
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .f1.f2
	pack forget .f1
	waitForReporting 2
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{.f1 <Enter> .f1} {.f1.f2 <Enter> .f1.f2}" \
		windetect-defaultDelay "{.f1.f2 <Enter> .f1.f2}" \
		tkwintrack {}]

test pw_mapping-2.2 {Leave two packed widgets consecutively through a single [pack forget]} -constraints includeWmNotInvolved -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1.f2 c
	waitForReporting 2; # including one virtual <Enter> event
	set reportingLog {}
} -body {
	pack forget .f1
	waitForReporting 2; # including one virtual <Leave> event
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pack forget .f1.f2
	update
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1.f2 <Leave> .}" \
		tkwintrack {}]

test pw_mapping-3.1 {Enter a new toplevel by a single [wm withdraw]} -constraints includeWmInvolved -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	#
	# Of the consecutive <Leave> and <Enter> events, the latter arrives late
	# with some window managers (and sometimes the event loop goes idle
	# in between). With reporting delay 0, this leads to two distinct
	# reportings, each for a single event, instead of one reporting for two
	# events.
	# The lateness can be accommodated for by using large values for the option
	# -wsrespite. Note that the latency has been observed to vary considerably,
	# and may reach extreme values of up to 20 ms (Fluxbox).
	#
	wm withdraw .two
	waitForReporting 2
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		update; # necessary to force servicing of pending <Configure> events to .pnw
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
	no_leak_drawing_events ws .
} -result [getExpectedResult \
		windetect "{. <Enter> .}" \
		tkwintrack {}]

test pw_mapping-3.2 {Enter another toplevel and return from it through consecutive [wm withdraw]+[wm deiconify]} -constraints {x11 noPracticalUseCase includeWmInvolved} -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	#
	# Note: this case is useless in practical circumstances. We include it
	# only because it gives insight into the inner workings of event
	# queuing and servicing.
	#
	# See also the comment to the previous test
	#
	wm withdraw .two  ; # Under win32 these consecutive commands don't generate
	wm deiconify .two ; # any crossing events. It seems that the windowing system
	                  ; # collapses the two opposing actions into a net noop.
	waitForReporting 4
	record state(outline) outline .two
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	wm withdraw .two
 	waitForReporting 2
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{. <Enter> .} {.two <Enter> .two}" \
		windetect-defaultDelay "{.two <Enter> .two}" \
		tkwintrack {}]

test pw_mapping-3.3 {Enter a new toplevel by a single [wm deiconify]} -constraints includeWmInvolved -setup {
	event generate . <Motion> -warp 1 -x 40 -y 40 -when now
	controlPointerWarpTiming
	set reportingLog {}
} -body {
	wm deiconify .two
	waitForReporting 2
	record state(outline) outline .two
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	wm withdraw .two
	waitForReporting 2
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two <Enter> .two}" \
		tkwintrack {}]

#
# Note regarding tests pw_mapping-3.[45]
#
# These tests exercise cases with non-linear virtual crossings. Under most
# window managers the crossing events received for cases 3.4 and 3.5
# (use option -detectiondetails), don't match with what the
# reference literature prescribes:
#
#    https://www.x.org/releases/X11R7.7/doc/libX11/libX11/libX11.html#Window_EntryExit_Events
#
# The issue exhibits only if the crossing events are induced by [wm deiconify],
# and they regard the detail field for toplevel crossings.
#
# The only window managers that seem to comply are x11.Fluxbox (3.5 only),
# x11.KWin and win32.win32_WM_NR.
#
# Also remarkable is that test pw_mapping-3.6 is the inverse of pw_mapping-3.5,
# but pw_mapping-3.6 does not exhibit the issue with any window manager.
#
# All in all, I have no confidence that any particular window manager
# does the right thing. Therefore, tests pw_mapping-3.[45] carry a constraint
# "wmIssueDetailFieldToplevelCrossing".
#
test pw_mapping-3.4 {Enter another toplevel from and to internal window} -constraints {includeWmInvolved wmIssueDetailFieldToplevelCrossing} -setup {
	pack .f1 -anchor nw
	update
	pack [frame .two.f1 -width 80 -height 80 -bg purple] -side right -anchor se
	pack propagate .two.f1 0
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	wm deiconify .two
	raise .two
	waitForReporting 4
	record state(outline) outline .two.f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm withdraw .two
	waitForReporting 4
	destroy .two.f1
	pointer_move . c
	waitForReporting
	pack forget .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two.f1 <Enter> .two.f1}" \
		tkwintrack {}]

test pw_mapping-3.5 {Enter another toplevel to internal window} -constraints {includeWmInvolved wmIssueDetailFieldToplevelCrossing} -setup {
	pack [frame .two.f1 -width 80 -height 80 -bg purple] -side right -anchor se
	pack propagate .two.f1 0
	update
	event generate . <Motion> -warp 1 -x 40 -y 40
	controlPointerWarpTiming
	set reportingLog {}
} -body {
	wm deiconify .two
	raise .two
	waitForReporting 3
	record state(outline) outline .two.f1
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm withdraw .two
	waitForReporting 3
	destroy .two.f1
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		pnw_follow_pointer
	}
	#
	# No leak prevention needed
	#
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two.f1 <Enter> .two.f1}" \
		tkwintrack {}]

test pw_mapping-3.6 {Enter another toplevel from internal window} -constraints includeWmInvolved -setup {
	pack .f1 -anchor nw
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	wm deiconify .two
	raise .two
	waitForReporting 3
	record state(outline) outline .two
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm withdraw .two
	waitForReporting 3
	pointer_move . c
	waitForReporting
	pack forget .f1
	no_leak_drawing_events tk
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two <Enter> .two}" \
		tkwintrack {}]

test pw_mapping-4.1 {Leave the client area by unmapping a toplevel: withdraw} -constraints includeWmInvolved -setup {
	set reportingLog {}
} -body {
	wm withdraw .
	#
	# Needs an awful 150 milliseconds to deliver the <Leave> event on Windows 7.
	# For reference: up to a few 100 microseconds are typical values for various
	# window managers on Linux-x11 (which is also considerably longer than other
	# cases of detection on Linux-x11). See also Tk ticket ff3580fa5e.
	#
	waitForReporting
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	wm deiconify .
	waitForReporting
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Leave> {}}" \
		tkwintrack [list outline: outline.none pnw: pnw.unmapped]]

test pw_mapping-4.2 {Leave and enter the client area by successive unmapping/remapping a toplevel: iconify (or: "minimize")} -constraints {includeWmInvolved wmPresent failsWithWindowMaker} -setup {
	set reportingLog {}
} -body {
	#
	# Notes:
	#
	# - This test has been observed to fail when the desktop environment or
	#   window manager either:
	#   - are lacking (test is constrained to not run, so no problem)
	#   - animates the process of iconification, or the subsequent
	#   deiconification. Most desktop environments or window managers can be
	#   configured to do that. Some do it by default, notably Enlightenment and
	#   WindowMaker.
	#
	# - With KWin (the standard wm for the KDE desktop environment), the invocation
	#   of [wm iconify .] in this test has been observed to ruin other tests,
	#   notably the tkwintrack tests in the section "TESTS REGARDING KEYBOARD SHORTCUTS".
	#   Replacing [wm iconify .] with [wm withdraw .], or issuing an extra call to
	#   [wm withdraw .] before deiconifying makes them run normally again.
	#
	wm iconify .
	waitForReporting
	record state(1,outline) outline .
	record state(1,pnw) pnw
	if {[applyWmAccommodations KWin]} {
		wm withdraw .; # see the note about KWin above
	}
	wm deiconify .
	waitForReporting
	record state(2,outline) outline .
	record state(2,pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(1,outline) $state(1,pnw) $state(2,outline) $state(2,pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	no_leak_drawing_events ws .
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Leave> {}} {. <Enter> .}" \
		tkwintrack [list 1,outline: outline.none 1,pnw: pnw.unmapped]]

#
# F. DESTRUCTION OF THE POINTER WINDOW
#
#	Note:
#
#	Servicing of <Destroy> events is done within the execution time of the
#	corresponding [destroy] command. This is different from <Enter> and
#	<Leave> events, which are normally serviced without any corresponding
#	Tcl command. <Enter> and <Leave> events may also be generated by the
#	[event generate ...] command. In that case, they may be serviced at
#	an arbitrary time, the soonest before the command returns.
#

test pw_destroy-1.1 {a packed window} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c_withDetectionDetails} -setup {
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	destroy .f1
	waitForReporting 1 1; # the detection event happened before the destroy command returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	createFrames
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Destroy> .}" \
		tkwintrack {}]

test pw_destroy-1.2 {Destruction of pointer window through destruction of its container window, single [destroy]} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c_withDetectionDetails} -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1.f2 c
	waitForReporting 2; # including one virtual <Enter> event
	set reportingLog {}
} -body {
	destroy .f1
	waitForReporting 2 2; # both detection events happened before the destroy command returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	createFrames
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{.f1.f2 <Destroy> .}" \
		windetect-defaultDelay "{.f1 <Destroy> .}" \
		tkwintrack {}]

#
# Consecutive combinations with [destroy]
#
# Note that consecutive <Leave><Destroy> events on the same window are
# impossible to bring about, e.g. through the sequence:
#
#	[pack forget .f1]; [destroy .f1]
#
# <Destroy> events are generated and serviced before the corresponding
# [destroy] command returns. The binding script for the <Leave> event
# scheduled by [pack] is never actually executed because the target
# window has been destroyed in the meantime.
#

test pw_destroy-2.1 {Consecutive destruction of contained windows, two separate calls to [destroy]} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c_withDetectionDetails} -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1.f2 c
	waitForReporting 2
	set reportingLog {}
} -body {
	destroy .f1.f2
	destroy .f1
	waitForReporting 2 2; # both detection events happened before the respective destroy commands returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	createFrames
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{.f1.f2 <Destroy> .}" \
		windetect-defaultDelay "{.f1 <Destroy> .}" \
		tkwintrack {}]

test pw_destroy-2.2 {Consecutive destruction of pointer window and unmapping its container window, [destroy]+[pack forget]} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c_withDetectionDetails} -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1.f2 c
	waitForReporting 2
	set reportingLog {}
} -body {
	destroy .f1.f2
	pack forget .f1
	waitForReporting 2 1; # the <Destroy> detection event happened before the destroy command returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	createFrames
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect-noDelay "{.f1.f2 <Destroy> .}" \
		windetect-defaultDelay "{.f1 <Leave> .}" \
		tkwintrack {}]

test pw_destroy-2.3 {Consecutive destruction of pointer window and mapping another one, [destroy]+[pack]} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c} -setup {
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	destroy .f1
	pack .g -pady 20
	waitForReporting 2 1; # the <Destroy> detection event was delivered/handled before the destroy command returned
	record state(outline) outline .g
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .g
	waitForReporting
	createFrames
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.g <Enter> .g}" \
		tkwintrack {}]

test pw_destroy-2.4 {Consecutive destruction of pointer window and mapping another one with reverse calling order, [destroy]+[place]} -constraints includeWmNotInvolved -setup {
	pack .f1
	update
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	#
	# The comments to the commands below explain the steps in the event loop
	# for the case without reporting delay.
	#
	place .g -in . -x 85 -y 25
	update idletasks;	  # Paints .g onto the screen and generates an <Enter> event on .g,
						  # which in turn queues a call to [handleDetectionEvent].
						  #
	destroy .f1;          # Calls [handleDetectionEvent] for the <Destroy> event synchronously,
						  # which in turn schedules a [report] for the <Destroy> detection event
						  # for execution at idle time.
						  #
	waitForReporting 2 1; # 1. The event loop services the queued [handleDetectionEvent]
						  #    for the <Enter> event on .g, which in turn appends on the idle
						  #    queue [report] for <Enter>  on .g
						  # 2. At the end of still the same pass, the event loop services everything
						  #    on the idle queue, calling [report] twice:
						  #    2a. once for the <Destroy> event on .f1 and
						  #    2b. once for the <Enter> event on .g, in that order.
						  #    This order is reversed when compared to the order of command invocations
						  #    that induced them. Because all servicing completes in the same pass
						  #    of the event loop, we ought not call [waitForReporting] twice.
						  #
						  # *********************************************************************
						  #  Known bug (with zero reporting delay):
						  #  Sometimes the event loop services 2a. before 1. This implies that the
						  #  event loop became idle early. I [EL] don't understand why or how this
						  #  unexpected behaviour can happen. Whatever the cause, it prevents
						  #  event pairing from taking place and leads to an extra reporting which
						  #  makes the test fail.
						  #  Note: the unexpected behaviour does not occur if the test is the first
						  #  one run (e.g. using "-match pw_destroy-2.4").
						  # *********************************************************************
						  #
	record state(outline) outline .g
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	place forget .g
	waitForReporting
	createFrames
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.g <Enter> .g}" \
		tkwintrack {}]

test pw_destroy-2.5 {Destruction of pointer window through destruction of its container window, and mapping another one, single [destroy]+[pack]} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c} -setup {
	pack .f1.f2
	pack .f1
	update
	pointer_move .f1.f2 c
	waitForReporting 2
	set reportingLog {}
} -body {
	destroy .f1
	pack .g
	waitForReporting 3 2; # both <Destroy> detection events happened before the destroy command returned
	record state(outline) outline .g
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	pack forget .g
	waitForReporting
	createFrames
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.g <Enter> .g}" \
		tkwintrack {}]

test pw_destroy-3.1 {a grabbed pointer window} -constraints {includeWmNotInvolved bug_Tk_9e1312f32c_withDetectionDetails} -setup {
	pack .f1
	update
	grab .f1; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pointer_move .f1 c
	waitForReporting
	set reportingLog {}
} -body {
	destroy .f1
	waitForReporting 1 1; # the detection event happened before the destroy command returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	createFrames
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.f1 <Destroy> .}" \
		tkwintrack {}]

test pw_destroy-3.2 {a pointer window which is outside the grab subtree} -constraints {includeWmNotInvolved bug_Tk_e3888d5820} -setup {
	pack .f1
	pack .g -side bottom
	update
	pointer_move .f1 c; # ensure that the outline widgets exist
	waitForReporting
	grab .g
	waitForReporting
	set reportingLog {}
} -body {
	destroy .f1
	if {[waitForReporting 1 0 1 10] != -1} {
		error "timeout expected"
	}; # no detection events are reported
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	#
	# bug_Tk_e3888d5820 prevents the mouse pointer from moving correctly. This
	# results in a sequence of detection events that is very different from
	# what it ought to be.
	#
	pointer_move . c
	grab release .g; # windetect fakes a detection event with detail NotifyInferior
	waitForReporting 1 1
	pack forget .g
	no_leak_drawing_events tk
	createFrames
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect {} \
		tkwintrack [list outline: outline.none pnw: pnw.unmapped]]

test pw_destroy-4.1 {Enter a new toplevel through destruction of another toplevel} -constraints includeWmInvolved -setup {
	toplevelTwo map movePointerIntoTwo
	set reportingLog {}
} -body {
	#
	# This test has been observed to fail with zero reporting delay under
	# x11.KWin.KDE if [wm iconify] was invoked previously, as in pw_mapping-4.2.
	# That test has been accommodated to remedy the issue. See also the
	# explanation to test pw_mapping-4.2.
	#
	destroy .two
	waitForReporting 2 1; # the <Destroy> detection event was serviced before the destroy command returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	pointer_move . c
	if {$Generic(pkgName) eq "tkwintrack"} {
		interp eval tkwintrack pnw.recall
		update; # enforce redraw of pnw
	}
	toplevelTwo create
	#
	# No extra event leaking prevention needed
	#
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{. <Enter> .}" \
		tkwintrack {}]

test pw_destroy-4.2 {a toplevel, enter screen outside client application} -constraints includeWmInvolved -setup {
	wm geometry .two +[expr [winfo rootx .] -80]+[expr [winfo rooty .] -80]
	wm deiconify .two
	waitForReporting 2
	event generate .two <Motion> -warp 1 -x 20 -y 100 -when now
	controlPointerWarpTiming
	set reportingLog {}
} -body {
	destroy .two
	waitForReporting 1 1; # the detection event happened before the destroy command returned
	record state(outline) outline .
	record state(pnw) pnw
	if {$Generic(pkgName) eq "tkwintrack"} {
		concat $state(outline) $state(pnw)
	} else {
		set reportingLog
	}
} -cleanup {
	toplevelTwo create
	pointer_move . c
	waitForReporting
	#
	# No extra event leaking prevention needed
	#
	unset -nocomplain state reportingLog
} -result [getExpectedResult \
		windetect "{.two <Destroy> {}}" \
		tkwintrack [list outline: outline.none pnw: pnw.unmapped]]

# EOF
