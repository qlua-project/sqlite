set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

# --sample117 - demo text & textbox

package require Blend2d

set sfc [image create blend2d -format {800 700} ]
label .x -image $sfc ; pack .x


$sfc clear
set fontFace [BL::FontFace new "$thisDir/Blacksword.otf"]
set font [BL::Font new $fontFace 40.0]

set fontFace2 [BL::FontFace new "$thisDir/verdana.ttf"]
set smallfont [BL::Font new $fontFace2 15.0]


$sfc configure -fill.style [BL::color gray90]

proc textAndBox { sfc xy txt -anchor anchor } {
	global font
	global smallfont
	$sfc fill   [BL::text    $xy $font $txt -anchor $anchor]
	$sfc stroke [BL::textbox $xy $font $txt -anchor $anchor] -style [BL::color lightblue]
	$sfc fill [BL::circle $xy 5] -style [BL::color red]
	$sfc fill [BL::text $xy $smallfont $anchor -anchor N] -style [BL::color red]
}


$sfc fill   [BL::text {400 30} $smallfont "Text and anchor points" -anchor MID] -style [BL::color red]
 

set y 100
$sfc stroke [BL::line [list 0 $y] [list 1200 $y]] -style [BL::color lightblue]
textAndBox $sfc [list 250 $y] "Blend2D" -anchor RIGHT
textAndBox $sfc [list 400 $y] "Blend2D" -anchor MID
textAndBox $sfc [list 550 $y] "Blend2D" -anchor LEFT

set y 250
$sfc stroke [BL::line [list 0 $y] [list 1200 $y]] -style [BL::color lightblue]
textAndBox $sfc [list 250 $y] "Blend2D" -anchor NE
textAndBox $sfc [list 400 $y] "Blend2D" -anchor CENTER
textAndBox $sfc [list 550 $y] "Blend2D" -anchor SW

set y 400
$sfc stroke [BL::line [list 0 $y] [list 1200 $y]] -style [BL::color lightblue]
textAndBox $sfc [list 250 $y] "Blend2D" -anchor E
textAndBox $sfc [list 400 $y] "Blend2D" -anchor CENTER
textAndBox $sfc [list 550 $y] "Blend2D" -anchor W

set y 550
$sfc stroke [BL::line [list 0 $y] [list 1200 $y]] -style [BL::color lightblue]
textAndBox $sfc [list 250 $y] "Blend2D" -anchor SE
textAndBox $sfc [list 400 $y] "Blend2D" -anchor CENTER
textAndBox $sfc [list 550 $y] "Blend2D" -anchor NW


$font destroy
$smallfont destroy
$fontFace destroy
