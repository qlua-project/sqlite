 # sample132-multiscale-truchet.tcl
 #
 # Credits
 # https://swift.swifteagle.co.uk/truchet/
 # 
 # The algorithm described in "Multi - Scale Truchet Patterns", Christopher
 # Carlson
 # https://christophercarlson.com/portfolio/multi-scale-truchet-patterns/
 #

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
	set ::PI [expr {acos(-1.0)}]
	proc tcl::mathfunc::deg2rad {a} { expr {$a*$::PI/180} }	


oo::class create Motifs {
	CLASS_VARS Specs
	
	CLASS_CONSTRUCTOR {
		 # -- Motifs specifications

		 # - Specs 0-1: paired arcs
		lappend Specs	{arcs {1 2}}
		lappend Specs	{arcs {0 3}}
		 # - Specs 2-4:  - ! +
		lappend Specs 	{hline true}
		lappend Specs 	{vline true}
		lappend Specs 	{hline true vline true}
		 # - Specs 5-6:  . #
		lappend Specs 	{}
		lappend Specs 	{inverted true}
		 # - Specs 7-10:  single arcs 
		lappend Specs 	{arcs {0}}
		lappend Specs 	{arcs {1}}
		lappend Specs 	{arcs {2}}
		lappend Specs 	{arcs {3}}
		 # - Specs 11-14:  rectangles		
		lappend Specs 	{rect 0}
		lappend Specs 	{rect 1}
		lappend Specs 	{rect 2}
		lappend Specs 	{rect 3}	
	}
	
	variable my ;# array of instance variables
	variable Cache

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
		my _reinitCache $size $levels $bgStyle $fgStyle	
	}
	
	destructor {
		my _cleanupCache
	}
	
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

	method levels {} { return $my(levels) }
	method minsize {} { return $my(minsize) }

	 # print all the Motifs
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

				 # highlight the tile area
				set color [BL::color yellow]				
				$sfc stroke [BL::rect [expr {$x+$size/2}] [expr {$y+$size/2}] $size $size] -style $color -width 3
				
				incr x $dx
				if { $x+$dx > $WIDTH } {
					set x 0
					incr y $dy
				}
			}
			incr y $size ; incr y $size			
		}
	}
}

# ----------------------------------------------------------------------------


 # create N Surfaces and (N-1) bitmaps:
 #  sfcLayer(0) .. sfcLayer(n-1),  each of WIDTHxHEIGHT pixels
 #  bitLayer(0) .. bitLayer(n-2),      each one with a 2x x 2x number of bits
proc createNewLayers {N maxWIDTH maxHEIGHT} {
	global sfcLayer
	global bitLayer
	
	 # recompute *real* WIDTH, HEIGHT so that
	 # a) WIDTH <= maxWIDTH , HEIGHT <= maxHEIGHT
	 # b) WIDTH, HEIGHT be a multiple of maxTileSize
	 
	set maxTileSize [tileSize 0]
	set nc [expr {$maxWIDTH/$maxTileSize}]  ;#  trunc integer
	set nr [expr {$maxHEIGHT/$maxTileSize}]  ;#  trunc integer
	set WIDTH  [expr {$nc*$maxTileSize}]
	set HEIGHT [expr {$nr*$maxTileSize}]
	
	for {set i 0} {$i<$N} {incr i} {
		 # for each Surface, we also build a bitmap 
		 #  (i.e. a matrix whose values (0/1) denote if it's "tile" (i,j)
		 #   is integral (0) or splitted (1) )
		set sfcLayer($i) [image create blend2d -format [list $WIDTH $HEIGHT]]
		$sfcLayer($i) clear -compop CLEAR
		
		 # no need to create the last bitLayer, since it will never be 'splitted'
		if {$i<$N-1} {
			set bitLayer($i) [image create photo -width $nc -height $nr]
		}
		set nc [expr {$nc*2}]	
		set nr [expr {$nr*2}]	
	}
}

 # last layer (N_OF_LAYERS-1) has tiles of size  MIN_TILESIZE
 # first layer (0) has tiles of size MIN_TILESIZE<<(N_OF_LAYERS-1)
proc tileSize {layer} {
	global MIN_TILESIZE
	global N_OF_LAYERS
	expr {$MIN_TILESIZE<<($N_OF_LAYERS-1-$layer)}
}

  #   given coords (x,y) and a layer i
  # returns
  #   the block's index (ix,iy)
proc xy2ixy { i x y } {
    set DX [tileSize $i]
    set ix [expr {$x/$DX}]
    set iy [expr {$y/$DX}]
    return [list $ix $iy]    
}

  #   given a layer and two tile's indices (ix iy)
  # returns
  #   the absolute coords ( x y )
proc ixy2xy {i ix iy} {
    set DX [tileSize $i]
    set x [expr {$ix*$DX}]
    set y [expr {$iy*$DX}]
    return [list $x $y]    
}

proc resetLayers {} {
	global bitLayer
	global sfcLayer
	global N_OF_LAYERS
		
	 # note: don't reset bitmap for the last layer
	 # since it will never be splitted
	for {set i 0} {$i<$N_OF_LAYERS-1} {incr i} {
		$bitLayer($i) blank	
		$sfcLayer($i) clear -compop CLEAR		
	}
	 # clean last sfcLayer
	$sfcLayer($i) clear -compop CLEAR		
}

 # get/set bitLayer
 # flag = 0 means : tile is "integral"
 # flag = 1 means : tile has been splitted
proc bitLayer {layer ix iy {flag {}}} {
	global bitLayer
	if {$flag eq {}} {
		$bitLayer($layer) transparency get $ix $iy	
	} else { 
		$bitLayer($layer) transparency set $ix $iy $flag
	}
}

proc fillLayer {layer motifs} {
	global sfcLayer
	set tileSize [tileSize $layer]

	lassign [$sfcLayer($layer) size] WIDTH HEIGHT
	set NC [expr {$WIDTH/$tileSize}]
	set NR [expr {$HEIGHT/$tileSize}]
	for {set r 0} {$r<$NR} {incr r} {
		for {set c 0} {$c<$NC} {incr c} {
			drawRandomWingedTile $layer $c $r $motifs
		}
	}
}

proc drawRandomWingedTile {layer ix iy motifs} {
	global N_OF_LAYERS
	global sfcLayer

	 # split tile (ix,ix)
	 # note: last layer has no tile to split
	if {$layer<$N_OF_LAYERS-1} {
		bitLayer $layer $ix $iy 0  ;# 0 means: tile is 'integral'
	}
	
	set size [tileSize $layer]
	set tkphoto [$motifs getRandomMotif $size]

	lassign [ixy2xy $layer $ix $iy] x y
	set x [expr {$x-$size/2}]
	set y [expr {$y-$size/2}]			
	$sfcLayer($layer) readFromTkphoto $tkphoto -to [list $x $y]
}

proc split_tile { motifs x y } {
	global N_OF_LAYERS
	global sfcLayer
	
	lassign [$sfcLayer(0) size] WIDTH HEIGHT
	if { $x < 0 || $x >= $WIDTH || $y < 0 || $y >= $HEIGHT } return
	
	set i 0
	while { $i < $N_OF_LAYERS-1 } {
		lassign [xy2ixy $i $x $y] ix iy
		if { [bitLayer $i $ix $iy] == 0 } {
			bitLayer $i $ix $iy 1 ;# 1 means: tiles has been splitted
			
			 # create 4 new tiles on the next layer
			incr i
			set ix [expr {$ix<<1}]
			set iy [expr {$iy<<1}]

			drawRandomWingedTile $i $ix            $iy            $motifs
			drawRandomWingedTile $i [expr {$ix+1}] $iy            $motifs
			drawRandomWingedTile $i $ix            [expr {$iy+1}] $motifs
			drawRandomWingedTile $i [expr {$ix+1}] [expr {$iy+1}] $motifs

			 # Now we should merge all the layers
			while {$i<$N_OF_LAYERS} {
				$sfcLayer(0) copy $sfcLayer($i)
				incr i
			}
			return
		}
		incr i
	}
}

# === main ============================
	set MIN_TILESIZE 15
	set N_OF_LAYERS  5 ;# ->  tilesize wil be: 15 30 60 120 240

	 # -- create a Pattern for the motifs background
		BL::Surface create X
		X load [file join $thisDir Orange-peel.jpg]
	set motifs [Motifs new $MIN_TILESIZE $N_OF_LAYERS [BL::color black] [BL::pattern X]]

	createNewLayers $N_OF_LAYERS 1500 1000
	 # sfcLayer(0) is the main rendering Surface
	pack [label .cvs -image $sfcLayer(0) -borderwidth 0]
	
	fillLayer 0 $motifs

	 # --- splash message ---
	label .msg -text "Click on the canvas.\nPress <n> to restart" -borderwidth 40
	place .msg -in .cvs -anchor center -relx 0.5 -rely 0.5
	bind .cvs <ButtonPress-1> { destroy .msg }
	tkwait window .msg  ;# wait for .msg destruction

	bind .cvs <ButtonPress-1> {
		split_tile $motifs %x %y
	}

	focus .cvs 
	bind .cvs <Key-n> {
		resetLayers
		fillLayer 0 $motifs
	}
