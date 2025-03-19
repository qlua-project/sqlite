#
#  logarithmic spiral
#  - approximated with a spline

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

set PI [expr {acos(-1)}]


 # spiral ::
 # theta0:  starting angle  (usually 0.0)
 # theta1:  final angle     (usually N*PI)
 # dtheta:  theta increment (usually from PI/2 (bad/funny).. PI/4 (almost perfect)
 # phi   :  phase           (0<=phi<<2*PI)
 #
 #  Logarithmic spiral:  for theta : theta0 .. theta1
 #   r = a**(b*(theta+phi))
 #
 #  return a list of points that should be be interpolated with a spline)
 #  Center of the spiral is at (0,0)
 #
proc spiral {theta0 theta1 dtheta phi} {
	set a 1.2
	set b 0.8
	set Points [list]
	for {set theta $theta0} {$theta<$theta1} {set theta [expr {$theta+$dtheta}] } {
		set r [expr {$a**($b*($theta+$phi))}]
		set x [expr {$r*cos($theta)}]
		set y [expr {$r*sin($theta)}]
		lappend Points [list $x $y]
	}
	return $Points
}

# co_after grabbed from the package "coroutine"
proc co_after {ms} {
    after $ms [list [info coroutine]]
    yield
    return
}


proc co_vwait {varname} {
    upvar 1 $varname var
	set callback [list apply { {coroName args} { $coroName ; return } } [info coroutine]]
    trace add    variable var write $callback
    yield
    trace remove variable var write $callback
    ::after idle [list [info coroutine]]
    yield
    return
}


# -- main ----
set sfc [image create blend2d -format {900 900}]
pack [label .x -image $sfc]

$sfc clear

set N 15 ;# number of 'rounds/2'
set points []
lappend points {*}[spiral 0 [expr {$N*$PI}] [expr {$PI/5}] 0]
 # then compute points for another spiral with a phase of PI;
 # this points should be 'reversed' and then attached tho the points of the first spiral
lappend points {*}[lreverse [spiral 0 [expr {$N*$PI}] [expr {$PI/5}] $PI]]

# direct draw:
# interpolate these points with a closed spline ..
# $sfc fill [BL::spline close {*}$points] -style [BL::color lightgreen]

# but, it's better to put the spline in a BL::Path, and then animate it ...
BL::Path create SpiralPath
SpiralPath add [BL::spline close {*}$points]


set PAUSE false
bind . <ButtonPress-1> { set PAUSE [expr {!$PAUSE}] }


proc co_animate {sfc spiralPath} {
	variable PAUSE false

	 # setting the coord-system:
	 #  * origin at center of the surface
	lassign [$sfc size] WIDTH HEIGHT
	$sfc push
	$sfc applyTransform [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGHT/2}]]

	$sfc configure -fill.style [BL::color gray80]

	set rot 17 ; # degrees
	while {1} {
		if { $PAUSE } { co_vwait PAUSE ; set rot [expr {-$rot}] }
		$sfc applyTransform [Mtx::rotation $rot degrees]
		$sfc clear -compop CLEAR
		$sfc fill $spiralPath

		 # bonus: apply a vignette-like shade
		$sfc fill all \
			-compop DARKEN \
			-style [BL::gradient RADIAL [list 0 0 0 0 [expr {$WIDTH/2}]] {0.0 0x90ffffff   1.0 0x80000000 }]

		co_after 70
	}
	$sfc pop
}

coroutine animate co_animate $sfc SpiralPath
