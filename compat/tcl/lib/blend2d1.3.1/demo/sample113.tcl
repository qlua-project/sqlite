#  
#  Blobs as close splines with perlin-noise variations

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

set auto_path [linsert $auto_path 0 [file join $thisDir lib]]
tcl::tm::path add [file join $thisDir lib]

package require perlin
package require Blend2d

	#
	# -- some math functions -----------------------------------------
	#

	set ::PI [expr {acos(-1.0)}]

	namespace eval tcl::mathfunc {	
		proc random {a b} { expr {rand()*($b-$a)+$a} }	
		 # Since noise (openprocessing) returns [0,1] and perlin() returns [-1,1]
		 # we need to scale ..
		proc noise {x y z} { expr { ([perlin $x $y $z]+1)/2.0 } }
	}

proc Draw {sfc k r0 dr n} {
	global T
	set dt 0.006
	for {set i 0} {$i<$n} {incr i} {
	
		drawblob $sfc $r0 $dr $k $T
		set T [expr {$T+$dt}]
		
		set r0 [expr {$r0+0.15}]
		set dr [expr {$dr+0.001}]
		set k [expr {$k+0.001}]
		update
	}
}

proc drawblob {sfc radius dr k t} {
	set blob [makeBlobPath $radius $dr $k $t]
	$sfc stroke $blob
	$blob destroy
}


 # create a blob (Path) centered at (0,0)
 
 # this blob starts with a circle centered at (0.0) and radius r0
 # then each point on the circumference (at a regular angular distance dTheta)
 # is pushed outside at a "random" radial distance"
 # * be careful this radial distance must be:
 #   increasing with the radius r0 ( ? linear quadratic ?)
 #   not too big , not too small
 #  The trick is that two blobs of radius r0 and (r0+dr)
 #  should cross  sometimes ..
 
 # ? what about dr ?  linear or quadratic ? 
proc makeBlobPath {r0 dr k t} {
	global PI

	set controlPoints {}	
	set dTheta [expr {2*$PI/60}]
	for {set theta 0.0}  {$theta<2*$PI} {set theta [expr {$theta+$dTheta}]} {
		set cosTheta [expr {cos($theta)}]
		set sinTheta [expr {sin($theta)}]
		
		set r [expr {$r0+$dr*noise($k*$cosTheta, $k*$sinTheta, $t)}]
		set x [expr {$r * $cosTheta}]
		set y [expr {$r * $sinTheta}]
		lappend controlPoints [list $x $y]
	}
	set blob [BL::Path new]	
	$blob add [BL::spline close {*}$controlPoints]
	return $blob
}

# ---  main -----

set WIDTH 600
set HEIGHT $WIDTH

wm title . "TclTk binding for Blend2d - demo 113"
set sfc [image create blend2d -format [list $HEIGHT $WIDTH]]
label .sfc -image $sfc ; pack .sfc
	
 # place the origin at the center of the surface
$sfc configure -matrix [Mtx::translation [expr {$WIDTH/2.0}] [expr {$HEIGHT/2.0}]]

set N 1000 ;# number of blobs

$sfc clear -style [BL::color white]
$sfc configure -stroke.style [BL::color black 0.1]
set k 0.3  ;#
set r0 50
set dr 150 
set T [expr {random(0.0,100.0)}]
Draw $sfc $k $r0 $dr $N
