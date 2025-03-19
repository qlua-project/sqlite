# sample140-annuli
#  see
#  https://openprocessing.org/sketch/1892578
#   by Roni Kaufman

# NOTE:
#  with respect to the original implementation,
#  there's no need of 6 precomputed images (6 discs with conical gradients)
#  that are rotated and blended at every step.
#  Here, I simply draw 6 annuli with a conical gradient computed on fly.
#  -
#  The main difference is that this conical gradient is interpolates the colors
#  in a linear way, whilst the original implementation uses an esing function ..
#  Anyway, it won't be difficult to recreate such gradient, save it in ONE image,
#   and then use this image as a pattern for filling the annuli.

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d 1.1.1

	#
	# -- some math constants -----------------------------------------
	#
	set PI  [expr {acos(-1)}]
	set TAU [expr {2*$PI}]

proc easing {t} {
  variable PI
	 # easeInOutSine(t)
  expr { -(cos($PI*$t)-1)/2 }
}


proc draw {sfc RMax stopList frameCount} {
	variable TAU

	$sfc clear -style 0xFFfffbe6

	 # every N frameCount, flip changes, 0,1,0,1 .....
	set N 500
	set flip [expr {($frameCount/$N)%2}]

	set t [expr {double($frameCount%$N)/$N}]
	set t [easing $t]

	set nOfSectors [expr {[llength $stopList]-1}]

	set nOfAnnuli 6
	set dR [expr {double($RMax)/$nOfAnnuli}]
	set R [expr {$dR/2}]

	for {set i 0} {$i<$nOfAnnuli} {incr i} {
		 # when flip is 0, then inner annulus does not rotate
		 # when flip is 1, then the last annulus does not rotate
		 # - nice movement, like the mainspring of a clock that winds and unwinds
		set beta [expr {$flip ? ($TAU*$i*$t) : -($nOfAnnuli-1-$i)*$TAU*$t }]
		if {$i%2==0} {set beta [expr {$beta + $TAU/$nOfSectors}] }

		  #  draw the anulus with a rotated conical gradient
		$sfc stroke [BL::circle {0 0} $R] -width $dR \
			-style [BL::gradient CONIC [list 0 0 $beta] $stopList]
		set R [expr {$R+$dR}]
	}
}

# co_after grabbed from the package "coroutine"
proc co_after {ms} {
    after $ms [list [info coroutine]]
    yield
    return
}

proc co_animate {sfc} {
	variable TAU
	 # setting the coord-system:
	 #  * origin at center of the surface
	lassign [$sfc size] WIDTH HEIGHT
	$sfc push
	$sfc applyTransform [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGHT/2}]]

	 # prepare the stopList for a conical gradient
	set palette  {0xFFabcd5e 0xFF14976b 0xFF2b67af 0xFF62b6de 0xFFf589a3 0xFFef562f 0xFFfc8405 0xFFf9d531}

	set i 0.0
	set step [expr {1.0/[llength $palette]}]
	set stopList {}
	foreach color $palette {
		lappend stopList $i $color
		set i [expr {$i+$step}]
	}
	lappend stopList 1.0 [lindex $palette 0]

	set R [expr {$WIDTH*0.4}]
	set framecount 0
	while {1} {
		draw $sfc $R $stopList $framecount
		co_after 10
		incr framecount
	}
	$sfc pop
}

# -- main ---------------------------------------------------------------------
set sfc [image create blend2d -format {600 600}]
pack [label .x -image $sfc]

coroutine animate co_animate $sfc
