#******************************************************************************
#
#       Copyright:      2010-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dGuiDirSelect.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with functions for creating megawidgets to
#                       select directories or files.
#                       The megawidget consists of a combobox used for 
#                       selection and display of the directory of file name.
#                       Next to the combobox is a label displaying a green OK
#                       or red Bad bitmap indicating a valid resp. invalid
#                       directory or file name.
#                       If the directory or file name is valid (i.e. exists)
#                       the virtual event <<NameValid>> is generated.
#                       The last widget is a button to open the standard Tk 
#                       directory or file chooser.
#
#******************************************************************************

namespace eval ::tcl3dDirSelect {

    namespace export SetFileTypes
    namespace export GetValue
    namespace export SetValue
    namespace export CreateDirSelect
    namespace export CreateFileSelect

    variable sett

    proc BmpDataOK_ {} {
        return {
        #define ok_width 16
        #define ok_height 16
        static char ok_bits[] = {
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40,
          0x00, 0x60, 0x00, 0x30, 0x00, 0x18, 0x02, 0x0c, 0x06, 0x06,
          0x0c, 0x03, 0x98, 0x01, 0xf0, 0x00, 0x60, 0x00, 0x00, 0x00,
          0x00, 0x00};
        }
    }

    proc BmpDataOK { {foreground "black"} {background ""} } {
        return [image create bitmap -data [BmpDataOK_] \
               -background $background -foreground $foreground]
    }

    proc BmpDataHalt_ {} {
        return {
            #define halt_width 16
            #define halt_height 16
            static unsigned char halt_bits[] = {
              0x00, 0x00, 0xe0, 0x07, 0x10, 0x08, 0x88, 0x11, 0x84, 0x21,
              0x82, 0x41, 0x82, 0x41, 0x82, 0x41, 0x82, 0x41, 0x82, 0x41,
              0x02, 0x40, 0x84, 0x21, 0x88, 0x11, 0x10, 0x08, 0xe0, 0x07,
              0x00, 0x00};
        }
    }

    proc BmpDataHalt { {foreground "black"} {background ""} } {
        return [image create bitmap -data [BmpDataHalt_] \
               -background $background -foreground $foreground]
    }

    # Internal function caching bitmaps for the OK and Bad images.
    proc CreateOkBadBitmaps {} {
        variable sett

        if { ! [info exists sett(bmpZoomOk)] } {
            set sett(bmpZoomOk) [BmpDataOK "darkgreen"]
        }
        if { ! [info exists sett(bmpZoomBad)] } {
            set sett(bmpZoomBad) [BmpDataHalt "red"]
        }
    }

    # Internal function storing the current value of a combobox
    # before opening the selection list.
    proc SaveComboEntry { comboId } {
        variable sett

        set sett($comboId,saveEntry) [$comboId get]
    }

    # Internal function adjusting the text of the combobox.
    # Note: The -width option of the combobox always returns the initial
    # width of the combobox. (TODO)
    proc AdjustText { comboId } {
        variable sett

        $comboId selection clear
        $comboId icursor end
        $comboId configure -justify right
        if { [$comboId cget -width] < [string length [$comboId get]] } {
            $comboId configure -justify right
            $comboId xview [$comboId index end]
        } else {
            $comboId configure -justify left
            $comboId xview 0
        }
        #puts "AdjustText [$comboId cget -width] ?? [string length [$comboId get]]"
    }

    # Internal function called by the ComboboxSelected virtual event.
    # It appends the new entry from the combobox selection list (which is a 
    # relative path name) to the (absolute) path name contained in the
    # combobox entry widget.
    proc UpdateNewEntry { comboId { appendSlash true } } {
        variable sett

        set oldPath ""
        if { [info exists sett($comboId,saveEntry)] } {
            set oldPath $sett($comboId,saveEntry)
        }
        if { $oldPath ne "" && [string index $oldPath end] ne "/" } {
            set oldPath [file dirname $oldPath]
            set oldPath [format "%s/" [string trimright $oldPath "/"]]
        }
        set curPath [$comboId get]
        if { [file pathtype $curPath] eq "absolute" } {
            set fullPath $curPath
        } else {
            set fullPath [format "%s%s" $oldPath $curPath]
        }
        if { $appendSlash && [file isdirectory $fullPath] } {
            set fullPath [format "%s/" [string trimright $fullPath "/"]]
        }
        $comboId set $fullPath
        tcl3dToolhelpAddBinding $comboId $fullPath
        AdjustText $comboId
        if { [file isfile $fullPath] } {
            event generate $comboId <<FileSelected>>
        } elseif { [file isdirectory $fullPath] } {
            event generate $comboId <<DirSelected>>
        }
    }

    # Internal function calling the standard Tk directory chooser.
    # It generates a <<NameValid>> virtual event, so that the caller
    # of the megawidget will be notified about the new entry.
    proc SelectDir { comboId labelId useTkChooser } {
        variable sett

        set initDir [string trimright [$comboId get] "/"]
        if { ! [file isdirectory $initDir] } {
            set initDir [pwd]
        }
        if { $useTkChooser } {
            set tmpDir [tk_chooseDirectory -initialdir $initDir \
                                           -mustexist 1 \
                                           -title $sett($comboId,msg)]
        }
        if { $tmpDir ne "" && [file isdirectory $tmpDir] } {
            $comboId set $tmpDir
            UpdateNewEntry $comboId
            CheckDirEntry $comboId $labelId
            focus $comboId
            event generate $comboId <<NameValid>>
        }
    }

    # Internal function calling the standard Tk file chooser.
    # It generates a <<NameValid>> virtual event, so that the caller 
    # of the megawidget will be notified about the new entry.
    proc SelectFile { comboId labelId mode useTkChooser } {
        variable sett

        set initFile [string trimright [$comboId get] "/"]
        if { [file isdirectory $initFile] } {
            set initDir $initFile
        } else {
            set initDir [file dirname $initFile]
        }
        if { ! [file isfile $initFile] } {
            set initFile ""
        } else {
            set initFile [file tail $initFile]
        }
        if { $useTkChooser } {
            if { $mode eq "open" } {
                set fileName [tk_getOpenFile -filetypes $sett($comboId,fileTypes) \
                                             -initialdir $initDir \
                                             -initialfile $initFile \
                                             -title $sett($comboId,msg)]
            } else {
                set fileName [tk_getSaveFile -filetypes $sett($comboId,fileTypes) \
                                             -initialfile $initFile \
                                             -initialdir  $initDir \
                                             -title $sett($comboId,msg)]
            }
        }
        if { $fileName ne "" && [file isfile $fileName] } {
            $comboId set $fileName
            UpdateNewEntry $comboId false
            CheckFileEntry $comboId $labelId
            focus $comboId
            event generate $comboId <<NameValid>>
        }
    }

    # Internal function checking if the current entry of the combobox
    # is an existing directory and setting the appropriate bitmap.
    proc CheckDirEntry { comboId labelId } {
        variable sett

        ::tcl3dDirSelect::CreateOkBadBitmaps
        set curPath [$comboId get]
        if { ! [file isdirectory $curPath] } {
            $labelId configure -image $sett(bmpZoomBad)
        } else {
            $labelId configure -image $sett(bmpZoomOk)
            tcl3dToolhelpAddBinding $comboId $curPath
            focus $comboId
            event generate $comboId <<NameValid>>
        }
    }

    # Internal function checking if the current entry of the combobox
    # is an existing file and setting the appropriate bitmap.
    proc CheckFileEntry { comboId labelId } {
        variable sett

        ::tcl3dDirSelect::CreateOkBadBitmaps
        set curPath [$comboId get]
        if { ! [file isfile $curPath] } {
            $labelId configure -image $sett(bmpZoomBad)
        } else {
            $labelId configure -image $sett(bmpZoomOk)
            tcl3dToolhelpAddBinding $comboId $curPath
            focus $comboId
            event generate $comboId <<NameValid>>
        }
    }

    # Internal function called by the Any-KeyRelease event.
    # It checks the combobox entry, if it is a valid directory and
    # fills up the combobox selection list with all possible directories.
    proc CheckDir { comboId labelId } {
        variable sett

        CheckDirEntry $comboId $labelId
        set curPath [$comboId get]
        set lastSlash [string last "/" $curPath]
        set preFix  [string range $curPath 0 $lastSlash]
        set postFix [string range $curPath [expr $lastSlash +1] end]
        set tmpList [lindex [tcl3dGetDirList $preFix 1 0 1 1 "${postFix}*"] 0]
        set dirList [list]
        foreach dir [lsort $tmpList] {
            lappend dirList [file tail $dir]
        }
        $comboId configure -values $dirList
    }

    # Internal function called by the Any-KeyRelease event.
    # It checks the combobox entry, if it is a valid file name and
    # fills up the combobox selection list with all possible directories
    # and file names.
    proc CheckFile { comboId labelId } {
        variable sett

        CheckFileEntry $comboId $labelId
        set curPath [$comboId get]
        set lastSlash [string last "/" $curPath]
        set preFix  [string range $curPath 0 $lastSlash]
        set postFix [string range $curPath [expr $lastSlash +1] end]
        set contList [tcl3dGetDirList $preFix 1 1 1 1 "*" "${postFix}*"]
        set tmpList  [lsort [lindex $contList 0]]
        set fileList [lsort [lindex $contList 1]]
        set dirList [list]
        foreach absDir $tmpList {
            set relDir [format "%s/" [string trimright [file tail $absDir] "/"]]
            lappend dirList $relDir
        }
        $comboId configure -values [concat $dirList $fileList]
    }

    # Set the list of file types used for the "Open file" dialogs.
    # Default list is: { {"All files" "*"} }
    proc SetFileTypes { comboId typeList } {
        variable sett

        set sett($comboId,fileTypes) $typeList
    }

    # Return the current value of the combobox.
    # This function is typically used in a binding of the main program:
    # bind $comboId <<NameValid>> "::tcl3dDirSelect::GetValue $comboId"
    proc GetValue { comboId } {
        return [$comboId get]
    }

    # Set the current combobox value.
    proc SetValue { comboId fileOrDir } {
        variable sett

        if { [file isdirectory $fileOrDir] } {
            set fileOrDir [format "%s/" [string trimright $fileOrDir "/"]]
            CheckDirEntry $comboId $sett($comboId,label)
        } else {
            CheckFileEntry $comboId $sett($comboId,label)
        }
        $comboId set $fileOrDir
        tcl3dToolhelpAddBinding $comboId $fileOrDir
    }

    # Create a megawidget for directory selection.
    # "masterFr" is the frame, where the components of the megawidgets are placed.
    # "initDir" is the initial name of the directory to be displayed in the combobox.
    # "buttonText" is an optional string displayed on the select button. If an empty string
    # is supplied, the select button is not drawn.
    # "msg" is an optional string displayed in the Tk directory chooser.
    proc CreateDirSelect { masterFr initDir \
                           { buttonText "Select ..." } \
                           { msg "Select directory" } } {
        variable sett

        set comboId ${masterFr}.cb
        set sett($comboId,msg) $msg
        set sett($comboId,label) $masterFr.l
        ttk::combobox $comboId -postcommand "::tcl3dDirSelect::SaveComboEntry $comboId"
        bind $masterFr.cb <Any-KeyRelease> \
                          "::tcl3dDirSelect::CheckDir $masterFr.cb $masterFr.l"
        bind $masterFr.cb <<ComboboxSelected>> \
                          "::tcl3dDirSelect::UpdateNewEntry $masterFr.cb ; ::tcl3dDirSelect::CheckDir $masterFr.cb $masterFr.l"
        bind $masterFr.cb <Configure> "::tcl3dDirSelect::AdjustText $masterFr.cb"

        label $masterFr.l
        pack $masterFr.cb -side left -anchor w -fill x -expand 1 -padx 1
        pack $masterFr.l  -side left -anchor w

        if { $buttonText ne "" } {
            ttk::button $masterFr.b -text $buttonText \
                        -command "::tcl3dDirSelect::SelectDir $masterFr.cb $masterFr.l 1"
            pack $masterFr.b -side left -anchor w
        }
        SetValue $comboId $initDir
        ::tcl3dDirSelect::CheckDir $masterFr.cb $masterFr.l
        UpdateNewEntry $comboId true
        focus $comboId
        return $comboId
    }

    # Create a megawidget for file selection.
    # "masterFr" is the frame, where the components of the megawidgets are placed.
    # "initFile" is the initial file name to be displayed in the combobox.
    # "mode" must be either "open" for a file to open or "save" for saving a file.
    # "buttonText" is an optional string displayed on the select button. If an empty string
    # is supplied, the select button is not drawn.
    # "msg" is an optional string displayed in the Tk file chooser.
    proc CreateFileSelect { masterFr initFile mode \
                           { buttonText "Select ..." } \
                           { msg "Select file" } } {
        variable sett

        set comboId ${masterFr}.cb
        set sett($comboId,msg) $msg
        set sett($comboId,label) $masterFr.l
        SetFileTypes $comboId { {"All files" "*"} }
        ttk::combobox $comboId -postcommand "::tcl3dDirSelect::SaveComboEntry $comboId"
        bind $masterFr.cb <Any-KeyRelease> \
                          "::tcl3dDirSelect::CheckFile $masterFr.cb $masterFr.l"
        bind $masterFr.cb <<ComboboxSelected>> \
                          "::tcl3dDirSelect::UpdateNewEntry $masterFr.cb false ; ::tcl3dDirSelect::CheckFile $masterFr.cb $masterFr.l"
        bind $masterFr.cb <Configure> "::tcl3dDirSelect::AdjustText $masterFr.cb"

        label $masterFr.l
        pack $masterFr.cb -side left -anchor w -fill x -expand 1 -padx 1
        pack $masterFr.l -side left -anchor w

        if { $buttonText ne "" } {
            ttk::button $masterFr.b -text $buttonText \
                        -command "::tcl3dDirSelect::SelectFile $masterFr.cb $masterFr.l $mode 1"
            pack $masterFr.b -side left -anchor w
        }
        SetValue $comboId $initFile
        ::tcl3dDirSelect::CheckFile $masterFr.cb $masterFr.l
        UpdateNewEntry $comboId true
        focus $comboId
        return $comboId
    }
}
