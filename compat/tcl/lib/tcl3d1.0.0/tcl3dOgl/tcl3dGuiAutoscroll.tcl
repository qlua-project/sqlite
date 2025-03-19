#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#                       2003 Kevin B Kenny <kennykb@users.sourceforge.net>
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dGuiAutoscroll.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module to create scroll bars that automatically
#                       appear when a window is too small to display its
#                       content.
#
#******************************************************************************

namespace eval ::tcl3dAutoscroll {
    namespace export autoscroll unautoscroll
    bind Autoscroll <Destroy> [namespace code [list destroyed %W]]
    bind Autoscroll <Map> [namespace code [list map %W]]
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::autoscroll - Create auto scrollbar
#
#       Synopsis:       tcl3dAutoscroll::autoscroll { w }
#
#       Description:    w : string (Widget name)
#
#                       Create a scroll bar that disappears when it is not
#                       needed, and reappears when it is.
#                       The scroll bar "w" should already exist.
#
#                       Side effects:
#                       The widget command is renamed, so that the 'set' command
#                       can be intercepted and determine whether the widget
#                       should appear.
#                       In addition, the 'Autoscroll' bind tag is added to the
#                       widget, so that the <Destroy> event can be intercepted.
#
#       See also:       tcl3dAutoscroll::unautoscroll
#
###############################################################################

proc ::tcl3dAutoscroll::autoscroll { w } {
    if { [info commands ::tcl3dAutoscroll::renamed$w] != "" } { return $w }
    rename $w ::tcl3dAutoscroll::renamed$w
    interp alias {} ::$w {} ::tcl3dAutoscroll::widgetCommand $w
    bindtags $w [linsert [bindtags $w] 1 Autoscroll]
    eval [list ::$w set] [renamed$w get]
    return $w
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::unautoscroll - Remove scrollbar from
#                       package control.
#
#       Synopsis:       tcl3dAutoscroll::unautoscroll { w }
#
#       Description:    w : string (Widget name)
#
#                       Return a scrollbar to its normal static behavior by
#                       removing it from the control of this package.
#
#                       "w" is the path name of the scroll bar, which must have
#                       previously had tcl3dAutoscroll::autoscroll called on it.
#
#                       Side effects:
#                       The widget command is renamed to its original name. 
#                       The widget is mapped if it was not currently displayed.
#                       The widgets bindtags are returned to their original state.
#                       Internal memory is cleaned up.
#
#       See also:       tcl3dAutoscroll::autoscroll
#
###############################################################################

proc ::tcl3dAutoscroll::unautoscroll { w } {
    if { [info commands ::tcl3dAutoscroll::renamed$w] != "" } {
        variable grid
        rename ::$w {}
        rename ::tcl3dAutoscroll::renamed$w ::$w
        if { [set i [lsearch -exact [bindtags $w] Autoscroll]] > -1 } {
            bindtags $w [lreplace [bindtags $w] $i $i]
        }
        if { [info exists grid($w)] } {
            eval [join $grid($w) \;]
            unset grid($w)
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::widgetCommand - Apply a widget command.
#
#       Synopsis:       tcl3dAutoscroll::widgetCommand { w command args }
#
#       Description:    w       : string (Widget name)
#                       command : string
#                       args    : argument list
#
#                       Apply widget command "command" on 'autoscroll' scrollbar
#                       "w". Arguments to the commands can be supplied in "args".
#                       Return whatever the widget command returns.
#
#                       Side effects:
#                       Has whatever side effects the widget command has. In
#                       addition, the 'set' widget command is handled specially,
#                       by gridding/packing the scroll bar according to whether
#                       it is required.
#
#       See also:       
#
###############################################################################

proc ::tcl3dAutoscroll::widgetCommand { w command args } {
    variable grid
    if { $command == "set" } {
        foreach { min max } $args {}
        if { $min <= 0 && $max >= 1 } {
            switch -exact -- [winfo manager $w] {
                grid {
                    lappend grid($w) "[list grid $w] [grid info $w]"
                    grid forget $w
                }
                pack {
                    foreach x [pack slaves [winfo parent $w]] {
                        lappend grid($w) "[list pack $x] [pack info $x]"
                    }
                    pack forget $w
                }
            }
        } elseif { [info exists grid($w)] } {
            eval [join $grid($w) \;]
            unset grid($w)
        }
    }
    return [eval [list renamed$w $command] $args]
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::destroyed - Destroy callback.
#
#       Synopsis:       tcl3dAutoscroll::destroyed { w }
#      
#       Description:    w : string (Widget name) 
#
#                       Callback executed when automatic scroll bar "w" is
#                       destroyed.
#
#                       Side effects:
#                       Cleans up internal memory.
#
#       See also:       tcl3dAutoscroll::map
#
###############################################################################

proc ::tcl3dAutoscroll::destroyed { w } {
    variable grid
    catch { unset grid($w) }
    rename ::$w {}
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::map - Mapping callback.
#
#       Synopsis:       tcl3dAutoscroll::map { w }
#
#       Description:    w : string (Widget name)
#
#                       Callback executed when automatic scroll bar "w" is mapped.
#
#                       Side effects:
#                       Geometry of scroll bar's top-level window is constrained.
#
#                       This procedure keeps the top-level window associated with
#                       an automatic scroll bar from being resized automatically
#                       after the scroll bar is mapped. This effect avoids a
#                       potential endless loop in the case where the resize of the
#                       top-level window resizes the widget being scrolled,
#                       causing the scroll bar no longer to be needed.
#
#       See also:       tcl3dAutoscroll::destroyed
#
###############################################################################

proc ::tcl3dAutoscroll::map { w } {
    wm geometry [winfo toplevel $w] [wm geometry [winfo toplevel $w]]
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::wrap - Autoscroll all new scrollbars.
#
#       Synopsis:       tcl3dAutoscroll::wrap {}
#
#       Description:    Arrange for all new scrollbars to be automatically 
#                       autoscrolled.
#
#                       Side effects:
#                       ::scrollbar is overloaded to automatically autoscroll
#                       any new scrollbars.
#
#       See also:       tcl3dAutoscroll::unwrap
#
###############################################################################

proc ::tcl3dAutoscroll::wrap {} {
    if {[info commands ::tcl3dAutoscroll::_scrollbar] != ""} {return}
    rename ::scrollbar ::tcl3dAutoscroll::_scrollbar
    proc ::scrollbar {w args} {
        eval ::tcl3dAutoscroll::_scrollbar [list $w] $args
        ::tcl3dAutoscroll::autoscroll $w
        return $w
    }
}

###############################################################################
#[@e
#       Name:           tcl3dAutoscroll::unwrap - Turn off automatic
#                       autoscrolling of new scrollbars.
#
#       Synopsis:       tcl3dAutoscroll::unwrap {}
#
#       Description:    Turn off automatic autoscrolling of new scrollbars.
#                       Does not effect existing scrollbars.
#
#                       Side effects:
#                       ::scrollbar is returned to its original state
#
#       See also:       tcl3dAutoscroll::wrap
#
###############################################################################

proc ::tcl3dAutoscroll::unwrap {} {
    if {[info commands ::tcl3dAutoscroll::_scrollbar] == ""} {return}
    rename ::scrollbar {}
    rename ::tcl3dAutoscroll::_scrollbar ::scrollbar
}
