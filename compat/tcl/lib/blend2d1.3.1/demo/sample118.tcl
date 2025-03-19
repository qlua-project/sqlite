# --
# -- complex font, font rotation
#

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }


set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

set sfc [image create blend2d -format {600 600}]
label .x -image $sfc ; pack .x

set fontFace [BL::FontFace new [file join $thisDir "GoudyIni.ttf"]]
set font [BL::Font new $fontFace 50.0]

set fontFace2 [BL::FontFace new "$thisDir/verdana.ttf"]
set smallfont [BL::Font new $fontFace2 5.0]

 # set the origin at the screen center 
lassign [$sfc size] WIDTH HEIGHT
$sfc configure -matrix [Mtx::identity]
$sfc applyTransform [Mtx::translation [expr {$WIDTH/2}] [expr {$HEIGHT/2}]]
$sfc applyTransform [Mtx::scale 4]


proc Redraw {sfc txt font angle} {
	$sfc push
	$sfc clear -style [BL::color gray20]
	
	$sfc applyTransform [Mtx::rotation $angle degrees]
	$sfc fill [BL::text {0 0} $font $txt -anchor "CENTER"] -style [BL::color green]
	$sfc pop
}

proc rotateloop {angle} {
	global sfc
	global font
	global smallfont
	
	if { $angle < 0 } {
	  event generate . <<EndOfAnimation>>		
	} else {
		Redraw $sfc "XYZ" $font $angle
		after 50 rotateloop [incr angle -5]
	}
}

set clickEnabled true

bind . <<EndOfAnimation>> {
	set clickEnabled true

	set txt "Click to rotate the text"
	$sfc fill [BL::text {0 50} $smallfont $txt -anchor "MID"] -style [BL::color white]
}

bind . <ButtonPress-1> { 
	if { $clickEnabled } {
		set clickEnabled false
		rotateloop 360
	}
}

tkwait visibility .

Redraw $sfc "XYZ" $font 0
event generate . <<EndOfAnimation>>
