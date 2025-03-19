# sample139-XOR

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

	proc tile {sfc x y size} {
		set P0 {0 0}
		set P1 [list $size 0]
		set P2 [list $size $size]
		set P3 [list 0 $size]
		set halfSize [expr {$size/2.0}]
		set C  [list $halfSize $halfSize]
		$sfc push
		$sfc applyTransform [Mtx::translation $x $y]

		$sfc configure -compop XOR
		$sfc fill [BL::polygon $P0 $P1 $P3]
		$sfc fill [BL::polygon $P0 $P2 $P3]
		$sfc fill [BL::circle $C [expr {$halfSize/1.2}]]
		$sfc pop
		# NOTE: XORed pixels becomes fully transparent
	}

# === main ===========================================
	set sfc [image create blend2d -format {900 900}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	$sfc configure -fill.style [BL::color darkblue]
	$sfc fill all

	set size 200
	set y 50
	for {set i 0} {$i < 4} {incr i} {
		set x 50
		for {set j 0} {$j < 4} {incr j} {
			tile $sfc $x $y $size
			incr x $size
		}
		incr y $size
	}
	# fill the transparent pixels
	$sfc clear -style [BL::color orange]  -compop DST_OVER
