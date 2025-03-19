#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dGuiWidgets.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module implementing some simple Tk widgets like
#                       scrolled listboxes and text widgets, as well as
#                       some widget and window handling utilities.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dHaveAqua - Check, if windowing system is Aqua. 
#
#       Synopsis:       tcl3dHaveAqua {}
#
#       Description:    Return true, if the windowing system is Apple's Aqua.
#                       Otherwise return false.
#
#       See also:       tcl3dShowIndicator
#
###############################################################################

proc tcl3dHaveAqua {} {
    if { [tk windowingsystem] eq "aqua" } {
        return true
    } else {
        return false
    }
}

###############################################################################
#[@e
#       Name:           tcl3dShowIndicator - Check, if button indicators 
#                       should be shown.
#
#       Synopsis:       tcl3dShowIndicator {}
#
#       Description:    Return true, if we want to show the indicators for
#                       radio- and checkbuttons. Currently we do this on a Mac
#                       running Aqua, because it looks very buggy otherwise.
#
#       See also:       tcl3dHaveAqua
#
###############################################################################

proc tcl3dShowIndicator {} {
    if { [tcl3dHaveAqua] } {
        return true
    } else {
        return false
    }
}

###############################################################################
#[@e
#       Name:           tcl3dAfterIdle - Workaround for after idle command.
#
#       Synopsis:       tcl3dAfterIdle { cmd args }
#
#       Description:    cmd : string
#                       args: Variable argument list
#
#                       Command "cmd" with optional arguments "args" is executed
#                       in an "after idle" callback.
#                       The after idle callbacks are typically used in Tcl3D
#                       scripts to implement animations.
#                       On the Mac the after idle usage causes problems
#                       (freezing the application) when resizing the window.
#                       This procedure implements a workaround for these Mac
#                       related problems. For all other platforms this procedure
#                       is just a wrapper for the standard "after idle" command.
#
#                       Return the callback id, which can be used in an
#                       "after cancel" callback.
#
#       See also:
#
###############################################################################

proc tcl3dAfterIdle { cmd args } {
    if { $::tcl_platform(os) eq "Darwin" } {
        update idletasks
        set idleId [after 1 $cmd $args]
    } else {
        set idleId [after idle $cmd $args]
    }
    return $idleId
}

###############################################################################
#[@e
#       Name:           tcl3dAddEvents - Add virtual events.
#
#       Synopsis:       tcl3dAddEvents {}
#
#       Description:    Add the following virtual events for cross-platform
#                       mouse event handling:
#                       <<LeftMousePress>>
#                       <<MiddleMousePress>>
#                       <<RightMousePress>>
#
#       See also:       
#
###############################################################################

proc tcl3dAddEvents {} {
    event add <<LeftMousePress>>   <ButtonPress-1>
    event add <<LeftMouseRelease>> <ButtonRelease-1>
    event add <<LeftMouseMotion>>  <B1-Motion>
    if { $::tcl_platform(os) eq "Darwin" } {
        event add <<MiddleMousePress>>   <ButtonPress-3>
        event add <<RightMousePress>>    <ButtonPress-2>
        event add <<RightMousePress>>    <Control-ButtonPress-1>
        event add <<MiddleMouseRelease>> <ButtonRelease-3>
        event add <<RightMouseRelease>>  <ButtonRelease-2>
        event add <<MiddleMouseMotion>>  <B3-Motion>
        event add <<RightMouseMotion>>   <B2-Motion>
    } else {
        event add <<MiddleMousePress>>   <ButtonPress-2>
        event add <<RightMousePress>>    <ButtonPress-3>
        event add <<MiddleMouseRelease>> <ButtonRelease-2>
        event add <<RightMouseRelease>>  <ButtonRelease-3>
        event add <<MiddleMouseMotion>>  <B2-Motion>
        event add <<RightMouseMotion>>   <B3-Motion>
    }
}

###############################################################################
#[@e
#       Name:           tcl3dWinIsTop - Check, if widget is a top level window.
#
#       Synopsis:       tcl3dWinIsTop { wid }
#
#       Description:    wid : string
#
#                       Return true, if widget "wid" is a top level window.
#
#       See also:       tcl3dWinRaise
#
###############################################################################

proc tcl3dWinIsTop { wid } {
    string equal $wid [winfo toplevel $wid]
}

###############################################################################
#[@e
#       Name:           tcl3dWinRaise - Raise a widget. 
#
#       Synopsis:       tcl3dWinRaise { wid }
#
#       Description:    wid : string
#
#                       Raise widget "wid" to the top of the widget layout
#                       hierarchy.
#
#       See also:       tcl3dWinIsTop
#
###############################################################################

proc tcl3dWinRaise { wid } {
    wm deiconify $wid
    update
    raise $wid
}

###############################################################################
#[@e
#       Name:           tcl3dSetFullScreenMode - Put a widget into fullscreen 
#                       mode.
#
#       Synopsis:       tcl3dSetFullScreenMode { wid }
#
#       Description:    wid : string
#
#                       Put widget "wid" into fullscreen mode:
#                       It's size is adjusted to fit the entire screen, window
#                       decoration is removed and the widget can not be resized.
#
#       See also:       tcl3dSetWindowMode
#
###############################################################################

proc tcl3dSetFullScreenMode { wid } {
    set sh [winfo screenheight $wid]
    set sw [winfo screenwidth  $wid]

    wm minsize $wid $sw $sh
    wm maxsize $wid $sw $sh
    set fmtStr [format "%dx%d+0+0" $sw $sh]
    wm geometry $wid $fmtStr
    wm overrideredirect $wid 1
    focus -force $wid
}

###############################################################################
#[@e
#       Name:           tcl3dSetWindowMode - Put a widget into windowing 
#                       mode.
#
#       Synopsis:       tcl3dSetWindowMode { wid w h }
#
#       Description:    wid : string
#                       w   : int
#                       h   : int
#
#                       Put widget "wid" into windowing mode:
#                       It's size is adjusted to width "w" and height "h",
#                       window decoration is enabled and the widget can be
#                       resized.
#
#       See also:       tcl3dSetFullScreenMode
#
###############################################################################

proc tcl3dSetWindowMode { wid w h } {
    set sh [winfo screenheight $wid]
    set sw [winfo screenwidth  $wid]

    wm minsize $wid 10 10
    wm maxsize $wid $sw $sh
    set fmtStr [format "%dx%d+0+25" $w $h]
    wm geometry $wid $fmtStr
    wm overrideredirect $wid 0
    focus -force $wid
}

###############################################################################
#[@e
#       Name:           tcl3dSetScrolledTitle - Set the title of a 
#                       scrolled widget.
#
#       Synopsis:       tcl3dSetScrolledTitle { wid titleStr 
#                                              { fgColor "black" } }
#
#       Description:    wid      : string
#                       titleStr : string
#                       fgColor  : string
#
#                       Set the title of scrolled widget "wid" to string
#                       "titleStr". The text color can be optionally specified
#                       with "fgColor". "fgColor" must be a valid Tk color name.
#                       "wid" must be a widget name returned from 
#                       tcl3dCreateScrolledWidget or descendants. 
#
#       See also:       tcl3dCreateScrolledWidget
#
###############################################################################

proc tcl3dSetScrolledTitle { wid titleStr { fgColor "black" } } {
    set pathList [split $wid "."]
    # Index -3 is needed for CreateScrolledFrame.
    # Index -2 is needed for all other widget types.
    foreach ind { -2 -3 } {
        set parList  [lrange $pathList 0 [expr [llength $pathList] $ind]]
        set parPath  [join $parList "."]

        set labelPath $parPath
        append labelPath ".label"
        if { [winfo exists $labelPath] } {
            $labelPath configure -text $titleStr -foreground $fgColor
            break
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledWidget - Create a scrolled widget.
#
#       Synopsis:       tcl3dCreateScrolledWidget { wType wid titleStr args }
#
#       Description:    wType     : string
#                       wid       : string
#                       titleStr  : string
#                       args      : list
#
#                       Create a compound widget with horizontal and vertical
#                       scrollbars. The type of the widget is given with "wType"
#                       and must be a valid Tk widget like canvas or text.
#                       "wid" is the parent frame of the compound widget and
#                       must already exist.
#                       The compound widget may have a title string, which is 
#                       given with "titleStr". If "titleStr" is an empty string,
#                       no title label will be generated.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created master widget.
#
#                       There exist several utility procedures for often used
#                       Tk widget types. See list below.
#
#       See also:       tcl3dSetScrolledTitle
#                       tcl3dCreateScrolledFrame
#                       tcl3dCreateScrolledListbox
#                       tcl3dCreateScrolledText
#                       tcl3dCreateScrolledCanvas
#                       tcl3dCreateScrolledTable
#                       tcl3dCreateScrolledTablelist
#
###############################################################################

proc tcl3dCreateScrolledWidget { wType wid titleStr args } {
    if { [winfo exists $wid.par] } {
        destroy $wid.par
    }
    ttk::frame $wid.par
    pack $wid.par -side top -fill both -expand 1
    if { [string compare $titleStr ""] != 0 } {
        ttk::label $wid.par.label -text "$titleStr"
    }
    eval { $wType $wid.par.widget \
            -xscrollcommand "$wid.par.xscroll set" \
            -yscrollcommand "$wid.par.yscroll set" } $args
    ttk::scrollbar $wid.par.xscroll -command "$wid.par.widget xview" \
                                   -orient horizontal -takefocus 0
    ttk::scrollbar $wid.par.yscroll -command "$wid.par.widget yview" \
                                   -orient vertical -takefocus 0
    set rowNo 0
    if { [string compare $titleStr ""] != 0 } {
        set rowNo 1
        grid $wid.par.label -sticky ew -columnspan 2
    }
    grid $wid.par.widget $wid.par.yscroll -sticky news
    grid $wid.par.xscroll                 -sticky ew

    grid rowconfigure    $wid.par $rowNo -weight 1
    grid columnconfigure $wid.par 0      -weight 1

    ::tcl3dAutoscroll::autoscroll $wid.par.xscroll
    ::tcl3dAutoscroll::autoscroll $wid.par.yscroll

    return $wid.par.widget
}

# Private callback function for tcl3dCreateScrolledFrame

proc __tcl3dScrolledFrameCfgCB { wid width height} {
    set newSR [list 0 0 $width $height]
    if { ! [string equal [$wid.canv cget -scrollregion] $newSR] } {
        $wid.canv configure -scrollregion $newSR
    }
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledFrame - Create a scrolled 
#                       frame widget.
#
#       Synopsis:       tcl3dCreateScrolledFrame { wid titleStr args }
#
#       Description:    wid        : string
#                       titleStr   : string
#                       args       : list
#           
#                       Create a scrolled frame widget. "wid" specifies the
#                       parent frame of the created scrolled widget. "titleStr"
#                       specifies the string displayed as widget title.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created frame widget.
#
#       See also:       tcl3dCreateScrolledWidget
#                       tcl3dSetScrolledTitle
#
###############################################################################

proc tcl3dCreateScrolledFrame { wid titleStr args } {
    ttk::frame $wid.par
    pack $wid.par -fill both -expand 1
    if { [string compare $titleStr ""] != 0 } {
        ttk::label $wid.par.label -text "$titleStr" -borderwidth 2 -anchor center
    }
    eval {canvas $wid.par.canv -xscrollcommand [list $wid.par.xscroll set] \
                               -yscrollcommand [list $wid.par.yscroll set]} $args
    ttk::scrollbar $wid.par.xscroll -orient horizontal -command "$wid.par.canv xview"
    ttk::scrollbar $wid.par.yscroll -orient vertical   -command "$wid.par.canv yview"
    set fr [frame $wid.par.canv.fr -borderwidth 0 -highlightthickness 0]
    $wid.par.canv create window 0 0 -anchor nw -window $fr

    set rowNo 0
    if { [string compare $titleStr ""] != 0 } {
        set rowNo 1
        grid $wid.par.label -sticky ew -columnspan 2
    }
    grid $wid.par.canv $wid.par.yscroll -sticky news
    grid $wid.par.xscroll               -sticky ew
    grid rowconfigure    $wid.par $rowNo -weight 1
    grid columnconfigure $wid.par 0      -weight 1
    # This binding makes the scroll-region of the canvas behave correctly as
    # you place more things in the content frame.
    bind $fr <Configure> [list __tcl3dScrolledFrameCfgCB $wid.par %w %h]
    $wid.par.canv configure -borderwidth 0 -highlightthickness 0
    return $fr
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledListbox - Create a scrolled 
#                       listbox widget.
#
#       Synopsis:       tcl3dCreateScrolledListbox { wid titleStr args }
#
#       Description:    wid        : string
#                       titleStr   : string
#                       args       : list
#           
#                       Create a scrolled listbox widget. "wid" specifies the
#                       parent frame of the created scrolled widget. "titleStr"
#                       specifies the string displayed as widget title.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created listbox widget.
#
#       See also:       tcl3dCreateScrolledWidget
#                       tcl3dSetScrolledTitle
#
###############################################################################

proc tcl3dCreateScrolledListbox { wid titleStr args } {
    return [eval {tcl3dCreateScrolledWidget listbox $wid $titleStr} $args ]
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledText - Create a scrolled 
#                       text widget.
#
#       Synopsis:       tcl3dCreateScrolledText { wid titleStr args }
#
#       Description:    wid        : string
#                       titleStr   : string
#                       args       : list
#           
#                       Create a scrolled text widget. "wid" specifies the
#                       parent frame of the created scrolled widget. "titleStr"
#                       specifies the string displayed as widget title.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created text widget.
#
#       See also:       tcl3dCreateScrolledWidget
#                       tcl3dSetScrolledTitle
#
###############################################################################

proc tcl3dCreateScrolledText { wid titleStr args } {
    return [eval {tcl3dCreateScrolledWidget text $wid $titleStr} $args ]
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledCanvas - Create a scrolled 
#                       canvas widget.
#
#       Synopsis:       tcl3dCreateScrolledCanvas { wid titleStr args }
#
#       Description:    wid        : string
#                       titleStr   : string
#                       args       : list
#           
#                       Create a scrolled canvas widget. "wid" specifies the
#                       parent frame of the created scrolled widget. "titleStr"
#                       specifies the string displayed as widget title.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created canvas widget.
#
#       See also:       tcl3dCreateScrolledWidget
#                       tcl3dSetScrolledTitle
#
###############################################################################

proc tcl3dCreateScrolledCanvas { wid titleStr args } {
    return [eval {tcl3dCreateScrolledWidget canvas $wid $titleStr} $args ]
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledTable - Create a scrolled 
#                       tktable widget.
#
#       Synopsis:       tcl3dCreateScrolledTable { wid titleStr args }
#
#       Description:    wid        : string
#                       titleStr   : string
#                       args       : list
#           
#                       Create a scrolled TkTable widget. "wid" specifies the
#                       parent frame of the created scrolled widget. "titleStr"
#                       specifies the string displayed as widget title.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created TkTable widget.
#
#       See also:       tcl3dCreateScrolledWidget
#                       tcl3dSetScrolledTitle
#
###############################################################################

proc tcl3dCreateScrolledTable { wid titleStr args } {
    return [eval {tcl3dCreateScrolledWidget table $wid $titleStr} $args ]
}

###############################################################################
#[@e
#       Name:           tcl3dCreateScrolledTablelist - Create a scrolled 
#                       tablelist widget.
# 
#       Synopsis:       tcl3dCreateScrolledTablelist { wid titleStr args }
#       Description:    wid        : string
#                       titleStr   : string
#                       args       : list
#           
#                       Create a scrolled tablelist widget. "wid" specifies the
#                       parent frame of the created scrolled widget. "titleStr"
#                       specifies the string displayed as widget title.
#                       With optional parameter "args" additional widget 
#                       specific parameters may be supplied.
#                       Return the identifier to the created tablelist widget.
#
#                       Note: A "package require tablelist" must be issued before
#                             using this function.
#
#       See also:       tcl3dCreateScrolledWidget
#                       tcl3dSetScrolledTitle
#
###############################################################################

proc tcl3dCreateScrolledTablelist { wid titleStr args } {
    return [eval {tcl3dCreateScrolledWidget tablelist::tablelist $wid $titleStr} $args ]
}
