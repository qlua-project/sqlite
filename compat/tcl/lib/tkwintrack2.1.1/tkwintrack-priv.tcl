# tkwintrack-priv.tcl --
#
#	When tracking windows in a GUI, outline detected windows and display
#	their pathname in a small widget, private interp side.
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
# PRIVATE INTERPRETER tkwintrack
#
# Code running in a separate interpreter in order to keep our own widgets
# inaccessible to any bindings in the client GUI.
#
# Another reason for using a separate interpreter is that the pathname widget
# would not receive any mouse events if it existed in the client interpreter
# and the client application sets a grab on one of its windows. That would
# make the pathname widget inaccessible for the user.
#
# Note that the namespace variable TkWintrack exists at both sides:
# - in the namespace ::tkwintrack in the client intepreter
# - in the global namespace in the tkwintrack interpreter
#
# These are separate entities that do not know about each other. The proc
# ::tkwintrack::config.transfer copies specifically those array elements
# from the tkwintrack interp that are needed in the client interp.
#
# ****************************************************************************

# init --
#
#	Initialization of the private interpreter
#
# Arguments: none
#
# Results: none
#
# Side effects: sets initial values and constants
#
proc init {} {
	package require Tk
	wm withdraw .
	tk appname tkwintrack
	variable TkWintrack

	# configuration related
	array set TkWintrack {
		aboutForeground #203569
		aboutBoxUnfolded 0
		after ""
		colorButtonHighlightBg #C0C8D8
		patch_applied_for_Tk_bug_7447ed20ec 0
		config,fileName ""
		config,maxFileSize 5000
		config,maxOtherClients 9
		config,optionNames {
			key,shortcutSeq,copy
			key,shortcutSeq,recall
			key,shortcutSeq,toggle
			outline,color
			outline,width
			pnw,background
			pnw,foreground
		}
		config,otherTxt ""
		config,version 1
		dlgBackground #607180
		dlgForeground #F2F2F2
		dlgDisabledForeground #A2A2A2
		forceInitPos 1
		hotspotHeight 2
		key,modifiers {Control Alt Shift Meta Mod1 Mod2 Mod3 Mod4 Mod5}
	}

	# see proc patch_Tk_bug_7447ed20ec below for explanation
	set TkWintrack(have_Tk_bug_7447ed20ec) [expr {([tk windowingsystem] eq "x11") && \
			(! [package vsatisfies [package present Tk] 8.6.14])}]

	#
	# The option command affects only widgets in the current interpreter
	#
	option add *font {Helvetica 10} widgetDefault; # allow this to be overridden by the user
	option add *config.*Background $TkWintrack(dlgBackground) interactive
	option add *config.*Foreground $TkWintrack(dlgForeground) interactive
	option add *config.*disabledForeground $TkWintrack(dlgDisabledForeground) interactive
	option add *Label.borderWidth 0 interactive
	option add *about.*Foreground $TkWintrack(aboutForeground) interactive
	option add *about.*Background $TkWintrack(dlgForeground) interactive

	#
	# Create images needed by the config dialog.
	# Note: installDir was set in [init] at the client side.
	#
	image create photo icon -file [file join $TkWintrack(installDir) img icon.gif]
	image create bitmap empty -data {}; # an empty image to disable character based screen distance units in buttons
	if {[package vcompare $::tk_version 8.6] < 0} {
		set TkWintrack(connectionSymbol) char
	} else {
		set TkWintrack(connectionSymbol) image
		image create photo connection -file [file join $TkWintrack(installDir) img connection.png]
	}

	#
	# Preferences, user-configurable at runtime
	#
	config.reset
	config.readFile
	clientInterp.transferConfig

	#
	# Display the tkwintrack widgets
	#
	# Note: [config] calls "update idletasks" and waits for the user to press
	# a button, while allowing events te be processed. That's when the process
	# becomes idle and [pnw.create] is executed.
	#
	after idle pnw.create
	config
}


# aboutBox --
#
#	Displays a auto-hide about box.
#
# Arguments: create, hide, show
#
# Results: none
#
# Side effects: see description.
#
proc aboutBox {mode} {
	variable TkWintrack
	switch -- $mode {
		create {
			set TkWintrack(aboutBox) [set aboutBox [frame .about -bg $TkWintrack(dlgForeground)]]
			array set info [subst {
				version ":  $TkWintrack(version)"
				author  ":  Erik Leunissen"
				license ":  Apache 2.0"
			}]

			set row -1
			set pady [expr {$::tcl_platform(platform) eq "unix"?"1p":"2p"}]
			grid [label $aboutBox.header -text "About tkwintrack" -anchor w -font $TkWintrack(headerFont) -fg $TkWintrack(aboutForeground) -padx 3p -pady $pady] -row [incr row] -columnspan 2 -sticky news
			foreach name {version author license} {
				grid [label $aboutBox.name_$name -text [string totitle $name] -anchor w] -row [incr row] -column 0 -sticky news -padx {3p 0}
				grid  [label $aboutBox.value_$name -text $info($name) -anchor w] -row $row -column 1 -sticky news -padx 6p
				grid rowconfigure $aboutBox $row -pad 1p
			}
			place $aboutBox -in $TkWintrack(cfgFrame) -anchor sw -relx 0.0 -rely 0.0 -relwidth 1.0 -y 0
			grid columnconfigure $aboutBox 1 -weight 1
			bind $aboutBox <Leave> {aboutBox hide}

			# hotspot
			set foreground #[expr {[string range $TkWintrack(aboutForeground) 1 end] + 333333}]
			grid [set TkWintrack(hotspot) [label $TkWintrack(cfgFrame).hotspot -bg $TkWintrack(dlgForeground) -text " \u21e3 " -font $TkWintrack(headerFont) -fg $foreground -pady [$TkWintrack(cfgFrame).clientInterp_name cget -pady]]] -row 1 -column 2 -sticky e
			lower $TkWintrack(hotspot)
			bind $TkWintrack(cfgFrame).clientInterp_name <Enter> [subst {
				twait 400; # be slow
				raise $TkWintrack(hotspot)
			}]
			bind $TkWintrack(cfgFrame).clientInterp_name <Leave> {
				if {[winfo containing [winfo pointerx .] [winfo pointery .]] ne $TkWintrack(hotspot)} {
					lower $TkWintrack(hotspot)
				}
			}
			bind $TkWintrack(hotspot) <Enter> {aboutBox showprologue}
			bind $TkWintrack(hotspot) <Leave> {
				if {$TkWintrack(after) ne ""} {
					after cancel $TkWintrack(after)
					set TkWintrack(after) ""
				}
				lower $TkWintrack(hotspot)
			}
		}
		hide {
			if {! $TkWintrack(aboutBoxUnfolded)} {
				return
			}
			set offset [winfo height $TkWintrack(aboutBox)]
			while {$offset > 0} {
				place configure $TkWintrack(aboutBox) -y [incr offset -10]
				twait 20
			}
			set TkWintrack(aboutBoxUnfolded) 0
		}
		showprologue {
			after 80
			set TkWintrack(after) [after 400 {aboutBox show}]
		}
		show {
			if {$TkWintrack(aboutBoxUnfolded)} {
				return
			}

			# Note: y offsets are relative to the sw anchor point (see [aboutBox create])
			set offset 0
			set height [winfo height $TkWintrack(aboutBox)]
			lower $TkWintrack(hotspot)
			while {$offset < $height} {
				if {[incr offset 10] > $height} {
					set offset $height
				}
				place configure $TkWintrack(aboutBox) -y $offset
				twait 20
			}
			set TkWintrack(aboutBoxUnfolded) 1
		}
	}
}


# cfgDialog.create --
#
#	Creates the config dialog
#
# Arguments: none
#
# Results: none
#
# Side effects: see description.
#
proc cfgDialog.create {} {
	variable TkWintrack

	. configure -cursor arrow
	wm protocol . WM_DELETE_WINDOW {
		set TkWintrack(dlgChoice) "exit"
	}
	wm iconphoto . icon
	wm title . tkwintrack
	wm resizable . 0 0
	wm attributes . -topmost 1

	#
	# Define appearance
	#
	set options(button) [list -width 7 -activebackground $TkWintrack(dlgForeground) -activeforeground $TkWintrack(dlgBackground)]
	set options(checkbutton) [list -padx 1 -highlightthickness 0 -bd 0 -anchor w -activebackground $TkWintrack(dlgBackground)]
	set options(sep) [list -bd 0 -bg $TkWintrack(dlgForeground)]
	set options(spinbox) [list -state readonly -bd 0 -highlightthickness 1p -readonlybackground $TkWintrack(dlgBackground) -disabledbackground $TkWintrack(dlgBackground) -highlightbackground $TkWintrack(dlgForeground) -highlightcolor $TkWintrack(dlgForeground) -cursor arrow -justify center]
	set options(colorButton) [list -highlightthickness 1p -relief ridge -image empty -width 30p -height 10p -padx 0 -pady 0 -compound right]
	switch -- $::tcl_platform(platform) {
		"unix" {
			lappend options(button) -padx 3p -pady 1p
			lappend options(colorButton) -bd 1
		}
		"windows" {
			lappend options(button) -padx 2p -pady 1p
			lappend options(colorButton) -bd 2
		}
	}

	#
	# Create widgets
	#
	set TkWintrack(cfgFrame) [set cfg [frame .config]]
	if {$TkWintrack(connectionSymbol) eq "char"} {
		set pady [expr {$::tcl_platform(platform) eq "unix"?"1.5p":"1p"}]
		set name(clientInterp) [label $cfg.clientInterp_name -padx 5p -pady $pady -anchor w -fg $TkWintrack(aboutForeground) -bg $TkWintrack(dlgForeground) \
				-text "\u26af $TkWintrack(clientInterpName)"]
	} else {
		set name(clientInterp) [label $cfg.clientInterp_name -padx 4p -pady 0.5p -anchor w -fg $TkWintrack(aboutForeground) -bg $TkWintrack(dlgForeground) \
				-image connection -compound left -text $TkWintrack(clientInterpName)]
	}

	#
	# We can determine any options defined by the user through the option database, only after the creation of the first widget
	#
	array set font [font actual [$name(clientInterp) cget -font]]
	set TkWintrack(headerFont) [list $font(-family) $font(-size) bold]
	$name(clientInterp) configure -font $TkWintrack(headerFont)
	set options(header) [list -font $TkWintrack(headerFont)]

	set name(outlineColor) [label $cfg.outline,color_name -text "Outline color"]
	set value(outlineColor) [button $cfg.outline,color_value -bg $TkWintrack(outline,color) -activebackground $TkWintrack(outline,color) -highlightbackground $TkWintrack(colorButtonHighlightBg) -command {cfgDialog.setColor outline,color} {*}$options(colorButton)]

	set name(outlineWidth) [label $cfg.outline,width_name -text "Outline width"]
	set value(outlineWidth) [spinbox $cfg.outline,width_value -width 2 -textvariable TkWintrack(outline,width) -from 1 -to 5 -increment 1 {*}$options(spinbox)]

	set name(pnwBackground) [label $cfg.pnw,background_name -text "Background color"]
	set value(pnwBackground) [button $cfg.pnw,background_value -bg $TkWintrack(pnw,background) -activebackground $TkWintrack(pnw,background) -highlightbackground $TkWintrack(colorButtonHighlightBg) -command {cfgDialog.setColor pnw,background} {*}$options(colorButton)]

	set name(pnwForeground) [label $cfg.pnw,foreground_name -text "Foreground color"]
	set value(pnwForeground) [button $cfg.pnw,foreground_value -bg $TkWintrack(pnw,foreground) -activebackground $TkWintrack(pnw,foreground) -highlightbackground $TkWintrack(colorButtonHighlightBg) -command {cfgDialog.setColor pnw,foreground} {*}$options(colorButton)]

	set name(followPointer) [label $cfg.pnw,followPointer_name -text "Follow pointer"]
	set value(followPointer) [checkbutton $cfg.pnw,followPointer_value -variable TkWintrack(pnw,followPointer) {*}$options(checkbutton)]

	set name(toggle) [label $cfg.toggle_name -text "Toggle detection on/off"]
	set TkWintrack(pnw,toggle) [label $cfg.toggle_value -textvariable TkWintrack(key,displayStr,toggle) -anchor e]

	set name(copy) [label $cfg.copy_name -text "Copy pathname"]
	set TkWintrack(pnw,copy) [label $cfg.copy_value -textvariable TkWintrack(key,displayStr,copy) -anchor e]

	set name(recall) [label $cfg.recall_name -text "Recall pathname widget"]
	set TkWintrack(pnw,recall) [label $cfg.recall_value -textvariable TkWintrack(key,displayStr,recall) -anchor e]

	set bbox [frame $cfg.bbox -height 5 -width 10]
	set TkWintrack(button_exit) [button $bbox.exit -text Exit -command {set TkWintrack(dlgChoice) "exit"} {*}$options(button)]
	set TkWintrack(button_reset) [button $bbox.reset -text "Reset" -command config.reset {*}$options(button)]
	set TkWintrack(button_continue) [button $bbox.continue -text Continue -command {set TkWintrack(dlgChoice) "cont"} {*}$options(button)]

	# highlighting of color button borders
	foreach color {outlineColor pnwBackground pnwForeground} {
		bind $value($color) <Enter> {%W configure -highlightbackground white}
		bind $value($color) <Leave> {%W configure -highlightbackground $TkWintrack(colorButtonHighlightBg)}
	}

	# configure behaviour for selection of keyboard shortcuts
	foreach function {toggle copy recall} {
		bind $TkWintrack(pnw,$function) <Enter> [list shortcut.setSequence $function]
		bind $TkWintrack(pnw,$function) <Leave> [list set TkWintrack(keyCollectState,$function) 2]
	}

	#
	# Grid widgets
	#

	# grid options
	set grid_options(sep) {-column 0 -columnspan 3 -sticky we -pady 12p}
	set grid_options(checkbutton) {-column 2 -sticky e -padx 2p -pady 1p}
	set grid_options(name) {-column 0 -sticky w -padx 4p -pady 2p}
	set grid_options(header) {-column 0 -columnspan 3 -sticky w -padx 12p -pady {1p 0} }
	set grid_options(value) {-column 1 -columnspan 2 -sticky e -padx {0 6p}}

	set row 0

	# client interpreter
	grid $name(clientInterp) -row [incr row] -column 0 -columnspan 3 -sticky news

	# section outline highlighting
	grid [frame $cfg.sep_highlighting {*}$options(sep)] -row [incr row] {*}$grid_options(sep)
	grid [label $cfg.l_highlighting -text " Outline highlighting " {*}$options(header)] -row $row {*}$grid_options(header)
	foreach function {outlineColor outlineWidth} {
		grid $name($function) -row [incr row] {*}$grid_options(name)
		if {$function eq "outlineWidth"} {
			grid $value($function) -row $row {*}$grid_options(value) -padx 7p
		} else {
			grid $value($function) -row $row {*}$grid_options(value)
		}
	}

	# section pathname widget
	grid [frame $cfg.sep_pathname {*}$options(sep)] -row [incr row] {*}$grid_options(sep)
	grid [label $cfg.l_pathname -text " Pathname widget " {*}$options(header)] -row $row {*}$grid_options(header)
	grid $name(pnwBackground) -row [incr row] {*}$grid_options(name)
	grid $value(pnwBackground) -row $row {*}$grid_options(value)
	grid $name(pnwForeground) -row [incr row] {*}$grid_options(name)
	grid $value(pnwForeground) -row $row {*}$grid_options(value)
	grid $name(followPointer) -row [incr row] {*}$grid_options(name)
	grid $value(followPointer) -row $row {*}$grid_options(checkbutton)

	# section keyboard shortcuts
	grid [frame $cfg.sep_Fkeys {*}$options(sep)] -row [incr row] {*}$grid_options(sep)
	grid [label $cfg.l_Fkeys -text " Keyboard shortcuts " {*}$options(header)] -row $row {*}$grid_options(header)
	foreach function {toggle copy recall} {
		grid $name($function) -row [incr row] {*}$grid_options(name)
		grid $TkWintrack(pnw,$function) -row $row {*}$grid_options(value) -sticky we
	}

	grid [frame $cfg.sep_bbox {*}$options(sep)] -row [incr row] {*}$grid_options(sep) -pady 8p
	set padX(windows) 2p
	set padX(unix) 4p
	pack $TkWintrack(button_exit) $TkWintrack(button_reset) $TkWintrack(button_continue) -side left -expand 1 -padx $padX($::tcl_platform(platform))
	grid $bbox -row [incr row] -column 0 -columnspan 3 -sticky news -pady {0 8p}

	pack .config -side top

	aboutBox create
}


# cfgDialog.setColor --
#
#	Lets the user choose a color value from a dialog and set the color variable.
#
# Arguments:
#
#	colorVar: the color variable to set
#
# Results: none
#
# Side effects: see description.
#
proc cfgDialog.setColor {colorVar} {
	variable TkWintrack

	if {$TkWintrack(have_Tk_bug_7447ed20ec) && ! $TkWintrack(patch_applied_for_Tk_bug_7447ed20ec)} {
		patch_Tk_bug_7447ed20ec
	}

	if {$colorVar eq "outline,color"} {
		set title "Outline color"
	} else {
		set title "Pathname [string range $colorVar 4 end] color"
	}

	if {[set color [tk_chooseColor -initialcolor $TkWintrack($colorVar) -parent $TkWintrack(cfgFrame).${colorVar}_value -title $title]] ne ""} {
		set TkWintrack($colorVar) $color
		$TkWintrack(cfgFrame).${colorVar}_value configure -bg $color -activebackground $color
	}
}


# cfgDialog.show --
#
#	Displays a dialog with user-preferences, and waits for the
#	user to select an action: Exit, Reset or Continue. If the user selects
#	"Continue", the application continues tracking with the selected
#	preferences.
#
# Arguments: none
#
# Results: 0 if "exit"" was selected
#		   1 if "continue" was selected
#
# Side effects: see description.
#
proc cfgDialog.show {} {
	variable TkWintrack

	if {! [winfo exists .config]} {
		cfgDialog.create
	}

	#
	# Position the config dialog relative to the largest application window (the parent window).
	# horizontal : the left border of the dialog is halfway the width of the parent window.
	# vertical   : the centre of the dialog is at the centre of the parent window, unless rooty < 0.
	#
	# Note: [update idletasks] provides the opportunity for size computation,
	#       required to make [winfo reqwidth] and [winfo reqheight] return
	#       a sensible value.
	#
	foreach {width height xcoord ycoord} [clientInterp.get_mainwin_geometry] {}
	update idletasks
	set y [expr {$ycoord+($height-[winfo reqheight .])/2}]
	if {$y < 0} {set y 0}
	wm geometry . +[expr {$xcoord+$width/2}]+$y

	# Display the config dialog
	clientInterp.focus save
	wm deiconify .

	#
	# Wait for the user to press a button and handle the choice
	#
	set TkWintrack(dlgChoice) ""
	vwait TkWintrack(dlgChoice)

	set result [expr {($TkWintrack(dlgChoice) eq "exit")?0:1}]
	unset TkWintrack(dlgChoice)
	wm withdraw .
	clientInterp.focus restore
	return $result
}


# config --
#
#	A wrapper around [cfgDialog.show] to make it re-entrant regardless detection state
#
# Arguments: none
#
# Results: 0 for the Exit button
#          1 for the Continue button
#
# Side effects: handles detection state and displays the config dialog
#
proc config {} {
	# Note:
	#
	# Because of the many indirections, it's easy to overlook the fact that the
	# call to [variable TkWintrack] is needed already here to bring the namespace
	# variable TkWintrack into scope. This is so because everything that is
	# defined right here, is part of the context of any [interp eval tkwintrack ...],
	# called at te client-side from the interp alias "clientInterp.config.prologue"
	# below, at any stack level. For example from inside [::tkwintrack::detect].
	#
	# Omitting the call here will make [interp eval tkwintrack ...], however
	# indirect from here, complain about variable "TkWintrack" not existing.
	#
	variable TkWintrack
	clientInterp.config.prologue; # switches detection off

	# display config dialog and collect user preferences
	if {[cfgDialog.show]} {
		# perform configuration actions that need to be done immediately
		$TkWintrack(pnLabel) configure -bg $TkWintrack(pnw,background) -fg $TkWintrack(pnw,foreground) -highlightbackground $TkWintrack(pnw,foreground)
		$TkWintrack(pnWidget) configure -bg $TkWintrack(pnw,foreground)

		config.saveFile
		clientInterp.config.epilogue; # switches detection on
		return 1
	} else {
		# user selected "exit".
		config.saveFile
		clientInterp.exit; # returns zero
		#
		# tkwintrack interpreter has been deleted
		#
	}
}


# config.getOldFileNameVersion --
#
#	Get the name of any configuration file used in older versions of tkwintrack
#	(including its predecessor wintrackgui), and record its config version.
#
# Arguments:
#	configDir: the directory where to look for such a file (besides the HOME directory)
#
# Results: the config file name to read from.
#
# Side effects: see description
#
proc config.getOldFileNameVersion {configDir} {
	variable TkWintrack

	#
	# A future-proof version numbering system is used to indicate and handle
	# incompatible changes between config file versions.
	#
	# Config versions 2 and later carry the config version number in their
	# file name. Like config version 1, the config file for the predecessor
	# program wintrackgui doesn't, and the file may be located in another
	# directory than used for more recent versions of tkwintrack. See [init]
	# for the current config version.
	#
	# Search order is from latest to oldest config version.
	#

	# Search for config files carrying a lower version than the current
	# config version in their file name
	for {set v [expr {$TkWintrack(config,version) - 1}]} {$v > 1} {incr v -1} {
		set fileName [file join $configDir tkwintrack.$v.conf]
		if {[file isfile $fileName]} {
			set TkWintrack(config,readVersion) $v
			return $fileName
		}
	}

	# Search for wintrackgui config files
	foreach dir [list [string map {tkwintrack wintrackgui} $configDir] $::env(HOME)] {
		set fileName [file join $dir wintrackgui.conf]
		if {[file isfile $fileName]} {
			set TkWintrack(config,readVersion) 0; # 0 for wintrackgui
			return $fileName
		}
	}

	# there is no older config file present
	return ""
}


# config.linkShortcutVars --
#
#	Create user-readable strings from the raw key sequence
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc config.linkShortcutVars {} {
	variable TkWintrack
	foreach {name value} [array get TkWintrack key,shortcutSeq,*] {
		set newName [string map {shortcutSeq displayStr} $name]
		set newValue [string map {- +} $value]
		set TkWintrack($newName) $newValue
	}
}


# config.readFile --
#
#	Read config file
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc config.readFile {} {
	variable TkWintrack

	if {[set configFile [config.setFile]] eq ""} {
		return
	}

	if {[catch {
		if {[file size $configFile] > $TkWintrack(config,maxFileSize)} {
			error "size of the config file \"$configFile\" exceeded the allowed maximum ($TkWintrack(config,maxFileSize) bytes)"
		}
		set fd [open $configFile r]
		set txt [read $fd]
		close $fd
	} errMsg]} {
		puts "warning: $errMsg. Will continue using defaults."
		return
	}

	if {$TkWintrack(config,version) != $TkWintrack(config,readVersion)} {
		# rewrite text from older config versions
		config.rewrite txt $TkWintrack(config,readVersion)
	}

	array set ctrl {
		clients {}
		clientIsNew 0
		otherCount 0
		selfFound 0
	}
	foreach line [split $txt \n] {
		if {[regexp -- {^\[([^|]+\|[^|]*\|[^|]*)\]$} $line -- clientID]} {
			if {[set ctrl(clientIsNew) [expr {$clientID ni $ctrl(clients)}]]} {
				lappend ctrl(clients) $clientID
			} else {
				continue ; # skip duplicates
			}
			if {$ctrl(selfFound) && ($ctrl(otherCount) == $TkWintrack(config,maxOtherClients))} {
				break
			}
			if {$clientID eq $TkWintrack(clientInterpID)} {
				set ctrl(self) true
				set ctrl(selfFound) 1
			} elseif {$ctrl(otherCount) < $TkWintrack(config,maxOtherClients)} {
				incr ctrl(otherCount)
				set ctrl(self) false
				append TkWintrack(config,otherTxt) \n\n$line
			}
		} elseif {$ctrl(clientIsNew) && [regexp -- {^([^=]+)\s*=\s*(.+)$} $line -- name value]} {
			if {$ctrl(self)} {
				set TkWintrack($name) $value
			} else {
				append TkWintrack(config,otherTxt) \n$line
			}
		} else {
			# ignore line
		}
	}

	config.linkShortcutVars
}


# config.reset --
#
#	Resets configurable settings to their default values.
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc config.reset {} {
	variable TkWintrack
	array set TkWintrack {
		key,shortcutSeq,copy Alt-8
		key,shortcutSeq,recall Alt-9
		key,shortcutSeq,toggle Alt-7
		outline,color #FF0000
		outline,width 2
		pnw,background lightyellow
		pnw,followPointer 1
		pnw,foreground black
	}

	config.linkShortcutVars

	# adjust the colors in the config dialog immediately
	if {[info exists TkWintrack(cfgFrame)] && [winfo exists $TkWintrack(cfgFrame)]} {
		$TkWintrack(cfgFrame).outline,color_value configure -bg $TkWintrack(outline,color) -activebackground $TkWintrack(outline,color)
		$TkWintrack(cfgFrame).pnw,background_value configure -bg $TkWintrack(pnw,background) -activebackground $TkWintrack(pnw,background)
		$TkWintrack(cfgFrame).pnw,foreground_value configure -bg $TkWintrack(pnw,foreground) -activebackground $TkWintrack(pnw,foreground)
	}
}


# config.rewrite --
#
#	Rewrite config file text from older config versions, where we made
#	decisions that we regretted afterwards.
#
# Arguments:
#	txtVar: the name of the variable referring to the text one level up the call stack
#	configVersion: the config version of the old config file
#
# Results: none
#
# Side effects: see description
#
proc config.rewrite {txtVar configVersion} {
	upvar 1 $txtVar txt

	#
	# We're currently at config version 1
	#

	if {$configVersion == 0} {
		# These are wintrackgui config files
		set txt [string map {outlineColor outline,color outlineWidth outline,width} $txt]
	}
}


# config.saveFile --
#
#	Save settings to a config file
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc config.saveFile {} {
	variable TkWintrack
	if {$TkWintrack(config,fileName) eq ""} {
		return
	}

	if {[file isfile $TkWintrack(config,fileName)]} {
		file rename -force $TkWintrack(config,fileName) $TkWintrack(config,fileName)~
	}
	set txt "\[$TkWintrack(clientInterpID)]"
	foreach name $TkWintrack(config,optionNames) {
		append txt "\n$name="
		if {$TkWintrack($name) eq ""} {
			append txt {}
		} else {
			append txt $TkWintrack($name)
		}
	}

	if {[catch {
		file mkdir [file dirname $TkWintrack(config,fileName)]
		set fd [open $TkWintrack(config,fileName) w]
		puts -nonewline $fd $txt
		puts $fd $TkWintrack(config,otherTxt)
		close $fd
	} errMsg]} {
		puts stderr "error: $errMsg."
	}
}


# config.setFile --
#
#	Set the name of the config file
#
# Arguments: none
#
# Results: the config file to read from (maybe in an older format)
#          Writing is always done to $TkWintrack(config,fileName), also defined
#          by this proc, but not returned.
#
# Side effects: see description
#
proc config.setFile {} {
	variable TkWintrack

	if {$TkWintrack(config,fileName) ne ""} {
		return $TkWintrack(config,fileName)
	}

	global env
	if {$::tcl_platform(platform) eq "windows"} {
		set envNames [list APPDATA LOCALAPPDATA]
	}
	lappend envNames HOME
	set varNotExists [list]
	set dirsNotOK [list]
	foreach name $envNames {
		if {[info exists env($name)]} {
			if {[file isdir $env($name)] && [file writable $env($name)]} {
				if {$name eq "HOME"} {
					# prefer ~/.config if it exists
					if {[file isdir [set dir [file join $env(HOME) .config]]]} {
						set configDir [file join $dir tkwintrack]
					} else {
						set configDir [file join $env(HOME) .tkwintrack]
					}
				} else {
					set configDir [file join $env($name) tkwintrack]
				}
				break
			} else {
				lappend dirsNotOK $env($name)
			}
		} else {
			lappend varNotExists $name
		}
	}
	if {! [info exists configDir]} {
		if {"stdout" in [file channels]} {
			if {[set count [llength $varNotExists]] == [llength $envNames]} {
				if {$count > 1} {
					set reason "none of the environment variables [join $varNotExists ", "] exists"
				} else {
					set reason "the environment variable [lindex $varNotExists 0] doesn't exist"
				}
			} elseif {[llength $dirsNotOK]} {
				set reason "no writable location was found in [join $dirsNotOK ", "]"
			} else {
				error "program flow reached a conceptually invalid section"
			}
			puts stdout "warning: cannot save/restore configuration because $reason"
		}
		return
	}

	if {$TkWintrack(config,version) > 1} {
		set TkWintrack(config,fileName) [file join $configDir tkwintrack.$TkWintrack(config,version).conf]
	} else {
		set TkWintrack(config,fileName) [file join $configDir tkwintrack.conf]
	}

	if {[file isfile $TkWintrack(config,fileName)]} {
		set TkWintrack(config,readVersion) $TkWintrack(config,version)
		return $TkWintrack(config,fileName)
	} else {
		# Check whether a config file of an older program version exists
		return [config.getOldFileNameVersion $configDir]
	}
}


# patch_Tk_bug_7447ed20ec --
#
#	Patches the proc ::tk::RestoreFocusGrab provided by standard Tk, if it
#	exhibits bug 7447ed20ec (Fossil bug ID). This prevents a failure upon
#	clicking a button in the Tk color pick dialog under X11 if the client
#	application holds a grab on a window which happens to have the same name
#	as one of the widgets in the private interpreter.
#
# Arguments: none
#
# Results: none
#
# Side effects: see description.
#
proc patch_Tk_bug_7447ed20ec {} {
	variable TkWintrack

	#
	# Overwrite the proc definition provided by standard Tk.
	#
	proc ::tk::RestoreFocusGrab {grab focus {destroy destroy}} {
		set index "$grab,$focus"
		if {[info exists ::tk::FocusGrab($index)]} {
			foreach {oldFocus oldGrab oldStatus} $::tk::FocusGrab($index) { break }
			unset ::tk::FocusGrab($index)
		} else {
			set oldGrab ""
		}

		catch {focus $oldFocus}
		grab release $grab
		if {$destroy eq "withdraw"} {
			wm withdraw $grab
		} else {
			destroy $grab
		}
		if {[winfo exists $oldGrab] && [winfo ismapped $oldGrab]} {
			if {$oldStatus eq "global"} {
				catch {grab -global $oldGrab}
			} else {
				catch {grab $oldGrab}
			}
		}
	}
	set TkWintrack(patch_applied_for_Tk_bug_7447ed20ec) 1
}


# pnw.copy --
#
#	Copies the pathname to the clipboard and notifies the user by a visual clue
#
# Arguments: none
#
# Results: none
#
# Side effects: as described above.
#
proc pnw.copy {} {
	variable TkWintrack

	if {! [winfo ismapped .pnw]} {
		return
	}

	set txt [$TkWintrack(pnLabel) cget -text]
	if {[string match "* (no outline)" $txt]} {
		set txt [string range $txt 0 end-13]
	}

	clipboard clear
	clipboard append -- $txt

	# invert background and foreground to give visual feedback signal
	$TkWintrack(pnLabel) configure -bg $TkWintrack(pnw,foreground) -fg $TkWintrack(pnw,background) -highlightbackground $TkWintrack(pnw,background)
	update idletasks
	after 150
	$TkWintrack(pnLabel) configure -bg $TkWintrack(pnw,background) -fg $TkWintrack(pnw,foreground) -highlightbackground $TkWintrack(pnw,foreground)
}


# pnw.create --
#
#	Create the pathname widget, and configure mouse behaviour for it.
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc pnw.create {} {
	variable TkWintrack

	set TkWintrack(pnWidget) [toplevel .pnw]
	wm withdraw .pnw
	wm overrideredirect .pnw 1
	set TkWintrack(pnLabel) [label .pnw.pathname -padx 3p -pady 0 -text "gF" -bg $TkWintrack(pnw,background) -fg $TkWintrack(pnw,foreground) -takefocus 0 -cursor hand2 -highlightthickness 1 -highlightbackground $TkWintrack(pnw,foreground)]
	if {($::tcl_platform(platform) eq "windows") && ([package vcompare $::tk_patchLevel 8.6.10] < 0)} {
		#
		# Suffers from a bug which causes the highlight border to not being
		# displayed. Appears to be fixed in 8.6.10
		# (I didn't yet identify the checkin that fixed it. It's not the fix for
		#  Tk bug [3ed5b66989], it was fixed before that. [EL])
		#
		# We work around the issue by making the pnWidget visible at its outer
		# sides by a width of 1 pixel. This work-around costs an extra crossing
		# event if the mouse pointer moves over or out of that 1 pixel wide
		# area. Because this is hardly noticeable when tracking windows, we
		# accommodate the users running Tk 8.6.9 and older.
		#
		$TkWintrack(pnLabel) configure -highlightthickness 0
		.pnw configure -bg $TkWintrack(pnw,foreground) -padx 1 -pady 1
	}
	pack $TkWintrack(pnLabel) -fill both -expand 1

	# Determine screen offset relative to the mouse pointer.
	# Note: [update idletasks] provides the opportunity for size computation,
	#       required to make [winfo reqheight] return a sensible value.
	update idletasks
	set TkWintrack(XOffset) 5
	set TkWintrack(YOffset) [expr {[winfo reqheight .pnw] + 5}]

	# define mouse button behaviour
	bind $TkWintrack(pnLabel) <ButtonPress-1> {setcoords %X %Y}
	bind $TkWintrack(pnLabel) <B1-Motion> {pnw.move %X %Y}
	bind $TkWintrack(pnLabel) <ButtonPress-3> {config}
}


# pnw.move --
#
#	Moves the pathname widget to a new position, as specified by the arguments.
#
# Arguments: the X and Y coordinates of the new position.
#
# Results: none
#
# Side effects: see description
#
proc pnw.move {X Y} {
	variable TkWintrack

	wm geometry $TkWintrack(pnWidget) +[expr {
		$TkWintrack(origCoords,rootX) + $X - $TkWintrack(origCoords,mouseX)
	}]+[expr {
		$TkWintrack(origCoords,rootY) + $Y - $TkWintrack(origCoords,mouseY)
	}]
}


# pnw.recall --
#
#	Call the pathname widget home
#
# Arguments: none
#
# Results: none
#
# Side effects: see description
#
proc pnw.recall {} {
	variable TkWintrack
	set X [winfo pointerx $TkWintrack(pnWidget)]; set Y [winfo pointery $TkWintrack(pnWidget)]
	wm geometry $TkWintrack(pnWidget) +[expr {$X+$TkWintrack(XOffset)}]+[expr {$Y-$TkWintrack(YOffset)}]
}


# pnw.update --
#
#	Update contents and position of the pathname widget
#
# Arguments:
#	txt  : text to display in the pathname widget
#	X, Y : screen coordinates of the mouse pointer
#
# Results: none
#
# Side effects: see description
#
proc pnw.update {txt X Y} {
	variable TkWintrack

	#
	# Put the window manager process to work while the text of the label widget
	# is being updated. This saves time and facilitates testing.
	#
	wm deiconify $TkWintrack(pnWidget)
	if {$TkWintrack(pnw,followPointer) || $TkWintrack(forceInitPos)} {
		wm geometry $TkWintrack(pnWidget) +[expr {$X+$TkWintrack(XOffset)}]+[expr {$Y-$TkWintrack(YOffset)}]
		set TkWintrack(forceInitPos) 0
	}
	$TkWintrack(pnLabel) configure -text $txt
	update idletasks; # This enforces the update of the text in the pathname widget (not the position)
	raise $TkWintrack(pnWidget)
}


# setcoords --
#
#	Store the coordinates of:
#	- the mouse pointer
#	- the pathname widget
#
# Arguments: the mouse coordinates
#
# Results: none
#
# Side effects: see description
#
proc setcoords {X Y} {
	variable TkWintrack

	set TkWintrack(origCoords,mouseX) $X
	set TkWintrack(origCoords,mouseY) $Y
	set TkWintrack(origCoords,rootX) [winfo rootx $TkWintrack(pnWidget)]
	set TkWintrack(origCoords,rootY) [winfo rooty $TkWintrack(pnWidget)]
}


# shortcut.collect --
#
#	Collects key presses for the purpose of composing the key sequence of a keybord shortcut.
#
#	Sets the variable keyCollectState when a key press results in a valid
#	key sequence [0]. This unblocks [shortcut.setSequence]
#
# Arguments:
#
#	function : the keybord shortcut's function, i.e.
#		- toggling detection on/off
#		- copying the pathname
#		- recalling the pathname widget
#
#	K : the keysym for the key pressed
#
# Results: none
#
# Side effects: see description
#
proc shortcut.collect {function K} {
	variable TkWintrack

	# see if we have a modifier key
	if {[set modK [string trimright $K _LR]] in $TkWintrack(key,modifiers)} {
		# don't distinguish modifiers that have a left and right variant
		set isModifier 1
		set K $modK
	} else {
		set isModifier 0
	}

	# remove any "Key-" identifier from user readable strings
	regexp -- {(?:Key-)?(.+?)$} $K -- str
	if {$isModifier && ($str eq "Control")} {
		set str "Ctrl"
	}
	if {($TkWintrack(keySeqLength,$function) == 2) && $isModifier} {
		#
		# A modifier key is invalid at 3rd (= last) position. Notify the user
		#
		bell
		$TkWintrack(pnw,$function) configure -foreground white -background red
		update idletasks; after 400
		$TkWintrack(pnw,$function) configure -background $TkWintrack(dlgForeground) -foreground $TkWintrack(dlgBackground)
		return
	}
	if {[incr TkWintrack(keySeqLength,$function)] == 1} {
		set TkWintrack(key,tmpShortcutSeq) $K
		set TkWintrack(key,displayStr,$function) $str
	} else {
		append TkWintrack(key,tmpShortcutSeq) -$K
		append TkWintrack(key,displayStr,$function) +$str
	}
	if {! $isModifier} {
		#
		# We have a valid key sequence; unblock "shortcut.setSequence"
		#
		set TkWintrack(keyCollectState,$function) 0
		return
	}
	#
	# Continue collecting keys (don't set keyCollectState)
	#
}


# shortcut.setSequence --
#
#	Allows the user to define the key sequence for a keybord shortcut by pressing keys
#
# Arguments:
#	function : the keybord shortcut's function, i.e.
#		- toggling detection on/off
#		- copying the pathname
#		- recalling the pathname widget
#
#	Overview of keyCollectState states:
#	[1]  editing is in progress
#	[0]  a key press resulted in a valid key sequence, ending the process of editing
#
# Results: none
#
# Side effects:
#	Records the selected keys and disables the Continue button in case the
#	user selected the same key for different actions
#
proc shortcut.setSequence {function} {
	variable TkWintrack

	set TkWintrack(keySeqLength,$function) 0
	set TkWintrack(keyCollectState,$function) 1; # edit mode
	set TkWintrack(key,displayStrSav,$function) $TkWintrack(key,displayStr,$function)

	bind . <KeyPress> [list shortcut.collect $function %K]
	$TkWintrack(pnw,$function) configure -background $TkWintrack(dlgForeground) -foreground $TkWintrack(dlgBackground)
	vwait TkWintrack(keyCollectState,$function)

	$TkWintrack(pnw,$function) configure -foreground $TkWintrack(dlgForeground) -background $TkWintrack(dlgBackground)
	bind . <KeyPress> {}

	if {[info exists TkWintrack(after,$function)]} {
		after cancel $TkWintrack(after,$function)
		unset TkWintrack(after,$function)
	}

	if {$TkWintrack(keyCollectState,$function) == 0} {
		# Editing resulted in a valid key sequence. Accept it.
		set TkWintrack(key,shortcutSeq,$function) $TkWintrack(key,tmpShortcutSeq)
	} elseif {$TkWintrack(keySeqLength,$function) > 0} {
		#
		# The mouse pointer left the widget while the edit didn't result in a valid
		# key sequence. Discard the edit and restore the original key sequence.
		#
		set TkWintrack(key,displayStr,$function) $TkWintrack(key,displayStrSav,$function)
		$TkWintrack(pnw,$function) configure -foreground $TkWintrack(dlgForeground) -background $TkWintrack(dlgBackground)
	}

	# disable the Continue button if the same key sequence is defined for two or more functions
	if {($TkWintrack(key,shortcutSeq,copy) eq $TkWintrack(key,shortcutSeq,toggle)) || \
			($TkWintrack(key,shortcutSeq,copy) eq $TkWintrack(key,shortcutSeq,recall)) || \
			($TkWintrack(key,shortcutSeq,toggle) eq $TkWintrack(key,shortcutSeq,recall))} {
		set state disabled
	} else {
		set state normal
	}
	$TkWintrack(cfgFrame).bbox.continue configure -state $state
}


# twait --
#
#	Wait for a specified duration while allowing events to be processed.
#
# Arguments:
#
#	duration: the amount of time to wait.
#
# Returns: nothing
#
proc twait {duration} {
	set ::_twait 1; after $duration {unset -nocomplain ::_twait}
	vwait ::_twait
}

# EOF
