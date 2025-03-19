#// Created for #Genuary2024 - Day 3 - Droste Effect
#// https://genuary.art/prompts#jan3

#// https://openprocessing.org/sketch/2135946

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d 1.1.1


proc drawDroste {sfc xc yc size angle level} {
	$sfc clear
	while {$level > 0 && $size > 1} {
		set quarter [expr {$size/4.0}]
		set x0 [expr {$xc-$size/2.0}]
		set y0 [expr {$yc-$size/2.0}]

		$sfc push
		 # compute the new angle depending on time.
		 #  level1 completes a 360 round in 10 seconds
		 #  level2 in 5 seconds
		 #  level3 in 10/3 secods .. and so on
		set t [expr {[clock milliseconds]/1000.0}]
		set angle [expr {$t*6.28/200.0*($level)}]
		$sfc applyTransform [Mtx::rotation $angle radians]

		$sfc fill [BL::rect $x0 $y0 $size $size] -style 0xFF000000

		set small [expr {0.91*$size}]
		set offset [expr {0.09*$size/2.0}]
		$sfc fill [BL::rect [expr {$x0+$offset}] [expr {$y0+$offset}] $small $small] -style 0xFFffffff

		$sfc fill [BL::rect [expr {$xc+$quarter}] [expr {$yc+$quarter}] $quarter $quarter] -style 0xFF000000
		$sfc fill [BL::rect $x0 $y0 $quarter $quarter] -style 0xFF000000

		$sfc pop

		set gScale 0.9
		set size  [expr {$gScale*$size}]
		incr level -1
	}
}



proc draw {sfc} {
	lassign [$sfc size] WIDTH HEIGHT
    drawDroste $sfc 0 0 $HEIGHT 0 50
}

# co_after grabbed from the package "coroutine"
proc co_after {ms} {
    after $ms [list [info coroutine]]
    yield
    return
}

proc co_animate {sfc} {
	 # setting the coord-system:
	 #  * origin at center of the surface
	lassign [$sfc size] WIDTH HEIGHT
	$sfc push
	$sfc applyTransform [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGHT/2}]]

	$sfc clear
	while {1} {
		draw $sfc
		co_after 50
	}
	$sfc pop
}

# -- main ---------------------------------------------------------------------

set size 800
set sfc [image create blend2d -format [list $size $size]]
pack [label .x -image $sfc]

catch {console show}

coroutine animate co_animate $sfc
