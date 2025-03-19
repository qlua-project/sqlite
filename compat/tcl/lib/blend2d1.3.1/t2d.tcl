# t2d.tcl
#
# Class definitions for the Tcl->Blend2D (t2d) integration
#

package require Mtx 1.1
package require HSB 1.0

namespace eval  BL {
	variable FontDir
	  # take into account not the 'devkit' tree, but the deployed package tree.
	set FontDir [file join [file normalize [file dirname [info script]]] "fonts"]
}

proc BL::_findDLL {dir pkgName} {
	set thisDir [file normalize ${dir}]

	set os $::tcl_platform(platform)
	switch -- $os {
		windows { set os win }
		unix    {
			switch -- $::tcl_platform(os) {
				Darwin { set os darwin }
				Linux  { set os linux  }
			}
		}
	}
	set majorVersion [lindex [split [package present Tcl] "."] 0]
	switch -- $majorVersion {
		8 {set vtag "86"}
		9 {set vtag "90"}
		default { error "tclBlend2d: Unsupported Tcl version" }
	}
	switch -- $pkgName {
	  Blend2d -
	  tkBlend2d {
		set libName "tkb2d"
	  }
		tclBlend2d {
		set libName "tclb2d"
	  }
	  default {
		error "Unregistered package name \"$pkgName\""
	  }
	}

	set tail_libFile ${libName}${vtag}[info sharedlibextension]
	 # try to guess the tcl-interpreter architecture (32/64 bit)
	set arch $::tcl_platform(pointerSize)
	switch -- $arch {
		4 { set arch x32  }
		8 { set arch x64 }
		default { error "${pkgName}: Unsupported architecture: Unexpected pointer-size $arch!!! "}
	}
	set dir_libFile [file join $thisDir ${os}-${arch}]
	if { ! [file isdirectory $dir_libFile ] } {
		error "${pkgName}: Unsupported platform ${os}-${arch}"
	}

	set full_libFile [file join $dir_libFile $tail_libFile]
    return $full_libFile
}

 # this proc is an 'internal' proc called from the "C" T2dSvgDoc_Setup initialization procedure
proc BL::_DefaultFonts_init {} {
	variable FontDir
	# Arial is not freely distributable loadsvgfonts [file join $FontDir "arial.ttf"]

	switch -- $::tcl_platform(platform) {
		windows {
				set fonts {
				"c:/Windows/Fonts/arial.ttf"
				"c:/Windows/Fonts/calibri.ttf"
				"c:/Windows/Fonts/cour.ttf"
				"c:/Windows/Fonts/times.ttf"
				"c:/Windows/Fonts/verdana.ttf"
				}
		}
		unix    {
			switch -- $::tcl_platform(os) {
				Darwin {
					set fonts {
					"Library/Fonts/Courier.ttc"
					"Library/Fonts/Helvetica.ttc"
					"Library/Fonts/Times.ttc"
					}
				}
				Linux  {
					set fonts {
					"/usr/share/fonts/truetype/freefont/FreeSans.ttf"
					"/usr/share/fonts/truetype/freefont/FreeSerif.ttf"
					}
				}
			}
		}
		default { set fonts {} }
	}
	foreach font $fonts {
		if {[file readable $font]} { 
			# ignore errors, try to load all fonts ..
			catch {loadsvgfonts $font}
		}
	}
}


namespace eval BL {
	oo::class create COMMON_METHODS {
		 # return the (sorted) list of current instances
		method names {} {
			lsort [info class instances [lindex [info level 0] 0]]
		}
	}

	variable _classes
	 # precompute _classes
	foreach clazz {Surface Path FontFace Font Svgdoc} {
		lappend _classes [namespace current]::$clazz
		::oo::class create $clazz {
		    # Constructor and methods are written in C
		}
		 # add the "names" typemethod 
		oo::objdefine $clazz {mixin COMMON_METHODS}
	}
	unset clazz

	proc classes {} {
		variable _classes
		return $_classes
	}

	proc classinfo {obj} {
		info object class $obj
	}

}

 # ------------------------------------------
 # some helper methods for class BL::Surface 
 # ------------------------------------------

package require BL::Filter

 # KNOWN LIMITS:
 #   Only the Surface object is cloned; if the original Surface is linked to
 #   a tk-image (of type "blend2d"), the new Surface will be devoid of it. 
 #   See CloneB2dProc in t2d_Surface.cxx 
::oo::define BL::Surface method dup {} {
	oo::copy [self]
} 

::oo::define BL::Surface method clear {args} {
	my fill all {*}$args
} 

::oo::define BL::Surface method size {} {
	lrange [my cget -format] 0 1
} 

	# rawcopy is similar to "copy".
	# The only diff is that with "rawcopy" the destination area is not
	# rotated/scaled by the current transformation matrix.
	#   i.e any geometry transformation is ignored
	# 
oo::define BL::Surface method rawcopy {fromSurf args} {
	set metamtx [my cget -metamatrix]
	set usermtx [my cget -matrix]

	my push
	my configure -matrix [Mtx::invert $metamtx]
	my userToMeta
	 # now meta-matrix and user-matrix are the Identity matrix
	try {		
		my copy $fromSurf -compop SRC_OVER {*}$args
	} finally {
		my pop
	}
}


 # ------------------------------------------
 # some helper methods for class BL::Path 
 # ------------------------------------------

::oo::define BL::Path method dup {} {
	oo::copy [self]
}
package require BL::SVG

::oo::define BL::Path method addSVGpath {dataStr} {
	BL::SVG::buildBLPathFromSVGPathD [self] $dataStr
}

 # ====================================================================
 # General rules:
 # All the following procs will build a standard representation for
 #  some geometric entities.
 # This representation is a list with 2 elems:
 #   a 'type'  (expressed with a keyword *matching ENUM_TABLE(GEOMETRIC_TYPES)*)
 #   a list  enclosing all the required parameters
 # ====================================================================

 # build a BOXD
 #  box P0 P1
proc BL::box {P0 P1} {
	list BOXD [list $P0 $P1]
}

 # build a RECTD
 #  rect x y w h
proc BL::rect {x y w h} {
	list RECTD [list $x $y $w $h]
}

# build an ROUND_RECT
#  roundrect x0 y0 w h rx ?ry?
proc BL::roundrect {x y w h rx {ry {}}} {
	if {$ry eq {}} { set ry $rx }
	list ROUND_RECT [list $x $y $w $h $rx $ry]
}

# build a CIRCLE
#  circle C radius
proc BL::circle {C r} {
	list CIRCLE [list $C $r]
}

# build an ELLIPSE
#  ellipse C rx ry
proc BL::ellipse {C rx ry} {
	list ELLIPSE [list $C $rx $ry]
}

# build an ARC
#  arc C  rx ry start sweep
proc BL::arc {C rx ry start sweep} {
	list ARC [list $C $rx $ry $start $sweep]
}

# build a CHORD
#  chord C  rx ry start sweep
proc BL::chord {C rx ry start sweep} {
	list CHORD [list $C $rx $ry $start $sweep]
}

# build a PIE
#  pie C  rx ry start sweep
proc BL::pie {C rx ry start sweep} {
	list PIE [list $C $rx $ry $start $sweep]
}	

proc BL::line {P0 P1} {
	list LINE [list $P0 $P1]
}

# build a POLYLINED
#  polyline P0 P1 ? ... Pn?
proc BL::polyline { args } {
	list POLYLINED $args
}

proc BL::polygon { args } {
	list POLYGOND $args
}

proc BL::text { xy font string args } {
    list XTEXT [list $xy $font $string {*}$args]
}

proc BL::textbox {xy font string args} {
	if { ! [info object isa object $font] || [info object class $font] ne "::BL::Font" } {
		error "\"$font\" is not a BL::Font object"
	}
	set bbox [$font textbox $xy $string {*}$args]
	lassign $bbox x0 y0 x1 y1
	list BOXD [list [list $x0 $y0] [list $x1 $y1]]
}

proc BL::spline { args } {
	list XSPLINE $args
}

# ----------------------------------------------------------------------------
# the following are not geometric entities , they are graphics entities ...
# ----------------------------------------------------------------------------

proc BL::rgb {R G B {alpha 1.0}} {
	if { $alpha < 0.0 } { set alpha 0.0 }
	if { $alpha > 1.0 } { set alpha 1.0 }
	set hexAlpha [expr {int(255*$alpha)}] 

	expr {($hexAlpha<<24) | ($R&0xFF)<<16 | ($G&0xFF)<<8 | ($B&0xFF) }
}

  # no check on arguments; they will be checked when used 
  # in -fill.style ... -fill.stroke
proc BL::pattern { surfaceOrFilename args } {
	list PATTERN $surfaceOrFilename {*}$args
}

  # no check on arguments; they will be checked when used 
  # in -fill.style ... -fill.stroke
proc BL::gradient { type values stopList args } {
	list GRADIENT $type $values $stopList {*}$args
}
