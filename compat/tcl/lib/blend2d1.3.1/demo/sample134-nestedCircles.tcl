# sample134-nestedCircles
#
#  See image
#  https://www.karinmonschauer.ch/data/_uploaded/2020%20Opere/163-L%27occhio-di-Internet-%281000-x-1000%29.jpg

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d


proc nestedCircles {sfc r dr steps} {
	set col1 [BL::color red]
	set col2 [BL::color black]

	while { $steps > 0 } {
		$sfc fill [BL::circle {0 0} $r] -style $col1
		set r [expr {$r-$dr}]
		 # fine tuning : to avoid small antialiasing imperfections,
		 #  move the black circle by 0.5 pixels ...
		set x [expr {-$dr-0.5}]
		$sfc fill [BL::circle [list $x 0] $r] -style $col2
		set r [expr {$r-$dr}]

		incr steps -1
	}
}

# -- main ------

set sfc [image create blend2d -format {800 800}]
pack [label .x -image $sfc]

$sfc clear
$sfc applyTransform [Mtx::translation 400 400]  ;# center origin
$sfc applyTransform [Mtx::yreflection]  ;# now y-axis is UP


	set R 350
	set dR 7
	set steps 5

	$sfc clear
$sfc push

	for {set i 0} { $i < 4} {incr i} {
		$sfc push
		if {$i%2==1} {
			$sfc applyTransform [Mtx::rotation +90 degrees]
 		}
		nestedCircles $sfc $R $dR $steps
		incr R [expr {-$dR*2*$steps}]
		$sfc pop
	}

	# last circles should be rotated by +180 degrees
	$sfc applyTransform [Mtx::rotation +180 degrees]
	nestedCircles $sfc $R $dR $steps

$sfc pop
