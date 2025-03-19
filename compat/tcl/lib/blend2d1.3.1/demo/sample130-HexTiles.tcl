# sample130-hexTiles.tcl

# Truchet Hexagonal tiles.
#
# Based on "Yet Another Truchet"
#  https://openprocessing.org/sketch/1916623
	
set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
set auto_path [linsert $auto_path 0 [file join $thisDir lib]]

package require HexCells
package require Blend2d

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

  # HexTile creates an istance of an hexagonal tile made of several BL:Paths
  # that can be painted on a BL::Surface ( see method "draw" )
  #
  # the center of the hexTile is at {0 0}.
  # the hexTile is *pointy-top* oriented
  # this HexTile ha a simmetry of 60 degrees
  # 
  # .. One instance of HexTile will be used by HexGrid for drawing all the tiles
oo::class create HexTile {
	variable my my
	 # An HexTile is made of several BL:Paths ,
	 #  each one stroked/filled with different options (style (color), width ...).
	 # All these BL::Paths (and relative options) are stored in a dictionary 
	 # " my(tileData)"  with the following keys:
	 #  "border" : a list of 1 or more {op shape options}
	 #  "bg"     :   idem
	 #  "fg"     :   idem
	 #  where
	 #     op is "fill" or "stroke"
	 #     path is a BL:Path
	 #    options is a list of options for stoking/filling the path
	 #
	 # result is an hextTile with an 'external' radius (and thus sides) of length $radius
	 # centered at (0,0).  
	constructor {radius} {
		set radius [expr {$radius*1.0}]  ;#  -- force to be a real number

		set bgStyle [BL::color black]
		 # == hextile background ; just a filled hexagon
		set hexShape [BL::Path new]
		$hexShape add [BL::polygon {*}[HexCellCorners {0 0} $radius]]

		dict set my(tileData) "border" [list "stroke" $hexShape "-style $bgStyle -width 2.5"]
		set hexShape2 [$hexShape dup]
		dict set my(tileData) "bg" [list "fill" $hexShape2 "-style $bgStyle"]
		
		 # == hexTile foreground is a set of 2n+1 'stripes' (arcs)
		 #  trick: in order to avoid gaps when two tiles are placed side by side,
		 #         we slightly extend the hexagon radius
		set r [expr {$radius+0.6}]

		set PI [expr {acos(-1)}]
		set deg120 [expr {120 *$PI/180.0}]         
		
		# prepare N=5 shapes (stripes):
		#  N must be odd
		#  stripe K and (N-K+1) must have the same style
		set styles [list \
			[BL::color lightblue] \
			[BL::color red] \
			[BL::color white]  \
			[BL::color red] \
			[BL::color lightblue] \
		]						
		set N [llength $styles]
		set width [expr {$r/($N+4)}]  ;# width should be less than r/(N+1)

		set i 1
		foreach style $styles {
			set k 5.0
			set r1 [expr {($r-2*$k)/($N+1)*($i)+$k}]
			incr i
		
			set shape [BL::Path new]
			 # prepare 3 arcs of 120 degrees (on 3 hexagon vertices)
			foreach beta {0 120 240} {
				$shape add [BL::arc [list $r 0.0] $r1 $r1 $deg120 $deg120]
				$shape apply [Mtx::rotation $deg120]
			}
			$shape apply [Mtx::rotation 30 degrees]
			dict lappend my(tileData) "fg" "stroke" $shape "-style $style -width $width"
		} 
	}

	destructor {
		if { [info exists my(tileData)] } {
			foreach key {"border" "bg" "fg"} {
				foreach {op path opt} [dict get $my(tileData) $key] {
					$path destroy		
				}
			}
		}
	}
	
	method draw {sfc x y angle scale {hasBorder false}} {
		$sfc push
		set M [Mtx::translation $x $y]
		set M [Mtx::rotate $M $angle "degrees"]
		if {$scale!=1.0} {
			set M [Mtx::scaling $M $scale $scale]
		}		
		$sfc applyTransform $M
		
		if {$hasBorder} {		
			foreach {op path opt} [dict get $my(tileData) "border"] {
				$sfc $op $path {*}$opt
			}		
		}
		foreach key {"bg" "fg"} {
			foreach {op path opt} [dict get $my(tileData) $key] {
				$sfc $op $path {*}$opt
			}
		}
 		$sfc pop
	}
}


proc co_after {ms} {
    after $ms [list [info coroutine]]
    yield
    return
}


 # bounce effect:
 #  easing 0 --> 0
 #  easing 1/d1   --> 1.0
 #  easing 2/d1   --> 1.0
 #  easing 2.5/d1 --> 1.0
 # easing  1.0    --> 1.0
                  
proc easing {x} {
	set  n1 7.5625
	set  d1 2.75

	if {$x < 1/$d1} {
			return [expr {$n1 * $x * $x}]
	} elseif {$x < 2/$d1} {
			set x [expr {$x-1.5/$d1}]
			return [expr {$n1 * $x * $x + 0.75}]
	} elseif {$x < 2.5/$d1} {
			set x [expr {$x-2.25/$d1}]		
			return [expr {$n1 * $x * $x + 0.9375}]
	} else {
			set x [expr {$x-2.625/$d1}]	
			return [expr {$n1 * $x * $x + 0.984375}]
	}
}

oo::class create HexGrid {
	variable my 

	 # An HexGrid is a rectangular grid of hexagonal cells.
	 # *my(tileMap)* is an internal 'matrix' of NxM entries.
	 #   each entry contains the rotation (in degrees) of the hexTile
	 #   Note that if a cell is being animated (rotating..), then its value
	 #   in my(tileMap) is not its 'current rotation' but it's its 'final rotation'.
	 # 
	 # In order to animate the cells, we must keep some data in two extra data structures:
	 #   RunningCells, SurrondingCells
	 # Please note that we cannot just repaint one rotating cells with
	 #  a progressively small increasing angle, because the surrounding cells
	 #  are partially soiled by the rotated hexagons. So, insted of repainting ALL the cells, we will just
	 #  repaint the surrounding cells ..
	 # 
	 # *my(RunningCells)* is a dictionary whose keys are the cells {col row}
	 #  being rotated.
	 #  Each running cell has a dictionary with the following keys:
	 #   -phase  - the current animation-phase (0,1,2)
	 #   -T      - the 'time' spent in the current phase
	 #   -angle0 , -angle1  the starting and the final angle for the animated rotation
	 #   -angle  - the current angle
	 #   -scale  - the current scale
	 # *my(SurroundingCells)* is a dictionary whose keys are the cells {col row}
	 #   surrounding the RunningCells.
	 # Since two RunningCells may have some SurroundingCells in common, this data
	 #  structure contains just the SET of the surrounding cells (no duplicates).
	 #  Each surronding cell has a dictionary with the following keys:
	 #   -count - number of running cells sharing this surrounding cell.
	 #            (when this count drops to zero, the sorrounding cell is removed)
	constructor {sfc radius} {
		set my(sfc) $sfc
		set my(r) $radius
		set my(hexTile) [HexTile new $radius]
		set my(tileMap) {}
		set my(RunningCells) [dict create]
		set my(SurroundingCells) [dict create]		
	}
	
	destructor {
		if {[info exists my(hexTile)]} { $my(hexTile) destroy }
	}

	method _GetRotation {cell} {
		lassign $cell col row
		lindex $my(tileMap) $col $row
	}
	method _SetRotation {cell angle} {
		lassign $cell col row
		lset my(tileMap) $col $row $angle
	}
		
	 # fill the whole sfc with randomly rotated tiles
	 # and set the *my(tileMap)*	
	method fillAll {} {
		lassign [$my(sfc) size] WIDTH HEIGHT
		set my(tileMap) {}
		
		set dy [expr {1.5*$my(r)}]
		set dx [expr {sqrt(3)*$my(r)}] ;# == 2*r*cos(30)
		
		set cols [expr {round($WIDTH/$dx)+1}]
		for {set y 0; set row 0} {$y-$dy/2 <$HEIGHT} {set y [expr {$y+$dy}]; incr row} {
			set x 0
			if {$row%2==1} {set x [expr {$dx/2}]}
			for {set x $x; set col 0} {$col < $cols} {set x [expr {$x+$dx}]; incr col} {
				set angle [expr {(rand()<0.5) ? 0 : 60}]
				my _SetRotation [list $col $row] $angle
				$my(hexTile) draw $my(sfc) $x $y $angle 1.0
			}
		}	
	}
	
	method animateCell {x y} {
		set cell [HexCellFromPoint [list $x $y] $my(r)]
		if { [my _IsValidCell $cell] } {
			my _AddRunningCell $cell
		}
	}
	
	method _IsValidCell {cell} {
		lassign $cell COL ROW
		expr {$COL >= 0 && $ROW>=0 
		       && $COL < [llength $my(tileMap)] 
			   && $ROW < [llength [lindex $my(tileMap) $COL]] 
			 }			
	}
	
	 # if cell is not among the the running cells, and there are less than 10 running cells,
	 # then update *my(RunningCells)*
	 # and also *my(SurroundingCells)*
	 # -- NOTE: cell must be a valid cell 
	 #
	 # my(SurroundingCells) is a dict whose keys are the cells 
	 # adjacent to the the running cells (with a refCounter).
	 # Since the rotated/scaled running cells may overlap their adjacent cells,
	 # then all these surrounding cells should be 'cleaned' (re-painted)
	 # before a drawing the animated running cells. 
	method _AddRunningCell {cell} {
		if { [dict size $my(RunningCells)] > 10 || [dict exists $my(RunningCells) $cell] } return
	
		set angle0 [my _GetRotation $cell]
		set angle1 [expr {$angle0+60}]
		 #update my(tileMap) with the final rotation
		my _SetRotation $cell [expr {$angle1%360}]
	
		dict set my(RunningCells) $cell [dict create \
			-T 0 \
			-phase 0 \
			-angle0 $angle0 \
			-angle1 $angle1 \
			-angle $angle0 \
			-scale 1 \
			]
		foreach nearbyCell [HexCellNeighbours $cell] {
			if {! [my _IsValidCell $nearbyCell]} continue
			if { [dict exists $my(SurroundingCells) $nearbyCell] } {
				set count [dict get $my(SurroundingCells) $nearbyCell "-count"]				
			} else {
				set count 0
			}
			dict set my(SurroundingCells) $nearbyCell "-count" [incr count]
		}
	
		#  start the animation loop (if it's not running)
		if {[info command _AnimateRunningCells] == {}} {
			coroutine _AnimateRunningCells my _co_animateRunningCells
		}	
	}
	
	method _co_animateRunningCells {} {
		while { [dict size $my(RunningCells)] > 0 } {
			 # === redraw all SurroundingCells ====
			foreach cell [dict keys $my(SurroundingCells)] {
				 # skip it if it's a RunningCells
				if { [dict exists $my(RunningCells) $cell] } continue
				set rotation [my _GetRotation $cell]
				set xy [PointFromHexCell $cell $my(r)]
				$my(hexTile) draw $my(sfc) {*}$xy $rotation 1.0
			}

			 # === redraw all RunningCells ====		
			set DT 50
			set phaseDuration {500 1000 500}   ;#3 phases	
			
			 # just scan all the RunningCells, 
			 # foreach RunningCell compute and store
			 #   its new "-T" and "-phase"
			 #   or remove it from RunningCells if it's at the end of the its last phase (2)
			foreach {cell data} [dict get $my(RunningCells)] {
				set T [dict get $data "-T"]
				set phase [dict get $data "-phase"]
				set duration [lindex $phaseDuration $phase]
				if { $T < $duration } {
					incr T $DT
					if {$T>$duration} { set T $duration }
				} else {
					incr phase
					set T 0
				}
				if { $phase <= 2 } {
					dict set data "-T" $T
					dict set data "-phase" $phase
					dict set my(RunningCells) $cell $data
				} else {
					 # remove cell from RunningCells and remove its SourroundingCells
					dict unset my(RunningCells) $cell
					foreach nearbyCell [HexCellNeighbours $cell] {
						if {![my _IsValidCell $nearbyCell]} continue
						set count [dict get $my(SurroundingCells) $nearbyCell "-count"]
						incr count -1
						if {$count==0} {
							dict unset my(SurroundingCells) $nearbyCell
						} else {
							dict set my(SurroundingCells) $nearbyCell -count $count
						}
					}
				}			
			}
			 # draw loop:
			 # foreach RunningCell, redraw it
			foreach {cell data} [dict get $my(RunningCells)] {
				set T [dict get $data "-T"]
				set phase [dict get $data "-phase"]
				set duration [lindex $phaseDuration $phase]
				
				set angle [dict get $data "-angle"]
				set scale [dict get $data "-scale"]
				
				set t [expr {double($T)/$duration}]						
				switch -- $phase {
					0 {  
						# increment scale from 1.0 to 1.2
						set scale [expr {1.0+0.2*[easing $t]}]
				 	}  
					1 {
						# rotate angle: from angle0 to angle1
						set angle0 [dict get $data -angle0]
						set angle1 [dict get $data -angle1]
						set angle [expr {$angle0+[easing $t]*($angle1-$angle0)}]
				 	} 
				 	2 {  
						# decrement scale from 1.2 to 1.0
						set scale [expr {1.0+0.2*(1-$t)}]
				 	}
				}
				set xy [PointFromHexCell $cell $my(r)]
				$my(hexTile) draw $my(sfc) {*}$xy $angle $scale true ;# draw with border
				 # update cell's data
				dict set data -angle $angle
				dict set data -scale $scale
				dict set my(RunningCells) $cell $data 
			}
			co_after $DT ;# -- async wait
		}
	}
	
}

# === main ===========================================
	set sfc [image create blend2d -format {1200 800}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	$sfc clear
	set hexGrid [HexGrid new $sfc 75.0]
	$hexGrid fillAll

	 # --- splash message ---
	label .top -text "Click on a tile to rotate it\nor Click and drag" -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5

	bind . <ButtonPress-1> {
		destroy .top
		bind . <ButtonPress-1> {}
	}
	tkwait window .top  ;# -- WAIT for .top destruction

	bind .cvs <ButtonPress-1> {
		$hexGrid animateCell %x %y
	}
	bind .cvs <B1-Motion> {
		$hexGrid animateCell %x %y
	}
