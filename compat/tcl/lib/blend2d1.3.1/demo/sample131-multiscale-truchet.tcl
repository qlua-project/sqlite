 # sample131-multiscale-truchet.tcl
 #
 # Credits
 # Author: Oliver Steele < steele@osteele.com>
 # Source: https://www.openprocessing.org/sketch/1055118
 #
 # The algorithm described in "Multi - Scale Truchet Patterns", Christopher
 # Carlson
 # https://christophercarlson.com/portfolio/multi-scale-truchet-patterns/
 #
 # Simplified version:
 #  no multiplanscroll
 #  no selction of subset of motifs
 #  no change of colors
 
# ... see also https://swift.swifteagle.co.uk/truchet/


set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
lappend auto_path [file join $thisDir lib]

package require Blend2d
package require OOClassvar

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::clamp {v a b} { expr {$v<$a ? $a : ($v<$b ? $v :$b)} }	
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }	
	proc tcl::mathfunc::random {a b} { expr {rand()*($b-$a)+$a} }
	proc tcl::mathfunc::random_item {items} { lindex $items [expr {int(rand()*[llength $items])}] }
	set PI [expr {acos(-1.0)}]
	proc tcl::mathfunc::deg2rad {a} { expr {$a*$::PI/180} }	

oo::class create Motifs {
	CLASS_VARS Specs
	
	CLASS_CONSTRUCTOR {
		 # -- Motifs specifications

		 # - Specs 0-1: paired arcs
		lappend Specs	{name "\\" arcs {1 2}}
		lappend Specs	{name "/"  arcs {0 3}}
		 # - Specs 2-4:  - ! +
		lappend Specs 	{name "-"  hline true}
		lappend Specs 	{name "|"  vline true}
		lappend Specs 	{name "+"  hline true vline true}
		 # - Specs 5-6:  . #
		lappend Specs 	{name "."}
		lappend Specs 	{name "#" inverted true}
		 # - Specs 7-10:  single arcs 
		lappend Specs 	{name "("  arcs {0}}
		lappend Specs 	{name ")"  arcs {1}}
		lappend Specs 	{arcs {2}}
		lappend Specs 	{arcs {3}}
		 # - Specs 11-14:  rectangles		
		lappend Specs 	{name "T" rect 0}
		lappend Specs 	{rect 1}
		lappend Specs 	{rect 2}
		lappend Specs 	{rect 3}	
	}
	
	variable my ;# array of instance cariables
	variable Cache

	 # size : size of inner square
	method _prepareInnerMotif {sfc size bgStyle fgStyle spec} {
		set Half [expr {$size/2.0}]
		set OneThird [expr {$size/3.0}]
		set TwoThird [expr {2*$size/3.0}]
				
		if { [dict exists $spec "inverted"] } {
			$sfc fill [BL::rect 0 0 $size $size] -style $fgStyle
		} else {
			$sfc fill [BL::rect 0 0 $size $size] -style $bgStyle
		}

		$sfc configure -stroke.style $fgStyle -stroke.width $OneThird
		
		
		if { [dict exists $spec "arcs"] } {
			foreach i [dict get $spec "arcs"] {
				switch -- $i {
				 0 { set x 0     ; set y 0     ; set a0 0 }
				 1 { set x $size ; set y 0     ; set a0 90 }
				 2 { set x 0     ; set y $size ; set a0 270 }
				 3 { set x $size ; set y $size ; set a0 180 }				 
				}
				set a0 [expr {deg2rad($a0)}]
				$sfc stroke [BL::arc [list $x $y] $Half $Half $a0 [expr {$::PI/2}]]
			}
		}
		if { [dict exists $spec "hline"] } {
			$sfc stroke [BL::line [list 0 $Half] [list $size $Half]]
		}
		if { [dict exists $spec "vline"] } {
			$sfc stroke [BL::line [list $Half 0] [list $Half $size]]
		}
		if { [dict exists $spec "rect"] } {
			switch -- [dict get $spec "rect"] {
			 0 { set shape [BL::rect 0 0 $TwoThird $size] }
			 1 { set shape [BL::rect 0 0 $size $TwoThird] }
			 2 { set shape [BL::rect $OneThird 0 $TwoThird $size] }
			 3 { set shape [BL::rect 0 $OneThird $size $TwoThird] }			 
			}
			$sfc fill $shape -style $fgStyle
		}
	}

	
	method _prepareWingedMotif {sfc size bgStyle fgStyle spec} {		
		set Half [expr {$size/2.0}]
		set OneQuarter [expr {$size/4.0}]
		set OneSixth   [expr {$size/6.0}]
		set OneTwelfth [expr {$size/12.0}]
				
		$sfc fill all -compop CLEAR
		
		$sfc push
		  $sfc applyTransform [Mtx::translation $OneQuarter $OneQuarter]
		  my _prepareInnerMotif $sfc $Half $bgStyle $fgStyle $spec
		$sfc pop

		$sfc push		
		$sfc applyTransform [Mtx::translation $Half $Half]
		for {set i 0} {$i<4} {incr i} {
			 # circles on the corners
			$sfc configure -fill.style $bgStyle
			$sfc fill [BL::circle [list $OneQuarter $OneQuarter] $OneSixth]
			 # midline small circles
			$sfc configure -fill.style $fgStyle 
			$sfc fill [BL::circle [list 0 $OneQuarter] $OneTwelfth]

			$sfc applyTransform [Mtx::rotation 90 degrees]
		}
		$sfc pop		 	
	} 	

	method setStyles { bgStyle fgStyle } {
		my _reinitCache $my(minsize) $my(levels) $bgStyle $fgStyle
	}
		
	method _reinitCache {size levels bgStyle fgStyle} {
		my _cleanupCache
		set wingedSize [expr {2*$size}]
		for {set level 0} {$level<$levels} {incr level} {
			set sfc [BL::Surface new -format [list $wingedSize $wingedSize]]
			set imgIdx 0
			foreach spec $Specs	{
				my _prepareWingedMotif $sfc $wingedSize $bgStyle $fgStyle $spec
				 # tkphoto name should be fixed, so that even if regenerated
				 # (change of colors..), it does not change
				set tkphoto [image create photo "[self]-${size}-${imgIdx}"]
				incr imgIdx
				$sfc writeToTkphoto $tkphoto
				lappend Cache($size) $tkphoto
			}
			set size [expr {$size*2}]
			set wingedSize [expr {$wingedSize*2}]
			
			set xStyle $bgStyle
			set bgStyle $fgStyle
			set fgStyle $xStyle
			$sfc destroy
		}
	}

	constructor {size levels bgStyle fgStyle} {
		USE_CLASS_VARS
		set my(levels) $levels
		 # size of the 'inner' non-winged tile
		set my(minsize) $size
		array set Cache {} ;# array of lists of prebuilt tiles (tkphoto)
		 # array index is size

		my _reinitCache $size $levels $bgStyle $fgStyle	
	}
	
	destructor {
		my _cleanupCache
	}
	
	method levels {} { return $my(levels) }
	method minsize {} { return $my(minsize) }
		
	method _cleanupCache {} {
		foreach {size tkphotos} [array get Cache] {
			image delete {*}$tkphotos
		}
		array unset Cache *	
	}

	 # return a random motif (a tkphoto) having size = size
	 # or "" 
	method getRandomMotif {size} {
		try {
			set tkphoto [expr {random_item($Cache($size))}]
		}
		return $tkphoto
	}		

	method showAll {sfc} {
		$sfc clear
		lassign [$sfc size] WIDTH HEIGHT
		
		set y 0		
		foreach size [lsort -integer [array names Cache]] {
			set dx [expr {$size*2}]
			set dy [expr {$size*2}]
			set x 0
			foreach tkphoto $Cache($size) {
				$sfc readFromTkphoto $tkphoto -to [list $x $y]
				incr x $dx
				if { $x+$dx > $WIDTH } {
					set x 0
					incr y $dy
				}
			}
			incr y 10
		}
	}
}
# -----------------------------------------------

oo::class create GridOfTiles { 
	variable my
	constructor {sfc motifs} {
		set my(sfc) $sfc
		set my(motifs) $motifs
	   # CONSTANTS
		set levels [$my(motifs) levels]
		set my(minTileSize) [$my(motifs) minsize]
		set my(maxTileSize) [expr {$my(minTileSize)*2**($levels-1)}]
		set my(subdivisionProbability) 0.5
		
		my createTiles
	}
	 # get/set
	method subdivisionProbability {args} {
		switch -- [llength $args] {
		  0 { return $my(subdivisionProbability) }
		  1 { 
		  	set v [lindex $args 0] 
		  	if { $v <0.0 || $v > 1.0 } { error "value must be between 0.0 and 1.0" }
		  	set my(subdivisionProbability) $v
		    }
		  default {
		  	error "wrong # args: should be \"[self] subdivisionProbability ?value?\""
		   }
		}
	}
	
	method maxTileSize {} {	return $my(maxTileSize) }
	
	method createTiles {} {
		set my(grid) {}
		my _addBottomRows	
	}
	method _createTileRow {y} {
		lassign [$my(sfc) size] WIDTH HEIGHT
		for {set x 0} {$x<$WIDTH} {incr x $my(maxTileSize)} {
			lappend my(grid) {*}[my _generateTiles $x $y $my(maxTileSize)]
		}
	}
	method _addBottomRows {} {
		set maxY 0
		foreach tile $my(grid) {
			lassign $tile _ y size _
			set y [expr {$y+$size}]
			if {$y>$maxY} {set maxY $y}
		}
		lassign [$my(sfc) size] WIDTH HEIGHT
		while { $maxY -$my(maxTileSize)/2 < $HEIGHT } {
			my _createTileRow $maxY
			set maxY [expr {$maxY+$my(maxTileSize)}]
		}
	}
	method removeInvisibleTiles {} {
		set newGrid {}
		foreach tile $my(grid) {
			lassign $tile _ y size _
			if { $y+2*$size > 0 } { lappend newGrid $tile }
		}
		set my(grid) $newGrid
	}
	
	method scroll {dy} {
		set my(grid) [\
			lmap tile $my(grid) { 
				lassign $tile x y size tkphoto
				set y [expr {$y+$dy}]
				list $x $y $size $tkphoto
			}\
		]
 
		# todo : optimization ...
		#  ... store top and bottom row, then call the following method only when ...
		my _addBottomRows
		my removeInvisibleTiles
	}

	method _generateTiles {x y size} {
		if {$size>$my(minTileSize)  &&  rand() < $my(subdivisionProbability) } {
			set Half [expr {$size/2}]
			set L {}
			lappend L {*}[my _generateTiles $x                $y                $Half]
			lappend L {*}[my _generateTiles $x                [expr {$y+$Half}] $Half]
			lappend L {*}[my _generateTiles [expr {$x+$Half}] $y                $Half]
			lappend L {*}[my _generateTiles [expr {$x+$Half}] [expr {$y+$Half}] $Half]
			return $L		
		} else {
			return [list [list $x $y $size [$my(motifs) getRandomMotif $size]]]
		}	
	}

	method draw {} {
		# important: draw smaller tiles on top of larger tiles
		
		# sort by size (2nd elem of ...) 
		foreach tile [lsort -decreasing -index 2 -integer $my(grid)] {
			lassign $tile x y size tkphoto
			set x [expr {$x-$size/2}]
			set y [expr {$y-$size/2}]			
			$my(sfc) readFromTkphoto $tkphoto -to [list $x $y]
		}
	}
	
}

set sfc [image create blend2d -format {700 1000}]
label .cvs -image $sfc
pack .cvs

BL::Surface create X
X load [file join $thisDir Orange-peel.jpg]
set motifs [Motifs new 30 3 [BL::color black] [BL::pattern X]]
set g [GridOfTiles new $sfc $motifs]


	proc draw_loop {grid} {
		global RUNNING
		global FRAMECOUNT

		$grid scroll -1 ;# scroll wupwards
		$grid draw 
		incr FRAMECOUNT 1
		
		if {$RUNNING} {after 10 [list draw_loop $grid]}
	}

	bind . <ButtonPress-1> {
		if {$RUNNING} { 
			set RUNNING false
			place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
		} else {
			place forget .top
			set RUNNING true
			draw_loop $g
		}
	}

	bind . <Key-plus> {
		set p [$g subdivisionProbability]
		set p [expr {$p+0.1}]
		if {$p<=1.0} {
			$g subdivisionProbability $p
		}
	}

	bind . <Key-minus> {
		set p [$g subdivisionProbability]
		set p [expr {$p-0.1}]
		if {$p>=0.0} {
			$g subdivisionProbability $p
		}
	}
	focus .
	

	set RUNNING false
	set FRAMECOUNT 0
	set MULTIPLANEFRAMEEND -1

	$g draw
		
	 # --- splash message ---
	label .top -text "Click to resume/supend" -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5
	vwait RUNNING
