#  sample105-SVGmoby.tcl
#  - Variation of sample105-SVGmoby.tcl
#  This versione make use of the new BL::SvgDoc class
#  for loading aan SVd

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

 # == MAIN =====

wm title . "\"Blend2d\" high performance 2D vector graphics engine - TclTk bindings"

set filename [file join $thisDir moby.svg]

set sfc [image create blend2d]
label .cvs -image $sfc -borderwidth 0
pack .cvs -padx 20 -pady 20 -expand 1 -fill both

set svgdoc [BL::Svgdoc new $filename]

proc Redraw {sfc svgdoc DX DY} {
	lassign [$sfc size] oDX oDY
	if { $oDX == $DX && $oDY== $DY } return

	$sfc configure -format [list $DX $DY]
	$sfc clear -style [BL::color lightblue]
$sfc push
	 # put the origin at the center of the Surface
	 #  and then anchor the CENTER of the svgdoc to this new origin
	$sfc applyTransform [Mtx::translation [expr {$DX/2.0}] [expr {$DY/2.0}]]
	$sfc paint $svgdoc -anchor CENTER -autoresize true
$sfc pop
}  

Redraw $sfc $svgdoc 500 300
      
bind .cvs <Configure> { Redraw $sfc $svgdoc %w %h }
