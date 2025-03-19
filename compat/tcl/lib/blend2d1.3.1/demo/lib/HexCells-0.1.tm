## HexCells 0.1
##
## This package is a *minimal* implementation of the math exposed in
## "Hexagonal Grids" by Amit Patel
##   https://www.redblobgames.com/grids/hexagons/#hex-to-pixel 
##
## == This package only deals with HexCells having a *pointy-top* orientation
## == *Size* is the radius of the outer circle and also the length of the hexagon's side.
##    Thus  
##      height = 2*size
##      width = sqrt(3)*size
##     hor-distance of two cells is  hor_dist = width = sqrt(3)*size
##     ver-distance of two cells is  ver_dist = 3/4*height = 3/2*size
## == HexCells are placed in a rectangular disposition with a *odd_r* layout.
## == The center of HexCell {0 0} is placed at (x,y)=(0,0)

##  - data structure:
##  Point:   {x y}
##  HexCube: {Q R} ( implicit S = -(Q+R) ) )
##  HexCell: {COL ROW}


 # return the HexCube {Q R} closer to FractionalHexCube {q r}
proc _HexCubeRound {fractionalHexCube} {
	lassign $fractionalHexCube q r  ;  set s [expr {-$q-$r}]
	set Q [expr {round($q)}]
	set R [expr {round($r)}]
	set S [expr {round($s)}]
	set q_diff [expr {abs($q-$Q)}]
	set r_diff [expr {abs($r-$R)}]
	set s_diff [expr {abs($s-$S)}]
	if { $q_diff > $r_diff && $q_diff > $s_diff } {
		set Q [expr {-$R-$S}]
	} elseif { $r_diff > $s_diff } {
		set R [expr {-$Q-$S}]
	}
	return [list $Q $R]	
}

 ## -- {COL ROW} --> {Q R}
proc _HexCubeFromHexCell {hexCell} {
	lassign $hexCell COL ROW
   	set Q [expr {$COL-($ROW-($ROW & 1))/2}] ;#  note: integer division
   	set R $ROW
	return [list $Q $R]
}

 ## -- {Q R} --> {COL ROW}
proc _HexCellFromHexCube {hexCube} {
	lassign $hexCube Q R
   	set COL [expr {$Q+($R-($R & 1))/2}]  ;#  note: integer division
	set ROW $R
	return [list $COL $ROW]
}

 ## -- {Q R}, size --> {x y}  (center of the HexCube)
proc _PointFromHexCube {hexCube size} {
	set SQRT3 [expr {sqrt(3)}]	
	lassign $hexCube Q R
	set x [expr {$size*($SQRT3*$Q + $SQRT3/2*$R)}]
	set y [expr {$size*(1.5*$R)}]
	return [list $x $y]
}

 ## -- {x y} --> {Q R}
proc _HexCubeFromPoint {xy size} {
	lassign $xy x y
	set q [expr {(1.0/sqrt(3)*$x - $y/3.0)/$size}]	
	set r [expr {(2.0/3.0*$y)/$size}]	
	return [_HexCubeRound [list $q $r]]
}


	# every hexagon has 6 neighbours.
	# These 'directions' are for *pointy-top* oriented cells, placed with an *odd_r* layout.
	# First list is for even rows, second list is for odd rows
	# Internal Note:: in order to loaded via 'package require ...'
	#  it should be set as fully-namespace-qualified variable
namespace eval HexCells {
 variable Directions {
	{
    	{+1  0} { 0 -1} {-1 -1} {-1  0} {-1 +1} { 0 +1}
    }
    {
		{+1  0} {+1 -1} { 0 -1} {-1  0} { 0 +1} {+1 +1}	
	}
 }
}
# ===========================================================================

  # == {COL ROW} --> {x y}  (center of the HexCell)
proc PointFromHexCell {hexCell size} {
	lassign $hexCell COL ROW
    set x [expr {$size * sqrt(3) * ($COL + 0.5 * ($ROW & 1) )}]
    set y [expr {$size * 1.5 * $ROW}]
    return [list $x $y]
}
if 0 {
	 # alternative: more elegant (?) but less performant 
	proc PointFromHexCell {hexCell size} {
		_PointFromHexCube [_HexCubeFromHexCell $hexCell] $size
	}
}

  # == {x y} --> {COL ROW}
  # NOTE: if Point = {0 y} , then COL may be -1 or 0
  #  TODO: no a BUG, but it's better to correct _HexCubeRound ...
proc HexCellFromPoint {xy size} {
	_HexCellFromHexCube [_HexCubeFromPoint $xy $size]
}

proc HexCellNeighbours {hexCell} {
	lassign $hexCell COL ROW
	set isEvenRow [expr {$ROW & 1}]
	set L {}
	foreach direction [lindex $::HexCells::Directions $isEvenRow] {
		lassign $direction dc dr
		lappend L [list [expr {$COL+$dc}] [expr {$ROW+$dr}]]
	}
	return $L
}

# --- geometry helper -------------------------------------------------

proc HexCellCorners {hexCell size} {
	set PI [expr {acos(-1)}]
	set corners {}
	set xy [PointFromHexCell $hexCell $size]
	lassign $xy xc yc
	
	for {set i 0} {$i < 6} {incr i} {
		set angle [expr {(30+60*$i)/180.0*$PI}] ;# start angle for pointy-top hexagon is 30
		set x [expr {$xc+$size*cos($angle)}]
		set y [expr {$yc+$size*sin($angle)}]
		lappend corners [list $x $y]		
	}
	return $corners
}

 # these procs are just a suggested framework ..
if 0 {

proc RectangularHexCellGrid {COLS ROWS size} {
	for {set ROW 0} {$ROW<$ROWS} {incr ROW} {
		for {set COL 0} {$COL<$COLS} {incr COL} {
			set xy [PointFromHexCell [list $COL $ROW] $size]
				# .. do something with HexCell {COL ROW} at {x y}
		}
	}
}

proc RectangularHexCubeGrid {COLS ROWS size} {
	for {set R 0} {$R<$ROWS} {incr R} {
		set R_offset [expr {$R>>1}]
		for {set Q [expr {-$R_offset}]} {$Q<=$COLS-$R_offset} {incr Q} {
			set xy [PointFromHexCube [list $Q $R] $size]
			# .. do something with HexCube {Q R} at {x y}
		}
	}
}

}

if 0 {
 # == TEST ====================

PointFromHexCell {1 0} 10

# test --
_HexCubeFromHexCell [_HexCellFromHexCube { 4 7 }]  ;# -> {4 7}
_HexCubeFromHexCell [_HexCellFromHexCube { 5 7 }]  ;# -> {5 7}

_HexCellFromHexCube [_HexCubeFromHexCell { 4 7 }]  ;# -> {4 7}
_HexCellFromHexCube [_HexCubeFromHexCell { 5 3 }]  ;# -> {5 3}

_PointFromHexCube [_HexCubeFromPoint { 153 231 } 10] 10 ;# -> 147.22431864335456 225.0

PointFromHexCell [HexCellFromPoint { 153 231 } 10] 10 ;# -> 153 231
HexCellFromPoint [PointFromHexCell { 153 231 } 10] 10 ;# -> 147.22431864335456 225.0

} ;# end of test
