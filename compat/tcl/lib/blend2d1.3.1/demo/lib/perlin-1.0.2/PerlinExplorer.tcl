 #
 # visualization of a Perlin-noise 2D map
 #
 
catch {console show}

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 $thisDir]

 # just for testing in the devkit environment
if { [file isdirectory $thisDir/XBUILD] } {
	set auto_path [linsert $auto_path 0 $thisDir/XBUILD]
}

package require perlin
package require snit



 # -- some basic widgets -----
 #  - XEntry
 #  - GrayLevelHistogram
 #  - ProfileWidget
 #  - PerlinMap2D
 
# ============================================================================= 
# === XEntry -minimal (Very) simplified Entry widget
# ============================================================================= 

 # Facility for deriving a new font.
 # example:
 #   buildFontVariation SystemFont -slant italic -underline 1 
 #
 # args is a list of key value like 
 #  -slant italic"|roman
 #  -weight normal!bold
 #  -overstrike ...
 #  ...
proc buildFontVariation {font args} {
	set newFont [font actual $font]
	foreach {key value} $args {
		dict set newFont $key $value
	}
	return $newFont
}

 # Note: the XEntry class is Entry
option add *Entry.editingfg #d70000

snit::widgetadaptor XEntry {

   typeconstructor {
         # set class-binding to the (pseudo)class XEentry
		bind XEntry <Key-Return> {%W _OnConfirmChanges}
		bind XEntry <Key-Escape> {%W _UndoChanges}		
		bind XEntry <FocusOut>   {%W _OnConfirmChanges} 
    }

	variable my

	 # This is dangerous but default bindings require almost all commands ..
	 # The "validate" method is reserved for internal use.
	 # Use instead the new "isValid" method (accordling to the new option "-ckeckcommand")
	delegate method * to hull except {validate}	

	 # -validate and -validatecommand are reserved for internal use;
	 # Now you have -checkcommand	
	delegate option * to hull except {-validate -validatecommand}

	 # Specifies the prefix of a Tcl command to invoke whenever the entry
	 # loose the focus or <Key-return> is pressed AND the entry value has changed.
	 # The actual command consists of this option followed by a space 
	 # and the current value of the entry.
	 # If this command returns true then the editing mode is closed,
	 #  and the virtual event <<XEntry.Changed>> is raised	 
	option -checkcommand
		
	 # Specify how the text (in editing-mode) should look like
	option -editingfont
	option -editingfg
		
	constructor {args} {
		installhull using entry	

         # ADD a pseudo-class bindtag "XEntry" just before the "Entry" bindtag
        set btags [bindtags $win]
        bindtags $win [linsert $btags [lsearch -exact $btags Entry] XEntry]    

		 # whenver a key is pressed, start editing.mode ...
		$hull configure -validate key -validatecommand [mymethod _StartEditMode]
		
		set my(internalState) normal
		
		$win configure {*}$args
	}

	method set {value} {
		$hull delete 0 end
		$hull insert 0 $value
		 # no validation is performed
		$win _CloseEditMode
		return $value
	}

	 # change the text appearance (font anf foreground color)
	method _StartEditMode {} {
		if  { $my(internalState) ne "editing" } {
			set my(internalState) "editing"

			set my(savedValue) [$win get]			
			set my(savedFont)  [$hull cget -font]
			set my(savedFg)    [$hull cget -foreground]
			
			if { $options(-editingfont) ne {} } {
				$hull configure -font $options(-editingfont)
			}
			catch { $hull configure -foreground $options(-editingfg) }
		}
		return true	
	}

	method _CloseEditMode {} {
		$hull configure \
			-font $my(savedFont) \
			-foreground $my(savedFg)			
		set my(internalState) "normal"
		return	
	}
	
	method _UndoChanges {} {
		if { $my(internalState) eq "editing" } {
			 # Warning: the following command will trigger _StartEditMode
			 # therefore we must do _CloseEditMode
			$win set $my(savedValue)
			$win _CloseEditMode
		}
	}
	
	method isValid {} {
		if { $options(-checkcommand) eq {} } { return true }
		uplevel #0 $options(-checkcommand) [list [$win get]]
	}
	
	method _OnConfirmChanges {} {
		if { $my(internalState) ne "editing" } return
		
		set currValue [$win get]
		if { $currValue eq $my(savedValue) } {
			$win _CloseEditMode
			return
		}
		 # else it's different ...
		if { [$win isValid] } {
			$win _CloseEditMode
			event generate $win <<XEntry.Changed>> -data [$win get]
			return
		}
	}
}

# ============================================================================= 
# === GrayLevelHistogram -simple histogram widget
# ============================================================================= 
 
snit::widgetadaptor GrayLevelHistogram {
	variable my

     # WARNING: this widget is a "Label" widget, therefore all the default options
	 #  in the "TK options database" may override the following defaults..
	 # THEN it is strongly recommended to explicitely configure these options
	 #   on every new wisget instance.	
	option -height -default 128 -readonly yes
	option -background -default gray10
	option -foreground -default white
	
	constructor {args} {
		 # widget is just a simple label with an image, no borders and no spacing
		installhull using label -borderwidth 0  -padx 0 -pady 0	

		$win configure {*}$args

		set my(image) [image create photo -width 256 -height $options(-height)]
		$hull configure -image $my(image) -compound top
	}
	
	destructor {
		catch {image delete $my(image)}
	}

	method clear {} {
		$my(image) put $options(-background) -to 0 0 [image width $my(image)] [image height $my(image)]		
	}
	
	 # this method takes
	 #  x (here unused)
	 #  data: a profile of a sampled 2d map (i.e list of values (0..255))
	method redraw {x data} {
		set H [lrepeat 256 0]
	
		set vmin [lindex $data 0]
		set vmax $vmin
		foreach d $data {
			lset H $d [expr {1+[lindex $H $d]}]
			set vmin [expr {min($vmin,$d)}]
			set vmax [expr {max($vmax,$d)}]
		}

		 # get the highest count (for scaling the bars ..)
		set hmax 0
		foreach h $H {
			set hmax [expr {max($hmax,$h)}]
		}			
		$win clear

		set ymax [image height $my(image)]
		set scale [expr {double($ymax)/$hmax}]
		
		for {set d 0} {$d<256} {incr d} {
			set h [lindex $H $d]
			set hh [expr {int($h*$scale)}]
			 # must be drawn from bottom up		
			$my(image) put $options(-foreground) -to $d [expr {$ymax-$hh}] [expr {$d+1}] $ymax 
		}	

		 # just for the label, map vmin,vmax (in 0..255) range
		 # to [-1..+1] range
 		set vvmin [expr {($vmin-127)/127.0}]
		set vvmin [format "%.2f" $vvmin]
		set vvmax [expr {($vmax-127)/127.0}]
		set vvmax [format "%.2f" $vvmax]
		$hull configure -text "Range: $vvmin .. $vvmax"
	}	

}

# ============================================================================= 
# === ProfileWidget -custom widgets for plotting a 'Profile' 
#     (Profile:  a sequence of discrete values )
# ============================================================================= 

snit::widgetadaptor ProfileWidget {
	variable my

     # WARNING: this widget is a "Label" widget, therefore all the default options
	 #  in the "TK options database" may override the following defaults..
	 # THEN it is strongly recommended to explicitely configure these options
	 #  (at least those used for the standar Label class) on every new wisget instance.	

	option -orient -readonly yes -type {
            snit::enum -values {horizontal vertical}
    }
	option -height -readonly yes
	option -width  -readonly yes

	option -background -default gray25
	option -foreground -default white
	option -markcolor  -default white
	
	constructor {args} {
		 # widget is just a simple label with an image, no borders and no spacing
		installhull using label -borderwidth 0  -padx 0 -pady 0	
		 
		$win configure {*}$args

		 # check for mandatory options
		foreach opt {-height -width -orient} {
			if { $options($opt) eq "" } {
				error "missing mandatory option \"$opt\"."
			}
		}
		
		if { $options(-orient) eq "vertical" } {
			set dummy $options(-height)
			set options(-height) $options(-width)
			set options(-width) $dummy
		}
		
		set my(image) [image create photo -width $options(-width) -height $options(-height)]
		$hull configure -image $my(image)		
	}

	destructor {
		catch {image delete $my(image)}
	}

	method clear {} {
		$my(image) put $options(-background) -to 0 0 [image width $my(image)] [image height $my(image)]		
	}

	 # this method takes
	 #  i: where to draw a vertical marker
	 #  data: a profile of a sampled 2d map (i.e list of N values (0..255))
	 #	--
	 #  the plotting image my(image) must be 
	 #     Nx256  (or 256xN if -orient is vertical)	
	method redraw {i data} {
		$win clear
		set fgColor $options(-foreground)
		set iColor  $options(-markcolor)
		switch -- $options(-orient) {
		 horizontal {
		 	set ymax [image height $my(image)]
			set x 0
			  # must be drawn from bottom up			
			foreach d $data {
				$my(image) put $fgColor -to $x [expr {$ymax-$d}]
				incr x
			}
			$my(image) put $iColor -to $i 0 [expr {$i+1}] $ymax 
		 }
		 vertical {
			set xmax [image width $my(image)]		
			set y 0
			foreach d $data {
				$my(image) put $fgColor -to $d $y
				incr y
			}
			$my(image) put $iColor -to 0 $i $xmax [expr {$i+1}] 
		 }
		}	
	}
}

# ============================================================================= 
# === PerlinMap2D - custom widgets for plotting a a sampled Perlin space
# ============================================================================= 

 # *warning* : external dependencies
 #   $::Colors(horProfile)
 #   $::Colors(verProfile)
 
snit::widgetadaptor PerlinMap2D {
	variable my

	option -height -readonly yes
	option -width  -readonly yes
	
	option -enablecorrection -default false  -configuremethod Set_correction
	option -rangecorrection  -default 1.0    -configuremethod Set_correction

	typevariable My ;# note the Uppercase for denoting a typevariable
	typeconstructor {
		 # initialize GrayTable:  i-> gray-color i  (e.g  #F8F8F8)
		set My(GrayTable) {}
		for {set i 0} {$i<256} {incr i} {
			lappend My(GrayTable) [format "#%02x%02x%02x " $i $i $i]
		}
	}

	constructor {args} {
		 # widget is just a simple canvas with an image, no borders and no spacing	
		installhull using canvas -borderwidth 0 -highlightthickness 0

		$win configure {*}$args

		 # check for mandatory options
		foreach opt {-height -width} {
			if { $options($opt) eq "" } {
				error "missing mandatory option \"$opt\"."
			}
		}

		set width  $options(-width)
		set height $options(-height)
		$hull configure	-width $width -height $height 
		
		set my(image) [image create photo -width $width -height $height]
		$hull create image 0 0 -image $my(image) -anchor nw -tags MAP2D

		 # create a crosshair cursor		
		 # TODO: *warning* use externally defined colors !!
    	$hull create line 0 0 $width 0  -tags {CROSSHAIR HOR} -fill $::Colors(horProfile)
    	$hull create line 0 0 0 $height -tags {CROSSHAIR VER} -fill $::Colors(verProfile)

		 # crosshair position (relative to the origin of my(image)) - in pixel coords
		set my(X) 0 ; set my(Y) 0

		 # origin of the sampled Perlin-noise space
		set my(x0) 0.0 ; set my(y0) 0.0 ; set my(z0) 0.0
		set my(step) 1.0 ;# don't care ..
		 # -- binding for moving the crosshair
		 
		 # small adjustment on tk-canvas click sensitivity,
		 #  in order to avoid to close (outside) the border of MAP2D
		$hull configure -closeenough 0.0
		 ;# so that click on margins won't trigger

    	$hull bind MAP2D <ButtonPress-1> [list apply {
    		{win hull X Y } {
    			focus $win
    			set X [expr {int([$hull canvasx $X])}]
    			set Y [expr {int([$hull canvasy $Y])}]
    			
				$win setCrosshairAt $X $Y 
			}} $win $hull %x %y ]

		bind $win <Key-Up>    [mymethod MoveCrosshair 0 -1]
		bind $win <Key-Down>  [mymethod MoveCrosshair 0 +1]
		bind $win <Key-Left>  [mymethod MoveCrosshair -1 0]
		bind $win <Key-Right> [mymethod MoveCrosshair +1 0]	
	}
	
	destructor {
		catch {image delete $my(image)}	
	}

     # for options -enablecorrection, -rangecorrection
	method Set_correction {opt val} {
		set options($opt) $val
		switch -- $opt {
		  -enablecorrection {
		     # the image should be recomputed if -enablecorrection is toggled
			$win redraw $my(x0) $my(y0) $my(z0) $my(step)
		  }
		  -rangecorrection {
			if { $options(-enablecorrection) } {
				$win redraw $my(x0) $my(y0) $my(z0) $my(step)
			}
		  }
		}	
	}

	method imagesize {} {
		list [image width $my(image)] [image height $my(image)]
	}
	
	 # this is the *core* for getting the Perlin-noise on a 2d sampled area.
	 #  returns a matrix NxM (as a list of lists..)
	 #  of Real numbers in [-1 .. +1)
	 # NOTE: if the option "-enablecorrection" is set to true,
	 #  then the resulting values are scaled by a factor taken from the
	 #  option "-rangecorrection"  ( and always clamped to [-1..+1) )
	method GetNoise2d {x0 y0 z0 step} {
		set data {}
	
		set y $y0
		set z $z0 ;# z is costant
		
		set NX $options(-width)
		set NY $options(-height)
		
		for {set i 0} {$i<$NY} {incr i} {
			set x $x0
			set datarow {}
			for {set j 0} {$j<$NX} {incr j} {
				set v [perlin $x $y $z]
				if { $options(-enablecorrection) } {
					set v [expr {$v*$options(-rangecorrection)}]
					if {$v < -1.0} {
						set v -1.0
					}
					if {$v > 1.0 } {
						set v 0.999999
					}
				}			
				lappend datarow $v			
				set x [expr {$x+$step}]
			}
			lappend data $datarow
			set y [expr {$y+$step}]	
		}
		return $data
	}

	 # return the crosshair position (relative to the origin of MAP2D) - in pixel coords.
	method getCrosshair {} {
		list $my(X) $my(Y)	
	}
	
	 # return the crosshair position in world coords
	method getxyz {} {
		set x [expr {$my(x0)+$my(X)*$my(step)}]
		set y [expr {$my(y0)+$my(Y)*$my(step)}]
		list $x $y $my(z0)
	}

	 # dX dY : integer 
	method MoveCrosshair {dX dY} {
		set newX [expr {$my(X)+$dX}]
		set newY [expr {$my(Y)+$dY}]
		
		if { 
			0 < $newX && $newX < $options(-width) 
			&&
			0 < $newY && $newY < $options(-height) 
			} {
				$win setCrosshairAt $newX $newY 			
		}
	}

	 # side effect:  
	 #  update my(X), my(Y)
	 #  raise two virtual events <<NEW_HOR_PROFILE>> and <<NEW_VER_PROFILE>>
	 #   carrying the relative Profiles  (a list of the gray values [0..255])
	 #   "under" the horizontal/vertical lines of the crosshair.
     #  raise the <<XY>> virtual event
	method setCrosshairAt {X Y} {
		set my(X) $X
		set my(Y) $Y
		 # dont'use moveto .. it's wrong 
		lassign [$hull coords "CROSSHAIR && HOR"] _ y0 _ y0
		set dy [expr {$Y-$y0}]
		$hull move "CROSSHAIR && HOR" 0 $dy
	
		lassign [$hull coords "CROSSHAIR && VER"] x0 _ x0 _
		set dx [expr {$X-$x0}]
		$hull move "CROSSHAIR && VER" $dx 0

		event generate $win <<NEW_HOR_PROFILE>> -data [list $X [$win getHorProfile $my(Y)]]
		event generate $win <<NEW_VER_PROFILE>> -data [list $Y [$win getVerProfile $my(X)]]	

		lassign [$win getxyz] x y
		event generate $win <<XY>> -data [list $x $y]
	}

	 # X is a pixel coordinate (relative to the origin of the image my(image)
	 # return a list of N gray levels [0..255]
	 #  N is the image height
	method getVerProfile {X} {
		set data {}
		set N [image height $my(image)] 
		for {set j 0} {$j<$N} {incr j} {
			set rgb [$my(image) get $X $j]
			 # since we know it's a gray , r g b components are identical, just take the first
			set gray [lindex $rgb 0]
			lappend data $gray
		}
		return $data	
	}

	 # Y is a pixel coordinate (relative to the origin of the image my(image)
	 # return a list of N gray levels [0..255]
	 #  N is the image width
	method getHorProfile {Y} {
		set data {}
		set N [image width $my(image)] 
		for {set j 0} {$j<$N} {incr j} {
			set rgb [$my(image) get $j $Y]
			 # since we know it's a gray , r g b components are identical, just take the first
			set gray [lindex $rgb 0]
			lappend data $gray
		}
		return $data	
	}

	 # this method *recomputes* a sampled 2d map and draw it.
	 #
	 # side effect:
	 #  the crosshair is updated (and then virtual events <<NEW_*_PROFILE>> raised)
	 #	 
	method redraw {x0 y0 z0 step} {
		set my(x0) $x0
		set my(y0) $y0
		set my(z0) $z0
		set my(step) $step
		 # ? why GetNoise2d does not get directly my(x0), my(y0) ...  ?
		 #    .. it's an internal method ..
		set data [$win GetNoise2d $x0 $y0 $z0 $step]
		 # here we must convert "data" (matrix of [-1..+1])
		 #  in a matrix "grayData" of gray colors #ggg
		set grayData {}
		foreach row $data {
			set grayRow {}
			foreach v $row {
				 # convert from -1..+1  to 0..1 .. then to (discrete) 0..255
				 # v = (v+1)/2
				 # v = int(v*256)
				if { $v >= 1.0 } {
					set g 255
				} else {
					set g [expr {int(($v+1.0)*128.0)}]  					
				}
				 # use a precomputed table foe converting g [0..255] in a color
				append grayRow [lindex $My(GrayTable) $g]
			}
			lappend grayData $grayRow
		}
		$my(image) put $grayData -to 0 0

		 # refresh the crosshair
		$win setCrosshairAt $my(X) $my(Y)
	}

}

# ===========================================================================
# ===========================================================================

# == GLOBAL PARAMS  (just the minimum)

set G(x0) 0.0    ;# x-origin of the explored Perlin space.
set G(y0) 0.0    ;# y-origin ...
set G(z0) 0.0    ;# z-origin ...
set G(step) 0.03 ;# resolution of the explored Perline space 
set G(ENABLED_CORRECTION) false


 # helpers for XEntry -checkcommand		
proc isDouble {x} {
	expr {$x ne "" && [string is double $x] } 
}

proc isDoublePositive {x} {
	expr {[isDouble $x] && $x > 0.0 } 
}

proc updateText {w mapWidget} {
	global G

	set x0 $G(x0)
	set y0 $G(y0)
	set step $G(step)

	lassign [$mapWidget imagesize] DX DY
	set x1 [expr {$x0+$step*$DX}]
	set y1 [expr {$y0+$step*$DY}]
	
	$w configure -text "
 Sampled Area from ($x0, $y0) to ([format "%.3f" $x1], [format "%.3f" $y1])
  $DX x $DY sampled points at $step resolution
 "
}


proc buildUI {win NX NY} {
	global G
	
	set w $win
	if { $win eq "." } { set w "" }

	$win configure -padx 10 -pady 10

	PerlinMap2D $w.2dmap -width $NX -height $NY 

	ProfileWidget $w.hplot -width $NX -height 256 -orient horizontal
		$w.hplot configure -background $::Colors(graphBg) -foreground $::Colors(horProfile) -markcolor $::Colors(verProfile)    	
		set cmd "$w.hplot redraw {*}%d"
		bind $w.2dmap <<NEW_HOR_PROFILE>> +$cmd

	ProfileWidget $w.vplot -width $NX -height 256 -orient vertical
		$w.vplot configure -background $::Colors(graphBg) -foreground $::Colors(verProfile) -markcolor $::Colors(horProfile)    	
		set cmd "$w.vplot redraw {*}%d"
		bind $w.2dmap <<NEW_VER_PROFILE>> +$cmd

	set f [frame $w.histframe]
		set H 150
		GrayLevelHistogram $f.hhist -height $H -background $::Colors(graphBg) -foreground $::Colors(horProfile)
		GrayLevelHistogram $f.vhist -height $H -background $::Colors(graphBg) -foreground $::Colors(verProfile)
			 # note: event <<NEW_*_PROFILE>> should be handled ...
			set cmd "$f.hhist redraw {*}%d"
			bind $w.2dmap <<NEW_HOR_PROFILE>> +$cmd
			set cmd "$f.vhist redraw {*}%d"
			bind $w.2dmap <<NEW_VER_PROFILE>> +$cmd
		 
		grid $f.hhist
		grid $f.vhist		 
	
	set f [frame $w.params]
		 # loop: create labels and XEntries for   x0 y0 step
		foreach name {x0 y0 step} {
			label  $f.l_${name} -text "$name"
			XEntry $f.${name} -checkcommand isDouble
			$f.${name} set $G($name)
			bind $f.${name} <<XEntry.Changed>> [list apply {
				{w name val} {
					global G
					set G($name) $val
					$w.2dmap redraw $G(x0) $G(y0) $G(z0) $G(step)
				}} $w $name %d]				
		}

		grid $f.l_x0 $f.x0   $f.l_y0 $f.y0   $f.l_step $f.step

	set f [frame $w.range]
		label $f.info -text \
"\
== Experimental ==
Amplify the values returned 
by the perlin(x,y,z) function.
"
		ttk::checkbutton $f.enable -text "" -variable G(ENABLED_CORRECTION) \
			-command [list apply {
				{mapW} {
					global G
					$mapW configure -enablecorrection $G(ENABLED_CORRECTION)
				}} $w.2dmap]

		label $f.l_coeff -text "amplitude factor"
		XEntry $f.coeff -checkcommand isDoublePositive

			bind $f.coeff <<XEntry.Changed>> "$w.2dmap configure -rangecorrection %d"
			 # initialize ..
			$w.2dmap configure -rangecorrection [$f.coeff set 1.5]		

		grid $f.info     -          -
		grid $f.enable  $f.l_coeff $f.coeff

	label $w.topmsg
		bind $w.params.x0   <<XEntry.Changed>>  +[list updateText $w.topmsg $w.2dmap]
		bind $w.params.y0   <<XEntry.Changed>>  +[list updateText $w.topmsg $w.2dmap]
		bind $w.params.step <<XEntry.Changed>>  +[list updateText $w.topmsg $w.2dmap]
		 # initialize
		updateText $w.topmsg $w.2dmap

	 # TODO: ttk::scale should be visually better but it lacks -resolution
	scale .z -orient vertical -from 0.0 -to 1.0 -resolution 0.01 \
		-borderwidth 0 -highlightthickness 0 \
		-label "z" \
		-variable G(z0) \
		-command [list apply {{w scale} {
			global G
			$w.2dmap redraw $G(x0) $G(y0) $G(z0) $G(step)
			}} $w]
			
	label $w.help   -text \
"\
Click on the Map
or 
press <Up> <Down>
for finer movements.

Use the vertical slider
to change the z-coord
or 
click in the through
for finer increments. 
"

proc updatexy {w x y} {
	$w configure -text \
		"x=[format "%.3f" $x] y=[format "%.3f" $y]"	
}
label $w.xy -text "xy"
	set cmd "updatexy $w.xy {*}%d"
	bind $w.2dmap <<XY>> +$cmd

	label $w.logo -text "Perlin Noise Explorer"
		$w.logo configure -font [buildFontVariation [$w.logo cget -font] -size 13]

	grid $w.logo     x $w.params   x
	grid ^           x $w.topmsg   x

	grid x          x    $w.xy       x
	
	grid $w.histframe $w.z $w.2dmap $w.vplot
	grid $w.help   x    $w.hplot $w.range
	

	grid configure $w.vplot -sticky w -padx 10
	grid configure $w.hplot -sticky n -pady 10
	
	grid configure $w.z -sticky ns

	 # wait for the GUI ready (and event queue empty), then start
	update
	.2dmap redraw $G(x0) $G(y0) $G(z0) $G(step)
	.2dmap setCrosshairAt 50 50
}

# ===========================================================================
# ===========================================================================
	array set Colors {
		background gray30
		foreground gray80
				
		entrybg    #c0c0c0 
		entryfg    #400040 
		
		graphBg    gray20
		verProfile yellow
		horProfile  red
	}

	 # -- options database for classic widgets
	option add *background $Colors(background)
	option add *foreground $Colors(foreground)	

	option add *Entry.background $Colors(entrybg)
	option add *Entry.foreground $Colors(entryfg)
	option add *Entry.width 8

	ttk::style configure TCheckbutton -background $Colors(background)
	ttk::style configure TCheckbutton -foreground $Colors(foreground)
	
	
	 # trick: apply bg to the "." toplevel since it's already created 
	. configure -bg $Colors(background)

	 # we assume that all the XEntry have the same font, then the same font-variation
	 # will be used for them for the editing-mode .. 
	XEntry .dummy
	set editingFont [buildFontVariation [.dummy cget -font] -slant italic -weight bold] 
	destroy .dummy
	 # NOTE: the XEntry class is Entry
	option add *Entry.editingfont $editingFont


# = MAIN ==================================================================
	buildUI . 400 400 ;# this is the size of the sampled 2D map
	wm resizable . 0 0


