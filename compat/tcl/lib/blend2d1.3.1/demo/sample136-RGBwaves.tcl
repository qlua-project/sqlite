# sample136-RGBwaves
# see
# https://openprocessing.org/sketch/1230713

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d 1.2.1

	#
	# -- some math constants -----------------------------------------
	#
	set PI  [expr {acos(-1)}]
	set TAU [expr {2*$PI}]


proc draw {sfc t} {
	variable PI
	variable TAU

	$sfc clear

	set dBeta [expr {$TAU/60}] ;# constant
	for {set c 0} {$c<9} {incr c} {
		set hsb [list [expr {(120*$c)%360}] 1 1]
		set phase [expr {$TAU*($c+1)*$t}]

		 # compute points for a damped sinusoid  ( for x: 0..2PI -> y: -1..+1 )
		set Pts {}
		lappend Pts [list -0.1 0] ; # first fake point of the spline
		for {set x 0.0} {$x<=$TAU} {set x [expr {$x+$dBeta}]} {
 			set y [expr {sin($x-$phase) * (sin($x/2))**2}]
			lappend Pts [list $x $y]
		}
		lappend Pts [list [expr {$TAU+0.1}] 0] ; # last point of the spline
     	$sfc fill [BL::spline {*}$Pts] -style [HSB {*}$hsb] -compop DIFFERENCE
	}
}

 # co_after and co_vwait are grabbed from the package "coroutine"
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

proc co_animateWaves {sfc} {
	variable PAUSE
	variable PI
	variable TAU
	 # setting the coord-system:
	 #  * x-axis along the center of the surface
	 #  * y-axis at left
	 #  * x-scale from 0 to TAU
	 #  * y-scale from -1.2 to +1.2

	$sfc clear
	lassign [$sfc size] WIDTH HEIGHT

	$sfc push
	$sfc applyTransform [Mtx::translation 0 [expr {$HEIGHT/2}]]
	$sfc applyTransform [Mtx::scale [expr {$WIDTH/$TAU}] [expr {$HEIGHT/2.4}]]

	set framecount 1
	while {1} {
		if { $PAUSE } { co_vwait PAUSE }
		draw $sfc [expr {$framecount*$TAU/$WIDTH}]
		co_after 100
		incr framecount
	}
	$sfc pop
}

# -- main ---------------------------------------------------------------------

set sfc [image create blend2d -format {900 900}]
pack [label .x -image $sfc]

set PAUSE false
bind . <ButtonPress-1> { set PAUSE [expr {!$PAUSE}] }

coroutine animateWaves co_animateWaves $sfc
