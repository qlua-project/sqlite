# --sample101a - Contour subdivision - demo

set thisDir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file dirname $thisDir]]

 # Press <F1> for the developer backdoor (Windows-only) ..
bind . <F1> { catch { console show } }

package require Blend2d

proc bboxToRect { bb } {
	lassign $bb x0 y0 x1 y1
	return [list $x0 $y0 [expr {$x1-$x0}] [expr {$y1-$y0}]]
}

 # return true if bbox has width or height <= 0
proc emptybbox {bbox} {
	lassign $bbox x0 y0 x1 y1
	expr {$x0>=$x1 || $y0>=$y1}
}

 # transform rectA (scale, translate) so that it fits into rectB
 # NOTE: raise an error if rectA has both width and height equal to 0
proc fitRect { rectA rectB } {
	lassign $rectA xA yA dxA dyA
	lassign $rectB xB yB dxB dyB
	
	set ratio [expr {min(double($dxB)/$dxA,double($dyB)/$dyA)}]
	
	set dxA [expr {$dxA*$ratio}]
	set dyA [expr {$dyA*$ratio}]
	
	set xA [expr {$xB+($dxB-$dxA)/2.0}]
	set yA [expr {$yB+($dyB-$dyA)/2.0}]
	return [list $xA $yA $dxA $dyA]
}

 # create a BLPath with a small arrow shape:
 #  origin in (0,0), length $len, oriented at 0 degrees
proc newArrow {len} {
	set arrowObj [BL::Path new]
    $arrowObj moveTo {0 0}
    set arrowEnd [list $len 0]
    $arrowObj lineTo $arrowEnd
    $arrowObj lineTo [list [expr {$len-3}] 2]
    $arrowObj lineTo [list [expr {$len-3}] -2]
    $arrowObj lineTo $arrowEnd
    $arrowObj close
    return $arrowObj
}

proc draw {sfc path} {
	global G
	global PARAM
	lassign [$sfc size] WIDTH HEIGHT

	 # -- clear $sfc and set some $sfc attributes
	$sfc configure -stroke.style [BL::color gray20]
	$sfc clear -fill.style [BL::color gray90]

	set HALF_WIDTH [expr {$WIDTH/2}]
	 # destination rect ; path should be 'framed' in this rect
	set m 20 ;# margin
	set frameRect [list $m $m [expr {$HALF_WIDTH-2*$m}] [expr {$HEIGHT-2*$m}]]
	
	set bbox [$path bbox]
	if {[emptybbox $bbox]} return ;# --- nothing to draw

	set rectA [bboxToRect $bbox]	
	# scale and fit $path in the frameRect
	$path fitTo [fitRect [bboxToRect $bbox] $frameRect ]
	
$sfc push
	set arrow [newArrow 20]

# note: this catch (or try) is just to be sure that in case of errors
# the surface-stack, the temporary arrow and gpath are properly 'closed'
	catch {
		# == left panel - t-subdivision ===
		 # move the origin 100 pixel down
		$sfc stroke [BL::rect {*}$frameRect] -style 0xffff0000

		$sfc fill $path -style 0x80808080
		$sfc stroke $path				
		markupCurves $sfc $path
		if { $PARAM(show) } {
			drawContours $sfc $path $arrow [list t-subdivision $PARAM(SUBDIVISION) normalAt]
		}
		# == right panel - l-subdivision ===
		 # move the origin HALF_WIDTH
		$sfc applyTransform [Mtx::translation $HALF_WIDTH 0]
		$sfc stroke [BL::rect {*}$frameRect] -style 0xffff0000

		$sfc fill $path -style 0x80808080
		$sfc stroke $path				
		markupCurves $sfc $path
		if { $PARAM(show) } {
			drawContours $sfc $path $arrow [list l-subdivision $PARAM(SUBDIVISION) normalAt]
		}
	}
$sfc pop
	$arrow destroy
}

proc markupCurves {sfc pathObj} {
	$sfc configure -fill.style [BL::color black 0.7]

    set nC [$pathObj contours count]
    for {set i 0} {$i<$nC} {incr i} {
    	 # start of the 0-th b-curve
    	set P [$pathObj contour $i 0 at 0.0]
		$sfc fill [BL::circle $P 6.0]	            
		foreach P [$pathObj contour $i * at 1.0] {
			$sfc fill [BL::circle $P 6.0]	            
        }        
    }
}

proc drawContours {sfc pathObj arrowObj subdivisionTypeAndargs} {
	$sfc configure -fill.style [BL::color red 0.7]
	$sfc configure -stroke.style [BL::color green 0.8]
		
    set nC [$pathObj contours count]
    for {set i 0} {$i<$nC} {incr i} { 
		foreach PN [$pathObj contour $i {*}$subdivisionTypeAndargs] {
			lassign $PN P N
			drawArrow $sfc $arrowObj $P $N
        }
    }
}

proc ::tcl::mathfunc::isNaN {x} {expr {$x!=$x}}

 # --- draw an arrow at P with direction N
 # WARNING: tangents and normal could be undefined when the curve is degenere-
 #  You must always check if it's NaN
proc drawArrow {sfc arrow P N } {
	$sfc fill [BL::circle $P 5.0]	            
	 # WARNING:  N could be {NaN,NaN}
	lassign $N dx dy
		if { !isNaN($dx) && !isNaN($dy) } {
		 # T is a rotation and a translation
		set T [list $dx $dy [expr {-$dy}] $dx {*}$P]
		$sfc stroke $arrow -transformation $T
	} 
}

proc onKeyPressed {sfc key} {
	global G

	if {$key eq "Up"} {
		set G(GLYPHIDX) [expr {($G(GLYPHIDX)+1)%$G(MAX_GLYPHIDX)}]
	} elseif {$key eq "Down"} {
		set G(GLYPHIDX) [expr {($G(GLYPHIDX)-1)%$G(MAX_GLYPHIDX)}]
	} else {
		if { [string length $key] != 1 } { bell ; return }
		
		set gIdx [$G(FONT) glyphs $key]
		if { $gIdx == 0 }  { bell ; return }
		
		set G(GLYPHIDX) $gIdx
	}
	set G(STATUSMSG) "glyph #$G(GLYPHIDX)"
	
	 # -- store the glyph in a NEW G(path)
    catch {$G(path) destroy}
	set G(path) [$G(FONT) glyph $G(GLYPHIDX)]
	draw $sfc $G(path)
}


 # === setup: surface, FONT
global G

set WIDTH 1200
set HEIGHT 600
set sfc [image create blend2d -format [list $WIDTH $HEIGHT]]
label .cvs -image $sfc ; pack .cvs -expand 1 -fill both
focus .cvs
label .topbar -textvariable G(TOPBARMSG)
pack .topbar -side top -before .cvs
label .statusbar -textvariable G(STATUSMSG)
pack .statusbar -side bottom -before .cvs

bind .cvs <Any-Key> { 
	onKeyPressed $sfc %K
}

 # side effect:
 #  set G(FONT), .....
proc setFont {filename} {
	global G
	try {
		catch {$G(FONT) destroy}
		set fontFace [BL::FontFace new $filename]
		set maxIdx [dict get [$fontFace details] "glyphCount"]
		set font [BL::Font new $fontFace 50.0] ; # don't care for the font size ... it will be scaled
		 # .. if no error ..
		set G(MAX_GLYPHIDX) $maxIdx
		set G(TOPBARMSG) "[file tail $filename] -- $maxIdx glyphs"	
		set G(FONT) $font
	} on error e {
		tk_messageBox -icon error -title "Font Error"\
			-message "Error loading [file tail $filename]" -detail $e
	} finally {
		catch {$fontFace destroy}
	}	
}

proc chooseFont {} {
	set filename [tk_getOpenFile -title "Choose a font-file"]
	if { $filename ne {} } {
		setFont $filename
	}
}

set PARAM(show) 1
set PARAM(SUBDIVISION) 20

proc controlPanel {w} {
	global PARAM
	frame $w -padx 10 -pady 10

set topMsg {\
Hit a key or press the up/down arrows
for another glyph
}
set msg0 {\
Each contour is made of several chained Bezier's curves.
(black dots indicates the start of each curve)
}	
set msg1 {\
On the left side: T-Subdivision
Each contour is traversed following the equation B(t) 
of each curve with constant steps dt.
The subdivision is denser in shorter curves
or when the curvature is greater.
}
	
set msg2 {\
On the right side: L-Subdivision
Each contour is subdivided in N parts
having the same length
}

	grid [label $w.l_topmsg -text $topMsg]
	grid [label $w.l_msg0 -text $msg0]

	grid [ttk::separator $w.sep_0] -sticky ew
	frame $w.sub
		ttk::checkbutton $w.sub.show -variable PARAM(show)
		ttk::scale       $w.sub.parts -variable PARAM(SUBDIVISION) \
			-from 1 -to 100
		grid $w.sub.show   [label $w.sub.l_show -text "Show Subdivision"]
		grid $w.sub.parts  [label $w.sub.l_parts -text "n.of parts"]
	grid $w.sub
	grid [ttk::separator $w.sep_1] -sticky ew
	grid [label $w.l_msg1 -text $msg1]
	grid [label $w.l_msg2 -text $msg2]

	grid [ttk::separator $w.sep_3] -sticky ew
	grid [ttk::button $w.font -text "Change Font..." -command "chooseFont"]


	$w.l_topmsg configure -font {-weight bold}

trace add variable PARAM(show) write [list apply {
	{args} { draw $::sfc  $::G(path) }
	}]

trace add variable PARAM(SUBDIVISION) write [list apply {
	{args} {
	global PARAM
	set PARAM(SUBDIVISION) [expr {int($PARAM(SUBDIVISION))}]
	draw $::sfc $::G(path)
	}}]

trace add variable G(FONT) write [list apply {
	{args} { onKeyPressed $::sfc "Up" }
	}]

	return $w
}

# -- control panel -----
toplevel .cp ; wm attributes .cp -topmost true
wm resizable .cp 0 0
wm protocol .cp WM_DELETE_WINDOW {;}  ;# never close this window
wm title .cp "Contours Subdivision"
pack [controlPanel .cp.panel]

 # initial glyph 
setFont "$thisDir/Blacksword.otf"

onKeyPressed $sfc "P"

update 

bind .cvs <Configure> {
	$sfc configure -format [list %w %h]
	draw $sfc $G(path)
}

#$G(FONT) destroy
