# blur experiment
# based on https://openprocessing.org/sketch/1631540

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

set auto_path [linsert $auto_path 0 [file join $thisDir lib]]
tcl::tm::path add [file join $thisDir lib]

package require Blend2d
package require perlin

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::clamp {v a b} { expr {$v<$a ? $a : ($v<$b ? $v :$b)} }
	
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }
	
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }

	proc tcl::mathfunc::random_item {items} { lindex $items [expr {int(rand()*[llength $items])}] }

	 # NOTE. perlin return (-1,+1) ; classic noise returns (0,1)
	proc tcl::mathfunc::noise {x y z} { perlin $x $y $z }

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


# ------------------------
set colorSchemes {}
lappend colorSchemes {#F27EA9 #366CD9 #5EADF2 #636E73 #F2E6D8} ;# Benedictus
lappend colorSchemes {#D962AF #58A6A6 #8AA66F #F29F05 #F26D6D} ;# Cross
lappend colorSchemes {#222940 #D98E04 #F2A950 #BF3E21 #F2F2F2} ;# Demuth
lappend colorSchemes {#1B618C #55CCD9 #F2BC57 #F2DAAC #F24949} ;# Hiroshige
lappend colorSchemes {#074A59 #F2C166 #F28241 #F26B5E #F2F2F2} ;# Hokusai
lappend colorSchemes {#023059 #459DBF #87BF60 #D9D16A #F2F2F2} ;# Hokusai Blue
lappend colorSchemes {#632973 #02734A #F25C05 #F29188 #F2E0DF} ;# Java
lappend colorSchemes {#8D95A6 #0A7360 #F28705 #D98825 #F2F2F2} ;# Kandinsky
lappend colorSchemes {#4146A6 #063573 #5EC8F2 #8C4E03 #D98A29} ;# Monet
lappend colorSchemes {#034AA6 #72B6F2 #73BFB1 #F2A30F #F26F63} ;# Nizami
lappend colorSchemes {#303E8C #F2AE2E #F28705 #D91414 #F2F2F2} ;# Renoir
lappend colorSchemes {#424D8C #84A9BF #C1D9CE #F2B705 #F25C05} ;# VanGogh
lappend colorSchemes {#D9D7D8 #3B5159 #5D848C #7CA2A6 #262321} ;# Mono
lappend colorSchemes {#906FA6 #025951 #252625 #D99191 #F2F2F2} ;# RiverSide
# ------------------------

proc Setup {} {	
	 # --- global parameters
	global G

	set G(FRAMECOUNT) 0
	set G(HEIGHT) 300
	set G(WIDTH)  800

#	set G(colorScheme) [expr {random_item($::colorSchemes)}]
	set G(colorScheme) [lindex $::colorSchemes 3]

	set G(xStep) 150.0 
	set G(yStep) [expr {$G(HEIGHT)/20.0}]  ;# 20 : nOf waves

	set G(RUNNING)    false
}

 # this is a costly operation
proc ResizeSurface {DX DY} {
	global G

	set G(HEIGHT) $DY
	set G(WIDTH)  $DX
	set G(xStep)  150.0
	set G(yStep)  [expr {$DY/20}]	
	
	SFC configure -format [list $DX $DY]
}

proc drawWave {sfc y0 colors} {
	global G

	# -- gradient
	lassign [shuffle $colors] color0 color1 color2
	set x [expr {map(noise(0,$y0, $G(FRAMECOUNT)/300.0), -1.0, +1.0, 0.0, 1.0)}]
	if { rand() > 0.5 } {
		set gradient [BL::gradient LINEAR \
			[list 0.0 [expr {-$G(yStep)*2}] $G(WIDTH) [expr {$G(yStep)*2}]] \
			[list 0.0 [BL::color $color0]  $x [BL::color $color1]  1.0 [BL::color $color2]] \
		 ]
	} else {
		set gradient [BL::gradient LINEAR \
			[list $G(WIDTH) [expr {-2*$G(yStep)}] 0.0 [expr {2*$G(yStep)}]] \
			[list 0.0 [BL::color $color0]  $x [BL::color $color1]  1.0 [BL::color $color2]] \
		]
	}
		 	
	$sfc push
	$sfc configure -matrix [Mtx::translation 0.0 $y0]
	$sfc configure -fill.style $gradient  ;#  even the gradient is translated
	set cPoints {}
	for { set x -$G(xStep) } { $x < $G(WIDTH)+$G(xStep)} { set x [expr {$x+$G(xStep)}] } {
		 # warning: if noise(x,y,z) has all 3 parameters integers, then result is 0.
		 #  for this reason, add something (0.2) to one corrd.
		set y [expr {noise($x+0.2,$y0,$G(FRAMECOUNT)/20.0)*$G(yStep)*4}]  
		 # the height of the wave should depend on the distance y0 ..
		 # distant waves (y0 small) should be smaller
		set y [expr {$y*$y0/$G(HEIGHT)}]
		lappend cPoints [list $x $y]
	}
	set gSpline [BL::Path new]	
	$gSpline add [BL::spline extend {*}$cPoints]	
	 # gSpline is an open spline ; .. now we should close it ..
	set bbox [$gSpline bbox]
	lassign $bbox x0 _ x1 y
	set y [expr {$y+$G(yStep)}]
	$gSpline lineTo [list $x1 $y] [list $x0 $y]
	$gSpline close
	
	$sfc fill $gSpline
	#$sfc stroke $gSpline
		
	$sfc pop		
	$gSpline destroy
}

proc Draw {} {
	global G

	incr G(FRAMECOUNT)	
	expr srand(0)  ;  # !! restart the random numbers at each frame
	for {set y -$G(yStep)} {$y<$G(HEIGHT)+$G(yStep)} {set y [expr {$y+$G(yStep)/2}]} {
		 # -- blur based on depth field ...
		 #    waves at 3/5 of field at 'at focus' (r=0)
		 #    closer or distant waves more blurred
		 
		 # blur radius r varies from 0 to 30
		 #  if r<=2  -->  r = 1  (no blur)
		set r [expr {map(abs($y-($G(HEIGHT)*3)/5), 0.0,$G(HEIGHT)/2+$G(yStep), 0, 30)}]
		set r [expr {int($r)}]
		if { $r <= 2 } { set r 1 }
		SFC filter blur -radius $r {
			drawWave SFC $y $G(colorScheme)
		}
	}
}

proc DrawLoop {} {
	global G
	Draw
	if { $G(RUNNING) } { after 1 DrawLoop }
}

Setup

image create blend2d SFC -format [list $G(WIDTH) $G(HEIGHT)]
label .cvs -image SFC -borderwidth 0
 # NO BORDERWIDTH !!  OR the ResizeSurface will go crazy !! 
pack .cvs -expand 1 -fill both

set G(RUNNING) true
DrawLoop

	 # --- splash message ---
	set msg "Click to stop/resume the animation.\nYou can resize the window (but the animation slows down a lot)"
	label .top -text $msg -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
	bind . <ButtonPress-1> { destroy .top }
	tkwait window .top  ;#  wait for .top destruction
	bind . <ButtonPress-1> {}
	

	
bind .cvs <ButtonPress-1> { 
	set G(RUNNING) [expr { !$G(RUNNING) }]
	if { $G(RUNNING) } DrawLoop
}

bind .cvs <Configure> { ResizeSurface %w %h ;Draw }
