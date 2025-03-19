#
# A collection of procs that carry out the elementary actions of a user
# operating mouse when navigating a GUI.
#
# "gn" stands for "gui navigation"
#

#
# Copyright 2020 Erik Leunissen
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

namespace eval ::gn {}

proc ::gn::init {} {
	package present Tk

	variable idle_pointer_warping [expr {![package vsatisfies [package provide Tk] 8.7-]}]

	namespace export getPointerWin mouse_button pointer_move controlPointerWarpTiming
	
	package provide gn 0.82
}


# controlPointerWarpTiming --
#
#	See for its purpose the proc with the same name in the Tk test suite
#
proc ::gn::controlPointerWarpTiming {{duration 1}} {
	if {$::gn::idle_pointer_warping} {
		update idletasks
	}
	if {[tk windowingsystem] eq "win32"} {
		after $duration
	}
}


proc ::gn::getPointerWin {} {
	return [winfo containing [winfo pointerx .] [winfo pointery .]]
}


# mouse_button --
#
# Performs a mouse button action
#
# Arguments
#
#	button : the mouse button nr. or the corresponding string left, middle, right
#	action : press, release, click or double-click
#	w      : the window to deliver the event to. If not supplied, then
#            the window currently containing the mouse pointer is used.
#
# Return value : a boolean 0 or 1
#
# Note: this has been targeted at my own mouse [EL]. It is most probably not
#       valid for all mice; not generic.
#
proc ::gn::mouse_button {button action {w ""}} {
	if {$w eq ""} {
		set w [winfo containing [winfo pointerx .] [winfo pointery .]]
		if {$w eq ""} {
			return -code error "the mouse pointer is outside the active area of the GUI"
		}
	} else {
		if {! [winfo exists $w]} {
			return -code error "window $w doesn't exist"
		}
		if {! [winfo ismapped $w]} {
			return -code error "window $w is not mapped onto the screen"
		}
		if {[getPointerWin] ne $w} {
			return -code error "the mouse pointer is outside window $w"
		}
	}
	switch -- $button {
		1 -
		"left" {
			set button_nr 1
		}
		2 -
		"middle" {
			set button_nr 2
		}
		3 -
		"right" {
			set button_nr 3
		}
		default {
			return -code error "invalid mouse button \"$button\""
		}
	}
	switch -- $action {
		"press" {
			event generate $w <ButtonPress> -button $button_nr
		}
		"release" {
			event generate $w <ButtonRelease> -button $button_nr
		}
		"click" {
			event generate $w <ButtonPress> -button $button_nr
			twait 10
			event generate $w <ButtonRelease> -button $button_nr
		}
		"doubleclick" {
			#
			# Note: the Double modifier as in <Double-1> is not
			#       allowed with [event generate]
			#
			event generate $w <ButtonPress> -button $button_nr
			twait 10
			event generate $w <ButtonRelease> -button $button_nr
			twait 20
			event generate $w <ButtonPress> -button $button_nr
			twait 10
			event generate $w <ButtonRelease> -button $button_nr
		}
		default {
			return -code error "invalid mouse action \"$action\""
		}
	}
}


# pointer_move --
#
#	Move the mouse pointer relative to a window.
#
# Arguments:
#
#	w        : window that serves as a geometric reference
#	position : the side or corner that serves as the geometric reference
#	side     : in or out
#
# Returns: nothing
#
proc ::gn::pointer_move {w position {side "in"}} {
	if {! [winfo ismapped $w]} {
		return -code error "window $w is not mapped"
	}
	if {($side ne "in") && ($side ne "out")} {
		return -code error "invalid side \"$side\""
	}
	switch -- $position {
		"c" {
			set x [expr {[winfo width $w]/2}]
			set y [expr {[winfo height $w]/2}]
		}
		"nw" {
			set x [expr {$side eq "in"?0:-1}]
			set y [expr {$side eq "in"?0:-1}]
		}
		"n" {
			set x [expr {[winfo width $w]/2}]
			set y [expr {$side eq "in"?0:-1}]
		}
		"ne" {
			set x [expr {[winfo width $w]-1}]
			set y 0
			if {$side eq "out"} {
				incr x
				set y -1
			}
		}
		"e" {
			set x [expr {[winfo width $w]-1}]
			set y [expr {[winfo height $w]/2}]
			if {$side eq "out"} {
				incr x
			}
		}
		"se" {
			set x [expr {[winfo width $w]-1}]
			set y [expr {[winfo height $w]-1}]
			if {$side eq "out"} {
				incr x
				incr y
			}
		}
		"s" {
			set x [expr {[winfo width $w]/2}]
			set y [expr {[winfo height $w]-1}]
			if {$side eq "out"} {
				incr y
			}
		}
		"sw" {
			set x 0
			set y [expr {[winfo height $w]-1}]
			if {$side eq "out"} {
				set x -1
				incr y
			}
		}
		"w" {
			set x [expr {$side eq "in"?0:-1}]
			set y [expr {[winfo height $w]/2}]
		}
		default {
			return -code error "invalid position \"$position\""
		}
	}

	#
	# Note that control over pointer warp timing is hardly possible with:
	#
	#    event generate $w <Motion> -warp 1 -x $x -y $y -when (tail|head)
	#
	# under Tk 8.7+, where the pointer warp is queued along with the <Motion>
	# event. In theory, control is possible with a full update. However, that
	# also forces servicing of events that follow up on the pointer warp.
	#
	# Therefore we always use "-when now".
	#
	event generate $w <Motion> -warp 1 -x $x -y $y -when now
	controlPointerWarpTiming
}


# twait --
#
#	Wait for a specified duration while allowing events to be processed.
#	It is used by gn to let events be delivered to a window before
#	generating an other event.
#
# Arguments:
#
#	duration: the amount of time to wait for.
#
# Returns: nothing
#
proc ::gn::twait {duration} {
	set ::gn::_twait 1; after $duration {unset ::gn::_twait}
	vwait ::gn::_twait
}


::gn::init
