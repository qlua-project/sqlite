# Splines

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

set sfc [image create blend2d -format {1000 800}]
pack [label .x -image $sfc]

set fontFace [BL::FontFace new [file join $thisDir "verdana.ttf"]]
set font [BL::Font new $fontFace 20]

proc DrawSpline {sfc mode Pts font text} {
$sfc push
	set polyType [expr {$mode eq "close" ? "polygon" : "polyline"}]

	 # draw the points
	$sfc configure -fill.style [BL::color red]
	foreach P $Pts {
		$sfc fill [BL::circle $P 10] 
	}

	# draw the segments
	$sfc stroke [BL::$polyType {*}$Pts] -style [BL::color lightgreen 0.5]

	# draw the spline
	$sfc stroke [BL::spline {*}$mode {*}$Pts] -style [BL::color white] -width 3
	
	$sfc fill [BL::text {600 20} $font $text] -style 0xffffff00
$sfc pop
}

set Pts {
  { 50   0}  
  {150 150}
  {250  20}
  {350 150}
  {450  20}
  {500 100}
  {550  00}
}

# NOTE: by default YAxis is inverted

$sfc applyTransform [Mtx::translation 0 20]
DrawSpline $sfc "" $Pts $font "canonical spline"

$sfc applyTransform [Mtx::translation 0 200]
DrawSpline $sfc "extend" $Pts $font "spline with extended extremities"

$sfc applyTransform [Mtx::translation 0 200]
DrawSpline $sfc "close" $Pts $font "closed spline"

$sfc applyTransform [Mtx::translation 0 200]
set Pts2 $Pts
lappend Pts2 [lindex $Pts end]
DrawSpline $sfc "close" $Pts2 $font "spline with an 'angular' control point"

