# tkwintrack.tcl --
#
#	When tracking windows in a GUI, outline detected windows and display
#	their pathname in a small widget, client side.
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


# ****************************************************************************
#
# CLIENT INTERPRETER
#
# Code that is executed in the interpreter running the client GUI,
# encapsulated in a separate namespace ::tkwintrack.
#
# The four frames of the outline widget and their widget class share the
# widget hierarchy with the client GUI. No encapsulation mechanism can be
# applied here. To prevent name collisions, we consistently use the string
# "tkwintrack" when naming them (possibly CamelCased, and/or attached with
# an underscore character). See also the proc "outline.create".
#
# ****************************************************************************

namespace eval ::tkwintrack {}

# ::tkwintrack::init --
#
#	Starts tkwintrack
#
# Arguments:
#
#	showConfigDlg: display the configuration dialog upon launch
#
# Results: none
#
# Side effects:
#	- sets initial values and constants
#	- launches the configuration dialog
#
proc ::tkwintrack::init {} {
	variable TkWintrack
	set TkWintrack(version) 2.1.1

	#
	# A. Prerequisites
	#
	set errMsg ""
	if {[catch {package present Tk} result]} {
		set errMsg "tkwintrack requires a running Tk application"
	} elseif {[package vcompare $result 8.5] < 0} {
		set errMsg "tkwintrack $TkWintrack(version) requires Tk 8.5 or newer"
	} elseif {([tk windowingsystem] ni "x11 win32") && \
			! ([info exists ::env(WINDETECT_NO_RESTRICT_WS)] && \
			($::env(WINDETECT_NO_RESTRICT_WS) eq "1"))} {
		set errMsg "tkwintrack $TkWintrack(version) does not support the windowing system \"[tk windowingsystem]\""
	}
	if {$errMsg ne ""} {
		namespace delete ::tkwintrack
		return -code error $errMsg
	}

	set TkWintrack(installDir) [file dirname [file normalize [info script]]]
	# Always indicate a minimum windetect version.
	package require windetect 2.0
	::windetect::instrument all *

	#
	# B. Initialization of the detection subsystem
	#
	#   The value for -delay is chosen to provide ample room for screen updates
	#	of tkwintrack widgets, without making the detection response sluggish.
	#
	::windetect::configure -callback ::tkwintrack::update_screen -delay 50
	set TkWintrack(detect) 0

	#
	# C. Initialization of the outline subsystem
	#
	variable Outline
	array set Outline {
		curToplevel {}
		curWin {}
		curWinIsMenubar 0
		curWinConfigureBinding {}
		toplevels {}
	}

	# Notify us of destruction of an outline widget for registration purposes.
	bind TkWintrackOutlineTop <Destroy> {::tkwintrack::outline.handleDestruction %W}

	#
	# D. Creation and initialization of the private interpreter
	#
	interp create tkwintrack

	# create aliases between the client interpreter part of tkwintrack and the private interpreter
	interp alias tkwintrack handlePnwLeaveEvent {} ::tkwintrack::pnw.handleLeaveEvent
	interp alias tkwintrack clientInterp.config.prologue {} ::tkwintrack::config.prologue
	interp alias tkwintrack clientInterp.config.epilogue {} ::tkwintrack::config.epilogue
	interp alias tkwintrack clientInterp.transferConfig {} ::tkwintrack::config.transfer
	interp alias tkwintrack clientInterp.get_mainwin_geometry {} ::tkwintrack::clientGUI.mainwin_geometry
	interp alias tkwintrack clientInterp.exit {} ::tkwintrack::exit
	interp alias tkwintrack clientInterp.focus {} ::tkwintrack::clientGUI.focus

	#
	#     Default values for identifiers in a standard Tk process that can be used
	#     for identification and naming of the client interpreter.
	# -------------------------------------------------------------------------------------------------------------------------------
	# variable       origin             . . . . . . . . .  . . . default values . . . . . . . . . .. . . . . . .. . . . . . .
	#                                   main interp, excutable invoked    main interp, executable         child interp with
	#                                   without parameter -name           invoked with parameter -name    package require Tk
	# -------------------------------------------------------------------------------------------------------------------------------
	# programName    $::argv0           [file tail $::argv0]              [file tail $::argv0]            -- (::argv0 doesn't exist)
	# appName        $::argv            --                                from $::argv                    -- (::argv is empty)
	# rootWinClass   [winfo class .]    [string totitle $programName]     [string totitle $appName]       "Tk"
	# tkSendName     [tk appname]       $programName                      $appName                        "tk"
	# -------------------------------------------------------------------------------------------------------------------------------
	#

	# add initialization code to the private interpreter
	set programName [expr {[info exists ::argv0]?[file tail $::argv0]:"--"}]
	set tkSendName [tk appname]
	if {$tkSendName ne ""} {
		set clientInterpName $tkSendName
	} else {
		set clientInterpName $programName
	}
	interp eval tkwintrack [subst {
		set TkWintrack(version) $TkWintrack(version)
		set TkWintrack(installDir) "[file dirname [file normalize [info script]]]"
		set TkWintrack(clientInterpName) "$clientInterpName"
		set TkWintrack(clientInterpID) "$programName|[winfo class .]|$tkSendName"
	}]

	# load private interp code
	interp eval tkwintrack {
		source [file join $TkWintrack(installDir) tkwintrack-priv.tcl]
	}

	package provide tkwintrack $TkWintrack(version)

	# let this proc return before launching private interp functionality
	after 0 {
	    interp eval tkwintrack init
	}
}


# ::tkwintrack::clientGUI.focus --
#
#	Save/Restore state of the client GUI as it was before displaying
#	the config dialog.
#
# Arguments: mode: save or restore
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::clientGUI.focus {mode} {
	variable TkWintrack

	switch -- $mode {
		save {
			set TkWintrack(client,saved-focus) [focus -lastfor .]
			if {$TkWintrack(client,saved-focus) eq ""} {
				# we require a focus window to make the keyboard shortcuts work
				focus $TkWintrack(client,mainwin)
				set TkWintrack(client,saved-focus) $TkWintrack(client,mainwin)
			}
		}
		restore {
			focus -force $TkWintrack(client,saved-focus); # -force is needed on Win7
		}
	}
}


# ::tkwintrack::clientGUI.mainwin_geometry --
#
#	Determine the geometry of the largest toplevel in the client GUI.
#
# Arguments: none
#
# Results: the geometry of the largest toplevel
#
# Side effects: unsets the namespace variable holding the collection of toplevel areas
#
# Algorithm basics:
#	Don't make any assumptions about the organization of toplevels in
#	the client GUI. Also consider unmapped toplevels, but only if no
#	other toplevels are mapped.
#
proc ::tkwintrack::clientGUI.mainwin_geometry {} {
	variable TkWintrack

	set TkWintrack(mainwin,ignoreUnMapped) 0
	clientGUI.toplevel_area_collect; # first of a recursive invocation

	set mainwin_area 0
	foreach {w area} $TkWintrack(mainwin,tlAreaList) {
		if {$area > $mainwin_area} {
			set TkWintrack(client,mainwin) $w
			set mainwin_area $area
		}
	}

	set result [list [winfo width $TkWintrack(client,mainwin)] [winfo height $TkWintrack(client,mainwin)] \
			[winfo rootx $TkWintrack(client,mainwin)] [winfo rooty $TkWintrack(client,mainwin)]]
	array unset TkWintrack mainwin,*
	return $result
}


# ::tkwintrack::clientGUI.toplevel_area_collect --
#
#	Recursively collect areas of toplevels in the client GUI
#
# Arguments:
#
#	w: the current window in the window hierarchy
#	   Should not be passed on the very first call
#
# Results: none
#
# Side effects: see description
#
# Algorithm explanation:
#
# We only consider unmapped toplevels as long as no other toplevels are mapped.
# In other words: as soon as we found a mapped toplevel, we stop collecting
# unmapped windows.
#
proc ::tkwintrack::clientGUI.toplevel_area_collect {{w .}} {
	variable TkWintrack

	if {[winfo manager $w] eq "wm"} {
		if {[winfo ismapped $w]} {
			if {! $TkWintrack(mainwin,ignoreUnMapped)} {
				set TkWintrack(mainwin,ignoreUnMapped) 1
				set TkWintrack(mainwin,tlAreaList) [list]; # reset toplevel area list
			}
			lappend TkWintrack(mainwin,tlAreaList) $w [expr {[winfo width $w]*[winfo height $w]}]
		} elseif {! $TkWintrack(mainwin,ignoreUnMapped)} {
			lappend TkWintrack(mainwin,tlAreaList) $w [expr {[winfo width $w]*[winfo height $w]}]
		}
	}
	foreach w [winfo children $w] {
		clientGUI.toplevel_area_collect $w
	}
}


# ::tkwintrack::config.epilogue --
#
#	Commands to be executed after withdrawal of config dialog
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::config.epilogue {} {
	config.transfer
	outline.configure

	# restore detection and key functions
	detect on
	bind all <$::tkwintrack::TkWintrack(key,shortcutSeq,toggle)> {::tkwintrack::detect toggle}
}


# ::tkwintrack::config.prologue --
#
#	Commands to be executed before display of config dialog
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::config.prologue {} {
	# switch detection and key functions off, and update screen
	bind all <$::tkwintrack::TkWintrack(key,shortcutSeq,toggle)> {}
	detect off
}


# ::tkwintrack::config.transfer --
#
#	Copy those elements from the TkWintrack array in the private interpreter
#	that are used in the client interpreter
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::config.transfer {} {
	array set ::tkwintrack::TkWintrack [interp eval tkwintrack {array get TkWintrack key,shortcutSeq,*}]
	array set ::tkwintrack::TkWintrack [interp eval tkwintrack {array get TkWintrack outline,*}]
}


# ::tkwintrack::detect --
#
#	Switch detection mode on/off
#
# Arguments:
#	state : the new detection state
#
# Results: none
#
# Side effects: as described above.
#
proc ::tkwintrack::detect {state} {
	variable TkWintrack

	if {$state eq "toggle"} {
		set state [expr {[::windetect::detect]?"off":"on"}]
	}

	if {($state eq "off") && ($TkWintrack(detect) == 1)} {
		variable Outline
		::windetect::detect off
		bind all <$TkWintrack(key,shortcutSeq,recall)> {}
		bind all <$TkWintrack(key,shortcutSeq,copy)> {}
		if {$::tcl_platform(platform) eq "windows"} {
			bind Toplevel <FocusIn> $TkWintrack(client,savedFocusInBnd,Toplevel)
			# Compensate for the root window not having a binding tag "Toplevel".
			# See also Tk bug [e5ccf54254].
			bind . <FocusIn> $TkWintrack(client,savedFocusInBnd,RootWin)
		}

		# Restore the configure bindings on the previously highlighted window.
		# Catch because the window may not exist anymore
		catch {bind $Outline(curWin) <Configure> $Outline(curWinConfigureBinding)}

		#
		# Remove bindings from our own widgets, before withdrawing them, to
		# prevent misbehaviour.
		#
		interp eval tkwintrack {
			bind $TkWintrack(pnWidget) <Leave> {}
			wm withdraw $TkWintrack(pnWidget)
		}

		if {[tkWithNotifyInferior]} {
			bind TkWintrackOutline <Leave> {}
		} else {
			::windetect::instrument TkWintrackOutline {}
		}

		outline.place {}
		set Outline(curWin) {}
		set TkWintrack(detect) 0
	} elseif {($state eq "on") && ($TkWintrack(detect) == 0)} {
		bind all <$TkWintrack(key,shortcutSeq,recall)> {interp eval tkwintrack pnw.recall}
		bind all <$TkWintrack(key,shortcutSeq,copy)> {interp eval tkwintrack pnw.copy}
		if {$::tcl_platform(platform) eq "windows"} {
			# Raise the pathname widget if the focus changes to (or virtually crossed)
			# the toplevel of the currently detected window. This is needed on
			# MS Windows where otherwise the pathname widget will become covered by
			# the client application's toplevel.
			#
			# Compensate for the root window not having a binding tag "Toplevel".
			# See also Tk bug [e5ccf54254].
			set TkWintrack(client,savedFocusInBnd,Toplevel) [bind Toplevel <FocusIn>]
			bind Toplevel <FocusIn> {+ interp eval tkwintrack {raise $TkWintrack(pnWidget)}}
			set TkWintrack(client,savedFocusInBnd,RootWin) [bind . <FocusIn>]
			bind . <FocusIn> {+ interp eval tkwintrack {raise $TkWintrack(pnWidget)}}
		}

		#
		# Make our own widgets sensitive to selected detection events. This is needed
		# to prevent misbehaviour in some corner cases.
		#
		# 1. the pathname widget
		#    Sensitivity to <Leave> events is needed for the case that the
		#    mouse pointer enters the area outside the client application
		#    from the pathname widget.
		#
		interp eval tkwintrack {
			bind $TkWintrack(pnWidget) <Leave> {
				# The following alias calls ::tkwintrack::pnw.handleLeaveEvent
				# in the client interpreter.
				handlePnwLeaveEvent %X %Y
			}
		}

		# 2. the outline widgets
		#    Sensitivity to <Leave> events is needed for the case where the mouse
		#    pointer leaves a direct contained widget of a toplevel in the client
		#    GUI, while staying inside the toplevel widget.
		#    (When leaving an outline widget with ni0, Tk skips any bindings for
		#     <Enter> events into another window because they carry a detail
		#     field "NotifyInferior".)
		#
		if {[tkWithNotifyInferior]} {
			bind TkWintrackOutline <Leave> {::tkwintrack::outline.handleLeaveEvent %m %d %X %Y %W}
		} else {
			::windetect::instrument TkWintrackOutline <Leave>
		}

		::windetect::detect on
		set TkWintrack(detect) 1
	}
}


# ::tkwintrack::exit --
#
#	Exits the application and returns to the client gui
#
# Arguments: none
#
# Results: 0
#
# Side effects:
#	Removes tkwintrack functionality, destroys our own widgets,
#	and deletes our namespace
#
proc ::tkwintrack::exit {} {
	variable TkWintrack

	# clean up behaviour
	detect off
	::windetect::instrument all {}
	bind all <$TkWintrack(key,shortcutSeq,toggle)> {}

	# clean up GUI
	outline.destroy
	clientGUI.focus restore

	# clean up code infrastructure
	interp delete tkwintrack
	::windetect::exit
	namespace delete ::tkwintrack; # also removes traces on namespace variables
	package forget tkwintrack

	return 0
}


# ::tkwintrack::outline.configure --
#
#	Configures color and width of the frames that compose the outline for all registered toplevels.
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.configure {} {
	variable TkWintrack

	foreach toplevel $::tkwintrack::Outline(toplevels) {
		set prefix [expr {$toplevel eq "."?"":$toplevel}]
		foreach side {top left right bottom} {
			$prefix.tkwintrack_outline_$side configure [expr {($side eq "top") || ($side eq "bottom")?"-height":"-width"}] \
					$TkWintrack(outline,width) -background $TkWintrack(outline,color)
		}

		place configure $prefix.tkwintrack_outline_right -x -$TkWintrack(outline,width)
		place configure $prefix.tkwintrack_outline_bottom -y -$TkWintrack(outline,width)
	}
}


# ::tkwintrack::outline.create --
#
#	Creates an outline widget for a specific toplevel
#
# Arguments:
#	toplevel: the toplevel of the window for which the outline widget is intended
#
#	Note:
#	Placing the top outline frame relative to its container window
#	requires that both the top outline frame and the container window (i.e.
#	the tracked window) are descendants of the same toplevel window.
#	(See also: man place.) Therefore, we need a different outline widget
#	for each window whose toplevel is a different one.
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.create {toplevel} {
	variable TkWintrack
	variable Outline

	set prefix [expr {$toplevel eq "."?"":$toplevel}]

	#
	# An outline consists of four lines, one for each side of a window
	# (top left right bottom). Since Tk doesn't provide a line widget,
	# we use a narrow empty frame for that purpose.
	#
	# An outline widget is a "Fremdkörper" to the client application, and
	# a source of anomalous behaviour. The problem is dual:
	# a. we don't want the client application to affect the appearance and
	#    behaviour of an outline widget. This is done by:
	#    - renaming the class of the frames in an outline widget
	#    - removing the standard binding tag "all" and the binding tag for the
	#      toplevel of an outline widget. Removing the binding tag "all" also
	#      makes them insensitive to detection by windetect.
	# b. we would like outline widgets to behave transparently for the client
	#    application, as if the outline were part of the tracked window. That
	#    goal is a bridge too far. However, we can make it appear to the user
	#    as if the outline were unresponsive to detection events. This is done by
	#    defining detection events specifically for the outline widgets, and
	#    handle them specially in [update_screen]. See also [detect].
	#
	foreach side {top left right bottom} {
		set Outline($side) [frame $prefix.tkwintrack_outline_$side -class TkWintrackOutline \
				[expr {($side eq "top") || ($side eq "bottom")?"-height":"-width"}] $TkWintrack(outline,width) \
				-background $TkWintrack(outline,color)]
		bindtags $Outline($side) [lrange [bindtags $Outline($side)] 0 end-2]
	}
	bindtags $Outline(top) [linsert [bindtags $Outline(top)] end TkWintrackOutlineTop]

	# Place left and right frame relative to top, and place bottom frame
	# relative to left (placement order: from the inside out)
	place $Outline(bottom) -in $Outline(left) -bordermode outside -relx 0 -x 0 -rely 1.0 -y -$TkWintrack(outline,width)
	place $Outline(left) -in $Outline(top) -bordermode outside -relx 0 -x 0 -rely 0 -y 0
	place $Outline(right) -in $Outline(top) -bordermode outside -relx 1.0 -x -$TkWintrack(outline,width) -rely 0 -y 0
	place configure $Outline(top) -bordermode outside
	# register the new outline widget
	lappend Outline(toplevels) $toplevel
}


# ::tkwintrack::outline.destroy --
#
#	Destroys all frames used for the outline of all registered toplevels,
#	and removes bindings that are not related to detection mode.
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.destroy {} {
	variable TkWintrack
	foreach toplevel $::tkwintrack::Outline(toplevels) {
		set prefix [expr {$toplevel eq "."?"":$toplevel}]
		destroy $prefix.tkwintrack_outline_top $prefix.tkwintrack_outline_bottom $prefix.tkwintrack_outline_right $prefix.tkwintrack_outline_left
	}
	bind TkWintrackOutlineTop <Destroy> {}
}


# ::tkwintrack::outline.handleDestruction --
#
#	Unregisters the toplevel of the currently outlined window when
#	it becomes destroyed. This handler is bound to a <Destroy> event
#	on the top outline frame of each outline widget. See also [init].
#
# Arguments:
#	W : the window that's in the process of being destroyed
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.handleDestruction {W} {
	#
	# The client application has destroyed an outline widget, either by
	# destroying the currently outlined window or a window containing
	# that (or else it purposely intruded on our package).
	#
	variable Outline

	# the window is in a zombie state, but we can still determine its toplevel.
	set toplevel [winfo toplevel $W]
	set index [lsearch $Outline(toplevels) $toplevel]
	set Outline(toplevels) [lreplace $Outline(toplevels) $index $index]
	if {$Outline(curToplevel) eq $toplevel} {
		set Outline(curToplevel) ""
	}
}


# ::tkwintrack::outline.handleLeaveEvent --
#
# Arguments:
#	mode   : the mode field of the crossing event
#	detail : the detail field of the crossing event
#	W      : the event window
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.handleLeaveEvent {mode detail X Y W} {
	#
	# Act as if the mouse pointer left the currently outlined window by generating
	# an extra <Leave> event with detail field NotifyNonlinear.
	#
	variable Outline
	if {([winfo toplevel $Outline(curWin)] eq $Outline(curWin)) && ($detail ne "NotifyInferior")} {
		event generate $Outline(curWin) <Leave> -mode  $mode -detail NotifyNonlinear -rootx $X -rooty $Y -when tail
	}
}


# ::tkwintrack::outline.place --
#
#	Positions the outline widget along the borders of a specific window.
#	Withdraws the outline widget if mouse pointer moved outside the active
#	client area.
#	May create a new outline widget if the window W is (contained in) a
#	new toplevel.
#
# Arguments:
#	W: the window to be outlined
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.place {W} {
	variable Outline

	# Restore the configure bindings on the previously highlighted window.
	# Catch because the window may not exist anymore
	catch {bind $Outline(curWin) <Configure> $Outline(curWinConfigureBinding)}

	#
	# Handle menu bars as if we're outside the active client area because
	# [place] doesn't work correctly with menubars.
	#
	if {($W eq "") || $Outline(curWinIsMenubar)} {
		outline.withdraw
		return
	}

	# Determine and select the outline widget that corresponds with the
	# toplevel window for $W
	set toplevel [winfo toplevel $W]
	if {$toplevel ne $Outline(curToplevel)} {
		outline.withdraw
		outline.set $toplevel
	}

	# place the outline frames along the borders of the window W
	place $Outline(top) -in $W -width [set width [winfo width $W]] -x 0 -y 0
	place configure $Outline(left) -height [set height [winfo height $W]]
	place configure $Outline(right) -height $height
	place configure $Outline(bottom) -width $width

	# Stacking order control: ensure that the outline widget stays above
	# any client widgets that are mapped after the outline widgets.
	foreach side {top left right bottom} {
		raise $Outline($side)
	}

	# handle resize events for the outlined window
	set Outline(curWinConfigureBinding) [bind $W <Configure>]
	bind $W <Configure> [list + ::tkwintrack::outline.resize %W $W %w %h]
}


# ::tkwintrack::outline.resize --
#
#	Configures the width and height of the four outline frames
#	to match the container window. Is called as a handler for a <Configure>
#	event on the tracked window.
#
# Arguments:
#	W         : the name of the window that triggered the binding
#	bindtag   : the name of the window (as a binding tag) for which
#	            the binding was intended.
#	newWidth  : the new width
#	newHeight : the new height
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.resize {W bindtag newWidth newHeight} {

	#
	# If the binding was made against a toplevel window, all internal
	# windows of that toplevel also inherit that binding. But we don't
	# want an outline widget around a toplevel to resize if an internal
	# window (W) resizes and not the toplevel itself (bindtag).
	#
	if {$W ne $bindtag} {
		return
	}

	#
	# We only care about resize events, i.e. <Configure> events caused by
	# a change of width or height. We don't care about other causes, for
	# example moving the window to another position.
	#
	variable Outline
	if {$newWidth != [winfo width $Outline(top)]} {
		place configure $Outline(top) -width $newWidth
		place configure $Outline(bottom) -width $newWidth
	}
	if {$newHeight != [winfo height $Outline(left)]} {
		place configure $Outline(left) -height $newHeight
		place configure $Outline(right) -height $newHeight
	}
}


# ::tkwintrack::outline.set --
#
#	Selects or creates the outline widget to be used for a specific toplevel
#
# Arguments:
#	toplevel: the toplevel of the window to be outlined
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.set {toplevel} {
	variable Outline
	variable TkWintrack

	set prefix [expr {$toplevel eq "."?"":$toplevel}]

	if {[winfo exists $prefix.tkwintrack_outline_top]} {
		#
		# Reuse the existing outline widget for this toplevel
		#
		foreach side {top left right bottom} {
			set Outline($side) $prefix.tkwintrack_outline_$side
		}

		# restore place configuration that is lost with [place forget]
		place configure $Outline(top) -bordermode outside
	} else {
		#
		# We need a new outline widget that is specific for this toplevel
		#
		outline.create $toplevel
	}

	# register the current toplevel
	set Outline(curToplevel) $toplevel
}


# ::tkwintrack::outline.withdraw --
#
#	Withdraw the current outline widget
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc ::tkwintrack::outline.withdraw {} {
	variable Outline

	if {$Outline(curToplevel) ne ""} {
		if {[winfo exists $Outline(top)]} {
			place forget $Outline(top)
			set Outline(curToplevel) ""; # register the new toplevel
		}
	}
}


# ::tkwintrack::pnw.handleLeaveEvent --
#
#	Trigger detection by windetect when the mouse pointer leaves the pathname
#	widget for the area outside the client application.
#
# Arguments: the X and Y coordinates of the <Leave> event
#
# Results: none
#
# Side effects: synthesizes a <Leave> event in the client interpreter
#
proc ::tkwintrack::pnw.handleLeaveEvent {X Y} {
	if {[winfo containing $X $Y] eq ""} {
		event generate . <Leave> -mode NotifyNormal -detail NotifyNonlinear -rootx $X -rooty $Y
	}
}


# ::tkwintrack::tkWithNotifyInferior --
#
#	Determines how the current Tk version handles binding scripts for
#	crossing events with detail field "NotifyInferior".
#
# Arguments: none
#
# Results: 0: Tk ignores the script
#          1: Tk invokes the script
#
# Side effects: sets a namespace variable TkWintrack(withNotifyInferior)
#               on first invocation.
#
proc ::tkwintrack::tkWithNotifyInferior {} {
	variable TkWintrack

	if {! [info exists TkWintrack(withNotifyInferior)]} {
		#
		# The code in tkWithNotifyInferior.tcl makes a call to "update".
		# That's why we cannot run that code as a proc inside windetect: it
		# could cause unknown effects in the client interpreter, and that's
		# a "NoNo". We need it to be in a separate process.
		#
		set TkWintrack(withNotifyInferior) [exec [info nameofexecutable] \
				[file join $TkWintrack(installDir) utils tkWithNotifyInferior.tcl] \
				[package present Tk]]
	}
	return $TkWintrack(withNotifyInferior)
}


# ::tkwintrack::update_screen --
#
#	Called by windetect when it reports a new window (reporting callback).
#	Updates the outline widget and the pathname widget.
#
# Arguments: the new window under the mouse pointer and the mouse coordinates
#
# Results: none
#
# Side effects:
#	- saves the new pathname in a global variable for the next reporting event.
#	- withdraws the pathname widget if outside the active area in the client gui
#	- handles highlighting of the previous and new windows
#	- moves the pathname widget to the mouse pointer location if so configured.
#
# Algorithm
# =========
#
# The following (corner) cases require specific and distinct handling of the
# pathname widget or the outline widget:
#
# A. The pointer moved out of the active area of the client application.
#    This happens when:
#    - the mouse pointer leaves a grabbed window
#    - the mouse pointer enters the screen outside any toplevel, possibly
#      after the toplevel containing the mouse pointer was destroyed/unmapped.
#    - a grab is set on a window while the mouse pointer resides in a window
#      outside the grab subtree
#
# B. The pointer entered the previously reported window again.
#    Detection events for other windows happened in the meantime because
#    the mouse pointer visited:
#
#    - one of our own widgets (pathname widget or outline widget). This was
#      already ignored in a previous round (case C2 below).
#    - another window, and the corresponding detection events were not reported
#      because the reporting delay skipped them. This can only happen with
#      detection events that occur in rapid succession. For example if the
#      mouse moves swiftly over the screen.
#
# C. The mouse pointer entered one of our own widgets. Sub-cases:
#
#    C1. The mouse pointer came from the pathname widget and entered
#        an outline widget.
#    C2. The mouse pointer came from any other window and entered an outline widget
#    C3. The mouse pointer entered the pathname widget
#
#
# The algorithm below has been optimized for efficiency in real situations
# that combine the above specific cases.
# Note: the order of handling these specific cases is important:
#
# A overrules all other cases except C3, which is an exceptional case of A
# B precedes C1 and C2 for reasons of execution efficiency
#
proc ::tkwintrack::update_screen {W X Y} {
	variable TkWintrack
	variable Outline

	if {$W eq ""} {
		if {[string match ".pnw*" [interp eval tkwintrack winfo containing $X $Y]]} {
			#
			# C3
			#
			return
		}
		#
		# A
		#

		# Remove the outline widget and withdraw the pathname widget
		# to indicate that the mouse pointer is outside the active client area.
		outline.place {}
		interp eval tkwintrack {wm withdraw $TkWintrack(pnWidget)}
		set Outline(curWin) {}
		return
	}
	if {($W eq $Outline(curWin)) || [string match *tkwintrack_* $W]} {
		#
		# B, C1 and C2.
		#
		return
	}

	#
	# Generic case: we detected another widget in the client GUI
	#

	set txt $W; # default text to be displayed in the pathname widget

	# menu bars require special treatment, we register that case
	set Outline(curWinIsMenubar) [expr {([winfo class $W] eq "Menu") \
			&& ([$W cget -type] eq "menubar")}]
	if {$Outline(curWinIsMenubar)} {
		append txt " (no outline)"
	}

	# Handle highlighting of the old and new tracked window, and
	# update contents and position of the pathname widget.
	outline.place $W
	interp eval tkwintrack [list pnw.update $txt $X $Y]

	# register the newly tracked window
	set Outline(curWin) $W
}

tkwintrack::init

#EOF
