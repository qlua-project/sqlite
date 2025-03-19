#  
#  Files within folder BoxAlphabet contains the preprocessed SVG-path
#  extracted from SVG files.
#

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d


 # ----------------------------------------------------------------------
 # LetterGeometry is a global variable containing the core data.
 #
 # LetterGeometry is a dictionary with the following keys:
 #  * viewbox  {x y dx dy}
 #  * fill     .. background color
 #  * layers   list of  ..  color, blPath
 #
 #

 # resize the Surface and set a 2d transformation to confine the viewbox 
 # within the Surface (leaving a 'frame' of m pixel )
 #  .. 
 #  W, H the size of the Surface container (in pixel)
 #  m  margin (in pixel)
 #  viewBox   (x y dx dy)  in world coords
 #
proc Resize {SFC W H m viewBox } {
	if { $W <= 2*$m || $H <= 2*$m }  return

	lassign $viewBox x0 y0 dx dy
	set dx [expr {double($dx)}]
	set dy [expr {double($dy)}]
	
	set ratio [expr {$dx/$dy}]

	 # pay attention: ratio of two integers ..
	if { double(($W-2*$m))/($H-2*$m) > $ratio } {
		set DY $H
			set DY1 [expr {$DY-2*$m}]
			set DX1 [expr {round($DY1*$ratio)}]
		set DX [expr {$DX1+2*$m}]
	} else {
		set DX $W
			set DX1 [expr {$DX-2*$m}]
			set DY1 [expr {round($DX1/$ratio)}]
		set DY [expr {$DY1+2*$m}]	
	}
	 # note that DX1/DY1 is equal to ratio
	set zoom [expr {$DX1/$dx}]  ; # same as DY1/dy

	 # DX DY is the required size of SFC
	 lassign [$SFC size] oldDX oldDY
	 if { $DX != $oldDX || $DY != $oldDY } {
	 	$SFC configure -format [list $DX $DY]
	 }
	 
	 # scale/traslate the SFC's coord-system
	set M [Mtx::MxM \
			[Mtx::scale $zoom] \
			[Mtx::translation $m $m] \
		]	
	$SFC configure -matrix $M
}

proc Redraw {SFC LetterGeometry filterType} {
	$SFC clear -style [BL::color [dict get $LetterGeometry "fill"]]

	foreach {color blPath} [dict get $LetterGeometry "layers"] {
		$SFC filter $filterType -radius 20 -dxy {3 10} -color [BL::color gray20] {
			$SFC fill $blPath -style [BL::color $color]
		}
	}
}  

 # free the memory (object instances)
proc unsetLetterGeometry { varname } {
	upvar $varname var
	foreach {color blPath} [dict get $var "layers"] {
		$blPath destroy
	}
	set var {}
}

proc loadLetter { dir c } {
	 # every letter is a dict with the following keys
	 #  viewbox
	 #  fill
	 #  layers
	 #
	 #  layers is a list of .. color SVGdata	 
	set f [open [file join $dir ${c}.svg.tcl] r]
	set letterDict [dict create {*}[read $f]]
	close $f

	 # transform svgdata in BLPath	 	
	set colorsAndBLPaths {}
	foreach {color svgdata} [dict get $letterDict "layers"] {
		set blPath [BL::Path new]
	    $blPath addSVGpath $svgdata
		lappend colorsAndBLPaths $color $blPath 
	}
	 # replace layers : from list of colors,svgdata to a list of colors,blPath
	dict set letterDict "layers" $colorsAndBLPaths
	return $letterDict
}

 # == MAIN =====

wm title . "TclTk bindings for Blen2d - demo 111"

set FILTER_TYPE "ignore"
set ALPHABET_DIR [file join $thisDir BoxAlphabet]
set MARGIN 30 ; # in pixel

frame .leftBar
	ttk::checkbutton .leftBar.shadow -text "Shadows" -variable FILTER_TYPE \
		-offvalue "ignore" -onvalue "shadow"

	ttk::label .leftBar.msg -text "Type a letter A..Z"
	pack .leftBar.msg .leftBar.shadow 
	pack .leftBar.shadow -padx 5 -side left

pack .leftBar -padx 5 -side left

set SFC [image create blend2d]
label .cvs -image $SFC -borderwidth 0
pack .cvs -padx 20 -pady 20 -expand 1 -fill both

# -----

set LetterGeometry [loadLetter $ALPHABET_DIR "A"]

Resize $SFC 500 500 $MARGIN [dict get $LetterGeometry "viewbox"]
Redraw $SFC $LetterGeometry $FILTER_TYPE    
      
 
 # resize and redraw
bind .cvs <Configure> { 
	Resize $SFC %w %h $MARGIN [dict get $LetterGeometry "viewbox"]	
	Redraw $SFC $LetterGeometry $FILTER_TYPE 
}

 # turn the shadow on/off     
.leftBar.shadow configure -command { Redraw $SFC $LetterGeometry $FILTER_TYPE }  

 # change the letter
bind . <Key> {
	set letter "%K" ;# -- it could be a string
	if { [string length $letter] != 1 } { set letter "" } 
	if { $letter ne ""  && [string is alpha $letter] } {
		set letter [string toupper $letter]
		 # Pay attention: destroy all the old BLPath stored in letterGeometry
		unsetLetterGeometry LetterGeometry
		set LetterGeometry [loadLetter $ALPHABET_DIR $letter] 
		Redraw $SFC $LetterGeometry $FILTER_TYPE
	}
} 
     