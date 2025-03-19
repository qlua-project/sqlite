#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dGuiToolhelp.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module implementing a simple tool help widget.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dToolhelpInit - Initialize toolhelp module.
#
#       Synopsis:       tcl3dToolhelpInit { w { bgColor yellow }
#                       { fgColor black } }
#
#       Description:    w        : string (Widget name)
#                       bgColor  : string
#                       fgColor  : string
#
#                       Initialize the toolhelp module.
#                       The initialization function only needs to be called
#                       when non-standard background and foreground colors 
#                       are needed.
#
#       See also:       tcl3dToolhelpAddBinding
#
###############################################################################

proc tcl3dToolhelpInit { w { bgColor yellow } { fgColor black } } {
    global __tcl3dToolhelpWidget

    # Create Toolbar help window with a simple label in it.
    if { [winfo exists $w] } {
        destroy $w
    }
    toplevel $w
    set __tcl3dToolhelpWidget $w
    label $w.l -text "Toolhelp" -bg $bgColor -fg $fgColor -relief ridge
    pack $w.l
    wm overrideredirect $w true
    if {[tcl3dHaveAqua]}  {
        ::tk::unsupported::MacWindowStyle style $w help none
    }
    wm geometry $w [format "+%d+%d" -100 -100]
}

###############################################################################
#[@e
#       Name:           tcl3dToolhelpShow - Display toolhelp message.
#
#       Synopsis:       tcl3dToolhelpShow { x y str }
#
#       Description:    x   : int
#                       y   : int
#                       str : string
#
#                       Display the toolhelp window at widget relative
#                       coordinates (x, y) with message string "str".
#
#                       A typical usage is like follows:
#                       bind $w <Enter> "tcl3dToolhelpShow %X %Y [list $str]"
#
#       See also:       tcl3dToolhelpHide
#                       tcl3dToolhelpAddBinding
#
###############################################################################

proc tcl3dToolhelpShow { x y str } {
    global __tcl3dToolhelpWidget

    $__tcl3dToolhelpWidget.l configure -text $str
    raise $__tcl3dToolhelpWidget
    set labelWidth [winfo width $__tcl3dToolhelpWidget.l]
    wm geometry $__tcl3dToolhelpWidget \
                [format "+%d+%d" [expr {$x - $labelWidth/2}] [expr {$y +10}]]
}

###############################################################################
#[@e
#       Name:           tcl3dToolhelpHide - Hide toolhelp message.
#
#       Synopsis:       tcl3dToolhelpHide {}
#
#       Description:    Hide the toolhelp message window.
#
#       See also:       tcl3dToolhelpShow
#                       tcl3dToolhelpAddBinding
#
###############################################################################

proc tcl3dToolhelpHide {} {
    global __tcl3dToolhelpWidget

    wm geometry $__tcl3dToolhelpWidget [format "+%d+%d" -100 -100]
}

###############################################################################
#[@e
#       Name:           tcl3dToolhelpAddBinding - Add binding for a toolhelp
#                       message.
#
#       Synopsis:       tcl3dToolhelpAddBinding { w str }
#
#       Description:    w   : string (Widget name)
#                       str : string
#
#                       Add bindings to widget "w" to display message string
#                       "str" in a toolhelp window near the widget. The 
#                       toolhelp window is shown, when the mouse enters the
#                       widget and unmapped, when the mouse leaves the widget.
#
#       See also:       tcl3dToolhelpInit
#
###############################################################################

proc tcl3dToolhelpAddBinding { w str } {
    global __tcl3dToolhelpWidget

    if { ![info exists __tcl3dToolhelpWidget]} {
        tcl3dToolhelpInit .tcl3dToolhelp
    }
    bind $w <Enter>  "tcl3dToolhelpShow %X %Y [list [string map {% %%} $str]]"
    bind $w <Leave>  "tcl3dToolhelpHide"
    bind $w <Button> "tcl3dToolhelpHide"
}
