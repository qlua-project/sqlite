# sample128-clouds.tcl

# This is an interesting way for visualing perlin noise.
# the x and y coords are shifted. x shift should be greater than shift y,
#  so that 'clouds' move horizontally and to a much lesser extent vertically.
# Just by shifting x and y we will get a scrolling effect; adding a small change in the z direction,
# we can observe a smooth variation of the clouds shapes.

# Note that computing the noise() for each pixel will require too much time,
# so, the trick is to reduce the resolution of each frame; in practice
# we draw many overlapped shapes (hexagons).

# Inspired by
# https://openprocessing.org/sketch/1918970

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

lappend auto_path [file join $thisDir lib]
package require perlin

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::clamp {v a b} { expr {$v<$a ? $a : ($v<$b ? $v :$b)} }
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }

	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }

	set ::PI [expr {acos(-1)}]
	proc tcl::mathfunc::deg2rad {a} {expr {$a*$::PI/180}}
	 # NOTE: Perlin return a floating number between -1 and +1 
	 # (in practice range is quite limited. -0.7 .. +0.7)
	 # Here we transform perlin() in noise(), returning a value between 0 and 1
	 # (in practice between 0.2 and 0.8)
	proc tcl::mathfunc::noise {x y z} {expr {[perlin $x $y $z]/2+0.5}} ;# normalize from 0 to 1
	proc tcl::mathfunc::noise {x y z} {expr {clamp(map([perlin $x $y $z],-0.7,0.6,0,1),0,1)}} ;# normalize from 0 to 1

 # hexagon centered at 0,0, inscribed in a circle of radius r
 # return a new BL::Path
proc newHexagon {r} {
	set hexagon [BL::Path new]
	$hexagon moveTo [list $r 0]
	for {set alfa 60} {$alfa<360} {incr alfa 60} {
		set a [expr {deg2rad($alfa)}]
		$hexagon lineTo [list [expr {$r*cos($a)}] [expr {$r*sin($a)}]]
	}
	$hexagon close
	$hexagon apply [Mtx::rotation 90 degrees]
	return $hexagon
}

# r should be equal to to hexagon radius (or less, for more fitting)

proc fillSurface {sfc hexShape r step} {
set  z $step
	lassign [$sfc size] WIDTH HEIGHT
	
	set i 0
	set dy [expr {1.5*$r}]
	set dx [expr {$r*sqrt(3)}]
	for {set y 0} {$y <=$HEIGHT} {set y [expr {$y+$dy}]} {
		if {$i%2==0} {set x 0} else {set x [expr {$dx/2.0}]}
		incr i
		for {set x $x} {$x<=$WIDTH} {set x [expr {$x+$dx}]} {
			set v [expr {noise($x/($WIDTH/2.0)+$z/200.0, $y/($HEIGHT/3.0)+$z/500.0, $z/200.0)}]
			set red [expr {int($v*255)}]
			set rgba [BL::rgb $red 120 150 0.8]
			$sfc fill $hexShape -matrix [list 1 0 0 1 $x $y] -style $rgba
		}
	}
}

proc setup {sfc} {
	global SHAPE
	global RADIUS
	
	$sfc fill all -style [BL::color skyblue]
	set RADIUS 8
	set SHAPE [newHexagon $RADIUS]
}

proc draw {sfc frameCount} {
	global SHAPE
	global RADIUS
	$sfc clear -style [BL::color skyblue]
	fillSurface $sfc $SHAPE $RADIUS  $frameCount
}

# === main ===========================================
	set sfc [image create blend2d -format {1200 600}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	setup $sfc
	set RUNNING false

	proc draw_loop {sfc} {
		global RUNNING
		global FRAMECOUNT
		
		draw $sfc [incr FRAMECOUNT 5]
		if {$RUNNING} {after 50 [list draw_loop $sfc]}
	}

	bind . <ButtonPress-1> {
		if {$RUNNING} { 
			set RUNNING false
			place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
		} else {
			place forget .top
			set RUNNING true
			draw_loop $sfc
		}
	}

	 # --- splash message ---
	label .top -text "Click to start" -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
	vwait RUNNING
