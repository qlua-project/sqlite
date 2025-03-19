# sample129b-Candy.tcl

#  Credits:
#  https://www.sosolimited.com/blog/programming-calligraphy-brushes/

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::lerp {x0 x1 t} { expr {$x0+($x1-$x0)*$t} }

 # a list of SVG-path (geom) and color-tags (tag)
set RAWShapeData {
	{ tag "color1" geom "M-241.05,976.5c0.4-2.5,0.7-5.1,0.9-7.7c0,0-2.9,1.8-7.9,4.8c-28.9,17.4-69.9,15.4-90.9-12.6
		c19,29,60,34,89.5,19.6C-244.05,978-241.05,976.5-241.05,976.5z" }
	{ tag "color1" geom "M-338.45,961c30.6,18,68.6,4,88.2-23.2c3.5-4.7,5.5-7.4,5.5-7.4c-0.8-2.5-1.7-4.9-2.7-7.3l0,0
		c0,0-1.8,2.9-4.9,7.8c-16.6,26-48.6,43-79.3,32.7C-335.95,962.2-338.45,961-338.45,961z" }
	{ tag "color1" geom "M-338.75,961c24.9,24,66.9,20,91.4-1.8c4.5-3.7,7.1-6,7.1-6c-0.2-2.6-0.5-5.2-0.9-7.7c0,0-2.4,2.4-6.6,6.5
		c-24.2,24-64.2,30-91.2,9c12,32,50,48,82.4,40c5.7-1.3,9-2.1,9-2.1l0,0c1-2.4,1.9-4.8,2.7-7.3c0,0-3.2,1-8.8,2.8
		C-284.95,1005-324.95,993-338.75,961L-338.75,961z" }
	{ tag "color2" geom "M-338.95,961.2c-34,5.8-56,41.8-52.2,75.1c0.4,5.8,0.5,9.1,0.5,9.1l0,0c2.2,1.4,4.5,2.7,6.8,3.8
		c2.3,1.2,4.6,2.3,7,3.3c2.4,1,4.8,1.9,7.3,2.7c2.4,0.8,4.9,1.5,7.4,2.1s5.1,1.1,7.6,1.5s5.1,0.7,7.7,0.9c2.5,0.2,5.1,0.3,7.7,0.3
		c2.6,0,5.2-0.1,7.7-0.3c2.6-0.2,5.2-0.5,7.7-0.9c2.6-0.4,5.1-0.9,7.6-1.5s5-1.2,7.5-2.1c2.5-0.8,4.9-1.7,7.3-2.7
		c2.4-1,4.8-2,7.1-3.3c2.3-1.1,4.6-2.4,6.8-3.8l0,0c0,0-3.1-1.3-8.5-3.7c-29-12.7-49-41.7-44.6-73.4
		C-339.75,963.8-338.95,961.2-338.95,961.2z" }
	{ tag "color2" geom "M-338.75,960.7c33.9-0.7,61.9-32.7,63.4-65.8c0.5-5.8,0.8-9.2,0.8-9.2c-1.9-1.7-4-3.3-6.1-4.8
		c-2.1-1.5-4.3-3-6.5-4.3c-2.2-1.4-4.5-2.7-6.8-3.8c-2.3-1.2-4.7-2.3-7.1-3.3c-2.4-1-4.8-1.9-7.3-2.7c-2.4-0.8-4.9-1.5-7.5-2.1
		c-2.5-0.6-5-1.1-7.6-1.5c-2.5-0.4-5.1-0.7-7.7-0.9c-2.5-0.2-5.1-0.3-7.7-0.3c-2.6,0-5.2,0.1-7.7,0.3c-2.6,0.2-5.2,0.5-7.7,0.9
		c-2.6,0.4-5.1,0.9-7.6,1.5s-5,1.3-7.4,2.1c-2.5,0.8-4.9,1.7-7.3,2.7c-2.4,1-4.8,2-7,3.3c-2.3,1.1-4.6,2.4-6.8,3.8
		c-2.2,1.3-4.4,2.8-6.5,4.3c0,0,3.1,1.2,8.6,3.1C-356.95,893-330.95,927-338.75,960.7L-338.75,960.7z" }
	{ tag "color1" geom "M-338.95,960.7c-19-29.7-61-34.7-89.5-19.1c-5.2,2.6-8.2,3.9-8.2,3.9l0,0c-0.4,2.5-0.7,5.1-0.9,7.7
		c0,0,2.9-1.5,7.9-4.5C-401.95,931-359.95,933-338.95,960.7L-338.95,960.7z" }
	{ tag "color1" geom "M-338.95,960.5c-11-33.5-51-46.5-82.5-39.2c-5.7,1.3-8.9,1.9-8.9,1.9c-1,2.4-1.9,4.8-2.7,7.3l0,0
		c0,0,3.2-0.8,8.7-2.6c28.5-9.9,65.5-0.9,81.9,26.2C-340.15,958-338.95,960.5-338.95,960.5z" }
	{ tag "color1" geom "M-430.45,998.9c1,2.4,2,4.8,3.3,7.1c0,0,1.7-2.8,4.4-8c14.8-30,50.8-50,83.8-37c-30-16-70,1-86.5,30.3
		C-428.45,996.2-430.45,998.9-430.45,998.9z" }
	{ tag "color1" geom "M-339.15,960.7c-24.8-23.7-66.8-19.7-91.3,2.3c-4.5,3.7-7.1,5.7-7.1,5.7c0.2,2.6,0.5,5.2,0.9,7.7l0,0
		c0,0,2.4-2.2,6.6-6.3c22.2-22.1,58.2-30.1,85-13.6C-341.15,959-339.15,960.7-339.15,960.7z" }
}


 # precompute paths: 
 #   trasform tag and geom (svg)
 #   in a list of dictionaries:  tag, geom (blPath)
 #  Moreover the whole shape becomes centered at (0.0), with a width of $w
proc adaptRAWShape {data w} {
	set xmin 1e20
	set xmax -1e20
	set ymin 1e20
	set ymax -1e20

	set newData {}

	foreach elem $data {
		set blPath [BL::Path new]
		$blPath addSVGpath [dict get $elem "geom"]
		dict set elem "geom" $blPath
				 
		lappend newData $elem

		lassign [$blPath bbox] x0 y0 x1 y1
		if { $x0 < $xmin } { set xmin $x0 }
		if { $x1 > $xmax } { set xmax $x1 }
		if { $y0 < $ymin } { set ymin $y0 }
		if { $y1 > $ymax } { set ymax $y1 }
	}

	# center and resize
	set xc [expr {($xmin+$xmax)/2.0}]
	set yc [expr {($ymin+$ymax)/2.0}]

	set M [Mtx::translation [expr {-$xc}] [expr {-$yc}]]
	set M [Mtx::MxM $M [Mtx::scale [expr {double($w)/($xmax-$xmin)}]]]
	foreach elem $newData {
		[dict get $elem "geom"] apply $M
	}

	 # *special* insert as a first element a £bgColor" disc of radius w/2
	set blPath [BL::Path new]
	$blPath add [BL::circle {0 0} [expr {$w/2}]]
	dict set elem "tag" "bgColor"
	dict set elem "geom" $blPath
	set newData [linsert $newData 0 $elem]

	return $newData
}

proc paintShape {sfc data} {
	global Color	
	foreach elem $data {
		$sfc fill [dict get $elem "geom"] \
			-fill.style $Color([dict get $elem "tag"]) 
	}
}

  # .. don't forget to destroy the Shape
proc freeShape {data} {
	foreach elem $data {
		[dict get $elem "geom"] destroy
	}		
}

global oldx
global oldy

set easing 0.09
set angle -60 

proc interpolateBrush {sfc x y shapeData} {
	global oldx
	global oldy
	global easing
	global angle

	set dx [expr {($x-$oldx)*$easing}]
	set dy [expr {($y-$oldy)*$easing}]

	set x2 [expr $oldx+$dx]
	set y2 [expr $oldy+$dy]

	set d [expr {sqrt(($x-$oldx)*($x-$oldx)+($y-$oldy)*($y-$oldy))}]

	set steps 18

	for {set i 0} {$i<=$steps} {incr i} {
		set t [expr {double($i)/$steps}]
		set cx [expr {lerp($oldx,$x2,$t)}]
		set cy [expr {lerp($oldy,$y2,$t)}]
		$sfc push
		$sfc applyTransform [Mtx::translation $cx $cy]
		$sfc applyTransform [Mtx::rotation $angle degrees]

		paintShape $sfc $shapeData

		set angle [expr {$angle+$d*0.18/$steps}]
		$sfc pop
	}
	set oldx $x2
	set oldy $y2
}

# === main ===========================================
	set sfc [image create blend2d -format {1000 700}]
	$sfc fill all -compop CLEAR
	pack [label .cvs -image $sfc] -padx 30 -pady 30
	. configure -background black
	.cvs configure -borderwidth 0

	bind .cvs <ButtonPress-1> { set oldx %x ; set oldy %y }
	bind .cvs <B1-Motion> { interpolateBrush $sfc %x %y $shapeData }
	bind .cvs <Enter> { focus %W }
	bind .cvs <Key-c> { $sfc fill all -compop CLEAR }

	 # set bgColor, color1, color2 ,  and adapt the RAWshape
	global Color
	set Color(bgColor) [BL::color white]
	set Color(color1) [BL::color lightblue]
	set Color(color2) [BL::color red]
	set shapeData [adaptRAWShape $RAWShapeData 50.0]

