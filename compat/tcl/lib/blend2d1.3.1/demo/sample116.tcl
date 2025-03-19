 # demo
 
set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d
package require snit

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::clamp {v a b} { expr {$v<$a ? $a : ($v<$b ? $v :$b)} }
	
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }
	
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }

	proc tcl::mathfunc::random_item {items} { lindex $items [expr {int(rand()*[llength $items])}] }

	set PI [expr {acos(-1.0)}]


     # a PulseTrain is an ordered sequence of 0..N of pulses
     # that will be interpolated on rendering.
     #  PulseTrain { (x0,y0 (x1,y1) .. (xN,Yn) }
     #  -velocity can be negative (--> PulseTrain goes from right to left)
     #  INVARIANTS:
     #   0.0 <= x(i) < x(i+1) <= 1.0
     #   -amplitude <= yi <= +amplitude
snit::type PulseTrain {
	variable my
	option -amplitude  1.0   ;# coefficent
	option -velocity   1.0   ;#coeffiient
	option -peakdistance 0.25  ;# coefficient: distance between two peaks
	
	constructor {args} {		
		set my(width) 1.0  ;# fixed
		set my(pulseSign) +1  ;# sign of the last pulse
		
		$self configurelist $args
		set my(peaks) {}
	}

	method shift {dt} {
		set dt [expr {$options(-velocity)*$dt}]
		set newPeaks {}
		foreach P $my(peaks) {
			lassign $P x y
			set x [expr {$x+$dt}]
			if { 0.0 <= $x && $x <= 1.0 } {
				lappend newPeaks [list $x $y]
			}
		}

		if { $options(-velocity) > 0 } {
			 # add a new peak at left, if needed
			if { $newPeaks == {} || [lindex $newPeaks 0 0] > $options(-peakdistance) } {
				#choose a random position near 0.0 with a 20% random variation
				set x [expr {random(0.0,0.2*$options(-peakdistance))}]
				set y [expr {$my(pulseSign)*$options(-amplitude)*random(0.3,1.0)}]
				set my(pulseSign) [expr {-$my(pulseSign)}]

				set newPeaks [linsert $newPeaks 0 [list $x $y]]
			}
		} else {
			 # add a new peak at right, if needed
			if { $newPeaks == {} || (1.0-[lindex $newPeaks end 0]) > $options(-peakdistance) } {
				#choose a random position near 1.0 with a 20% random variation
				set x [expr {1-0-random(0.0,0.2*$options(-peakdistance))}]
				set y [expr {$my(pulseSign)*$options(-amplitude)*random(0.3,1.0)}]
				set my(pulseSign) [expr {-$my(pulseSign)}]

				lappend newPeaks [list $x $y]
			}
		}		 
		set my(peaks) $newPeaks
		return $my(peaks)
	}

	method peaks { {points {}} } {
		if {$points== {} } { 
			return $my(peaks) 
		}
		set my(peaks) $points
	}	
}

snit::type Wave {
	variable my
	component my_train

	delegate option * to my_train

    constructor {args} {
		set my(colors) [randomColors]
        set my_train [PulseTrain %AUTO%]
		set my(blPath) {}		
		$self configurelist $args		
	}

	destructor {
		if { $my(blPath) != {} } { $my(blPath) destroy }
		$my_train destroy
	}


	proc randomColors {} {
		set colors  {#ff0000 #ff8700 #ffd300 #deff0a #a1ff0a
					#0aff99 #0aefff #147df5 #580aff #be0aff}
		
		set n 4
		set n [expr {2*$n-1}]
	
		set darkbg  "#2a1039"
		set stripecolors {}
		for {set i 0} {$i<$n} {incr i} {
			if {$i % 2 == 0} {
				lappend stripecolors [expr {random_item($colors)}]
			} else {
				lappend stripecolors $darkbg
			}
		}
		return $stripecolors
	}

	 # the PulseTrain peaks near x=0 and x=1 should be smoothed to 0 
	proc smoothExtremities {points} {
		set newpoints {}
		foreach P $points {
			lassign $P x y			
			 # this is an inverse parabolic with roots at x=0 and x=1.0
			# set c [expr {-4.0*($x)*($x-1.0)}]
			 # more stretched
			set c [expr {-64*(($x)*($x-1.0))**3}]
			 
			lappend newpoints [list $x [expr {$c*$y}]]		
		}
		return $newpoints
	}

	method shift {dx} {
		$my_train shift $dx
		 # invalidate blPath
		if { $my(blPath) != {} } { $my(blPath) destroy }
		set my(blPath) {}
	}
	
	method _getNormalizedPath {} {
		if { $my(blPath) != {} } {
			return $my(blPath)
		}		
		set my(blPath) [BL::Path new]
		set controlPoints [smoothExtremities [$my_train peaks]]		

		set controlPoints [linsert $controlPoints 0  {0.0 0.0}]
		lappend controlPoints {1.0 0.0} 

		$my(blPath) add [BL::spline extend {*}$controlPoints]
		return $my(blPath)
	}
	
	 #draw the PulseTrain on a blend2d surface (sfc)
	 # NOTE: you must set a scaling/translation matrix, since a PulseTrain 
	 # is always mapped in the x-interval 0..1 and the y-interval 0..Amplitude
	method draw {sfc DX DY hasShadow} {
		set blPath [[$self _getNormalizedPath] dup]
		 # stretch blPath
		$blPath apply [Mtx::scale $DX $DY]
		
		set N [expr {2*[llength $my(colors)]-1}]  ;# number of stripes
		set singleThickness [expr {$DY/$N}]

		set thickness $DY
		
		$sfc push
		$sfc configure -stroke.transformorder AFTER  ;# default ..
		
		set filterType "shadow"
		if { ! $hasShadow } { set filterType "ignore" }
		$sfc filter $filterType -radius 20 -dxy {4 -10}   {
			foreach color $my(colors) {
				$sfc stroke $blPath -width $thickness -style [BL::color $color]
				set thickness [expr {$thickness-2*$singleThickness}]		
			}
		}
		
		$sfc pop		
		$blPath destroy
	}	
}


set WIDTH 600
set HEIGHT 1000
set sfc [image create blend2d -format [list $WIDTH $HEIGHT]]
label .x -image $sfc ; pack .x

set Waves {}
for {set i 0} {$i < 5} {incr i} {
	set wave [Wave %AUTO%]
	$wave configure \
		-amplitude [expr {random(0,1.5)}] \
		-velocity  [expr {random(-1,1)}] \
		-peakdistance [expr {random(0.15,1.0)}]
	lappend Waves $wave
}

 # create a control panel
 # ------------------------
toplevel .z
	wm attributes .z -topmost true
	wm title .z "Mixer"
	label .z.text_a -text "Amp"
	label .z.text_v -text "Vel"
	label .z.text_f -text "Freq"
	
	grid configure x .z.text_a .z.text_v .z.text_f
	set i 1
	foreach wave $Waves {
		grid configure [label .z.w${i}-title -text "Wave $i"] -row $i -column 0
		ttk::scale .z.w${i}-amplitude -orient vertical -from 3.0 -to 0.0
		grid configure .z.w${i}-amplitude -row $i -column 1
		ttk::scale .z.w${i}-velocity  -orient vertical -from +2.0 -to -2.0
		grid configure .z.w${i}-velocity -row $i -column 2
		ttk::scale .z.w${i}-peakdistance  -orient vertical -from 0.1 -to +1.0
		grid configure .z.w${i}-peakdistance -row $i -column 3
	
		grid rowconfigure .z $i -pad 20
		incr i
	}
	for {set i 0} {$i<3} {incr i} {
		grid columnconfigure .z $i -pad 20
		incr i
	}

	set i 1
	foreach wave $Waves {
		foreach opt {-amplitude -velocity -peakdistance} {
			.z.w${i}${opt} set [$wave cget $opt]
			.z.w${i}${opt} configure -command [list $wave configure $opt]	
		}
		incr i
	}

	set ::HASSHADOW true
	ttk::checkbutton .z.shadow -variable ::HASSHADOW -text "shadow" \
		-onvalue true -offvalue false
	set ::RUN false
	ttk::checkbutton .z.run -variable ::RUN -text "Run" -command "DRAWLOOP $sfc" \
		-onvalue true -offvalue false
	
	grid x .z.shadow
	grid x .z.run


 
 #======================================== 

proc DrawRibbons {sfc} {
	global WIDTH
	global HEIGHT
	global Waves
	global HASSHADOW
	
	$sfc push
	$sfc clear -style 0xffffffff
	set margin 100

	set N [llength $Waves]
	set H [expr {double($HEIGHT)/$N}]
	set W [expr {$WIDTH+2*$margin}]

	set i 1
	foreach wave $Waves {
		$sfc configure -matrix [Mtx::translation -$margin [expr {$i*$H-$H/2}]]
		$wave draw $sfc  $W $H $HASSHADOW	
		incr i
	}
	$sfc pop
}

proc DRAWLOOP {sfc} {
	global RUN
	global HASSHADOW
	global WIDTH
	global Waves
	
	if { ! $RUN } return

	set step [expr {3.0/$WIDTH}] ; # 3 pixel every step
	foreach wave $Waves {
		$wave shift $step
	}
	DrawRibbons $sfc
	 # to do; find a better way to control the animation speed
	set delay [expr {$HASSHADOW ? "10" : "50" }]
	after $delay DRAWLOOP $sfc
}


DrawRibbons $sfc 

update
 # this is very slow
bind .x <Configure> {
	set WIDTH %w
	set HEIGHT %h 
	[%W cget -image] configure -format [list $WIDTH $HEIGHT]
	DrawRibbons $sfc
}
