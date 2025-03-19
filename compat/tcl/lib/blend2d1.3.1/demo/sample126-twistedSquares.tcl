# sample126-twistedsquares.tcl

# Based on "Twisted Squares" 
#   https://openprocessing.org/sketch/954947

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::lerp {x0 x1 t} { expr {$x0+($x1-$x0)*$t} }
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }
	set ::PI [expr {acos(-1)}]
	proc tcl::mathfunc::deg2rad {a} {expr {$a*$::PI/180}}

set A1 0
set A2 0
set RF 45

proc setup {sfc} {
	lassign [$sfc size] WIDTH HEIGTH
	$sfc configure -matrix  [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGTH/2}]]
}

proc draw {sfc MOUSEY} {
	global A1 ; # degrees
	global A2 ; # degrees
	global RF
	
	lassign [$sfc size] WIDTH HEIGHT
	$sfc clear -style [BL::color black]

	$sfc configure \
		-fill.style [BL::color white 0.12] \
		-stroke.style [BL::color black] 
	
	set RF [expr {lerp($RF,map($MOUSEY,0,$HEIGHT,45,135),0.1)}]
	for {set i [expr {$WIDTH/2}]} {$i<$WIDTH} {incr i 8} {
		$sfc push
		 # this rotation is so absurd ... but it works !
		$sfc applyTransform [Mtx::rotation [expr {$RF*cos(deg2rad($i*$A1))}] degrees]
		set dx [expr {$WIDTH - $i}]
		set halfdx [expr {$dx/2}]
		set radius [expr {$dx/8}]
		 # draw a rounded-square centered at 0,0
		$sfc fill [BL::roundrect -$halfdx -$halfdx $dx $dx $radius]
		$sfc stroke [BL::roundrect -$halfdx -$halfdx $dx $dx $radius]
		$sfc pop
	}
	set A1 [expr {sin(deg2rad($A2))}]
	set A2 [expr {$A2+0.2}]
}

# === main ===========================================
	set sfc [image create blend2d -format {1000 700}]
	pack [label .cvs -image $sfc] -padx 30 -pady 30
	. configure -background black
	.cvs configure -borderwidth 0



set MOUSEY 0
bind .cvs <Motion> { set MOUSEY %y }

proc draw_loop {sfc} {
	draw $sfc $::MOUSEY
	after 10 [list draw_loop $sfc]
}
	
	setup $sfc
	draw_loop $sfc
