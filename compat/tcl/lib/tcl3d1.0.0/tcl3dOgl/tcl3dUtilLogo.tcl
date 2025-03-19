#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dUtilLogo.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module showing the Tcl/Tk and poSoft logo.
#
#******************************************************************************

proc __tcl3dLogoShrinkWindow { tw dir } {
    set width  [winfo width $tw]
    set height [winfo height $tw]
    set x      [winfo x $tw]
    set y      [winfo y $tw]
    set inc -1

    if { [string compare $dir "x"] == 0 } {
        for { set w $width } { $w >= 20 } { incr w $inc } {
            wm geometry $tw [format "%dx%d+%d+%d" $w $height $x $y]
            update
            incr inc -1
        }
    } else {
        for { set h $height } { $h >= 20 } { incr h $inc } {
            wm geometry $tw [format "%dx%d+%d+%d" $width $h $x $y]
            update
            incr inc -1
        }
    }
}

proc __tcl3dLogoSetWackelDelay { mouseX mouseY } {
    global __tcl3dLogoWackel

    set __tcl3dLogoWackel(wackelSpeed) [expr $mouseX + $mouseY]
}

proc __tcl3dLogoSwitchLogo { b } {
    global __tcl3dLogoWackel

    if { $__tcl3dLogoWackel(onoff) == 1 } {
        set __tcl3dLogoWackel(onoff) 0
    }
    set __tcl3dLogoWackel(curImg) [expr 1 - $__tcl3dLogoWackel(curImg)]
    $b configure -image $__tcl3dLogoWackel($__tcl3dLogoWackel(curImg))
}

proc __tcl3dLogoStartWackel { b } {
    global __tcl3dLogoWackel

    if { $__tcl3dLogoWackel(onoff) == 0 } {
        set __tcl3dLogoWackel(onoff) 1
        __tcl3dLogoWackel $b
    } else {
        __tcl3dLogoStopWackel $b
    }
}

proc __tcl3dLogoStopWackel { b } {
    global __tcl3dLogoWackel 

    set __tcl3dLogoWackel(onoff)  0
    set __tcl3dLogoWackel(curImg) 1
    after $__tcl3dLogoWackel(wackelSpeed) __tcl3dLogoWackel $b
}

proc __tcl3dLogoWackel { b } {
    global __tcl3dLogoWackel

    if { $__tcl3dLogoWackel(onoff) == 1 } {
        set __tcl3dLogoWackel(curImg) [expr 1 - $__tcl3dLogoWackel(curImg)]
        $b configure -image $__tcl3dLogoWackel($__tcl3dLogoWackel(curImg))
        update
        after $__tcl3dLogoWackel(wackelSpeed) "__tcl3dLogoWackel $b"
    }
}

###############################################################################
#[@e
#       Name:           tcl3dLogoDestroyPoSoft - Destroy poSoft logo window.
#
#       Synopsis:       tcl3dLogoDestroyPoSoft {}
#
#       Description:    Destroy a previously opened poSoft logo window.
#
#       See also:       tcl3dLogoShowPoSoft
#                       tcl3dLogoShowTcl
#
###############################################################################

proc tcl3dLogoDestroyPoSoft {} {
    global __tcl3dLogoWackel
    global __tcl3dLogoWinId
    global __tcl3dLogoWithdrawnWinId

    if { [info exists __tcl3dLogoWinId] && [winfo exists $__tcl3dLogoWinId] } {
        __tcl3dLogoShrinkWindow $__tcl3dLogoWinId x
        set __tcl3dLogoWackel(onoff) 0
        image delete $__tcl3dLogoWackel(0)
        image delete $__tcl3dLogoWackel(1)
        destroy $__tcl3dLogoWinId
        if { [winfo exists $__tcl3dLogoWithdrawnWinId] } {
            wm deiconify $__tcl3dLogoWithdrawnWinId
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dLogoShowPoSoft - Display poSoft logo.
#
#       Synopsis:       tcl3dLogoShowPoSoft { version copyright withdrawWin }
#
#       Description:    version     : string
#                       copyright   : string
#                       withdrawWin : string (Widget name)
#
#                       Display the poSoft logo in two possible ways:
#                       If "withdrawWin" is set to the empty string, the logo
#                       is shown in a window with decoration. This may be used
#                       for displaying the logo as an action for an "About"
#                       menu entry. 
#                       If "withdrawWin" is set to an existing window name
#                       (typically the name of the main application window), the
#                       logo window is shown without decoration as a splash
#                       window, which automatically disappears after a second.
#                       The logo window has two label widgets to display 
#                       additional text messages, which are specified in 
#                       "version" and "copyright".
#
#       See also:       tcl3dLogoDestroyPoSoft
#                       tcl3dLogoShowTcl
#
###############################################################################

proc tcl3dLogoShowPoSoft { version copyright {withdrawWin ""} } {
    global __tcl3dLogoWackel
    global __tcl3dLogoWinId
    global __tcl3dLogoWithdrawnWinId

    set t ".poShowLogo"
    set __tcl3dLogoWinId $t
    set __tcl3dLogoWithdrawnWinId $withdrawWin
    if { [winfo exists $t] } {
        tcl3dWinRaise $t
        return
    }

    set __tcl3dLogoWackel(0) [image create photo -data [__tcl3dLogoPoLogo200_text]]
    set __tcl3dLogoWackel(1) [image create photo -data [__tcl3dLogoPoLogo200_text_flip]]
    set __tcl3dLogoWackel(onoff)  0
    set __tcl3dLogoWackel(curImg) 0
    set __tcl3dLogoWackel(wackelSpeed) 500

    toplevel $t
    ttk::frame $t.f
    pack $t.f
    wm resizable $t false false
    if { [string compare $withdrawWin ""] == 0 } {
        wm title $t "poSoft Information"
    } else {
        if { [string compare $withdrawWin "."] != 0 } {
            wm withdraw .
        }
        if { [winfo exists $withdrawWin] } {
            wm withdraw $withdrawWin
            set __tcl3dLogoWithdrawnWinId $withdrawWin
        }
        wm overrideredirect $t 1
        set xmax [winfo screenwidth $t]
        set ymax [winfo screenheight $t]
        set x0 [expr {($xmax - [image width  $__tcl3dLogoWackel(0)])/2}]
        set y0 [expr {($ymax - [image height $__tcl3dLogoWackel(0)])/2}]
        wm geometry $t "+$x0+$y0"
        $t.f configure -borderwidth 10
        raise $t
        update
    }

    ttk::label $t.f.l1 -text "Paul Obermeier's Portable Software" -anchor center
    pack $t.f.l1 -fill x
    ttk::button $t.f.l2 -image $__tcl3dLogoWackel(0)
    bind $t.f.l2 <Motion> { __tcl3dLogoSetWackelDelay %x %y }
    bind $t.f.l2 <Shift-Button-1> "__tcl3dLogoStartWackel $t.f.l2"
    bind $t.f.l2 <Button-1> "__tcl3dLogoSwitchLogo $t.f.l2"
    pack $t.f.l2
    ttk::label $t.f.l3 -text $version -anchor center
    pack $t.f.l3 -fill x
    ttk::label $t.f.l4 -text $copyright -anchor center
    pack $t.f.l4 -fill x
    if { [string compare $withdrawWin ""] == 0 } {
        ttk::button $t.f.b -text "OK" -command "tcl3dLogoDestroyPoSoft" \
                    -default active
        pack $t.f.b -fill x
        bind $t <KeyPress-Escape> "tcl3dLogoDestroyPoSoft" 
        bind $t <KeyPress-Return> "tcl3dLogoDestroyPoSoft"
        focus $t
        update
    } else {
        focus $t
        update
        after 500
        __tcl3dLogoSwitchLogo $t.f.l2
        update
        after 300
    }
}

###############################################################################
#[@e
#       Name:           tcl3dLogoDestroyTcl - Destroy Tcl logo window.
#
#       Synopsis:       tcl3dLogoDestroyTcl { w img }
#
#       Description:    Destroy a previously opened Tcl logo window.
#
#       See also:       tcl3dLogoShowTcl
#                       tcl3dLogoShowPoSoft
#
###############################################################################

proc tcl3dLogoDestroyTcl { w img } {
    __tcl3dLogoShrinkWindow $w y
    image delete $img
    destroy $w
}

###############################################################################
#[@e
#       Name:           tcl3dLogoShowTcl - Display Tcl logo.
#
#       Synopsis:       tcl3dLogoShowTcl { args }
#
#       Description:    args : variable parameter list
#
#                       Display the Tcl logo with additional text messages in
#                       a window with decoration. This may be used
#                       for displaying the logo as an action for an "About"
#                       menu entry. 
#                       "args" may contain any combination of the following
#                       package names:
#                       Tk Img Tktable combobox mysqltcl tcom
#
#       See also:       tcl3dLogoShowPoSoft
#
###############################################################################

proc tcl3dLogoShowTcl { args } {
    global __url

    set t ".tcl3dLogoShowTcl"
    if { [winfo exists $t] } {
        tcl3dWinRaise $t
        return
    }

    toplevel $t
    wm title $t "Tcl/Tk Information"
    wm resizable $t false false

    set ph [image create photo -data [__tcl3dLogoPwrdLogo200]]
    ttk::button $t.img -image $ph
    pack $t.img
    ttk::label $t.l1 -anchor w -text "With a little help from my Tcl friends ..."
    pack $t.l1

    set row 0
    ttk::frame $t.f
    pack $t.f -fill both -expand 1
    foreach extension $args {
        set retVal [catch {package present $extension} versionStr]
        if { $retVal != 0 } {
            set versionStr "(not loaded)"
        }
        switch -exact -- $extension {
            Tcl            { set progName     "Tcl [info patchlevel]"
                             set __url($row) "https://www.tcl-lang.org/"
                             set author      "all Tcl developers" 
                           }
            Tk             { set progName     "Tk $versionStr"
                             set __url($row) "https://www.tcl-lang.org/"
                             set author      "all Tk developers" 
                           }
            Img            { set progName    "Img $versionStr"
                             set __url($row) "https://tkimg.sourceforge.net/"
                             set author      "Jan Nijtmans, Andreas Kupries"
                           }
            tablelist -
            tablelist_tile { set progName    "tablelist $versionStr"
                             set __url($row) "https://www.nemethi.de/tablelist/"
                             set author      "Csaba Nemethi" 
                           }
            tkdnd          { set progName    "tkdnd $versionStr"
                             set __url($row) "https://github.com/petasis/tkdnd/"
                             set author      "Georgios Petasis"
                           }
        }
        ttk::label $t.f.lext$row -text $progName
        eval ttk::entry $t.f.rext$row -state normal -width 35 \
                        -textvariable __url($row)
        grid $t.f.lext$row -row $row -column 0 -sticky w
        grid $t.f.rext$row -row $row -column 1 -sticky w
        incr row
    }
    ttk::button $t.b -text "OK" -command "tcl3dLogoDestroyTcl $t $ph" \
                -default active
    pack $t.b -fill x
    bind $t <KeyPress-Escape> "tcl3dLogoDestroyTcl $t $ph" 
    bind $t <KeyPress-Return> "tcl3dLogoDestroyTcl $t $ph"
    focus $t
}

# Inlined logo images.

proc __tcl3dLogoPoLogo200_text {} {
return {
R0lGODdhyACpAPcAAAAAAAEBAQUFBQ8PDyQkJERERGhoaIODg4iIiHZ2dlRU
VDIyMhgYGAkJCQMDAwsLCxwcHDs7O2VlZYyMjJ+fn5aWlnV1dUpKSiYmJhAQ
EEZGRm1tbYeHh0BAQCEhIQ4ODgwMDB8fH2tra5KSkqSkpJmZmUtLSwQEBCMj
I5CQkKGhoZeXl3l5eVFRUS0tLRUVFQgICAICAiIiIkVFRXFxcaioqJubmx4e
Hj09PWZmZo2NjaampqWlpYuLi2RkZDw8PCUlJUlJSampqZqamnR0dEhISDMz
M1lZWaKioqurq01NTSkpKRISEgYGBnh4eJycnHBwcA0NDREREScnJ3Nzc6ys
rF1dXTU1NRkZGUxMTKenp5WVlUJCQiAgIB0dHTo6OmJiYpSUlGxsbEFBQQcH
BxQUFFJSUn19faCgoK2trXp6ek9PTyoqKnd3d29vb0NDQ1xcXDQ0NJiYmHJy
cgoKChsbGzk5OT4+Pi8vL1ZWVoKCgq6urm5ubp2dnX9/f1NTUxMTE5OTk4qK
il5eXj8/P05OTigoKImJiWlpaXx8fH5+fkdHR1BQUI6OjoGBgYWFhaqqqp6e
nnt7eysrK4CAgCwsLI+Pjy4uLhoaGjg4OGNjY1dXVzY2Nl9fX2FhYTc3N6Oj
ozExMTAwMFtbWxYWFoaGhlpaWmBgYJGRkVVVVYSEhBcXF1hYWGdnZ2pqaq+v
r8bGxv///+Li4ra2tr6+vszMzMPDw8rKytbW1tDQ0Li4uLS0tM7OztjY2NPT
08HBwc3NzcXFxbq6usjIyLOzs7m5ub+/v729vbW1tbe3t7KysrCwsLGxsf//
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
/////////////////////ywAAAAAyACpAAAI/wABCBxIsKDBgwgHBhAwgEAB
AwcQJFCwgEEDBwkTJkyYMGHChAkTOngAIYKECRQqWLiAIYOAAAkTJkyYMGHC
hAkBBBAwgICGDRMqcJDQwcMHAQESJkyYMGHChAkTInQAIkQHESNIlEhgAkMG
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
Ow==}
} ; # End of proc __tcl3dLogoPoLogo200_text

proc __tcl3dLogoPoLogo200_text_flip {} {
return {
R0lGODdhyACpAPYAANjY2NbW1ri4uLe3t9DQ0M7OzsHBwb+/v8rKysjIyLOz
s7Kysr29vbq6ur6+vrGxsczMzNPT07W1tWZmZmVlZTw8PDs7O8XFxcPDw21t
bWxsbEJCQkFBQVFRUVBQUIeHh4aGhpGRkZCQkEVFRURERGFhYWBgYK+vr35+
fn19fZeXl5aWll5eXl1dXYKCgoGBgSgoKCcnJ5+fn56enhwcHBsbGzQ0NDMz
MxQUFBMTE3Z2dnV1dWRkZElJSUhISHBwcG9vb6enp6ampq6urkBAQI+Pj2tr
a4CAgC4uLi0tLZWVlSYmJlxcXDk5OSIiIiEhIYyMjIuLi5ubm5qamk5OTq2t
rXt7e4SEhKKioqGhoUdHR2NjYxoaGhcXFxYWFjExMXNzc6ysrKWlpSUlJSAg
ID4+PpmZmZOTk1paWqurq2hoaOLi4jg4OExMTFVVVVNTU4mJiSoqKnl5eR4e
HqqqqjY2Nqmpqf///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAyACp
AEYH/oB4goOEhYaHiIk5Sz07KzJQFBY0OYmWl5iZmpuIOTg3bjofLmokY5Wc
qaqrmzlPI2AqQVM7PaesuLm6gzldNkwfYlUqP6aou8jJl14xVHIzVVNgI07H
ytfYnkhuRzJCRROT2OPkeDlJ3N5FFBU05e+6XOguWEHrFVzW8PutXRZbUYQE
gbJlkj5+CC/laPaMDjFqBxNKNNfli5sUM9JgAcGCDaWJIDHlyPEFDb0gSjJs
eBIxJDYcY0hMiFJPxQ4PSHC43KlpJJkKJl7MoIPlQ4ky1VryzJSDDJESIGRU
KUqBw62lWFXlGDMigxI69tRsqJZVEQ1QVlQIwQJnwoYl/krLytWEwwkRIyLs
pEk54lRchHU58PiAZeqHLRVYzl2srFeSDnKmCDGjw0OSv+OaVlATwk6QKCbY
5GNMupyXbS+wDJGiowdcfp6amIgSxE4RHu2SubnDuzfvBBZKz2264YcZjUc6
xMGcC2YbOVJnyLEV17d134iKXL/+w9Aa33TAfu+dxtAO3mwO0eh9aDzv8EHc
3ylfaI787dZ7OtECRkoVGVZQAQNzrHBRhwlwiCHGB0x8gQOBhdDBmxucQMEb
FIew0VsTlrA3yG53XJAIiBgKoiFvHCbiIR4/8LaGO4e0eMcareQQxxtHiLHa
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
YAIZYARvYANbzBinIWQukAJc+tOJEAgAOw==}
} ; # End of proc __tcl3dLogoPoLogo200_text_flip

proc __tcl3dLogoPwrdLogo200 {} {
return {
R0lGODlhggDIAPUAAP//////zP//mf//AP/MzP/Mmf/MAP+Zmf+ZZv+ZAMz/
/8zM/8zMzMyZzMyZmcyZZsyZAMxmZsxmM8xmAMwzM8wzAJnM/5nMzJmZzJmZ
mZlmmZlmZpkzZpkzM5kzAGaZzGZmzGZmmWZmZmYzZmYzMzNmzDNmmTMzmTMz
ZgAzmQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH+BSAtZGwtACH5BAEKAAIALAAA
AACCAMgAAAb+QIFwSCwaj8ikcslsOp/QqFT6qEYkWElly+1WJNOweKysVrNa
r3rN9kbIcHhkfqXY2/i8Hg+O+417gYKDg29/f4SJbBOKexRiCJEPaGlbfVCN
axMJCXkGA6CMmXkRZpSjX1KoXJ8Dopqgsa6rtIKGmKutnW2tsga1wHkPqqgJ
sXi9sQa7wc1ew1GrscxqE76vztlcU5WKELHYXrLU2uXco62/bMag5OXa55mt
4V3K7/db8Y3H66Dq+O/0KfLXBhzAewITheo3wN3BYJegPBgFqmDFh+UiPpmY
acA/L98GQKgV4QABAgW6AdTohOM+hxVa0XpAAIDNmwcwQovicuD+yGrtVtW8
SRRAgYc7JVL86YUdKgkBikqNcBBBGHT0KhDMJEEqAAwfPmCoGeCgGKxAZzVC
UJRBiRRw4aJ4AKCnuauZEtCTuZboAhBxA6c4sYEAwLOZINALqigCUQyCI6fA
QAEf4kYTwllTS6jrTcCSI2+wjBeY00SebZoILfmEB4Sla336GIhCVAALVrOO
3OEeyyfNGA8aymC3ZBL4fjsJtjkrngM2ixsXPGLlZVqnBXleMF0wioNJowGb
Pcg2AAW6u8N9DTA8rlrC9wxNr763WTEqMzW3ZfOD+rjV1WKMAc5VMEZ+mC0U
SFQX/AfXCYJsMptz6bBxYC3f0PbceQ7+wmWfHhOEZFBaDa2RAX4CelSbTaD9
F6AgInLmRS9rnCCZEwgq8glMakAnnYMDxcKUF5sNUGNkJuAom4xteEZfdx8O
IkuB/HghGQgtLVlgF9BB5uCLhPRCZYlqSPZBlrRcpIdqHcqzFRufZHUjmtIY
qQddXv6H3D7xqaGiGh3M2YRdHWm4Rk1PGvddkzluMSIsWQUa2UbwGepFV9w5
GOUWERQwVFmLVLkGBEN2IWlgJbyHikh6QOefi13Q5FWOIVm6BY8jRHYmcGmW
eigAbW7RQQgYFLtAUQgwtCUeuQomnjTLdvVjdyiMYGNkJ3yggE05rcGXIs0G
9iwqBJICwKv+HbKWgU2GrdHnIChMqio6rQJwbbqhedYukQoqEm9gSc6blx4E
ZIqvZCjou8aAo9wLF5YCY6ZHAHkeLBgJdAGwbxef+DqIvBFrA0CLFgfWAVsA
dNvFZqiAzGtyACRacgUFcKuGMTzucWpcxODjWMmRfTcUoXGOsjNcPd8TgcFA
w4XcTSpZY2sgR6c67jsHVNx0B6ndzGQiJAi2KxSNBpN104FVAJ3GahgwdSDh
Ii1F2cAcgG7TQttklzXL7hF3CglpcwDJQJNAwU1qQPB2IP/yPDdAB8h8sAeO
GdV233s0nkLAUdBdCwKSpwvhUFEvzjiqgWcTQegdVsfuzZjv4ez+FFT5zDpc
t3uYMaEeNzK7FLX7drvDu1VA1j2/RxH8PbcTHlrCNi3vzNFhSF/O7XezNgJd
G2ezM+fKH6S5d5NBWZPnqOw8dtLv/A1gByVkn2/K+ITteGzth0aCBxg4H/QB
oLqH/eSGv3IMUDAe6MACiCeZEQAAfauI2xgOcrQHVcCB3XGAyu7ROPCxDxjJ
6oIHGliBECigO917R+MgVsBaHGCDFThOBTDQIONsAIK0aNz6PliLmvVEMr1h
QA21h5EY3q+FtBgaF8aXggp04Fy7WRRGxDXBbAwFAA0YAQnG950nys9kRTQi
AZEolKJ8gHjV2UDMWLMnjJzKgzxMok3+FFAsEBCuN+uSnBTdGJcdxrGMUAxN
bxoArNCogQI4zMSp4KCNobzFkBU4lv62YJKTPLB+RyQjKobCQAtWwCZRHMGx
bAKQATLSiqB8nhNxM50TQCeF2fjXCU7pjJowjToVcMwQtVcTGGrjXywMQwgE
x8pJ0mWXoXHgJTGZAj9GYZjZ8BEbK+CAr0xHAzZJZCbsBwdoOqNLrHkNIb8o
mGoC4CDcJIM3mwHO0LymJuQMDAPYVsoxhsEE2nCMA1izhXnG80FR8aU2wgZH
KYggnwDYJyRt8kjWnEBvFGwmHA6aja4cIDQQ+uQad6NMbSoScBPVxuEOwMQU
dJFNu1HjMvH+Eag4gCkYhytASb/jJONg85wRdWk5AkCAAwLoCyhlTeUwMks4
vDQYPPWp0yqg0ts5BpblCKYYjgoMT1UwBchR6XSeihEMxKGN3wTAVZGTMUVx
9SF+2FQw6CLGwJA1ldrrClThEQe1AqMrEmAicsxpHMPR8z5wsGst8MpEPMJV
kMabazbS+g4ARMB9hi0ka3pTE4wwthwEOABkK7AuyUISOpaFwwcE60ICVDCy
UdyCp0JLBhCwJ5+m5Q1nDxu0LQTgKA+xChlM8NqKnlO2nd0NcroSwqrAwTX3
eCBwaXuxCrAVI7odQwp6a8W8Cga1kzUebnMLh+neIxLjw64huxL+RvdIwbvv
kEAB/oac4PKTANZLDhn8A5CeNte9xylJGFMxBvriowBHay9z49IBQh1EOU9Y
TXskcN8Bm7QyXDBwRnbbxOQoNC7IuSliI4xTtEq3wvg4gMO+E4KgxiWjEnjA
bYpIBriAR3MkNrHTKLA2xLE2DCY9cAgC852mRqYLCBgKi6W7x3uIgMdMlXGA
PLDFh3YYsFPwT5HfcbQLKjluD1XsYsXwlimXo8pPDKRD/wplKXQ5I8WtwAjT
1oFt/XMw9LvxeXNcDo1VAoEKFHNoSizhu+CYzo3klgQ6QJ/eHOvNJfYoKj4M
Vmdk7DNurYAFAIDMyFQzjIxObnSehBz+DFDaOCfBtBiWijUANDQw1fH0tCLj
QIHCZgqgabQzuqI1uVRAw6xRY3xfbWZSl5qBENIqa55bRPM2AcMAoZhkKsAB
m3TSpKEOI4KXQOD2mPrHYZacrvc7bSVUGyAFWOB1I7lRSwewiN1Owrfru2rk
wLOBAeizb/6cAtI6gwIEmFZ1qvnFCJy7iI+QArrsfW8C5Ok7xwwaARQNDFiv
+yAUYECegLrqFGzA1R6OQnoIrg0auvhwJ+QxxjMOhbTtt4Rn7A1tOX6YObv4
5BVAgQmqg6gTw9wLUzA5zFHwnZq1SNYnz3lcbi4stQXSy0F3OYiJ7piRJx0K
dyM6F+QqdTX+SCE9GX2HpwgQgLIB4N9Vv3pckO6MbOKhslXvgtLJ3gyztwE6
DPfzE5AMELezgS67hvna+YAAeQvC7msgbtojHAW6s4HqqwD8GuI8+Fs04W5s
RzwqFK+GaDceCqcGuiXWNoc2lOQA8qa8F0A7+FxCgT6a/wJ0AtB5NUjgJBJA
5MLZIPpYrbTqjmdCc5tE5i5IXvJeqP3U61L6gDth94fvPRdqpjLP0P72tN9u
1Y1/7EjzHqoQjXCOhM8Frhe/5NZPPvaJvwfub4Etcb/3E7KXeqCO3+9cMD9Q
4S9nJdyRD8rfQk3sEvvFQ5/2WjZkTfAk9gZ8tid9xvN86IN2aff+BMRTgF/n
XNZTM5WQEgq4B3A3eHM3bmfHU2kWKyfxQghyAAVQgiWoB11Bf2XmbRxYep+k
gi1XfWDkgsYDg6Qhg0NHgxXQdxr4eD+mgynWg0xwai8HhEK4BImigzQYXSwo
GErogsZWBMvmDAnUASRwhTzXOFm4hVp0hV5IAh0QhmIYhvsVhUQwhYkghlc4
Ajz3bGhjHCewhVnYhV8IhmMYhtS1BmY4BLXFBmI4AoDIc284iIQIF1ZDb2PX
AYEoiIXYiI7YR2LgP484iZQoUWFAhJWYiY7oTMeniZ74iJyIg584imgTirpH
iqjYNB+WiqyIL6vYirCoHpEIhyZQi7v+YQJhETrpgS4m0Em1aItI8ous8Ysy
cwLC2B2zuBsfcBMVBxfLeBO1tjnWZAIjkwIlUI2C4WSfFhmeZhPRSI1zZCY3
kRvTIQZu6Iym5mmJQo0LUAImME+YmAILwB3L2CCe1hrYKBmedgLzJBnUGI3o
aEfFtBujZhzLGD/l1kflZk3cCCzzBCwLUGlw1j/xeI8X4FlxQY0XAALxeJDN
lJCConSh8YwDGRgXGRgA0IzXuIyetoz+81AKsADR2I16lpE2IZPi+BYgkI+h
UZDKeC7x+JGg8Y+hMUopcBMYxZOC4WkxGRpEOZLXpo7G4ZOs4ZFO2R8lsC1B
6WkNcpESCWfDH+CO+jgyDCkYGimWunIuy9iMyQN102GVobGTkBaXUHSNkqiN
zWiRICmNSJmW0XGO9rR+3ZE7J1ACJQCYZ+SMt3iM2agbveiPjGmWwGgcBTWA
sXiZg3lPmLmZw4iInPmZuOOZoMmZlXkIogUCuTOaUmWarEkEH4CagAmLptia
tDkEr5mamjibtbmbRZCLuEmIusmbwokEr3mYlBicw5mcTMCRg6iczmmatxmb
LvOc1AmdqDmV1ZmdwhmW6aGd3vmdSxAEADs=}
} ; # End of proc __tcl3dLogoPwrdLogo200
