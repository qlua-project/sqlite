# sample130A-hexTiles.tcl

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


proc midPoint {A B} {
	set M {}
	foreach a $A b $B {
		lappend P [expr {($a+$b)/2.0}]
	}
	return $P
}

set ::PI [expr {acos(-1)}]
proc deg2rad {angle} { expr {${::PI}/180*$angle} }

  # HexTile creates (one of 5 variants of) an istance of an hexagonal tile made of several BL:Paths
  # that can be painted on a BL::Surface ( see method "draw" )
  #
  # the center of the hexTile is at {0 0}.
  # the hexTile is *pointy-top* oriented
  # 
oo::class create HexTile {
	variable my my
	 # An HexTile is made of several BL:Paths ,
	 #  each one stroked/filled with different options (style (color), width ...).
	 # All these BL::Paths (and relative options) are stored  
	 # in *my(tileData)*  as 
	 #  {op1 path1 options1  op2 path2 options2 .....}
	 #  where
	 #     op     is "fill" or "stroke"
	 #     path   is a BL:Path
	 #    options is a list of options for stroking/filling the path
	 #
	 # result is an hextTile with an 'external' radius (and thus sides) of length $radius
	 # centered at (0,0).  
	constructor {variantId radius} {
		set radius [expr {$radius*1.0}]  ;#  -- force to be a real number

		set bgStyle [BL::color white]
		set fgStyle [BL::color lightblue]

		set my(tileData) [my _buildVariant ${variantId} $radius $bgStyle $fgStyle]
	}

	 #rotate all the tileData's internal tileRef (tileData does not change)
	method _rotate {tileData angle} {
		if { $angle == 0 } return
		foreach {op path opt} $tileData {
			$path apply [Mtx::rotation $angle degrees]
		}
	}

	method _buildVariant {variantId r bgStyle fgStyle} {
		  #  trick: extend the hexagon radius in order to avoid annoying border between tiles.
		set r [expr {$r+1.0}]
		set half_r [expr {$r/2-0}]

		set deg120 [deg2rad 120]
		set hexCorners [HexCellCorners {0 0} $r]
		lassign $hexCorners P0 P1 P2 P3 P4 P5
		set postRotation 0

		set tileData [list]
		switch -- $variantId {
		 A -
		 B -
		 C {	
			if { $variantId == "B" } {
				set postRotation 120
			}
			if { $variantId == "C" } {
				set postRotation -120
			}		
			set shape [BL::Path new]
			# ----------------------
			set polygon {}		
			lappend polygon [midPoint $P2 $P3]
			lappend polygon $P3
			lappend polygon [midPoint $P3 $P4]
			lappend polygon [midPoint $P4 $P5]
			lappend polygon $P5
			lappend polygon [midPoint $P5 $P0]
			$shape add [BL::polygon {*}$polygon]		
			lappend tileData "fill" $shape "-style $fgStyle"
		
			set shape [BL::Path new]
			# ----------------------
			set polygon {}		
			lappend polygon [midPoint $P5 $P0]
			lappend polygon $P0
			lappend polygon [midPoint $P0 $P1]
			lappend polygon [midPoint $P1 $P2]
			lappend polygon $P2
			lappend polygon [midPoint $P2 $P3]
			$shape add [BL::polygon {*}$polygon]					
			$shape add [BL::pie $P4 $half_r $half_r [deg2rad 30] $deg120]
			lappend tileData "fill" $shape "-style $bgStyle"

			set shape [BL::Path new]
			# ----------------------
			$shape add [BL::pie $P1 $half_r $half_r [deg2rad 210] $deg120]
			lappend tileData "fill" $shape "-style $fgStyle"

			set shape [BL::Path new]
			$shape add [BL::line [midPoint $P5 $P0] [midPoint $P2 $P3]]
			$shape add [BL::arc $P4 $half_r $half_r [deg2rad 30] $deg120]
			$shape add [BL::arc $P1 $half_r $half_r [deg2rad 210] $deg120]
			lappend tileData "stroke" $shape "-style 0xff000000 -stroke.width 3"
			}
		  D -
		  E {
			if { $variantId == "D" } {
				set dummy $bgStyle ; set bgStyle $fgStyle ; set fgStyle $dummy
				set postRotation 60
			}
			set shape [BL::Path new]
			# ----------------------
			set polygon {}		
			lappend polygon $P0
			lappend polygon [midPoint $P0 $P1]
			lappend polygon [midPoint $P1 $P2]
			lappend polygon $P2
			lappend polygon [midPoint $P2 $P3]
			lappend polygon [midPoint $P3 $P4]
			lappend polygon $P4
			lappend polygon [midPoint $P4 $P5]
			lappend polygon [midPoint $P5 $P0]
			$shape add [BL::polygon {*}$polygon]		
			lappend tileData "fill" $shape "-style $bgStyle"

			set shape [BL::Path new]
			# ----------------------
			set shape [BL::Path new]
			$shape add [BL::pie $P1 $half_r $half_r [deg2rad 210] $deg120]
			$shape add [BL::pie $P3 $half_r $half_r [deg2rad -30] $deg120]
			$shape add [BL::pie $P5 $half_r $half_r [deg2rad 90]  $deg120]
			lappend tileData "fill" $shape "-style $fgStyle"

			set shape [BL::Path new]
			$shape add [BL::arc $P1 $half_r $half_r [deg2rad 210] $deg120]
			$shape add [BL::arc $P3 $half_r $half_r [deg2rad -30] $deg120]
			$shape add [BL::arc $P5 $half_r $half_r [deg2rad 90]  $deg120]
			lappend tileData "stroke" $shape "-style 0xff000000 -stroke.width 3"
			}
		  default {
			error "\"$variantId\" is not a supported HexTile variant."
		  }		
		}
		my _rotate $tileData $postRotation
		return $tileData
	}
			
	destructor {
		if { [info exists my(tileData)] } {
			foreach {op path opt} $my(tileData) {
				$path destroy		
			}
		}
	}
	
	method draw {sfc x y angle} {
		$sfc push
		set M [Mtx::translation $x $y]
		set M [Mtx::rotate $M $angle "degrees"]
		$sfc applyTransform $M
		foreach {op path opt} $my(tileData) {
			$sfc $op $path {*}$opt
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
	 #   Each entry contains a reference to one of the 5 valid HexTiles
	 #
	 # Please note that these particular HexTiles CANNOT be rotated independently;
	 # ALL the tiles should be rotated simultaneously, and then, after 60 degrees
	 # they reach a new admissible global pattern.
	 # For these reason we don't need to store the rotation of each tiles;
	 #   *my(angle)* denotes the current rotation of ALL the cells.
	constructor {sfc radius} {
		set my(sfc) $sfc
		set my(r) $radius
		set my(hexTiles) {}
		foreach variant {"A" "B" "C" "D" "E"} {
			lappend my(hexTiles) [HexTile new $variant $radius]
		}
		set my(tileMap) {}
		set my(angle) 0  ;# the same rotation (in degree) is applied to all the tiles
	}
	
	destructor {
		if {[info exists my(hexTiles)]} {
			 foreach tile $my(hexTiles) {
			 	$tile destroy
			}
		}
	}

	method _randomHexTile {} {
		lindex $my(hexTiles) [expr {int(rand()*[llength $my(hexTiles)])}]	
	}

	 # This method *prepares* my(tileMap) with a 'matrix' of NxM  cells.
	 # Each cell just contains the reference to a random hexTile.
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
				lset my(tileMap) $col $row [my _randomHexTile]
			}
		}	
	}
		
	method rotate60 {} {
		#  start the animation (if it's not running)
		if {[info command _rotate60] == {}} {
			coroutine _rotate60 my _co_rotate60
		}	
	}

	method _co_rotate60 {} {
		for {set angle $my(angle)} {$angle<$my(angle)+60} {incr angle 3} {
			set t [expr {($angle-$my(angle))/60.0}]
			set a [expr {$my(angle)+[easing $t]*60}]
			my draw $a
			co_after 20 ;# async wait for 20 msec
		}	
		set my(angle) [expr {($my(angle)+60)%360}]
		my draw $my(angle)

	}

	method draw {angle} {
		$my(sfc) clear
		set col 0
		foreach column $my(tileMap) {
			set row 0
			foreach ref $column {
				set xy [PointFromHexCell [list $col $row] $my(r)]
				$ref draw $my(sfc) {*}$xy $angle				
				incr row
			}
			incr col
		}
	}
	
}

# === main ===========================================
	set sfc [image create blend2d -format {1200 800}]
	pack [label .cvs -image $sfc]
	.cvs configure -borderwidth 0

	$sfc clear
	set hexGrid [HexGrid new $sfc 50.0]
	$hexGrid fillAll
	$hexGrid draw 0

	 # --- splash message ---
	label .top -text "Click to rotate the tiles\nRight-Click for a new pattern" \
		 -borderwidth 40
	place .top -in .cvs -anchor center -relx 0.5 -rely 0.5

	bind . <ButtonPress-1> {
		destroy .top
		bind . <ButtonPress-1> {}
	}
	tkwait window .top  ;# -- WAIT for .top destruction

	bind .cvs <ButtonPress-1> {
		$hexGrid rotate60
	}
	bind .cvs <ButtonPress-3> {
		$hexGrid fillAll
		$hexGrid draw 0
	}
