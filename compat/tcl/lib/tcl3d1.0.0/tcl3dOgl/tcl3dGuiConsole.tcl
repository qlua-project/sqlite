#******************************************************************************
#
#       Copyright:      2006-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dGuiConsole.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module implementing a simple Tk console. It is
#                       used in the tcl3dsh, the Tcl3D Starpack.
#                       The implementation of this console window was taken
#                       from D. Richard Hipp's mktclapp.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dConsoleCreate - Create a console window.
#
#       Synopsis:       tcl3dConsoleCreate { w prompt title }
#
#       Description:    w      : string (Widget name)
#                       prompt : string
#                       title  : string
#
#                       Create a new console window "w". The window's title will
#                       be set to "title". The prompt inside the console's text
#                       widget will be set to "prompt".
#
#                       Example: 
#                       tcl3dConsoleCreate .myConsole "tcl3d> " "Tcl3D Console"
#
#       See also:
#
###############################################################################

proc tcl3dConsoleCreate {w prompt title} {
    upvar #0 $w.t v
    if {[winfo exists $w]} {destroy $w}
    if {[info exists v]} {unset v}
    toplevel $w
    wm title $w $title
    wm iconname $w $title
    set mnu $w.mb
    menu $mnu -borderwidth 2 -relief sunken
    $mnu add cascade -menu $mnu.file -label File -underline 0
    $mnu add cascade -menu $mnu.edit -label Edit -underline 0

    set fileMenu $mnu.file
    set editMenu $mnu.edit

    menu $fileMenu -tearoff 0
    __tcl3dAddMenuCmd $fileMenu "Save as ..." "" "__tcl3dConsoleSaveFile $w.t"
    __tcl3dAddMenuCmd $fileMenu "Close"       "" "destroy $w"
    __tcl3dAddMenuCmd $fileMenu "Quit"        "" "exit"

    __tcl3dConsoleCreateChild $w $prompt $editMenu
    $w configure -menu $mnu
}

#
# Private console procedures.
#

proc __tcl3dAddMenuCmd { menu label acc cmd } {
    $menu add command -label $label -accelerator $acc -command $cmd
}

proc __tcl3dConsoleCreateChild {w prompt editMenu} {
    upvar #0 $w.t v
    if {$editMenu!=""} {
        menu $editMenu -tearoff 0
        __tcl3dAddMenuCmd $editMenu "Cut"   "" "__tcl3dConsoleCut $w.t"
        __tcl3dAddMenuCmd $editMenu "Copy"  "" "__tcl3dConsoleCopy $w.t"
        __tcl3dAddMenuCmd $editMenu "Paste" "" "__tcl3dConsolePaste $w.t"
        __tcl3dAddMenuCmd $editMenu "Clear" "" "__tcl3dConsoleClear $w.t"
        $editMenu add separator
        __tcl3dAddMenuCmd $editMenu "Source ..." "" "__tcl3dConsoleSourceFile $w.t"
        catch {$editMenu config -postcommand "__tcl3dConsoleEnableEditMenu $w"}
    }
    scrollbar $w.sb -orient vertical -command "$w.t yview"
    pack $w.sb -side right -fill y
    text $w.t -font fixed -yscrollcommand "$w.sb set"
    pack $w.t -side right -fill both -expand 1
    bindtags $w.t Console
    set v(editmenu) $editMenu
    set v(text) $w.t
    set v(history) 0
    set v(historycnt) 0
    set v(current) -1
    set v(prompt) $prompt
    set v(prior) {}
    set v(plength) [string length $v(prompt)]
    set v(x) 0
    set v(y) 0
    $w.t mark set insert end
    $w.t tag config ok -foreground blue
    $w.t tag config err -foreground red
    $w.t insert end $v(prompt)
    $w.t mark set out 1.0
    catch {rename puts __tcl3dConsoleOldPuts$w}
    proc puts args [format {
        if {![winfo exists %s]} {
            rename puts {}
            rename __tcl3dConsoleOldPuts%s puts
            return [uplevel #0 puts $args]
        }
        switch -glob -- "[llength $args] $args" {
            {1 *} {
                set msg [lindex $args 0]\n
                set tag ok
            }
            {2 stdout *} {
                set msg [lindex $args 1]\n
                set tag ok
            }
            {2 stderr *} {
                set msg [lindex $args 1]\n
                set tag err
            }
            {2 -nonewline *} {
                set msg [lindex $args 1]
                set tag ok
            }
            {3 -nonewline stdout *} {
                set msg [lindex $args 2]
                set tag ok
            }
            {3 -nonewline stderr *} {
                set msg [lindex $args 2]
                set tag err
            }
            default {
                uplevel #0 __tcl3dConsoleOldPuts%s $args
                return
            }
        }
        __tcl3dConsolePuts %s $msg $tag
    } $w $w $w $w.t]
    after idle "focus $w.t"
}

bind Console <1> {__tcl3dConsoleButton1 %W %x %y}
bind Console <B1-Motion> {__tcl3dConsoleB1Motion %W %x %y}
bind Console <B1-Leave> {__tcl3dConsoleB1Leave %W %x %y}
bind Console <B1-Enter> {__tcl3dConsoleCancelMotor %W}
bind Console <ButtonRelease-1> {__tcl3dConsoleCancelMotor %W}
bind Console <KeyPress> {__tcl3dConsoleInsert %W %A}
bind Console <Left> {__tcl3dConsoleLeft %W}
bind Console <Control-b> {__tcl3dConsoleLeft %W}
bind Console <Right> {__tcl3dConsoleRight %W}
bind Console <Control-f> {__tcl3dConsoleRight %W}
bind Console <BackSpace> {__tcl3dConsoleBackspace %W}
bind Console <Control-h> {__tcl3dConsoleBackspace %W}
bind Console <Delete> {__tcl3dConsoleDelete %W}
bind Console <Control-d> {__tcl3dConsoleDelete %W}
bind Console <Home> {__tcl3dConsoleHome %W}
bind Console <Control-a> {__tcl3dConsoleHome %W}
bind Console <End> {__tcl3dConsoleEnd %W}
bind Console <Control-e> {__tcl3dConsoleEnd %W}
bind Console <Return> {__tcl3dConsoleEnter %W}
bind Console <KP_Enter> {__tcl3dConsoleEnter %W}
bind Console <Up> {__tcl3dConsolePrior %W}
bind Console <Control-p> {__tcl3dConsolePrior %W}
bind Console <Down> {__tcl3dConsoleNext %W}
bind Console <Control-n> {__tcl3dConsoleNext %W}
bind Console <Control-k> {__tcl3dConsoleEraseEOL %W}
bind Console <<Cut>> {__tcl3dConsoleCut %W}
bind Console <<Copy>> {__tcl3dConsoleCopy %W}
bind Console <<Paste>> {__tcl3dConsolePaste %W}
bind Console <<Clear>> {__tcl3dConsoleClear %W}

proc __tcl3dConsolePuts {w t tag} {
    set nc [string length $t]
    set endc [string index $t [expr $nc-1]]
    if {$endc=="\n"} {
        if {[$w index out]<[$w index {insert linestart}]} {
            $w insert out [string range $t 0 [expr $nc-2]] $tag
            $w mark set out {out linestart +1 lines}
        } else {
            $w insert out $t $tag
        }
    } else {
        if {[$w index out]<[$w index {insert linestart}]} {
            $w insert out $t $tag
        } else {
            $w insert out $t\n $tag
            $w mark set out {out -1 char}
        }
    }
    $w yview insert
}

proc __tcl3dConsoleInsert {w a} {
    $w insert insert $a
    $w yview insert
}

proc __tcl3dConsoleLeft {w} {
    upvar #0 $w v
    scan [$w index insert] %d.%d row col
    if {$col>$v(plength)} {
        $w mark set insert "insert -1c"
    }
}

proc __tcl3dConsoleBackspace {w} {
    upvar #0 $w v
    scan [$w index insert] %d.%d row col
    if {$col>$v(plength)} {
        $w delete {insert -1c}
    }
}

proc __tcl3dConsoleEraseEOL {w} {
    upvar #0 $w v
    scan [$w index insert] %d.%d row col
    if {$col>=$v(plength)} {
        $w delete insert {insert lineend}
    }
}

proc __tcl3dConsoleRight {w} {
    $w mark set insert "insert +1c"
}

proc __tcl3dConsoleDelete w {
    $w delete insert
}

proc __tcl3dConsoleHome w {
    upvar #0 $w v
    scan [$w index insert] %d.%d row col
    $w mark set insert $row.$v(plength)
}

proc __tcl3dConsoleEnd w {
    $w mark set insert {insert lineend}
}

proc __tcl3dConsoleEnter w {
    upvar #0 $w v
    scan [$w index insert] %d.%d row col
    set start $row.$v(plength)
    set line [$w get $start "$start lineend"]
    if {$v(historycnt)>0} {
        set last [lindex $v(history) [expr $v(historycnt)-1]]
        if {[string compare $last $line]} {
            lappend v(history) $line
            incr v(historycnt)
        }
    } else {
        set v(history) [list $line]
        set v(historycnt) 1
    }
    set v(current) $v(historycnt)
    $w insert end \n
    $w mark set out end
    if {$v(prior)==""} {
        set cmd $line
    } else {
        set cmd $v(prior)\n$line
    }
    if {[info complete $cmd]} {
        set rc [catch {uplevel #0 $cmd} res]
        if {![winfo exists $w]} return
        if {$rc} {
            $w insert end $res\n err
        } elseif {[string length $res]>0} {
            $w insert end $res\n ok
        }
        set v(prior) {}
        $w insert end $v(prompt)
    } else {
        set v(prior) $cmd
        regsub -all {[^ ]} $v(prompt) . x
        $w insert end $x
    }
    $w mark set insert end
    $w mark set out {insert linestart}
    $w yview insert
}

proc __tcl3dConsolePrior w {
    upvar #0 $w v
    if {$v(current)<=0} return
    incr v(current) -1
    set line [lindex $v(history) $v(current)]
    __tcl3dConsoleSetLine $w $line
}

proc __tcl3dConsoleNext w {
    upvar #0 $w v
    if {$v(current)>=$v(historycnt)} return
    incr v(current) 1
    set line [lindex $v(history) $v(current)]
    __tcl3dConsoleSetLine $w $line
}

proc __tcl3dConsoleSetLine {w line} {
    upvar #0 $w v
    scan [$w index insert] %d.%d row col
    set start $row.$v(plength)
    $w delete $start end
    $w insert end $line
    $w mark set insert end
    $w yview insert
}

proc __tcl3dConsoleButton1 {w x y} {
    global tkPriv
    upvar #0 $w v
    set v(mouseMoved) 0
    set v(pressX) $x
    set p [__tcl3dConsoleNearestBoundry $w $x $y]
    scan [$w index insert] %d.%d ix iy
    scan $p %d.%d px py
    if {$px==$ix} {
        $w mark set insert $p
    }
    $w mark set anchor $p
    focus $w
}

proc __tcl3dConsoleNearestBoundry {w x y} {
    set p [$w index @$x,$y]
    set bb [$w bbox $p]
    if {![string compare $bb ""]} {return $p}
    if {($x-[lindex $bb 0])<([lindex $bb 2]/2)} {return $p}
    $w index "$p + 1 char"
}

proc __tcl3dConsoleSelectTo {w x y} {
    upvar #0 $w v
    set cur [__tcl3dConsoleNearestBoundry $w $x $y]
    if {[catch {$w index anchor}]} {
        $w mark set anchor $cur
    }
    set anchor [$w index anchor]
    if {[$w compare $cur != $anchor] || (abs($v(pressX) - $x) >= 3)} {
        if {$v(mouseMoved)==0} {
            $w tag remove sel 0.0 end
        }
        set v(mouseMoved) 1
    }
    if {[$w compare $cur < anchor]} {
        set first $cur
        set last anchor
    } else {
        set first anchor
        set last $cur
    }
    if {$v(mouseMoved)} {
        $w tag remove sel 0.0 $first
        $w tag add sel $first $last
        $w tag remove sel $last end
        update idletasks
    }
}

proc __tcl3dConsoleB1Motion {w x y} {
    upvar #0 $w v
    set v(y) $y
    set v(x) $x
    __tcl3dConsoleSelectTo $w $x $y
}

proc __tcl3dConsoleB1Leave {w x y} {
    upvar #0 $w v
    set v(y) $y
    set v(x) $x
    __tcl3dConsoleMotor $w
}

proc __tcl3dConsoleMotor w {
    upvar #0 $w v
    if {![winfo exists $w]} return
    if {$v(y)>=[winfo height $w]} {
        $w yview scroll 1 units
    } elseif {$v(y)<0} {
        $w yview scroll -1 units
    } else {
        return
    }
    __tcl3dConsoleSelectTo $w $v(x) $v(y)
    set v(timer) [after 50 __tcl3dConsoleMotor $w]
}

proc __tcl3dConsoleCancelMotor w {
    upvar #0 $w v
    catch {after cancel $v(timer)}
    catch {unset v(timer)}
}

proc __tcl3dConsoleCanCut w {
    set r [catch {
        scan [$w index sel.first] %d.%d s1x s1y
        scan [$w index sel.last] %d.%d s2x s2y
        scan [$w index insert] %d.%d ix iy
    }]
    if {$r==1} {return 0}
    if {$s1x==$ix && $s2x==$ix} {return 1}
    return 2
}

proc __tcl3dConsoleCut w {
    if {[__tcl3dConsoleCanCut $w]==1} {
        __tcl3dConsoleCopy $w
        $w delete sel.first sel.last
    }
}

proc __tcl3dConsoleCopy w {
    if {![catch {set text [$w get sel.first sel.last]}]} {
        clipboard clear -displayof $w
        clipboard append -displayof $w $text
    }
}

proc __tcl3dConsolePaste w {
    if {[__tcl3dConsoleCanCut $w]==1} {
        $w delete sel.first sel.last
    }
    if {[catch {selection get -displayof $w -selection CLIPBOARD} topaste]} {
        return
    }
    set prior 0
    foreach line [split $topaste \n] {
        if {$prior} {
            __tcl3dConsoleEnter $w
            update
        }
        set prior 1
        $w insert insert $line
    }
}

proc __tcl3dConsoleClear w {
    $w delete 1.0 {insert linestart}
}

proc __tcl3dConsoleEnableEditMenu w {
    upvar #0 $w.t v
    set m $v(editmenu)
    if {$m=="" || ![winfo exists $m]} return
    switch [__tcl3dConsoleCanCut $w.t] {
        0 {
            $m entryconf Copy -state disabled
            $m entryconf Cut -state disabled
        }
        1 {
            $m entryconf Copy -state normal
            $m entryconf Cut -state normal
        }
        2 {
            $m entryconf Copy -state normal
            $m entryconf Cut -state disabled
        }
    }
}

proc __tcl3dConsoleSourceFile w {
    set types {
        {{TCL Scripts}  {.tcl}}
        {{All Files}    *}
    }
    set f [tk_getOpenFile -filetypes $types -title "TCL Script To Source..."]
    if {$f!=""} {
        uplevel #0 source $f
    }
}

proc __tcl3dConsoleSaveFile w {
    set types {
        {{Text Files}  {.txt}}
        {{All Files}    *}
    }
    set f [tk_getSaveFile -filetypes $types -title "Write Screen To..."]
    if {$f!=""} {
        if {[catch {open $f w} fd]} {
            tk_messageBox -type ok -icon error -message $fd
        } else {
            puts $fd [string trimright [$w get 1.0 end] \n]
            close $fd
        }
    }
}
