# AHI !! ogni tanto si inchioda ... no crash ma si bloccae non risponde piu' !!!

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname [file dirname $thisDir]]]
#
# Blend2d - Tiger demo - with perspective deformation
#

package require Blend2d 

 # load the tiger-data - result is a big list named TigerData
set thisDir [file dirname [file normalize [info script]]]
source $thisDir/tiger-data.tcl
             
 # precompute paths:
 # for each path, change the geom attribute from a (simplyfied) SVG spec, to BL::Path objects.
 proc precomputePaths {data} {
	set newData {}
	foreach path $data {
		set geom [dict get $path geom]
		set blPath [BL::Path new]
		foreach {cmd coords} $geom {			
			switch -- $cmd {
			 "M" -
			 "L" { 
				lassign $coords x y
				if { $cmd eq "M" } { 
			 		$blPath moveTo $coords
				} else {
			 		$blPath lineTo $coords				
				} 
			 }
			 "C" {
			 	set PP {}
			 	foreach {x y} $coords {
					lappend PP [list $x $y] 
				 }
			 	$blPath cubicTo {*}$PP 
				}
			 "Z" { $blPath close }		 
			}
		}
		$blPath shrink
		dict set path geom $blPath
	
		lappend newData $path
	}
	return $newData
}

 # return the box as {x0 y0 x1 y1}
 # data should be a list of 'paths' with the "geom" attribute already converted to a BL::Path
proc precomputeBbox {data} {
	set xmin +Inf
	set xmax -Inf
	set ymin +Inf
	set ymax -Inf

	foreach path $data {
		set blPath [dict get $path geom]
		lassign [$blPath bbox] x0 y0 x1 y1
		if { $x0 < $xmin } { set xmin $x0 }
		if { $x1 > $xmax } { set xmax $x1 }			
		if { $y0 < $ymin } { set ymin $y0 }
		if { $y1 > $ymax } { set ymax $y1 }			
	}
	return [list $xmin $ymin $xmax $ymax]
}

# Paint
# parameters:
#   data : the precomputed .. paths ..
#   sfc      : the BL::Surface
proc Paint { sfc data planarPerspective} {
	foreach path $data {
		set fillrule [dict get $path "fill"]
		set geom  [dict get $path "geom"]
		 # alter a copy of geom
		set geom [$geom dup]
		$geom apply $planarPerspective

		if { $fillrule ne "NONE" } {
			$sfc fill $geom \
				-fill.rule $fillrule \
				-fill.style [dict get $path "fillColor"] 
		}

		if { [dict get $path "stroke"] } {
		   # currently a cached strokedpath is not supported ...
		   # a strokedpath is a countour that will be FILLED (instead of STROKED)
		   $sfc configure \
		   	-stroke.style [dict get $path "strokeColor"] \
		   	-stroke.cap [dict get $path "strokeCap"] \
			-stroke.join [dict get $path "strokeJoin"] \
			-stroke.miterlimit [dict get $path "strokeMiterLimit"] \
			-stroke.width [dict get $path "strokeWidth"] 	
		   $sfc stroke $geom
		}
		 # destroy the dup geom
		$geom destroy
	}		
}	

# ==== quad controls ====================================================

proc flat {xyList} {
	set L {}
	foreach xy $xyList {
  		lappend L {*}$xy
	}
	return $L
}

proc createCircle {cvs C r} {
	lassign $C x y
	$cvs create oval [expr {$x-$r}] [expr {$y-$r}] [expr {$x+$r}] [expr {$y+$r}]
}

proc circleMoveTo {cvs tags C r} {
	lassign $C x y
	$cvs coords "$tags" [expr {$x-$r}] [expr {$y-$r}] [expr {$x+$r}] [expr {$y+$r}]
}


 # xylist must be a list of 4 points {x y}
proc createQuad {cvs xyList} {
	set quadId [$cvs create polygon [flat $xyList] -outline gray80 -fill {} -tags QUAD]
	set quadTag "QUAD_$quadId"
	$cvs addtag $quadTag withtag $quadId
	for {set idx 0} { $idx < 4 } {incr idx} {
		set xy [lindex $xyList $idx]
		set id [createCircle $cvs $xy 10]

		$cvs addtag SPOT withtag $id
		$cvs addtag $quadTag withtag $id
		$cvs itemconfigure $id -activefill white
		$cvs addtag "SPOT_$idx" withtag $id
	}
	return $quadTag
}

proc quadDelete { cvs quadTag } {
	$cvs delete $quadTag
}

proc quadGet {cvs tag} {
	set L {}
	foreach {x y} [$cvs coords "$tag"] {
		lappend L [list $x $y]
	}
	return $L
}

proc quadSet {cvs quadTag xyList} {
	$cvs coords "QUAD && $quadTag" [flat $xyList]
	set R 10
	for {set idx 0} { $idx < 4 } {incr idx} {
		circleMoveTo $cvs "SPOT && SPOT_$idx && $quadTag" [lindex $xyList $idx] $R
	}
}

proc co_movequad {cvs sfc quadTag spotId x0 y0} {
	$cvs bind SPOT <B1-Motion> [list [info coroutine] [list %x %y]]
	$cvs bind SPOT <ButtonRelease-1> [list [info coroutine] {}]

	set tags [$cvs gettags $spotId]
	 # expected  SPOT SPOT_k QUAD_n
	regexp {SPOT_(.*)} [lsearch -inline -glob $tags SPOT_*] _ spotIdx
	while { [set xy [yield]] != {} } {
		lassign $xy x y
		set dx [expr {$x-$x0}]
		set dy [expr {$y-$y0}]
		set x0 $x
		set y0 $y
		$cvs move $spotId $dx $dy

		set P [lrange [$cvs coords "QUAD && $quadTag"] [expr {2*$spotIdx}] [expr {2*$spotIdx+2}]]
		lassign $P x y
		$cvs imove "QUAD && $quadTag" [expr {2*$spotIdx}] [expr {$x+$dx}] [expr {$y+$dy}]

		doPaint $cvs $sfc $quadTag
	}
	$cvs bind SPOT <B1-Motion> {}
	$cvs bind SPOT <ButtonRelease-1> {}
}

proc BBoxToQuad {x0 y0 x1 y1} {
	list [list $x0 $y0]  [list $x1 $y0]  [list $x1 $y1]  [list $x0 $y1]
}

# =======================================================================

proc doPaint {cvs sfc quadTag} {
	global TigerData
	global TigerBBox

	set quadA [BBoxToQuad {*}$TigerBBox]
	set quadB [quadGet $cvs $quadTag]
		# note invM could be precomputed; it changes only when SFC is resized ..
	set invM1 [Mtx::invert [$sfc cget -matrix]]
	set quadB [Mtx::multiPxM $quadB $invM1]
	set planarM [Mtx::quadtoquad $quadA $quadB] ;# may raise an error ..

    $sfc clear -style 0xFF00007F
	Paint $sfc $TigerData $planarM
}

# == MAIN =================================================================
wm title . "\"Blend2d\" high performance 2D vector graphics engine - TclTk bindings"

set TigerData [precomputePaths $TigerData]
set TigerBBox [precomputeBbox $TigerData]
 # enlarge the bbox for a better control
	lassign $TigerBBox x0 y0 x1 y1
	set x0 [expr {$x0-20}]
	set y0 [expr {$y0-20}]
	set x1 [expr {$x1+20}]
	set y1 [expr {$y1+20}]
	set TigerBBox [list $x0 $y0 $x1 $y1]

# add a grid to TigerData
	lassign $TigerBBox x0 y0 x1 y1
	set dx [expr {($x1-$x0)/6.0}]
	set dy [expr {($y1-$y0)/6.0}]
	set blPath [BL::Path new]
	for {set x $x0} {$x<$x1} {set x [expr {$x+$dx}]} {
		$blPath add [BL::line [list $x $y0] [list $x $y1]]
	}
	for {set y $y0} {$y<$y1} {set y [expr {$y+$dy}]} {
		$blPath add [BL::line [list $x0 $y] [list $x1 $y]]
	}
	dict set path "geom" $blPath
	dict set path "fill" "NONE"
	dict set path "stroke" "true"
	dict set path "strokeColor" [BL::color white 0.5]
	dict set path "strokeCap" "ROUND"
	dict set path "strokeJoin" "MITER_BEVEL"
	dict set path "strokeMiterLimit" "10.0"
	dict set path "strokeWidth" 2.0
	lappend TigerData $path



set WIDTH  500
set HEIGHT 500

canvas .cvs
pack .cvs -expand 1 -fill both    -padx 20 -pady 20
set SFC [image create blend2d -format [list $WIDTH $HEIGHT]]
.cvs create image {0 0} -image $SFC -anchor nw

set quadTag [createQuad .cvs [BBoxToQuad 0 0 $WIDTH $HEIGHT]]
.cvs itemconfigure "SPOT && $quadTag" -fill red

.cvs bind SPOT <ButtonPress-1> [list apply {
	{cvs sfc qTag x y} {
		coroutine movequad co_movequad $cvs $sfc $qTag [$cvs find withtag current] $x $y
	} } %W $SFC $quadTag %x %y ]


quadSet .cvs $quadTag [BBoxToQuad 0 0 $WIDTH $HEIGHT]

doPaint .cvs $SFC $quadTag

proc OnConfigure {cvs sfc w h dataBBox quadTag} {
	global WIDTH
	global HEIGHT
	if { $w == $WIDTH && $h == $HEIGHT } return

	set WIDTH $w
	set HEIGHT $h
	$sfc configure -format [list $w $h]

	 # set the Surface transform so that dataBBox will be centered
	lassign $dataBBox tx0 ty0 tx1 ty1
	set tdx [expr {$tx1-$tx0}]
	set tdy [expr {$ty1-$ty0}]
	 # use a larger box, so to have a a margin
	set tdx [expr {$tdx+100}]
	set tdy [expr {$tdy+100}]

	set s [expr {min( $w/$tdx , $h/$tdy)}]

	 # collimate the center of the dataBBox with the center of the Surface
	set tcx [expr {($tx0+$tx1)/2.0}]
	set tcy [expr {($ty0+$ty1)/2.0}]
	set wcx [expr {$w/2.0}]
	set wcy [expr {$h/2.0}]
	set M1 [Mtx::translation [expr {$wcx-$tcx}] [expr {$wcy-$tcy}]]

	set M1 [Mtx::MxM $M1 [Mtx::scale $s $s [list $wcx $wcy]]]
	set quad [Mtx::multiPxM [BBoxToQuad {*}$dataBBox] $M1]
	quadSet $cvs $quadTag $quad

	doPaint $cvs $sfc $quadTag
}

bind .cvs <Configure> [list OnConfigure .cvs $SFC %w %h $TigerBBox $quadTag]
