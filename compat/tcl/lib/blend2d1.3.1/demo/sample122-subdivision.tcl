# sample122-subdivision

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

image create blend2d SFC -format {1000 900}
label .cvs -image SFC
pack .cvs

SFC configure -stroke.style [BL::color green] -stroke.width 3

set fontFace [BL::FontFace new "$thisDir/verdana.ttf"]
set font [BL::Font new $fontFace 25.0]

set path1 [BL::Path new]

 # a cubic with a loop
SFC fill   [BL::text {500 100} $font "20 points with T_SUBDIVISION" -anchor CENTER] -style [BL::color white]
$path1 reset
$path1 moveTo {100 100}
$path1 cubicTo {1000 500} {0 500} {900 100}
SFC stroke $path1

foreach P [$path1 contour 0 t-subdivision 20 at] {
	SFC fill [BL::circle $P 7] -style 0x8000ff00
}

SFC applyTransform [Mtx::translation 0 400]
#  plot the same curve with l-subdivision

 # NOTE: for these long curves, use a minimum tolearance (tolerance is relative to curve length!)
$path1 contours tolerance 1e-8
SFC fill   [BL::text {500 100} $font "20 points with L_SUBDIVISION (costant length)" -anchor CENTER] -style [BL::color white]
SFC stroke $path1
foreach P [$path1 contour 0 l-subdivision 20 at] {
	SFC fill [BL::circle $P 7] -style 0x8000ff00
}

