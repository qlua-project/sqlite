#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dUtilCapture.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module implementing functions for capturing window
#                       contents into an image or file.
#                       Note: All of the functionality requires the help of the
#                       Img extension. Some of the functionality requires the
#                       help of the Twapi extension and is therefore only
#                       available on Windows.
#
#******************************************************************************

proc __tcl3dCaptureInit {} {
    global __tcl3dCaptureInt

    set retVal [catch {package require Img} __tcl3dCaptureInt(Img,version)] 
    set __tcl3dCaptureInt(Img,avail) [expr !$retVal]
    set retVal [catch {package require twapi} __tcl3dCaptureInt(twapi,version)] 
    set __tcl3dCaptureInt(twapi,avail) [expr !$retVal]
}

proc __tcl3dCaptureSubWindow { win img px py ign } {
    if { ![winfo ismapped $win] } {
        return
    }

    regexp {([0-9]*)x([0-9]*)\+([-]*[0-9]*)\+([-]*[0-9]*)} \
        [winfo geometry $win] - w h x y

    if { $x < 0 || $y < 0 } {
        return
    }

    incr px $x
    incr py $y

    # Make an image from this widget
    set tmpImg [image create photo -format window -data $win]
 
    # Copy this image into place on the main image
    $img copy $tmpImg -to $px $py
    image delete $tmpImg

    foreach child [winfo children $win] {
        if { $ign ne "" && ! [string match -nocase $ign $child] } {
            __tcl3dCaptureSubWindow $child $img $px $py $ign
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dWidget2Img - Copy widget content into photo image. 
#
#       Synopsis:       tcl3dWidget2Img { win { ign "" } }
#
#       Description:    win : string (Widget name)
#                       ign : string
#
#                       Copy contents of widget "win" and all of its 
#                       sub-widgets into a photo image.
#                       If "ign" is specified and not the empty string, it is
#                       interpreted as a pattern for widget names, that should 
#                       be ignored while traversing the widget hierarchy.
#                       The pattern is passed to the "string match" command.
#
#                       Return the photo image identifier.
#
#       See also:       tcl3dWidget2File
#                       tcl3dCanvas2Img
#                       tcl3dClipboard2Img
#                       tcl3dWindow2Img
#
###############################################################################

proc tcl3dWidget2Img { win { ign "" } } {
    global __tcl3dCaptureInt

    regexp {([0-9]*)x([0-9]*)\+([0-9]*)\+([0-9]*)} \
            [winfo geometry $win] - w h x y

    if { !$__tcl3dCaptureInt(Img,avail) } {
        set img [image create photo -width $h -height $h]
        $img blank
    } else {
        set img [image create photo -format window -data $win]

        foreach child [winfo children $win] {
            if { $ign ne "" && ! [string match -nocase $ign $child] } {
                __tcl3dCaptureSubWindow $child $img 0 0 $ign
            }
        }
    }
    return $img
}

###############################################################################
#[@e
#       Name:           tcl3dWidget2File  - Copy widget content into image file.
#
#       Synopsis:       tcl3dWidget2File { win fileName { ign "" }
#                                          { fmt "JPEG" } { opts "" } }
#
#       Description:    win      : string (Widget name)
#                       fileName : string
#                       ign      : string
#                       fmt      : string
#                       opts     : string
#
#                       Copy contents of widget "win" and all of its 
#                       sub-widgets into a photo image and save this image to 
#                       file "fileName". The file format handler is determined
#                       with "fmt". Some formats need optional parameters.
#                       These can be supplied in "opts".
#                       See the Img documentation (man img) for a list of format
#                       handlers and options.
#                       If "ign" is specified and not the empty string, it is
#                       interpreted as a pattern for widget names, that should 
#                       be ignored while traversing the widget hierarchy.
#                       The pattern is passed to the "string match" command.
#
#       See also:       tcl3dWidget2Img
#                       tcl3dCanvas2File
#                       tcl3dClipboard2File
#                       tcl3dWindow2File
#
###############################################################################

proc tcl3dWidget2File { win fileName { ign "" } { fmt "JPEG" } { opts "" } } {
    set img [tcl3dWidget2Img $win $ign]

    if { [string length $fileName] != 0 } {
        $img write $fileName -format "$fmt $opts"
    }
    image delete $img
}

###############################################################################
#[@e
#       Name:           tcl3dCanvas2Img - Copy canvas content into photo image. 
#
#       Synopsis:       tcl3dCanvas2Img { canv }
#
#       Description:    canv : string (Widget name)
#
#                       Copy the contents of canvas "canv" into a photo image.
#
#                       Return the photo image identifier.
#
#       See also:       tcl3dCanvas2File
#                       tcl3dWidget2Img
#                       tcl3dClipboard2Img
#                       tcl3dWindow2Img
#
###############################################################################

proc tcl3dCanvas2Img { canv } {
    global __tcl3dCaptureInt

    set region [$canv cget -scrollregion]
    set xsize [lindex $region 2]
    set ysize [lindex $region 3]
    set img [image create photo -width $xsize -height $ysize]
    if { !$__tcl3dCaptureInt(Img,avail) } {
        $img blank
    } else {
        $canv xview moveto 0
        $canv yview moveto 0
        update
        set xr 0.0
        set yr 0.0
        set px 0
        set py 0
        while { $xr < 1.0 } {
            while { $yr < 1.0 } {
                set tmpImg [image create photo -format window -data $canv]
                $img copy $tmpImg -to $px $py
                image delete $tmpImg
                set yr [lindex [$canv yview] 1]
                $canv yview moveto $yr
                set py [expr round ($ysize * [lindex [$canv yview] 0])]
                update
            }
            $canv yview moveto 0
            set yr 0.0
            set py 0

            set xr [lindex [$canv xview] 1]
            $canv xview moveto $xr
            set px [expr round ($xsize * [lindex [$canv xview] 0])]
            update
        }
    }
    return $img
}

###############################################################################
#[@e
#       Name:           tcl3dCanvas2File - Copy canvas content into image file.
#
#       Synopsis:       tcl3dCanvas2File { canv fileName { fmt "JPEG" }
#                                          { opts "" } }
#
#       Description:    canv     : string (Widget name)
#                       fileName : string
#                       fmt      : string
#                       opts     : string
#
#                       Copy the contents of canvas "canv" into a photo image
#                       and save the image to file "fileName". The file format
#                       handler is determined with "fmt". Some formats need
#                       optional parameters. These can be supplied in "opts".
#                       See the Img documentation (man img) for a list of format
#                       handlers and options.
#
#       See also:       tcl3dCanvas2Img
#                       tcl3dWidget2File
#                       tcl3dClipboard2File
#                       tcl3dWindow2File
#
###############################################################################

proc tcl3dCanvas2File { canv fileName { fmt "JPEG" } { opts "" } } {
    set img [tcl3dCanvas2Img $canv]

    if { [string length $fileName] != 0 } {
        $img write $fileName -format "$fmt $opts"
    }
    image delete $img
}

###############################################################################
#[@e
#       Name:           tcl3dClipboard2Img - Copy clipboard content into photo
#                       image.
#
#       Synopsis:       tcl3dClipboard2Img {}
#
#       Description:    Copy the contents of the Windows clipboard into a photo
#                       image.
#
#                       Return the photo image identifier, if successful. 
#                       Otherwise a Tcl error is thrown.
#
#                       Note: This function is currently available only under 
#                             Windows and needs the Twapi extension.
#
#       See also:       tcl3dClipboard2File
#                       tcl3dWidget2Img
#                       tcl3dCanvas2Img
#                       tcl3dWindow2Img
#
###############################################################################

proc tcl3dClipboard2Img {} {
    global __tcl3dCaptureInt

    if { !$__tcl3dCaptureInt(twapi,avail) } {
        error "Twapi extension not available"
    }

    twapi::open_clipboard

    # Assume clipboard content is in format 8 (CF_DIB)
    set retVal [catch {twapi::read_clipboard 8} clipData]
    if { $retVal != 0 } {
        error "Invalid or no content in clipboard"
    }

    # First parse the bitmap data to collect header information
    binary scan $clipData "iiissiiiiii" \
           size width height planes bitcount compression sizeimage \
           xpelspermeter ypelspermeter clrused clrimportant

    # We only handle BITMAPINFOHEADER right now (size must be 40)
    if {$size != 40} {
        error "Unsupported bitmap format. Header size=$size"
    }

    # We need to figure out the offset to the actual bitmap data
    # from the start of the file header. For this we need to know the
    # size of the color table which directly follows the BITMAPINFOHEADER
    if {$bitcount == 0} {
        error "Unsupported format: implicit JPEG or PNG"
    } elseif {$bitcount == 1} {
        set color_table_size 2
    } elseif {$bitcount == 4} {
        # TBD - Not sure if this is the size or the max size
        set color_table_size 16
    } elseif {$bitcount == 8} {
        # TBD - Not sure if this is the size or the max size
        set color_table_size 256
    } elseif {$bitcount == 16 || $bitcount == 32} {
        if {$compression == 0} {
            # BI_RGB
            set color_table_size $clrused
        } elseif {$compression == 3} {
            # BI_BITFIELDS
            set color_table_size 3
        } else {
            error "Unsupported compression type '$compression' for bitcount value $bitcount"
        }
    } elseif {$bitcount == 24} {
        set color_table_size $clrused
    } else {
        error "Unsupported value '$bitcount' in bitmap bitcount field"
    }

    set phImg [image create photo]
    set filehdr_size 14                 ; # sizeof(BITMAPFILEHEADER)
    set bitmap_file_offset [expr {$filehdr_size+$size+($color_table_size*4)}]
    set filehdr [binary format "a2 i x2 x2 i" \
                 "BM" [expr {$filehdr_size + [string length $clipData]}] \
                 $bitmap_file_offset]

    append filehdr $clipData
    $phImg put $filehdr -format bmp

    twapi::close_clipboard
    return $phImg
}

###############################################################################
#[@e
#       Name:           tcl3dClipboard2File  - Copy clipboard content into file.
#
#       Synopsis:       tcl3dClipboard2File { fileName { fmt "JPEG" }
#                       { opts "" } }
#
#       Description:    fileName : string
#                       fmt      : string
#                       opts     : string
#
#                       Copy the contents of the Windows clipboard into a photo
#                       image and save the image to file "fileName". The file 
#                       format handler is determined with "fmt". Some formats
#                       need optional parameters. 
#                       These can be supplied in "opts".
#                       See the Img documentation (man img) for a list of format
#                       handlers and options.
#
#                       Note: This function is currently available only under
#                             Windows and needs the Twapi extension.
#
#       See also:       tcl3dClipboard2Img
#                       tcl3dWidget2File
#                       tcl3dCanvas2File
#                       tcl3dWindow2File
#
###############################################################################

proc tcl3dClipboard2File { fileName { fmt "JPEG" } { opts "" } } {
    # If the clipboard is empty or the image is large, it may take some time
    # for the clipboard to have a valid content. So try it 5 times.
    set count 5
    while { $count > 0 } {
        set retVal [catch { tcl3dClipboard2Img } img]
        if { $retVal == 0 } {
            break
        }
        after 200
        incr count -1
    }

    if { [string length $fileName] != 0 } {
        $img write $fileName -format "$fmt $opts"
    }
    image delete $img
}

###############################################################################
#[@e
#       Name:           tcl3dImg2Clipboard - Copy photo image into clipboard.
#
#       Synopsis:       tcl3dImg2Clipboard { phImg }
#
#       Description:    phImg : string (Photo image identifier)
#
#                       Copy photo image "phImg" into the Windows clipboard.
#
#                       Note: This function is currently available only under
#                             Windows and needs the Twapi extension.
#
#       See also:       tcl3dClipboard2Img
#
###############################################################################

proc tcl3dImg2Clipboard { phImg } {
    global __tcl3dCaptureInt

    if { ! $__tcl3dCaptureInt(twapi,avail) } {
        error "tcl3dImg2Clipboard: Twapi extension not available"
    }
    if { ! $__tcl3dCaptureInt(Img,avail) } {
        error "tcl3dImg2Clipboard: Img extension not available"
    }

    set retVal [catch { twapi::open_clipboard }]
    if { $retVal != 0 } {
        error "tcl3dImg2Clipboard: Clipboard cannot be opened"
    }
    twapi::empty_clipboard

    # First 14 bytes are bitmap fileheader - get rid of this.
    if { [package vsatisfies $__tcl3dCaptureInt(Img,version) "2.0-"] } {
	# Img 2.0 returns image data as binary string.
        set data [string range [$phImg data -format bmp] 14 end]
    } else {
        # Img 1.4 returns image data as base64 encoded string.
        set data [string range [binary decode base64 [$phImg data -format bmp]] 14 end]
    }
    twapi::write_clipboard 8 $data
    twapi::close_clipboard
}

###############################################################################
#[@e
#       Name:           tcl3dWindow2Clipboard - Copy window contents into 
#                       clipboard.
#
#       Synopsis:       tcl3dWindow2Clipboard {}
#
#       Description:    Copy the contents of the top level window (Alt-PrtSc) 
#                       into the Windows clipboard.
#
#                       Note: This function is currently available only under
#                             Windows and needs the Twapi extension.
#
#       See also:       tcl3dClipboard2Img
#
###############################################################################

proc tcl3dWindow2Clipboard {} {
    global __tcl3dCaptureInt

    if { !$__tcl3dCaptureInt(twapi,avail) } {
        error "Twapi extension not available"
    }
    # Clear clipboard before making a screenshot of the current window.
    set retVal [catch { twapi::open_clipboard }]
    if { $retVal != 0 } {
        error "tcl3dWindow2Clipboard: Clipboard cannot be opened"
    }
    twapi::empty_clipboard
    twapi::close_clipboard
    twapi::send_keys {%{PRTSC}{ALT}}
    update
}

###############################################################################
#[@e
#       Name:           tcl3dDesktop2Clipboard - Copy desktop contents into
#                       clipboard.
#
#       Synopsis:       tcl3dDesktop2Clipboard {}
#
#       Description:    Copy the contents of the whole desktop (PrtSc) into the 
#                       Windows clipboard.
#
#                       Note: This function is currently available only under
#                             Windows and needs the Twapi extension.
#
#       See also:       tcl3dWindow2Clipboard
#
###############################################################################

proc tcl3dDesktop2Clipboard {} {
    global __tcl3dCaptureInt

    if { !$__tcl3dCaptureInt(twapi,avail) } {
        error "Twapi extension not available"
    }
    twapi::send_keys {{PRTSC}}
    update
}

###############################################################################
#[@e
#       Name:           tcl3dWindow2Img - Copy window contents into photo image.
#
#       Synopsis:       tcl3dWindow2Img {}
#
#       Description:    Copy the contents of the top level window into a photo 
#                       image.
#                       Return the photo image identifier, if successful. 
#                       Otherwise a Tcl error is thrown.
#
#       See also:       tcl3dWindow2File
#
###############################################################################

proc tcl3dWindow2Img {} {
    if { $::tcl_platform(platform) eq "windows" } {
        tcl3dWindow2Clipboard
        return [tcl3dClipboard2Img]
    } else {
        set dumpProg [auto_execok "import"]
        if { $dumpProg ne "" } {
            set fp [open "|$dumpProg -frame -window [winfo id .] png:-" "r"]
            fconfigure $fp -translation binary
            set data [read $fp]
            close $fp
            set phImg [image create photo -data $data]
            return $phImg
        } else {
            error "Screenshot on X11 needs the import command (ImageMagick)"
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dWindow2File -  Copy window contents into file.
#
#       Synopsis:       tcl3dWindow2File { fileName { fmt "JPEG" } { opts "" } }
#
#       Description:    fileName : string
#                       fmt      : string
#                       opts     : string
#
#                       Copy the contents of the top level window into a photo
#                       image and save the image to file "fileName". The file 
#                       format handler is determined with "fmt".
#                       Some formats need optional parameters. These can be
#                       supplied in "opts".
#                       See the Img documentation (man img) for a list of format
#                       handlers and options.
#
#       See also:       tcl3dWindow2Img
#
###############################################################################

proc tcl3dWindow2File { fileName { fmt "JPEG" } { opts "" } } {
    if { $::tcl_platform(platform) eq "windows" } {
        tcl3dWindow2Clipboard
        tcl3dClipboard2File $fileName $fmt $opts
    } else {
        set img [tcl3dWindow2Img]
        if { [string length $fileName] != 0 } {
            $img write $fileName -format "$fmt $opts"
        }
        image delete $img
    }
}

__tcl3dCaptureInit
