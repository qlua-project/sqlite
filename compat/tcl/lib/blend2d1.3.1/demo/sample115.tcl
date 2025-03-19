#
# TclTk porting of https://openprocessing.org/sketch/1518376
#

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]
set auto_path [linsert $auto_path 0 [file join $thisDir lib]]
	

package require Blend2d
package require IKscale

# --------------------------

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

	#
	# -- some math functions -----------------------------------------
	#
	proc tcl::mathfunc::map {x a0 a1 b0 b1} { expr {(double($x)-$a0)*($b1-$b0)/($a1-$a0)+$b0} }	
	set PI [expr {acos(-1)}]
	proc randomChoice {L} { lindex $L [expr {int(rand()*[llength $L])}] }

proc midPoint {A B} {
	lmap a $A b $B { expr {($a+$b)/2.0} }	
}	
	

 # Color palettes
set PALETTES [dict create \
	rainbow 			{#531253 #9a5de5 #ec5bb3 #29f0b6 #57b576 
						 #3131d1 #090584 #171773 #3965f5 #238cf4 
						 #34bbfb #ec5d19 #ef8311 #FFC21F #e8ff81} \
	fullrainbow 		{#ff0000 #ff8700 #ffd300 #deff0a #a1ff0a
						 #0aff99 #0aefff #147df5 #580aff #be0aff} \
	orangebrown 		{#fe5b14 #ff9831 #cec8b8 #222    #53372a} \
	purplegreenyellow	{#29f0b6 #6f1161 #fecd28 #fb8c8c #fa901e #abffed} \
	orangebluebrown 	{#fe5b14 #ff9831 #3131d1 #34bbfb #53372a} \
	blueorange 			{#3d348b #7678ed #f7b801 #f18701 #f35b04} \
	sunset 				{#ffbe0b #fb5607 #ff006e #8338ec #3a86ff} \
	neorustic 			{#d7263d #f46036 #2e294e #1b998b #c5d86d} \
	pastel 				{#9a5de5 #ec5bb3 #fce439 #34bbfb #40f5d6} \
	genuary 			{#2E294E #541388 #F1E9DA #FFD400 #D90368} \
	turquoisegray 		{#00b0c5 #09E8DE #dddfe3 #808080 #5E5E5E} \
	greengray 			{#08b233 #a1ff0a #dddfe3 #808080 #5E5E5E} \
	green 				{#57b576 #08b233 #a1ff0a #808080 #5E5E5E} \
	cyber 				{#E36397 #db6800 #e8ff81 #29f0b6 #531253 #938ba1 #ea3788} \
	]

proc palette {id} {
	dict get $::PALETTES $id
}

 # set G(colors)
proc newRibbonColors {} {
	global P
	global G
	
	set palette [palette $P(paletteID)]
	set G(colors) {}
	for {set i 0} {$i < $P(numWaves)} {incr i} {
		set n [randomChoice {2 3 3 3 4}]
		set n [expr {2*$n-1}]
		lappend G(colors) [generateRibbonColors $n $palette]
	}	
}

 # set G(ribbons)  (list of normalized paths)
proc newRibbons {} {
	global P
	global G
	
	foreach path $G(ribbons) { $path destroy }
	set G(ribbons) {}
	for {set i 0} {$i < $P(numWaves)} {incr i} {
		lappend G(ribbons) [newNormalizedRibbonPath $P(numDivisions)]
	}
	newRibbonColors
}

proc drawRibbons {surf} {
	global P
	global G

	lassign [$surf cget -format] width height	
	$surf fill all -style [BL::color white]

	$surf push
	$surf configure -stroke.transformorder BEFORE	

	set dy $height
	set sy [expr {$P(deltaY)*$height/$P(numWaves)}]
	foreach path $G(ribbons) colors $G(colors)  {
		$surf configure -matrix [list $width 0 0 $sy 0 $dy]
		set filterType [expr {$P(shadow) ? "shadow" : "ignore"}]
		$surf filter $filterType -radius 20 -dxy {3 10} {
				drawRibbon $surf $path $colors
		}
		set dy [expr {$dy-$height/$P(numWaves)}]
	}
	$surf pop
}




# ------

# a normalized ribbon goes from x=0.0 to x=1.0
# Y position is 'near 0'
# Y amplitude is among -1 and 1
proc newNormalizedRibbonPath {numDivisions} {
	set numDivisions [expr {$numDivisions+0.0}]
	set randomXoffset [expr {rand()/$numDivisions}]
		set dymin 1.0
		set dymax -1.0

	set path [BL::Path new]
	set i 0
	set P1 [list \
		[expr {$i  / $numDivisions - $randomXoffset}] \
		[expr {map(rand(), 0.0, 1.0, $dymin, $dymax)}] \
		]
	set P1 [list \
		[expr {$i  / $numDivisions - $randomXoffset}] \
		0.0
		]

	set i 1
	set P2 [list \
		[expr {$i / $numDivisions - $randomXoffset}] \
		[expr {map(rand(), 0.0, 1.0, $dymin, $dymax)}] \
	]
	$path moveTo $P1

	for { set i 1} { $i < $numDivisions + 2} {incr i} {
		set P1 $P2
		set P2 [list \
			[expr {($i+1) / $numDivisions - $randomXoffset}] \
			[expr {map(rand(), 0.0, 1.0, $dymin, $dymax)}] \
		]
		set Pm [midPoint $P1 $P2]
		$path quadTo $P1 $Pm
	}

	$path lineTo [list [expr {($numDivisions+2) / $numDivisions - $randomXoffset}] \
 0.0]
	return $path
}


# to do:  discard a color if equal the the previous.
#  black and white should not be among the palette colors..
proc generateRibbonColors {n palette} {
	set darkbg  "#2a1039"
	set stripecolors {}
	for {set i 0} {$i<$n} {incr i} {
		if {$i % 2 == 0} {
			lappend stripecolors [randomChoice $palette]
		} else {
			lappend stripecolors $darkbg
		}
	}
	return $stripecolors
}

# a ribbon with K (symmetric) colors has K 'bands' forming 2K-1 stripes
proc drawRibbon {surf path stripecolors} {
	global P
	lassign [$surf cget -format] width height

	set numStripes [expr {2*[llength $stripecolors]-1}]
	set ribbonWidth [expr {$numStripes/6.0*$height/$P(numWaves)}]

	set s [llength $stripecolors]
	set k [expr {2*$s-1}]
	while {$s > 0} {

		set rwidth [expr { $ribbonWidth / $k * (2*$s-1)}]
		surf configure \
			-stroke.style [BL::color [lindex $stripecolors $s-1]] \
			-stroke.width $rwidth \
			-stroke.cap ROUND
		 # draw striped curve
		$surf stroke $path
		incr s -1
	}
}



package require IKscale	

proc controlPanel {w} {
	global PALETTES
	global P
	
	frame $w -padx 15 -pady 15
	ttk::combobox $w.palette \
		-state readonly \
    	-values [dict keys $PALETTES] \
    	-textvariable P(paletteID)
	
	bind $w.palette <<ComboboxSelected>> { newRibbonColors; drawRibbons surf}

	IKscale $w.numWaves \
		-from 2 -to 20 \
		-labelside right \
		-variable P(numWaves) \
		-command {apply {{args} {newRibbons; drawRibbons surf}}}

	IKscale $w.numDivisions \
		-from 2 -to 20 \
		-labelside right \
		-variable P(numDivisions) \
		-command {apply {{args} {newRibbons; drawRibbons surf}}}

	IKscale $w.deltaY \
		-from 0.0 -to 3.0  -resolution 0.1 \
		-labelside right \
		-variable P(deltaY) \
		-command {apply {{args} {drawRibbons surf}}}


	ttk::checkbutton $w.shadow -variable P(shadow) \
		-command {apply {{args} {drawRibbons surf}}}


	grid [label $w.l_palette -text "palette"]  $w.palette
	grid [label $w.l_numWaves -text "n. of waves"]  $w.numWaves
	grid [label $w.l_numDivisions -text "n. of divisions"]  $w.numDivisions
	grid [label $w.l_numdeltaY -text "amplitude"]  $w.deltaY
	grid [label $w.l_shadow -text "shadow"]  $w.shadow
		
	return $w
}
# --- main --------------------------------------------------------------

 # Parameters
set P(numWaves)  8
set P(numDivisions) 5
set P(deltaY) 1.2
set P(paletteID) "fullrainbow"
set P(shadow) 1 ;# ON


image create blend2d surf -format {1000 500}
label .surf -image surf \
	-borderwidth 0 -highlightthickness 0
pack .surf -expand 1 -fill both



toplevel .cpanel
wm title .cpanel "Control Panel"
wm attributes .cpanel -topmost true 
pack [controlPanel .cpanel.p]

set G(ribbons) {}
set G(colors)  {}
newRibbons

bind .surf <Configure> { 
	surf configure -format {%w %h}
	drawRibbons surf
}

