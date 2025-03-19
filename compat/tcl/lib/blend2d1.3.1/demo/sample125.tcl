# TclTk porting from
#   https://openprocessing.org/sketch/1995082

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }
	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::clamp {v a b} { expr {$v<$a ? $a : ($v<$b ? $v :$b)} }
	
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }
	
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }

	proc tcl::mathfunc::random_item {items} { lindex $items [expr {int(rand()*[llength $items])}] }

	proc tcl::mathfunc::norm {x x0 x1} { expr {($x-$x0)/double($x1-$x0)} }

	proc tcl::mathfunc::lerp {x0 x1 t} { expr {$x0+($x1-$x0)*$t} }


   # create a matrix of objs
proc setup {sfc} {
	lassign [$sfc size] WIDTH HEIGHT
	set c 8
	set w [expr {$WIDTH/$c}]
	set objs {}
	for {set i 0} {$i<$c} {incr i} {
		for {set j 0} {$j<$c} {incr j} {
			set x [expr {$i*$w+$w/2.0}]
			set y [expr {$j*$w+$w/2.0}]
			lappend objs [OBJ new $x $y $w]
		}
	}	
	return $objs
}

proc draw {sfc objs} {
	$sfc clear -style 0xff000000
	foreach obj $objs {
		$obj run $sfc
	}
}

proc easeInOutExpo {x} {
	expr { 
	($x == 0.0) 
		? 0.0
		: ($x == 1.0)
			? 1.0
			: ($x < 0.5) 
				? 2**(20 * $x - 10) / 2
				: (2 - 2**(-20 * $x + 10)) / 2
		}
}

proc shuffle {L} {
    set n [llength $L]
    while {$n>0} {
        set j [expr {int($n * rand())}]
        set tmp [lindex $L $j]
        lset L $j [lindex $L [incr n -1]]
        lset L $n $tmp
    }
    return $L
}

oo::class create OBJ {
	variable my ;# --array
	constructor {x y w} {
		set my(x) $x
		set my(y) $y
		set my(w) $w

		set my(cx) $x
		set my(cy) $y		

		set my(pdrc) 0
		my init

		set colors {0xff235789 0xffc1292e 0xfff1d302 0xffffffff 0xffd67ab1 0xffff8c42 0xff81c14b 0xff2e933c 0xffe4572e 0xff17bebb}
		set my(colors) [lrange [shuffle $colors] 0 3]
		set my(t1) 50
	}

	method show {sfc} {	
		set xx  [expr {$my(x)-$my(w)/2.0}]
		set yy  [expr {$my(y)-$my(w)/2.0}]
		set ww  [expr {$my(cx)-$xx}]
		set hh  [expr {$my(cy)-$yy}]
		set off [expr {$my(w)*0.1}]

		set dx [expr {$ww-$off}]
		set dy [expr {$hh-$off}]
		set crr [expr {min($dx,$dy)/2}]
		$sfc fill [BL::roundrect [expr {$xx+$off/2}] [expr {$yy+$off/2}] $dx $dy $crr] \
			-style [lindex $my(colors) 0]
			
		set dx [expr {$my(w)-$ww-$off}]
		set crr [expr {min($dx,$dy)/2}]						
		$sfc fill [BL::roundrect [expr {$xx+$ww+$off/2}] [expr {$yy+$off/2}] $dx $dy $crr] \
			-style [lindex $my(colors) 1]
		set dy [expr {$my(w)-$hh-$off}]	
		set crr [expr {min($dx,$dy)/2}]						
		$sfc fill [BL::roundrect [expr {$my(cx)+$off/2}] [expr {$my(cy)+$off/2}] $dx $dy  $crr] \
			-style [lindex $my(colors) 2]
		set dx [expr {$ww-$off}]
		set crr [expr {min($dx,$dy)/2}]									
		$sfc fill [BL::roundrect [expr {$xx+$off/2}] [expr {$yy+$hh+$off/2}] $dx $dy $crr] \
			-style [lindex $my(colors) 3]
	}

	method move {} {
		if {0 < $my(t) &&  $my(t) < $my(t1)} {
			set v [expr {double($my(t))/$my(t1)}]
			set v [easeInOutExpo $v]
			set my(cx) [expr {lerp($my(cx0),$my(cx1), $v)}]
			set my(cy) [expr {lerp($my(cy0),$my(cy1), $v)}]
		}
		if {$my(t) > $my(t1)} { my init }
		incr my(t)
	}

	method init {} {
		set drc [expr {int(rand()*5)}]
		while {$drc == $my(pdrc)} {
			set drc [expr {int(rand()*5)}]
		} 
		set d [expr {$my(w)*random(0.4, 0.75)}]

		set my(pdrc) $drc
		if {$drc == 0} {
			set my(cx1) [expr { $my(x)+($my(w)/2-$d/2) }]
			set my(cy1) [expr { $my(y)+($my(w)/2-$d/2) }]
		} elseif {$drc == 1} {
			set my(cx1) [expr { $my(x)-($my(w)/2-$d/2) }]
			set my(cy1) [expr { $my(y)+($my(w)/2-$d/2) }]
		} elseif {$drc == 2} {
			set my(cx1) [expr { $my(x)+($my(w)/2-$d/2) }]
			set my(cy1) [expr { $my(y)-($my(w)/2-$d/2) }]
		} elseif {$drc == 3} {
			set my(cx1) [expr { $my(x)-($my(w)/2-$d/2) }]
			set my(cy1) [expr { $my(y)-($my(w)/2-$d/2) }]
		} elseif {$drc == 4} {
			set my(cx1) $my(x)
			set my(cy1) $my(y)
		}
		set my(cx0) $my(cx)
		set my(cy0) $my(cy)
		set my(t) 0
	}

	method run {sfc} {
		my show $sfc
		my move
	}
}

# ==== main =====
package require Blend2d

set sfc [image create blend2d -format {900 900}]
pack [label .cvs -image $sfc]

proc draw_loop {sfc objs} {
	draw $sfc $objs
	after 10 [list draw_loop $sfc $objs]
}

set objs [setup $sfc]
draw_loop $sfc $objs
