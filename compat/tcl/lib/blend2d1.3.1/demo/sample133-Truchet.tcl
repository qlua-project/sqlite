# sample133-truchet.tcl

# Truchet tiles.
#
# Based on
# https://www.reddit.com/r/generative/comments/r4qfmv/improved_version_of_my_triangular_truchet_tile/
# code: (Python) https://pastebin.com/NQuAnL2S#
	
set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
set auto_path [linsert $auto_path 0 [file join $thisDir lib]]

package require Blend2d
package require RandGen

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

# ====================================================

	proc tcl::mathfunc::P {x y} {list $x $y}
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }	
	 # randrange(A,B)	Returns a random integer from A to B-1.
	proc tcl::mathfunc::randrange {n1 n2} { expr {int(random($n1,$n2))} }

	set PI [expr {acos(-1)}]
	 # height of an equilater triangle with baseLen = 1
	set H_RATIO [expr {sqrt(3)/2}]


  # an HexGrid is made of 6 equilater triangles forming an hexagon
  # The center of the hexagon is placed at (0,0)
proc createHexGrid {size} {
	variable H_RATIO
	set B [expr {$size/2.0}]
	set H [expr {$B*$H_RATIO}]

	set b [expr {$B/2}]
	set h [expr {$H/2}]

	 # a triangle is specified as a list of
	 #   {cx cy} size orientation
	 #   - {cx cy} are the coords of its center
	 #   - size is the the lenght of its side
	 #   - orientation : 1 is point-y UP, 0 is point-y DOWN
	lappend triangles [list [expr {P(-$b,+$h)}] $B 1]
	lappend triangles [list [expr {P(0.0,+$h)}] $B 0]
	lappend triangles [list [expr {P(+$b,+$h)}] $B 1]
	lappend triangles [list [expr {P(-$b,-$h)}] $B 0]
	lappend triangles [list [expr {P(0.0,-$h)}] $B 1]
	lappend triangles [list [expr {P(+$b,-$h)}] $B 0]
	return $triangles
}


  # -- Split a triangle in 4 triangles
  #    Result is a list of 4 triangles
proc splitTriangle {tri} {
	variable H_RATIO

	lassign $tri P size isUp
	lassign $P xc yc

	set B [expr {$size/2}]
	set b [expr {$size/4}]
	set h [expr {$b*$H_RATIO}]
	if {!$isUp} { set h [expr {-$h}] }

	set triangles [list]
	lappend triangles [list [expr {P($xc,   $yc+$h)}] $B $isUp]
	lappend triangles [list [expr {P($xc-$b,$yc-$h)}] $B $isUp]
	lappend triangles [list [expr {P($xc,   $yc-$h)}] $B [expr {!$isUp}]]
	lappend triangles [list [expr {P($xc+$b,$yc-$h)}] $B $isUp]
	return $triangles
}

proc drawTriangle {sfc triangle} {
	variable H_RATIO
	variable PI
	lassign $triangle P size isUp
	lassign $P xc yc

	set h [expr {$size*$H_RATIO}]
	set sweep [expr {$PI/3}]
	set vIdx [expr {randrange(0,3)}]
  $sfc push
	$sfc applyTransform [Mtx::translation $xc $yc]
	if {!$isUp} { $sfc applyTransform [Mtx::yreflection] }

	drawArcs $sfc [expr {P(-$size/2,-$h/2)}] [expr {$size*($vIdx==0?0.75:0.5)}] 0 $sweep
	drawArcs $sfc [expr {P(+$size/2,-$h/2)}] [expr {$size*($vIdx==1?0.75:0.5)}] [expr {$PI*2/3}] $sweep
	drawArcs $sfc [expr {P(0,$h/2)}]         [expr {$size*($vIdx==2?0.75:0.5)}] [expr {$PI*4/3}] $sweep
  $sfc pop
# -- uncomment for animation
#  after [expr {int(2*$size)}]
#  update
}


 # fill a sector of a circle (a pie) [with -fill.style]
 # and then stroke a sequence of arcs [with -stroke.style]
proc drawArcs {sfc P size a0 sweep} {
	$sfc fill [BL::pie $P $size $size $a0 $sweep]
	set sw [$sfc cget -stroke.width]
	set n [expr {int($size/$sw/2.0)}]
	for {set i 1} {$i<= $n} {incr i} {
		set s [expr {$sw*(2*$i)}]
		$sfc stroke [BL::arc $P $s $s $a0 $sweep]
	}
	$sfc fill [BL::circle $P [expr {$sw/2}]] \
		-style [$sfc cget -stroke.style]
}

 # return the 6 hexagon's vertices
proc Hexagon {hexSide} {
	variable PI
	set Vertices [list]
	for {set i 0} {$i<6} {incr i} {
		lappend Vertices [expr {P($hexSide*cos($i*$PI/3),$hexSide*sin($i*$PI/3))}]
	}
	return $Vertices
}

proc Redraw {sfc bgStyle borderWidth} {
	variable MinLevel
	variable MaxLevel

	set MinLevel [expr {randrange(0,2)}]
	set MaxLevel [expr {randrange($MinLevel+2,6)}]

	$sfc clear -style $bgStyle
	lassign [$sfc size] WIDTH HEIGHT
  $sfc push
	 # place the origin at the center of the surface,
	 #  rotate the axes by 30 degrees
	 #  invert the y-axis orientation (y-axis UP)
	$sfc applyTransform [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGHT/2}]]
	$sfc applyTransform [Mtx::rotation 30 degrees]
	$sfc applyTransform [Mtx::yreflection]

	set hexSide [expr {double((min($WIDTH,$HEIGHT)-2*$borderWidth)/2)}]

	$sfc configure \
		-fill.style   [BL::color white] \
		-stroke.style [BL::color black] \
		-stroke.width [expr {$hexSide/8/(2**$MaxLevel)}]

	 # FIX - draw a white hexagon as a background
	 #       - this should avoid smaill antialiased gaps between tiles
	$sfc fill [BL::polygon {*}[Hexagon [expr {$hexSide+1}]]]
	 # NOTE:  there's still a small gaps between black arcs
	
	foreach triangle [createHexGrid [expr {2*$hexSide}]] {
		Rtruchet $sfc $triangle 1	
	}
	decorateHexBorders $sfc $hexSide
  $sfc pop
}


proc decorateHexBorders {sfc hexSide} {
	variable PI
	variable MaxLevel

	 # draw a circle on every hexagon vertex
	set sw [$sfc cget -stroke.width]
	set sweep [expr {$PI/3*4}]
	for {set i 0} {$i<6} {incr i} {
		set vx [expr {$hexSide*cos($PI/3*$i)}]
		set vy [expr {$hexSide*sin($PI/3*$i)}]
		set Vtx [list $vx $vy]
		set cornerArcs($i) [expr {randrange(2,$MaxLevel+1)}]
		set s [expr {2*$cornerArcs($i)*$sw}]
		set a0 [expr {$PI/3*($i-2)}]
		drawArcs $sfc $Vtx $s $a0 $sweep
	}

	 # draw a sequence of semi-circles on each hexagon's side 
	for {set i 0} {$i<6} {incr i} {
		 # every hexagon side can be split in maxSteps parts of lenght sw
		set maxSteps [expr {int($hexSide/$sw)}]
		 # the last steps are used by the arc on the next vertex
		set maxSteps [expr {$maxSteps - 2*$cornerArcs([expr {($i+1)%6}])}]
		 # the first steps are used by the corner arcs on this vertex
		set n [expr {2*$cornerArcs($i)}]
		
		while {$n<$maxSteps} {
			set arcs [expr {randrange(1,3*$MaxLevel)}]
			if {4*$arcs > $maxSteps-$n} {
				set arcs [expr {($maxSteps-$n)/4}]
				if {$arcs==0} { set arcs 1 }
			}
			set x [expr {cos($i*$PI/3)*$hexSide+cos(2*$PI/3+$i*$PI/3)*$sw*(2*$arcs+$n)}]
			set y [expr {sin($i*$PI/3)*$hexSide+sin(2*$PI/3+$i*$PI/3)*$sw*(2*$arcs+$n)}]
			set s [expr {2*($arcs)*$sw}]
			drawArcs $sfc [list $x $y] $s [expr {$PI/3*($i+2)-$PI}] $PI 
		
			incr n [expr {4*$arcs}]
		}		
	}	
}


 # Recursive Truchet:
 #  draw o triangle, or split it in 4 triangles and recursively ...
proc Rtruchet {sfc triangle level} {
	variable MinLevel
	variable MaxLevel

	if {$level <= $MinLevel || ($level <= $MaxLevel && rand() <0.5 )} {
		incr level
		foreach tri [splitTriangle $triangle] {
			Rtruchet $sfc $tri $level
		}
	} else {
		drawTriangle $sfc $triangle		
	}
}


# === main ===========================================

	set sfc [image create blend2d -format {1024 1024}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	place [RandGen::widget .rg] -in .cvs -x 10 -y 10
	.rg configure -borderwidth 5 -relief raised
	.rg set "BUZZ"

	set borderWidth 100
	set bgStyle [BL::color red]
		
	RandGen::SeedInit [.rg get]
	Redraw $sfc $bgStyle $borderWidth

	bind .rg <<Changed>> {
		RandGen::SeedInit %d
		Redraw $sfc $bgStyle $borderWidth
	}
