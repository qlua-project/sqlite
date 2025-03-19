#  
#  Cards with shadows.
#  Strange loops: Where is the top card ?
#
set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

package require Blend2d

# --------------------------------------------------------------------------
 set PI [expr {acos(-1)}]

proc enlargedRect { rect dx dy } {
	lassign $rect x y w h
	list [expr {$x-$dx}] [expr {$y-$dy}] [expr {$w+2*$dx}] [expr {$h+2*$dy}]
}

 # get the width,height of a PNG file
	 # very simplified,; we assume cardFile is a good PNG file.
	 # no error check !
proc CardImageSize {cardFile} {
	set f [open $cardFile r]
	fconfigure $f -translation binary

	 #skip header and IHDR chunk signature 
	read $f 16
    binary scan [read $f 8] II width height
	close $f

	return [list $width $height]
}


  # -- special processing for the 1st card ...
  # $sfc will be resized for containing the (scaled) card
  # surrounded by a (symmetric) margin for the shadow.
  # -
  # return the scaled size of the the card (without shadow)
proc ResizeAndApplyShadow {sfc cardImage scaleFactor blurRadius blur_dxy} {
	set fullCardSfc [BL::Surface new]
	$fullCardSfc load $cardImage
	lassign [$fullCardSfc size] width height

	set dx [expr {int($width*$scaleFactor)}]
	set dy [expr {int($height*$scaleFactor)}]
	
	lassign $blur_dxy bdx bdy
	set xmargin [expr {$blurRadius+abs($bdx)}]
	set ymargin [expr {$blurRadius+abs($bdy)}]
	
	set enlarged_dstRect [enlargedRect [list 0 0 $dx $dy]  $xmargin $ymargin]
	
	lassign $enlarged_dstRect _ _ edx edy

	 # resize sfc
	$sfc configure -format [list $edx $edy]
	$sfc clear -compop CLEAR
	$sfc filter shadow -radius $blurRadius -dxy $blur_dxy {
	 	 # copy $fullCardSfc in $sfc, scaled, and with a margin for the shadow
		$sfc copy $fullCardSfc -to [list $xmargin $ymargin $dx $dy]
	} 
	
	$fullCardSfc destroy
	return [list $dx $dy]
}

 set imageDir [file join $thisDir Cards Spades]
 set N 7
 
# - GUI----------------------------------------------------------------
 wm title . "TclTk bindings for Blen2d - demo 114"
 frame .leftBar
	ttk::spinbox .leftBar.n -textvariable N \
		-from 4 -to 14 -width 4
	ttk::button .leftBar.run -text "Run" -command {RunOnce $imageDir $N $DX $DY}
	
	ttk::label .leftBar.msg -text "How many cards ?"
	pack .leftBar.msg .leftBar.n .leftBar.run 

 pack .leftBar -padx 5 -side left

 set DX 1000
 set DY 1000
  # --  create the main surface SURF
 image create blend2d SURF -format [list $DX $DY]
 label .cvs -image SURF
 pack .cvs -padx 10 -pady 10 -expand 1 -fill both

 
# -------------------------------------------------------------------
set isRunning false
proc RunOnce {imageDir N DX DY} {
	global isRunning
	if { $isRunning } return
	set isRunning true
	Run $imageDir $N $DX $DY
	set isRunning false
}

proc Run {imageDir N DX DY} {
	global PI
	
 set blurRadius 10
 set blur_dxy {5 7}

 set cards { A 2 3 4 5 6 7 8 9 10 J Q K Joker }
 set n [llength $cards] 
  # -- shuffle cards
 set i 0
 foreach card $cards {
 	set j [expr {round(rand()*($n-1))}]
 	set card [lindex $cards $j]
	lset cards $j [lindex $cards $i]
	lset cards $i $card
	incr i
 }

 set cards [lrange $cards 0 $N-1]

  # get the 1st card and remove it form $cards
 set cards [lassign $cards card_0]

  # get the image size (we assume all cards have the same size)
 lassign [CardImageSize [file join $imageDir ${card_0}.png]] srcDX srcDY

  # compute the scaling factor 
 set scaleFactor [expr {min(double($DX)/double($srcDX),double($DY)/double($srcDY))/4.5}] ;# >=4




  SURF reset
 
  # this is CRITICAL ... background should be fully transparent,
  #  because we must draw the last half card UNDER an existing card,
  #  and this works only if background is fully transparent  
  # it will be filled at the end with the DST_OVER composition
 SURF clear -compop CLEAR 
 
 SURF configure -matrix [Mtx::translation [expr {$DX/2}] [expr {$DY/2}]]
 SURF userToMeta
  # now the origin is at the window's center.
 SURF push ;# fix the metamatrix before appliying all the next rotations

  # -- special processing for the 1st card ...
  # it will be loaded in an auxiliary new Surface.
  # it will be scaled and surrounded by a (symmetric) margin for the shadow.
  # ---
 set card0Sfc [BL::Surface new]
 lassign \
  [ResizeAndApplyShadow $card0Sfc [file join $imageDir ${card_0}.png] $scaleFactor $blurRadius $blur_dxy] \
  dx dy
 
 # -- get height,width of the scaled image, enlarged with shadow
 lassign [$card0Sfc size] edx edy
 # -- set the destination of the scaled image (without shadows)
 set dstRect [list [expr {-$dx/2}] 0 $dx $dy]

  # this (unused) distance is the MIN distance so that  all cards
  # placed in circle, DON'T overlap (i.e. they just have a single point of contact)
 # set dMax [expr {$dx/2.0/tan($PI/$N)+$dy/2.0}]

 # the anchor point of each card is placed at top(center) of the image;
 # We need to translate each card (after each rotation) by this distance.
 # This distance if the MIN distance from the center of the main SURF,
 #  so that cards are overlapping but they don't cover more than half of the previous card.
 #  NOTE: it works only for N >= 4

 set d [expr {($edx/2.0)/tan(2*$PI/$N)}]
   set mdy [expr {($edy-$dy)/2.0}] ; # shadow margin dy
 set d [expr {$d+$mdy}]
 
# draw all the card (but card_0)
  set dTheta [expr {2*$PI/$N}]
  set cardSfc [BL::Surface new] ;# surface for holding a card in turn  (not scaled)
  foreach card $cards {
	SURF configure -matrix [Mtx::rotation $dTheta]
	SURF userToMeta

 	$cardSfc load [file join $imageDir ${card}.png]

	 SURF filter shadow -radius $blurRadius -dxy $blur_dxy {
		SURF configure -matrix [Mtx::translation 0 $d]
	 	# note: due to "-to rect", cardSfc is scaled on copy
		SURF copy $cardSfc -to $dstRect
	 }
     # just for animation ... you may remove
	after 100 ; update   
  }
  $cardSfc destroy 

   # -- final step, ... this is the trick ...
  SURF pop ;# this is for resetting all the accumulated rotation in metaMatrix
  SURF push

   # -- draw the 1st card (just the right-half)
  set mdy [expr {($edy-$dy)/2.0}] ; # shadow margin dy
  SURF configure -matrix [Mtx::translation 0 $d]
  set edx2 [expr {$edx/2}]
  set edy2 [expr {-$edy/2}]
  SURF copy $card0Sfc -from [list $edx2 0 $edx2 $edy] -to [list 0 [expr {-$mdy}]]

   # -- draw the 1st card (just the left-half) UNDER then the next card
  SURF copy $card0Sfc -from [list 0 0 $edx2 $edy] \
  	-to [list [expr {-$edx2}] [expr {-$mdy}]] \
	-compop DST_OVER

     # just for animation ... you may remove
   update

  $card0Sfc destroy 
  SURF pop

   # draw the background UNDER the cards
     # just for animation ... you may remove
	after 500 ; update 

  SURF fill all -compop DST_OVER -style [BL::color #00c100]
}