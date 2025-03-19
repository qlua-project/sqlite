package provide HSB 1.3

##  HSB.tcl
##
##	utilities for color processing
##		RGB <--> HSB   NOTE:  HSB == HSV
##		RGB <--> HSL
##      HSBblend
##      HSLblend
##
##
## This library is free software; you can use, modify, and redistribute it
## for any purpose, provided that existing copyright notices are retained
## in all copies and that this notice is included verbatim in any
## distributions.
##

#  HSB h s b ?a?       --> 0xAARRGGBB 
#  RGB2HSB 0xAARRGGBB  --> { h s b a }
#  HSBblend {h1 s1 b1 ?a1?} {h2 s2 b2 ?a2?} --> {h s b a}
#
#  HSL h s l ?a?       --> 0XAARRGGBB
#  RGB2HSL 0xAARRGGBB  --> { h s l a }
#  HSLblend {h1 s1 l1 ?a1?} {h2 s2 l2 ?a2?} --> {h s l a}

  # General info
  #
  #   h (hue)  is a 0.0..360.0 angle
  #   s (saturation)  is 0.0 .. 1.0
  #   b (brigthess)   is 0.0 .. 1.0  ( 0 is black, 1 is white )
  #
  #  alpha is 0.0 .. 1.0  

namespace eval HSx {
	namespace export \
			HSB RGB2HSB HSBblend\
			HSL RGB2HSL HSLblend


	# hue:  any angle in degrees (internally normalized to 0.0..360)
	# sat:  0.0 .. 1.0
	# brigthness: 0.0 .. 1.0
	#
	# returns:
	#   a 32bit ARGB color as 0xAARRGGBB

	proc HSB {hue sat val {alpha 1.0}} {
		set alpha [expr {round($alpha*255.0)}]
		set v [expr {round(255.0*$val)}]
		if {$sat == 0.0} {
			return [expr {$alpha<<24 | $v<<16 | $v<<8 | $v}]
		}
		while { $hue < 0 } {
			set hue [expr {$hue+360.0}]
		}
		set hue [expr {fmod($hue,360.0)}]
		set hueSector [expr {$hue/60.0}]    ;# result is 0.0...5.999
		set i [expr {int($hueSector)}]
		set f [expr {$hueSector-$i}]
		set p [expr {round(255.0*$val*(1 - $sat))}]
		set q [expr {round(255.0*$val*(1 - ($sat*$f)))}]
		set t [expr {round(255.0*$val*(1 - ($sat*(1 - $f))))}]
		switch $i {
		  0 {return [expr {$alpha<<24 | $v<<16 | $t<<8 | $p}]}
		  1 {return [expr {$alpha<<24 | $q<<16 | $v<<8 | $p}]}
		  2 {return [expr {$alpha<<24 | $p<<16 | $v<<8 | $t}]}
		  3 {return [expr {$alpha<<24 | $p<<16 | $q<<8 | $v}]}
		  4 {return [expr {$alpha<<24 | $t<<16 | $p<<8 | $v}]}
		  5 {return [expr {$alpha<<24 | $v<<16 | $p<<8 | $q}]}
		}
	}

	# input is
	#    a 32bit ARGB color as 0xAARRGGBB
	#
	# returns a list { hue sat brightness alpha }
	#   hue: 0.0 .. 360.0
	#   sat: 0.0 .. 1.0
	#   brightness: 0.0 .. 1.0
	#   alpha: 0.0 .. 1.0
	proc RGB2HSB { aarrggbb } {
		set alpha [expr {$aarrggbb>>24 & 0xFF}]
		set red   [expr {$aarrggbb>>16 & 0xFF}]
		set green [expr {$aarrggbb>>8  & 0xFF}]
		set blue  [expr {$aarrggbb     & 0xFF}]

		if {$red > $green} {
			set max $red
			set min $green
		} else {
			set max $green
			set min $red
		}
		if {$blue > $max} {
			set max $blue
		} else {
			if {$blue < $min} {
				set min $blue
			}
		}
		set range [expr {double($max-$min)}]
		if {$max == 0.0} {
			set sat 0.0
		} else {
			set sat [expr {$range/$max}]
		}
		if {$sat == 0.0} {
			set hue 0.0
		} else {
			set rc [expr {($max - $red)/$range}]
			set gc [expr {($max - $green)/$range}]
			set bc [expr {($max - $blue)/$range}]
			if {$red == $max} {
				set hue [expr {60.0*($bc - $gc)}]
			} else {
				if {$green == $max} {
					set hue [expr {60*(2 + $rc - $bc)}]
				} else {
					set hue [expr {.166667*(4 + $gc - $rc)}]
				}
			}
			if {$hue < 0.0} {
				set hue [expr {$hue + 360.0}]
			}
		}
		return [list $hue $sat [expr {$max/255.0}] [expr {$alpha/255.0}]]
	}

	 # --- Color interpolation in HSB color space

	 # h is a float number .. should be normalized in 0..360
	 #    normalize 90 --> 90.0
	 #    normalize 721.1 -> 1.1
	 #    normalize -90 -> 270.0
	 #    normalize -721.1 -> 358.9
	proc normalize360 {h} {
		set h [expr {fmod($h,360)}]
		while { $h < 0 } {
			set h [expr {fmod($h+360,360)}]
		}
		return $h
	}

	proc clamp {v a b} { expr {$v<$a ? $a : ($v<$b ? $v :$b)} }
	proc lerp {x0 x1 t} { expr {$x0+($x1-$x0)*$t} }

	 # t must be [0...1]
	proc lerpHue { h1 h2 t } {
		set h1 [normalize360 $h1]
		set h2 [normalize360 $h2]
		# NOTE: Calculate the shortest arc between h1 and h2
		set delta_h [expr {$h2 - $h1}]
		if {$delta_h > 180} {
			set delta_h [expr {$delta_h - 360}]
		} elseif {$delta_h < -180} {
			set delta_h [expr {$delta_h + 360}]
		}
		set h [expr {$h1 + $t * $delta_h}]
		set h [normalize360 $h]
		return $h
	}

	proc HSBblend {hsb1 hsb2 t} {
		set hsb {}
		set t [clamp $t 0 1]
		lassign $hsb1 h1 s1 b1 a1
		if {$a1 ==""} { set a1 1.0 }
		lassign $hsb2 h2 s2 b2 a2
		if {$a2 ==""} { set a2 1.0 }
		return [list [lerpHue $h1 $h2 $t] [lerp $s1 $s2 $t] [lerp $b1 $b2 $t] [lerp $a1 $a2 $t]]
	}


	# --- HSL -----------------------------------------------------------------

	proc HSL {h s l {alpha 1.0}} {
		set v [expr {$l+$s*min($l,1-$l)}]
		set sat [expr {$v==0 ? 0.0 : 2*(1-$l/$v)}]
		HSB $h $sat $v $alpha
	}

	# input is
	#    a 32bit ARGB color as 0xAARRGGBB
	#
	# returns a list { hue sat lightness alpha }
	#   hue: 0.0 .. 360.0
	#   sat: 0.0 .. 1.0
	#   lightness: 0.0 .. 1.0
	#   alpha: 0.0 .. 1.0
	proc RGB2HSL { aarrggbb } {
		lassign [RGB2HSB $aarrggbb] hue sat val alpha
		set l [expr {$val*(1-$sat/2.0)}]
		set satL [expr {($l==0.0 || $l ==1.0) ? 0.0 : ($val-$l)/min($l,1-$l)}]
		return [list $hue $satL $l $alpha]
	}

	proc HSLblend {hsl1 hsl2 t} {
		tailcall HSBblend $hsl1 $hsl2 $t
	}
}

namespace import HSx::*
