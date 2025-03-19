# demo svg anchor placement

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d 1.3


proc updateCoordSys {} {
	global SFC
	global X0 Y0
	global ANGLE
	 # be careful; there can be a metamatrix set
	lassign [Mtx::PxM [list $X0 $Y0] [Mtx::invert [$SFC cget -metamatrix]]] mx0 my0
	$SFC configure -matrix [Mtx::translation $mx0 $my0]
	$SFC applyTransform [Mtx::rotation $ANGLE degrees]
}

 # to be called after setting the coord-system of the surface
proc drawAxis {sfc} {
	$sfc push
	$sfc configure -stroke.style [BL::color red] -stroke.width 1
	$sfc stroke [BL::line {-10000 0} {+10000 0}]
	$sfc stroke [BL::line {0 -10000} {0 +10000}]
	$sfc pop
}

proc redraw {} {
	global SFC
	global SVG
	global ANCHOR
	global AUTORESIZE

	$SFC clear -style [BL::color gray90]
	drawAxis $SFC
	 # ------------------------------------------------------------
	set M [$SFC paint $SVG -anchor $ANCHOR -autoresize $AUTORESIZE]
	 # ------------------------------------------------------------
	if { $M == {} } {
		 # TO DO; a message like "With autoresize enabled, the coordinate-system's origin must be within the surface borders"
		bell
		return
	}
	 # draw a bounding box
	$SFC push
		lassign [$SVG bbox] x0 y0 x1 y1
		$SFC applyTransform $M
		$SFC configure -stroke.width 2 -stroke.transformorder BEFORE
		$SFC stroke [BL::box [list $x0 $y0] [list $x1 $y1]] -style [BL::color red]
	$SFC pop
}

# ======================================================

# few global variable, just for laziness
#  SFC
#  SVG
#  X0 Y0     Coord-systems's origin
#  ANGLE     Coord-system's rotation (in degrees)
#  ANCHOR
#  AUTORESIZE

set SVG [BL::Svgdoc new [file join $thisDir moby.svg]]

set SFC [image create blend2d -format {1000 700}]
label .sfc -image $SFC

frame .panel -padx 5 -pady 5
pack .sfc .panel -side left

bind .sfc <ButtonPress-1> {
	set X0 %x
	set Y0 %y
	updateCoordSys ; redraw
}


pack [scale .panel.angle] -fill x
.panel.angle configure -orient horizontal -from 0 -to 360 -variable ANGLE
trace add variable ANGLE write { apply {{args} {updateCoordSys ; redraw}} }

set ANCHOR NONE
set w .panel.anchor
ttk::labelframe $w -text "Anchor"
foreach a {NONE CENTER N S E W NW NE SW SE} {
	ttk::radiobutton $w.a_$a -variable ANCHOR -value $a -text $a
}

grid    x       $w.a_NONE     x       -sticky w
grid   $w.a_NW  $w.a_N       $w.a_NE  -sticky w
grid   $w.a_W   $w.a_CENTER  $w.a_E   -sticky w
grid   $w.a_SW  $w.a_S       $w.a_SE  -sticky w
pack $w

trace add variable ANCHOR write { apply {{args} {redraw}} }

set AUTORESIZE false
ttk::checkbutton .panel.autoresize -variable AUTORESIZE -text "autoresize" -command redraw
pack .panel.autoresize

pack [text .panel.txt -height 20 -width 40 -font {-size 9}]
.panel.txt insert 0.0 {
The SVG image is always drawn accordling to the current coord-sys (XY axes in red).

Click on the canvas to move the origin of the coord-sys, or use the rotation's slider.

The selected Anchor determines whick corner/side of the image should be anchored to the origin of the current coord-sys.

If Autoresize is active, then the image is automatically scaled, so as to occupy the maximum Surface area, compliant with the current coordinate-system and respecting the anchor constraints.

Note that if Autoresize is active, if the origin of the coord-sys is not within the surface, then nothing is drawn.
}
.panel.txt configure -state disabled

set X0 100 ; set Y0 50 ; updateCoordSys ; redraw

