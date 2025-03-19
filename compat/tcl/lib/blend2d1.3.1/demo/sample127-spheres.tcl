# sample127-spheres.tcl

# Spheres with shadows

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }


proc draw {sfc} {
	lassign [$sfc size] WIDTH HEIGHT

	set x [expr {random(30,$WIDTH-30)}]
	set y [expr {random(30,$HEIGHT-30)}]
	set radius [expr {random(30,120)}]

	set hue  [expr {random(0,360)}]
	set innerColor [HSB $hue 0.8 0.95]
	set outerColor [HSB $hue 1.0 0.6]
	
	set x1 [expr {$x-2*$radius/5}]
	set y1 [expr {$y-2*$radius/5}]
	
	set dx [expr {int($radius/10)}]
	set dy $dx

	$sfc filter shadow -radius 20 -dxy [list $dx $dy] {	
		$sfc fill [BL::circle [list $x $y] $radius] -style \
			[BL::gradient RADIAL [list $x $y $x1 $y1 [expr {$radius/1}]] \
				[list 0.0 $innerColor 1.0 $outerColor]]		
	}
}

# === main ===========================================
	set sfc [image create blend2d -format {1000 700}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	$sfc clear -style [BL::color white]

	 # --- splash message ---
	label .top -text "Click to start/stop" -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
	bind . <ButtonPress-1> { destroy .top }
	tkwait window .top  ;#  wait for .top destruction

	proc draw_loop {sfc} {
		global RUNNING
		draw $sfc
		if {$RUNNING} {after 200 [list draw_loop $sfc]}
	}

	set RUNNING true
	draw_loop $sfc
	
	bind . <ButtonPress-1> {
		if {$RUNNING} { 
			set RUNNING false
		} else {
			set RUNNING true
			draw_loop $sfc
		}
	}
