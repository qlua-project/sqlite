# sample140B-annuli
#  variation a sample140
#
#  Instead of painting annuli with a rainbow gradient,
#  they are painted with an image
#

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


proc draw {sfc RMax pattern t flip} {
	$sfc clear

	set t [easing $t]

	set nOfAnnuli 6
	set dR [expr {double($RMax)/$nOfAnnuli}]
	set R [expr {$dR/2}]

	 # center of pattern image
	lassign [$pattern size] w h
	set cx [expr {$w/2.0}]
	set cy [expr {$h/2.0}]

	for {set i 0} {$i<$nOfAnnuli} {incr i} {
		 # when flip is 0, then inner annulus does not rotate
		 # when flip is 1, then the last annulus does not rotate
		 # - nice movement, like the mainspring of a clock that winds and unwinds
		set beta [expr {$flip ? (360*$i*$t) : -($nOfAnnuli-1-$i)*360*$t }]

		$sfc push
		# make sthe stroke width 2 pixel larger, so that annuli borders will overlay
		$sfc applyTransform [Mtx::rotation $beta degrees]
		$sfc stroke [BL::circle {0 0} $R] -width [expr {$dR-2}] \
			-style [BL::pattern $pattern -matrix [Mtx::translation $cx $cy]]
		$sfc pop
		set R [expr {$R+$dR}]
	}
}

# co_after grabbed from the package "coroutine"
proc co_after {ms} {
    after $ms [list [info coroutine]]
    yield
    return
}

proc co_animate {sfc patternSfc} {
	variable TAU
	 # setting the coord-system:
	 #  * origin at center of the surface
	lassign [$sfc size] WIDTH HEIGHT
	$sfc push
	$sfc applyTransform [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGHT/2}]]

	set R [expr {$WIDTH*0.48}]
	set framecount [expr {int(rand()*500)}] ; # start with a random framecount
	set flip 0
     # every N frameCount, flip changes, 0,1,0,1 .....
	set N 500
	while {1} {
		set t [expr {double($framecount)/$N}]

		draw $sfc $R $patternSfc $t $flip
		co_after 10
		incr framecount

		if {$framecount >= $N} {
			set framecount 0
			set flip [expr {!$flip}]
			co_after 500  ;# pause 500 ms
		}
	}
	$sfc pop
}

# -- main ---------------------------------------------------------------------

# ----------------------------------------------
set patternFile [file join $thisDir johnny.jpg]
# ----------------------------------------------

set patternSfc [BL::Surface new]
$patternSfc load $patternFile
 # patternfile should be square, so let's take the min(width,height)
lassign [$patternSfc size] width height
set size [expr {min($width,$height)}]

set sfc [image create blend2d -format [list $size $size]]
pack [label .x -image $sfc]

coroutine animate co_animate $sfc $patternSfc
