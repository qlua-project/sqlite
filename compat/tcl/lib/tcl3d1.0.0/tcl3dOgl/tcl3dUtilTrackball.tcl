#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dUtilTrackball.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Simple trackball-like motion adapted (ripped off)
#                       from projtex.c (written by David Yu and David Blythe).
#                       See the SIGGRAPH '96 Advanced OpenGL course notes.
#
#                       Usage overview:
#
#                       Call tcl3dTbInit before any other trackball call.
#                       Call tcl3dTbReshape from the reshape callback.
#                       Call tcl3dTbMatrix to get the trackball matrix rotation.
#                       Call tcl3dTbStartMotion to begin trackball movement.
#                       Call tcl3dTbStopMotion to stop trackball movement.
#                       Call tcl3dTbMotion from the motion callback.
#                       Call tcl3dTbAnimate(1) if you want the trackball to
#                            continue spinning after the mouse button has been
#                            released.
#                       Call tcl3dTbAnimate(0) if you want the trackball to stop
#                            spinning after the mouse button has been released.
#
#                       See ftglDemo.tcl for a real world example.
#
#                       Modified for Tcl3D by Paul Obermeier 2006/02/02
#                       See www.tcl3d.org for the Tcl3D extension. 
#
#******************************************************************************

proc _tcl3dTbGetTimeMS { toglwin } {
    global __tcl3dTB
    return [expr int ([tcl3dLookupSwatch $__tcl3dTB(swatch,$toglwin)] * 10)]
}

proc _tcl3dTbStopIdleFunc { toglwin } {
    global __tcl3dTB
    if { [info exists __tcl3dTB(afterId,$toglwin)] } {
        after cancel $__tcl3dTB(afterId,$toglwin)
    }
}

proc _tcl3dTbAnimate { toglwin } {
    global __tcl3dTB

    tcl3dTrackballAddQuats $__tcl3dTB(lastQuat,$toglwin) \
                           $__tcl3dTB(curQuat,$toglwin) \
                           $__tcl3dTB(curQuat,$toglwin)
    $toglwin postredisplay
    set __tcl3dTB(afterId,$toglwin) [after idle "_tcl3dTbAnimate $toglwin"]
}

###############################################################################
#[@e
#       Name:           tcl3dTbStartMotion - Begin trackball movement
#
#       Synopsis:       tcl3dTbStartMotion { toglwin x y } 
#
#       Description:    toglwin : string
#                       x       : int
#                       y       : int
#
#                       Begin movement of the trackball attached to Togl window
#                       "toglwin".
#                       "x" and "y" give the actual mouse position inside the
#                       Togl window.
#                       This procedure is typically bound to a button press 
#                       event.
#                       Example: bind .toglwin <ButtonPress-1> 
#                                "tcl3dTbStartMotion .toglwin %x %y"
#
#       See also:       tcl3dTbStopMotion
#                       tcl3dTbMotion
#
###############################################################################

proc tcl3dTbStartMotion { toglwin x y } {
    global __tcl3dTB

    _tcl3dTbStopIdleFunc $toglwin
    set __tcl3dTB(tracking,$toglwin) 1
    set __tcl3dTB(lasttime,$toglwin) [_tcl3dTbGetTimeMS $toglwin ]
    set __tcl3dTB(beginx,$toglwin) $x
    set __tcl3dTB(beginy,$toglwin) $y
}

###############################################################################
#[@e
#       Name:           tcl3dTbStopMotion - Stop trackball movement
#
#       Synopsis:       tcl3dTbStopMotion { toglwin } 
#
#       Description:    toglwin : string
#
#                       Stop movement of the trackball attached to Togl window
#                       "toglwin".
#                       This procedure is typically bound to a button release 
#                       event.
#                       Example: bind .toglwin <ButtonRelease-1> 
#                                "tcl3dTbStopMotion .toglwin"
#
#       See also:       tcl3dTbStartMotion
#                       tcl3dTbMotion
#
###############################################################################

proc tcl3dTbStopMotion { toglwin } {
    global __tcl3dTB

    set __tcl3dTB(tracking,$toglwin) 0

    set t [_tcl3dTbGetTimeMS $toglwin ]
    if { ($t == $__tcl3dTB(lasttime,$toglwin)) && \
         $__tcl3dTB(animate,$toglwin) } {
        _tcl3dTbAnimate $toglwin
    } else {
        _tcl3dTbStopIdleFunc $toglwin
    }
}

###############################################################################
#[@e
#       Name:           tcl3dTbAnimate - Set the trackball animation mode.
#
#       Synopsis:       tcl3dTbAnimate { toglwin animate }
#
#       Description:    toglwin : string
#                       animate : bool
#
#                       Set the animation mode of the trackball attached to
#                       Togl window "toglwin".
#                       If the trackball shall continue spinning after the
#                       mouse button has been released, set "animate" to true.
#                       Set "animate" to false, if the trackball should stop
#                       spinning after the mouse button has been released.
#
#       See also:       tcl3dTbStartMotion
#
###############################################################################

proc tcl3dTbAnimate { toglwin animate } {
    global __tcl3dTB

    set __tcl3dTB(animate,$toglwin) $animate
}

###############################################################################
#[@e
#       Name:           tcl3dTbInit - Initialize the trackball module.
#
#       Synopsis:       tcl3dTbInit { toglwin }
#
#       Description:    toglwin : string
#
#                       Initialize the trackball attached to Togl window
#                       "toglwin".
#                       This procedure must be called before any other trackball
#                       procedures, for example in the Togl create callback.
#
#       See also:
#
###############################################################################

proc tcl3dTbInit { toglwin } {
    global __tcl3dTB

    set __tcl3dTB(swatch,$toglwin) [tcl3dNewSwatch]
    tcl3dStartSwatch $__tcl3dTB(swatch,$toglwin)
    set __tcl3dTB(lasttime,$toglwin) [_tcl3dTbGetTimeMS $toglwin]
    set __tcl3dTB(tracking,$toglwin) 0
    set __tcl3dTB(animate,$toglwin)  1
    set __tcl3dTB(curQuat,$toglwin)  [tcl3dVector GLfloat 4]
    set __tcl3dTB(lastQuat,$toglwin) [tcl3dVector GLfloat 4]
    tcl3dTrackball $__tcl3dTB(curQuat,$toglwin) 0.0 0.0 0.0 0.0
}

###############################################################################
#[@e
#       Name:           tcl3dTbMatrix - Use the trackball matrix rotation
#
#       Synopsis:       tcl3dTbMatrix { toglwin }
#
#       Description:    toglwin : string
#
#                       Use the rotation matrix of the trackball attached to
#                       Togl window "toglwin". 
#                       The rotation matrix is applied to the top most OpenGL
#                       matrix with glMultMatrixf.
#                       This procedure is typically called in the Togl display
#                       callback.
#
#       See also:
#
###############################################################################

proc tcl3dTbMatrix { toglwin } {
    global __tcl3dTB

    set m [tcl3dVector GLfloat 16]
    tcl3dTrackballBuildRotMatrix $m $__tcl3dTB(curQuat,$toglwin)
    set ml [tcl3dVectorToList $m 16]
    glMultMatrixf $ml
    $m delete
}

###############################################################################
#[@e
#       Name:           tcl3dTbReshape - Notify trackball about a reshape.
#
#       Synopsis:       tcl3dTbReshape { toglwin w h }
#
#       Description:    toglwin : string
#                       w       : int
#                       h       : int
#
#                       Notify the trackball attached to Togl window "toglwin"
#                       that the size of the window has been changed to 
#                       width "w" and height "h".
#                       This procedure is typically called in the Togl reshape
#                       callback.
#
#       See also:       tcl3dTbInit
#
###############################################################################

proc tcl3dTbReshape { toglwin w h } {
    global __tcl3dTB

    set __tcl3dTB(width,$toglwin)  $w
    set __tcl3dTB(height,$toglwin) $h
}

###############################################################################
#[@e
#       Name:           tcl3dTbMotion - Move the trackball.
#
#       Synopsis:       tcl3dTbMotion { toglwin x y }
#
#       Description:    toglwin : string
#                       x       : int
#                       y       : int
# 
#                       Move the trackball attached to Togl window "toglwin".
#                       "x" and "y" give the actual mouse position inside the
#                       Togl window.
#                       This procedure is typically bound to a mouse motion  
#                       event.
#                       Example: bind .toglwin <B1-Motion> 
#                                "tcl3dTbMotion .toglwin %x %y"
#
#       See also:       tcl3dTbStartMotion
#                       tcl3dTbStopMotion
#
###############################################################################

proc tcl3dTbMotion { toglwin x y } {
    global __tcl3dTB

    if { $__tcl3dTB(tracking,$toglwin) } {
        set __tcl3dTB(lasttime,$toglwin) [_tcl3dTbGetTimeMS $toglwin]
        set w  $__tcl3dTB(width,$toglwin)
        set h  $__tcl3dTB(height,$toglwin)
        set bx $__tcl3dTB(beginx,$toglwin)
        set by $__tcl3dTB(beginy,$toglwin)
        tcl3dTrackball $__tcl3dTB(lastQuat,$toglwin) \
                       [expr {(2.0 * $bx - $w) / $w}] \
                       [expr {($h - 2.0 * $by) / $h}] \
                       [expr {(2.0 * $x - $w)  / $w}] \
                       [expr {($h - 2.0 * $y)  / $h}]
        set __tcl3dTB(beginx,$toglwin) $x
        set __tcl3dTB(beginy,$toglwin) $y
        tcl3dTrackballAddQuats $__tcl3dTB(lastQuat,$toglwin) \
                               $__tcl3dTB(curQuat,$toglwin) \
                               $__tcl3dTB(curQuat,$toglwin)
        $toglwin postredisplay
    }
}
