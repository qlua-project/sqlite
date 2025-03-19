# sample129-Ribbon.tcl

#  Credits:
#  https://www.sosolimited.com/blog/programming-calligraphy-brushes/

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
package require Blend2d

# TODO:
# * hot-key for saving on a ribbon-##.png
# * erase (need a new cursor , no easing)
# *  circular cursor,

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::lerp {x0 x1 t} { expr {$x0+($x1-$x0)*$t} }
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }


# Every brush is made of two thin vertical rectangles (left, right).
# Each rectangle is made of 1..N 'bands' of different colors and heights
#  e.g.   { red 10  white 20  blue 9.5  black 0.5 } {orange 10}
#  NOTE: the bands heights are not absolute. They will be scaled so that
#        the sum of heights be 'height'
#  Return a list { path color path color .... }

proc createHalfBrush { x0 x1 height bands } {
	set H 0.0
	foreach {blColor h} $bands {
		set H [expr {$H+$h}]
	}
	set half [expr {$height/2.0}]
	set h0 0.0
    set y0 [expr {map($h0,0,$H, -$half, +$half)}]
	foreach {blColor h} $bands {
		set h1 [expr {$h0+$h}]
        set y1 [expr {map($h1,0,$H, -$half, +$half)}]

		set path [BL::Path new]
        $path add [BL::box [list $x0 $y0] [list $x1 $y1]]
		lappend figure $path "-style $blColor"
		set h0 $h1
		set y0 $y1

	}
	return $figure
}


oo::class create Brush {
	variable my
	constructor {DX DY leftBands rightBands} {
		set my(height0) $DY ;# initial height

		set my(scale) 1.0
		set my(angle) 0.0

		set my(figure) {}
		set half [expr {$DX/2.0}]

		lappend my(figure) {*}[createHalfBrush [expr {-$half}] 0 $DY $leftBands]
		lappend my(figure) {*}[createHalfBrush 0 $half $DY $rightBands]
		my rotate 30
	}

	method rot {} { return $my(angle) }
	method sf {} {return $my(scale)}
	method height {} { expr {$my(height0)*$my(scale)} }

	destructor {
		foreach {path options} $my(figure) { $path destroy }
	}
	method draw {sfc} {
		foreach {path options} $my(figure) {
			$sfc fill $path {*}$options
		}
	}
	method scale {sf} {
		set my(scale) [expr {$my(scale)*$sf}]
		set beta [my rot]
		my rotate [expr {-$beta}]
		foreach {path options} $my(figure) {
			$path apply [Mtx::scale 1.0 $sf]
		}
		my rotate $beta
	}

	method rotate {beta} {
		set my(angle) [expr {$my(angle)+$beta}]
		foreach {path options} $my(figure) {
			$path apply [Mtx::rotation $beta degrees]
		}
	}
}

 #  {x1 y1 x2 y2 ...} --> {{x1 y1} {x2 y2} ..}
proc CoordsToPoints { coords } {
	set points {}
	foreach {x y} $coords { lappend points [list $x $y] }
	return $points
}

 #  {{x1 y1} {x2 y2} ..} --> {x1 y1 x2 y2 ...}
proc PointsToCoords {points} {
	set coords {}
	foreach p $points { lappend coords {*}$p }
	return $coords
}

oo::class create PenCursor {
	variable my
	constructor {cvs} {
		set my(cvs) $cvs
		set my(height0) 20 ; # unimportant; it will be resized by 'adaptToBrush'
		set my(angle) 0.0
		set my(scale) 1.0

		 # HOTSPOT is a just a 'point' ( -> use an "image" item-type - note it has no related image, only its coords are useful )
		 # It must be the first item of the group (tag) CUR_$id
		set id  [$my(cvs) create image 0 0 -tags HOTSPOT]
		set my(tag) "CUR_$id"
		$my(cvs) addtag $my(tag) withtag $id
		set half [expr {$my(height0)/2.0}]
		$my(cvs) create line  0 [expr {-$half}] 0  $half -tags $my(tag) -fill black -width 4
		$my(cvs) create line  0 [expr {-$half+1}] 0 [expr {$half-1}] -tags $my(tag) -fill white -width 2
	}

	destructor {
		$my(cvs) delete $my(tag)
	}

	method show {} { $my(cvs) itemconfigure $my(tag) -state normal ; $my(cvs) raise $my(tag) }
	method hide {} { $my(cvs) itemconfigure $my(tag) -state hidden }

	method getpos {} {
		$my(cvs) coords "$my(tag) && HOTSPOT"
	}
	method rot {} { return $my(angle) }
	method sf {} { return $my(scale) }
	method height {} { expr {$my(height0)*$my(scale)} }

	 # rotate the cursor by beta degrees
	 #  NOTA: rotation is incremental
	method rotate {beta} {
		set my(angle) [expr {$my(angle)+$beta}]

		lassign [my getpos] cx cy
		set M [Mtx::rotation $beta degrees [list $cx $cy]]
		foreach itemID [$my(cvs) find withtag $my(tag)] {
			set points [CoordsToPoints [$my(cvs) coords $itemID]]
			set points [Mtx::multiPxM $points $M]
			$my(cvs) coords $itemID [PointsToCoords $points]
		}
	}

	method reset {} {
		my rotate [expr {-$my(angle)}]
		my scale  [expr {1.0/$my(scale)}]
	}

	method adaptToBrush {brushObj} {
		my reset
		my scale  [expr {[$brushObj height]/$my(height0)}]
		my rotate [$brushObj rot]
	}

	method scale {sf} {
		set my(scale) [expr {$my(scale)*$sf}]
		set beta [my rot]
		my rotate [expr {-$beta}]
		lassign [my getpos] cx cy
		$my(cvs) scale $my(tag) $cx $cy 1.0 $sf
		my rotate $beta
	}

	method move {dx dy} {
		$my(cvs) move $my(tag) $dx $dy
	}

	method moveto {x y} {
		lassign [my getpos] cx cy
		my move [expr {$x-$cx}] [expr {$y-$cy}]
	}

}

global oldx
global oldy
set easing 0.09

proc interpolateBrush {sfc brush x y} {
	global oldx
	global oldy
	global easing

	set dx [expr {($x-$oldx)*$easing}]
	set dy [expr {($y-$oldy)*$easing}]

	set x2 [expr $oldx+$dx]
	set y2 [expr $oldy+$dy]

	set steps 28 ;# ? magic ?

	for {set i 0} {$i<=$steps} {incr i} {
		set t [expr {double($i)/$steps}]
		set cx [expr {lerp($oldx,$x2,$t)}]
		set cy [expr {lerp($oldy,$y2,$t)}]
		$sfc push
		$sfc applyTransform [Mtx::translation $cx $cy]
		$brush draw $sfc
		$sfc pop
	}
	set oldx $x2
	set oldy $y2
}

# === main ===========================================

proc help {} {
	tk_messageBox -message "\
<c>   clear
<up> <down>   resize
<left> <right>  rotate brush

Button #1,2, #3 for choosing another kind of ribbon.
"
}

	pack [ttk::button .help -text "?" -width 4 -command help]
	. configure -padx 10 -pady 10 -background gray

	 # create a blend2d image and put it in a canvas widget.
	 # In this we can superimpose aome canvas-widgets (e.g a special cursor ...)
	 # over the blend2d image without touching the image

	set WIDTH 1000
	set HEIGHT 500
	set sfc [image create blend2d -format [list $WIDTH $HEIGHT]]
	$sfc fill all -compop CLEAR

	pack [canvas .cvs -height $HEIGHT -width $WIDTH]
	.cvs create image 0 0 -image $sfc -anchor nw

	set H 40.0  ;#  initial brush height

	set brush1 [Brush new 4.0 $H \
		[list [BL::rgb 202 210 37] 100] \
		[list [BL::rgb 157 175 10] 100] \
	]

	set brush2 [Brush new 4.0 $H \
		[list \
			[BL::color gray50 0.1] 0.5 \
			[BL::color red]        10  \
			[BL::color white]      10  \
			[BL::color blue]       10  \
			[BL::color gray50 0.1] 0.5 \
		] \
		[list \
			[BL::color darkred]        10  \
			[BL::color gray70]      10  \
			[BL::color darkblue]   10  \
		] \
		]

	set color1  [BL::rgb 120 131 235]
	set color1B [BL::rgb 120  80 235]
	set color2  [BL::rgb 102 102 204]
	set color2B [BL::rgb 102  80 204]
	set brush3 [Brush new 4.0 $H \
		[list \
			[BL::color gray 0.5] 1 \
			$color1 20   \
			$color2 18   \
			$color1 24   \
			$color2 18   \
			$color1 20   \
			[BL::color gray 0.5] 1 \
		] \
		[list \
			$color1B 20   \
			$color2B 18   \
			$color1B 24   \
			$color2B 18   \
			$color1B 20   \
		] \
		]

	set brush4 [Brush new 4.0 $H \
		[list \
			[BL::color orange 0.5] 1 \
			0x000000 1   \
			[BL::color orange 0.5] 1 \
		] \
		[list \
			[BL::color red 0.5] 1 \
			0x000000 1   \
			[BL::color red 0.5] 1 \
		] \
		]

	.cvs configure -cursor none

proc changeBrush {brushObj} {
	variable mycursor
	variable currBrush

	set currBrush $brushObj
	$mycursor adaptToBrush $currBrush
}

	set mycursor [PenCursor new .cvs]
	changeBrush $brush1


bind .cvs <Motion>          { $mycursor moveto %x %y }

bind .cvs <ButtonPress-1>   { set oldx %x ; set oldy %y ; $mycursor hide }
bind .cvs <ButtonRelease-1> { $mycursor show }
bind .cvs <Motion>          { $mycursor moveto %x %y }
bind .cvs <B1-Motion>       { interpolateBrush $sfc $currBrush %x %y ; $mycursor moveto %x %y }

bind .cvs <Enter> {focus %W}
 # cleanup
bind .cvs <Key-c> { $sfc fill all -compop CLEAR }

bind .cvs <Key-Left>  {$mycursor rotate -15 ; $currBrush rotate -15}
bind .cvs <Key-Right> {$mycursor rotate +15 ; $currBrush rotate +15}
bind .cvs <Key-Up>    {$mycursor scale  1.1; ; $currBrush scale 1.1}  ;# non mi piace, deve essere lineare
bind .cvs <Key-Down>  {$mycursor scale  [expr {1/1.1}] ; ; $currBrush scale [expr {1/1.1}] }  ;# non mi piace, deve essere lineare e ci deve essere un limite

 # -3 buttons for 3 brushes
frame .brushes
set i 1
foreach brush [list $brush1 $brush2 $brush3 $brush4] {
	ttk::button .brushes.b$i -text "#$i" -width 4 \
		-command [list changeBrush $brush]
	pack .brushes.b$i -side left
	incr i
}
pack .brushes

