# sample124-circles.tcl

# Inspired by 
#   https://openprocessing.org/sketch/1015319

# same results but with a very different tecnique.
#  *  Use the composition-op DST_OVER for drawing "under" 
#     (insted of using several layers and a complex "erase()" method)

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

set COLOR_IDX 0
proc nextColor {} {
	global COLOR_IDX
	set palette {
		0xffabcd5e 0xff14976b 0xff2b67af 0xff62b6de
		0xfff589a3 0xffef562f 0xfffc8405 0xfff9d531
	}
	incr COLOR_IDX
	if {$COLOR_IDX == [llength $palette]} { set COLOR_IDX 0 }
	return [lindex $palette $COLOR_IDX]
}

proc draw {sfc} {
	lassign [$sfc size] WIDTH HEIGHT

	 # create random circles
	set centers {}
	set N [expr {6+int(rand()*4)}]
	for {set i 0} {$i<$N} {incr i} {
		lappend centers [list [expr {rand()*$WIDTH}] [expr {rand()*$HEIGHT}]] 
	}
	
	set step 15
	$sfc clear -compop CLEAR ; #  bg should be fully transparent.	
	$sfc configure -compop DST_OVER ;# this is the trick for drawing "under"
	$sfc configure -stroke.width 8

	set i 0	
	for {set d $step} {$d <$WIDTH/2} {set d [expr {$d+$step}]} {
		set color [expr {[incr i]%2==0 ? 0xff000000 : [nextColor]}]
		$sfc configure -fill.style $color
		foreach C $centers {
			$sfc fill [BL::circle $C $d]
		}
	}
}

# === main ===========================================
	set sfc [image create blend2d -format {1200 600}]
	pack [label .cvs -image $sfc] -padx 30 -pady 30
	. configure -background black
	.cvs configure -borderwidth 0

	draw $sfc
	
	 # --- splash message ---
	label .top -text "Click for a new picture" -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
	bind . <ButtonPress-1> { destroy .top }
	tkwait window .top  ;#  wait for .top destruction
	bind . <ButtonPress-1> {}
	
	bind .cvs <ButtonPress-1> { draw $sfc }
