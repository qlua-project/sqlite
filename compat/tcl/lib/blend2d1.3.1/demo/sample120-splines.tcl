# sample117 
# based on https://openprocessing.org/sketch/1934228

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

#
# -- some math functions -----------------------------------------
#
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }

	proc tcl::mathfunc::distance {P0 P1} { 
		lassign $P0 x0 y0
		lassign $P1 x1 y1
		set dx [expr {$x0-$x1}]
		set dy [expr {$y0-$y1}]
		expr {sqrt($dx*$dx+$dy*$dy)}
	}
# ----------------------------------------------------------------	

oo::class create tracer {
	variable my
	constructor {sfc} {
		set my(sfc) $sfc
		set my(pulselength) [expr {random(0.5,2)}]

		lassign [$my(sfc) size] DX DY
		 # create 4 random ControlPoints (P1,P1,P2,P3)
		set my(CPs) {}
		for {set i 0} {$i<4} {incr i} {
			set x [expr {random(0.1*$DX,0.9*$DX)}]
			set y [expr {random(0.1*$DY,0.9*$DY)}]			
			lappend my(CPs) [list $x $y]
		}

		 # a canonical Spline with 4 CP is just a cubic curve with extremities in P1 an P2 
		set my(curve) [BL::Path new]
		my _curveRebuild
	}
	
	destructor {
		$my(curve) destroy
	}

	 # rebuild my(curve)
	 #  reset my(t)
	 #  and update my(dt)
	method _curveRebuild {} {
		global G
		$my(curve) reset
		$my(curve) add [BL::spline {*}$my(CPs)]  ;# just 1 cubic ..

		 # dt should be inversely proportional to curvelength
		set my(dt) [expr {1.0/floor([my _curveLength]/$G(SPACING))}]
		# WARNING: denon could be 0 !!  -> my(dt) == Inf
		if  { $my(dt) == Inf || $my(dt) < 1e-3 || $my(dt) > 1.0 } {
			set my(dt) 1.0  ;# in this way the curve will be recomputed ..
		}
		set my(t) 0.0
		# $my(sfc) stroke $my(curve)	
	}
	
	method update {} {
		set my(t) [expr {$my(t)+$my(dt)}]
		if { $my(t) > 1.0 } {
			 # drop the first CP and add a new random CP 
			set my(CPs) [lrange $my(CPs) 1 end]

			lassign [$my(sfc) size] DX DY
			set x [expr {random(0.1*$DX,0.9*$DX)}]
			set y [expr {random(0.1*$DY,0.9*$DY)}]			
			lappend my(CPs) [list $x $y]
			
			my _curveRebuild
		} 
		my display
	}

	 # draw a square centered on my(curve) at my(t)
	 #  the square must be rotated according to the normal of the curve at my(t)
	 #  the square size varies accoding a sin() function
	 #  the square color (just its hue) varies with my(t) 
	 #  the square has a thin black border
	method display {} {
		global G		
		lassign [$my(curve) contour 0 0 normalAt $my(t)] XY normalXY
		lassign $XY x y
		lassign $normalXY nx ny

		$my(sfc) push
		 set size [expr {20*(2+sin($G(FRAMECOUNT)/20.0/$my(pulselength)))}]
		 set x [expr {$x -$size/2}]
		 set y [expr {$y -$size/2}]
		 $my(sfc) applyTransform [Mtx::rotation [expr {atan2($ny,$nx)}] radian $XY]
		 $my(sfc) fill [BL::rect $x $y $size $size] -style [HSB [expr {$my(t)*360}] 0.8 0.5]
		 $my(sfc) stroke [BL::rect $x $y $size $size]
		$my(sfc) pop
	}

	 # rough *approximation* curvelength
	 # this only works for these spline segments - Don't use it for more general cases. 
	method _curveLength {} {
		set len 0.0
		set dt [expr {1.0/8}] ;#  just evaluate 8 point
	
		set t 0.0
		set P0 [$my(curve) contour 0 0 at $t]
		for {set t $dt} {$t<1.0} {set t [expr {$t+$dt}] } {
			set P1 [$my(curve) contour 0 0 at $t]
			set len [expr {$len+distance($P0,$P1)}]
			set P0 $P1
		}
		return $len
	}
}

proc Setup {} {	
	 # --- global parameters
	global G
	set G(RUNNING)    false
	set G(FRAMECOUNT) 0
	set G(BG) [BL::color black]
	set G(SHADE) [BL::color black 0.125]
	
	 lassign [SFC size] DX DY
	set G(SPACING) 	[expr {min($DX,$DY)/100.0}]  ;# CONSTANT - spacing based on screen size

	set G(FIGURES) {}
	for {set i 0} {$i<12} {incr i} {
		lappend G(FIGURES) [tracer new SFC]
	}	
	
	SFC configure -stroke.style 0xff000000 ;# black
	SFC fill all -style $G(BG)
}

proc Draw {} {
	global G
	
	incr G(FRAMECOUNT)
	if { $G(FRAMECOUNT) % 256 == 0 } { SFC fill all -style $G(SHADE) }
	foreach obj $G(FIGURES) {
		$obj update
	}
}


proc DrawLoop {} {
	global G
	Draw
	if { $G(RUNNING) } { after 1 DrawLoop }
}

 # this is a costly operation
proc ResizeSurface {DX DY} {
	global G
	set runningState $G(RUNNING)
	set G(RUNNNG) false
	 # save the image before resizing the surface
	set tmpPhoto [image create photo]
	SFC writeToTkphoto $tmpPhoto
	SFC configure -format [list $DX $DY]
	SFC fill all -style $G(BG)
	SFC readFromTkphoto $tmpPhoto
	image delete $tmpPhoto

	set G(SPACING) 	[expr {min($DX,$DY)/100.0}]  ;# spacing based on screen size
	set G(RUNNING) $runningState
}

image create blend2d SFC -format {1000 1000}
label .cvs -image SFC
 # NO BORDERWIDTH !!  OR the ResizeSurface will go crazy !! 
.cvs configure -borderwidth 0
pack .cvs -expand 1 -fill both

bind .cvs <ButtonPress-1> { 
	set G(RUNNING) [expr { !$G(RUNNING) }]
	if { $G(RUNNING) } DrawLoop
}

Setup
set G(RUNNING) true
DrawLoop

	 # --- splash message ---
	label .top -text "Click to stop/resume the animation" -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
	bind . <ButtonPress-1> { destroy .top }
	tkwait window .top  ;#  wait for .top destruction
	bind . <ButtonPress-1> {}

bind .cvs <Configure> { ResizeSurface %w %h }
