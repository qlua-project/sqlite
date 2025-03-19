# sample123-twistedpuffs.tcl

# Inspired by "Rainbow Ribbons" 
#   https://openprocessing.org/sketch/1870879

# same results but with a very different tecnique.
#  *  Use a simple Path made of 4 quadratic curves (instead of a spline)
#  *  no need to use several layers and a complex "erase()" method
#     nor, no need to use the composition-op DST_OVER for drawing "under" 
#     Simply, start drawing the top ribbons

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

 # --make a 'puff' shape in $path.
 #   origin at (0,0)
proc shape_a_Puff {path dx dy dh} {
	$path reset
	set y2 [expr {$dy/2}]   ;# dx/2
	set x1 [expr {$dx/4}]   ;# (1/4)d
	set x2 [expr {$dx/2}]   ;# (1/2)dx
	set x3 [expr {$dx*3/4}] ;# (3/4)dx
	 # -- from (0,0) goto (dx,dy) with two quadratic curves 
	$path moveTo {0 0}
	$path quadTo [list $x1 0] [list $x2 $y2] \
	             [list $x3 $dy] [list $dx $dy]
	 # -- add a vertical segment of length dh
	set dy [expr {$dy+$dh}]
	$path lineTo [list $dx $dy]
	 # -- add two quadratic curves to go back to (0,0)
	set y2 [expr {$dy/2}]	
	$path quadTo [list $x3 $dy] [list $x2 $y2] \
		         [list $x1 0] {0 0}			
	$path close
}

set COLOR_IDX 0
proc nextColor {} {
	global COLOR_IDX
	set palette {
		0xffabcd5e 0xfff9d531 0xfffc8405 0xffef562f
		0xfff589a3 0xff62b6de 0xff2b67af 0xff14976b 
	}
	incr COLOR_IDX
	if {$COLOR_IDX == [llength $palette]} { set COLOR_IDX 0 }
	return [lindex $palette $COLOR_IDX]
}

proc draw {sfc} {
	$sfc clear
	
	set puffUp [BL::Path new]
	set puffDown [BL::Path new]
	
	lassign [$sfc size] WIDTH HEIGHT
	
	set XC [expr {$WIDTH/2}]
	set YC [expr {$HEIGHT/2}]
	
	set dh 50
	for {set y [expr {2*$dh}]} {$y<=$HEIGHT-2*$dh} { incr y [expr {2*$dh}]} {
		 # the drawing order is critical:
		 #   first the white puff, then the colored puffs
		  
		shape_a_Puff $puffDown $WIDTH $y $dh 
		 # puffUp should by xreflected.
		 #  Note: puffUp is NOT simply puffDown "y-reflected"; it's higher then puffDown.
		shape_a_Puff $puffUp $WIDTH [expr {$y+$dh}] $dh 
		$puffUp apply [Mtx::yreflection $YC]

		set color 0xFFffffff
		$sfc fill $puffDown -style $color
		$sfc fill $puffUp   -style $color -transformation [Mtx::xreflection $XC]

		$sfc fill $puffDown -style [nextColor] -transformation [Mtx::xreflection $XC]
		$sfc fill $puffUp   -style [nextColor]		

	}
	$puffUp destroy
	$puffDown destroy
}

# === main ===========================================
	set sfc [image create blend2d -format {700 900}]
	pack [label .cvs -image $sfc] -padx 30 -pady 30
	. configure -background black
	.cvs configure -borderwidth 0
	
	draw $sfc
