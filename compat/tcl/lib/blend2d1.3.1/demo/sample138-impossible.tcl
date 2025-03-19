# sample138-impossible.tcl
#  from the original design by Oscar_Reutersvärd

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
set auto_path [linsert $auto_path 0 [file join $thisDir lib]]

package require HexCells
package require Blend2d

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }


  # result is an hextTile with an 'external' radius (and thus sides) of length $radius
  # centered at (0,0).
  # the hexTile is *pointy-top* oriented
oo::class create HexTile {
	variable my

	constructor {radius} {
		set radius [expr {$radius*1.0}]  ;#  -- force to be a real number

		set points [HexCellCorners {0 0} $radius]
		lassign $points P0 P1 P2 P3 P4 P5

		set my(style3) [BL::color gray40]
		set my(style2) [BL::color gray65]
		set my(style1) [BL::color gray90]  ;# top face

		set shadowRadius [expr {int($radius*0.3)}]
		set shadowDXY {-7 5}
		 # Note: W,H should be enlarged for the shadow
		 #  ..  here is a LARGE amount added
		set W [expr {int(ceil(sqrt(3)*$radius))}]
		set H [expr {int(ceil(2*$radius))}]
		incr W [expr {$shadowRadius*5}]
		incr H [expr {$shadowRadius*5}]

		set my(image) [BL::Surface new -format [list $W $H]]
		$my(image) clear -compop CLEAR
		set my(cx) [expr {$W/2.0}]
		set my(cy) [expr {$H/2.0}]

		$my(image) applyTransform [Mtx::translation $my(cx) $my(cy)]
		$my(image) filter shadow \
			-radius $shadowRadius -color [BL::color black] -dxy $shadowDXY {
			set facePoints [list {0 0} $P3 $P4 $P5]
			$my(image) fill [BL::polygon {*}$facePoints] -style $my(style1)

			set facePoints [list {0 0} $P5 $P0 $P1]
			$my(image) fill [BL::polygon {*}$facePoints] -style $my(style2)

			set facePoints [list {0 0} $P1 $P2 $P3]
			$my(image) fill [BL::polygon {*}$facePoints] -style $my(style3)

			$my(image) stroke [BL::polygon {*}$points] -style [BL::color black 0.5 ] -width 1.5
		}
	}

	destructor {
		if { [info exists my(image)] } { $my(image) destroy }
	}
	
	method draw {sfc x y} {
		set x [expr {$x-$my(cx)}]
		set y [expr {$y-$my(cy)}]
		$sfc copy $my(image) -to [list $x $y]
	}
}


oo::class create HexTileTrick {
	superclass HexTile
	variable my
	 # result is an hextTile with an 'external' radius (and thus sides) of length $radius
	 # centered at (0,0).
	constructor {radius} {
        next $radius

		# my(image) should be cut in two parts, delimited by the diagonal line
		# passing through the vertices #0 and #3 of the hexagon
		# -
		# my(image) will contain the half hehagon that should be drawn 'over'
		# my(image1) will contain the half hexagon that sould be drawn 'under'
		set my(image1) [$my(image) dup]

		 # this is the basic halfplane (y>=0) ; it should be rotated by 30 and 210 degrees
		set halfPlane [BL::rect -1e5 0.0 2e5 1e5]
		$my(image)  fill $halfPlane -transformation [Mtx::rotation 210 degrees] -compop DST_OUT
		$my(image1) fill $halfPlane -transformation [Mtx::rotation 30 degrees] -compop DST_OUT

		# fine correction: when drawing image and image1, there's a small imperfection
		# on the junction line, due to antialiasing ...
		# In order to fix it, we should redraw some small segments over this junction line ..
		set PI [expr {acos(-1)}]
		set x1 [expr {($radius-1)*cos($PI/6)}]
		set y1 [expr {($radius-1)*sin($PI/6)}]

		$my(image1) stroke [BL::line {0.5 0.5} [list $x1 $y1]] \
			-style $my(style2) -width 1.5

		$my(image1) stroke [BL::line {0.5 0.5} [list [expr {-$x1}] [expr {-$y1}]]] \
			-style $my(style1) -width 1.5
	}

	destructor {
		if { [info exists my(image1)] } { $my(image1) destroy }
		next
	}

	method draw {sfc x y} {
		set x [expr {$x-$my(cx)}]
		set y [expr {$y-$my(cy)}]

		$sfc copy $my(image1) -to [list $x $y] -compop DST_OVER  ;# draw UNDER
		$sfc copy $my(image) -to [list $x $y]
	}
}

    # N >=4
proc ImpossibleTriangle {sfc N cubeSize} {
	set R $cubeSize
	set cube [HexTile new $R]

	set H [expr {2*$R}]
	set W [expr {sqrt(3)*$R}]

	set border 20
	set x0 [expr {$R+3*$border}]
	set y0 [expr {$R+$border}]

	$sfc clear -compop CLEAR ;# trasparent

	for {set i 1}  {$i <$N} {incr i} {
		$cube draw $sfc $x0 $y0
		set x0 [expr {$x0+0.75*$W}]
		set y0 [expr {$y0+0.75*$H/2}]
	}
	for {set i 1}  {$i <$N} {incr i} {
		$cube draw $sfc $x0 $y0
		set x0 [expr {$x0-0.75*$W}]
		set y0 [expr {$y0+0.75*$H/2}]
	}
	 # last vertical columns; note that only N-1 cubes are drawn
	for {set i 1}  {$i <$N-1} {incr i} {
		$cube draw $sfc $x0 $y0
		set y0 [expr {$y0-1.5*$H/2}]
	}
	 # create a tricky cube, with a part that will be drawn under the previously drawn cubes
	set cube1 [HexTileTrick  new $R]
	$cube1 draw $sfc $x0 $y0

	$cube destroy
	$cube1 destroy
}

# === main ===========================================
	set sfc [image create blend2d -format {800 800}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	ImpossibleTriangle $sfc 6 80.0

	 # marble effect ..
	 #  please note that also the shadows becomes 'texturized'
	set overlaySfc [BL::Surface new]
	$overlaySfc load [file join $thisDir cem9.jpg]
	$sfc copy $overlaySfc -compop SRC_ATOP -globalalpha 0.3
	$overlaySfc destroy

	 # finally, fill transparent pixels with a radial gradient
	lassign [$sfc size] W H
	set W2 [expr {$W/2}]
	set H2 [expr {$H/2}]
	set innerColor [BL::color red]
	set outerColor [BL::color black]
	$sfc fill [BL::circle [list $W2 $H2] $W2] -compop DST_OVER -style \
			[BL::gradient RADIAL [list $W2 $H2 $W2 $H2  $W2] \
				[list 0.0 $innerColor 1.0 $outerColor]]
