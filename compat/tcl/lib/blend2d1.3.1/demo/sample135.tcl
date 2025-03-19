# sample135-Shifted
# see
# https://openprocessing.org/sketch/1237334

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d 1.2.1

 # create (as a BL::Path) a new square of size 1.0 with differently rounded corners
proc newRoundrect {r1 r2 r3 r4} {
	set path [BL::Path new]
	if { $r1>0 } {
		$path moveTo [list 0 $r1]
		$path quadTo {0 0} [list $r1 0]
	} else {
		$path moveTo {0 0}
	}
	$path lineTo [list [expr {1-$r2}] 0]
	if { $r2>0 } {
		$path quadTo {1 0} [list 1 $r2]
	}
	$path lineTo [list 1 [expr {1-$r3}]]
	if { $r3>0 } {
		$path quadTo {1 1} [list [expr {1-$r3}] 1]
	}
	$path lineTo [list $r4 1]
	if { $r4>0 } {
		$path quadTo {0 1} [list 0 [expr {1-$r4}]]
	}
	$path close

	return $path
}

# -- main ------

set sfc [image create blend2d -format {800 800}]
pack [label .x -image $sfc]

	set bgHSB {240 0.7 0.1}   ;# dark blue
	set fgHSB {0   0.7 1.0}   ;# red (desaturated)

	$sfc configure -fill.style [HSB {*}$bgHSB]
	$sfc clear

	lassign [$sfc size] WIDTH HEIGHT
	set sw $WIDTH
	set shadow [expr {$WIDTH*0.01}]
	set radius 4.0

	set r1 [expr {1.0/$radius}]
  	set rrObj [newRoundrect $r1 $r1 0 $r1]

	for {set x $sw} {$x>=0} {set x [expr {$x-$WIDTH/10.0}]} {
		$sfc push
		$sfc applyTransform [Mtx::translation [expr {$WIDTH/$radius}] [expr {$WIDTH/$radius}]]
		$sfc applyTransform [Mtx::translation [expr {-$x/$radius+$shadow}] [expr {-$x/$radius+$shadow}]]
		$sfc fill $rrObj -transformation [Mtx::scale $x $x]

		set hsb [HSBblend $fgHSB $bgHSB [expr {$x/$sw}]]

		$sfc applyTransform [Mtx::translation [expr {-$shadow}] [expr {-$shadow}]]
		$sfc fill $rrObj -style [HSB {*}$hsb]  -transformation [Mtx::scale $x $x]
		$sfc pop
	}
	$rrObj destroy
