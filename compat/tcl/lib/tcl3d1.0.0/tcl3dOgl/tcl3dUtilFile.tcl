#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dUtilFile.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with file handling Tcl3D utility procedures.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dGetTmpDir - Get the name of a temporary directory.
#
#       Synopsis:       tcl3dGetTmpDir {}
#
#       Description:    Return the location of a temporary directory name.
#                       The function checks the following environment variables
#                       first: TMP, TEMP, TMPDIR.
#                       If none of these variables are defined, standard places
#                       are checked (C:/Windows/Temp, /tmp).
#
#       See also:       tcl3dCreateTmpDir
#
###############################################################################

proc tcl3dGetTmpDir {} {
    global tcl_platform env

    set tmpDir ""
    # Try different environment variables.
    if { [info exists env(TMP)] && [file isdirectory $env(TMP)] } {
        set tmpDir $env(TMP)
    } elseif { [info exists env(TEMP)] && [file isdirectory $env(TEMP)] } {
        set tmpDir $env(TEMP)
    } elseif { [info exists env(TMPDIR)] && [file isdirectory $env(TMPDIR)] } {
        set tmpDir $env(TMPDIR)
    } else {
        # Last resort. These directories should be available at least.
        switch $tcl_platform(platform) {
            windows {
                if { [file isdirectory "C:/Windows/Temp"] } {
                    set tmpDir "C:/Windows/Temp"
                } elseif { [file isdirectory "C:/Winnt/Temp"] } {
                    set tmpDir "C:/Winnt/Temp"
                }
            }
            unix {
                if { [file isdirectory "/tmp"] } {
                    set tmpDir "/tmp"
                }
            }
        }
    }
    return [file nativename $tmpDir]
}

###############################################################################
#[@e
#       Name:           tcl3dCreateTmpDir - Create a unique temporary directory.
#
#       Synopsis:       tcl3dCreateTmpDir {}
#
#       Description:    Create a unique temporary directory.
#                       Return the full path name of the created directory.
#                       The new directory is created in the standard temporary
#                       directory as returned by tcl3dGetTmpDir.
#
#       See also:       tcl3dGetTmpDir
#
###############################################################################

proc tcl3dCreateTmpDir {} {
    set masterTmpDir [tcl3dGetTmpDir]
    set i 0
    while { 1 } {
        set tmpDirName [format "tcl3d_%05d.tmp" $i]
        set tmpDir [file join $masterTmpDir $tmpDirName]
        # puts "Checking for directory $masterTmpDir"
        if { [file exists $tmpDir] } {
            # Directory already exists. Try to delete it and recreate it first,
            # before attempting to create new number.
            set retVal [catch { file delete -force $tmpDir } ]
            if { $retVal != 0 } {
                incr i
                continue
            }
        }
        file mkdir $tmpDir
        # puts "\tCreating directory $tmpDir"
        return $tmpDir
    }
}

###############################################################################
#[@e
#       Name:           tcl3dGenExtName - Create a name on the file system.
#
#       Synopsis:       tcl3dGenExtName { fileName }
#
#       Description:    fileName : string
#
#                       Return a valid path name on the file system generated
#                       from the file name specified in "fileName".
#                       Use this function, if writing to a file from a script,
#                       which may be running from within a Starpack. 
#                       If the script is not executed from a Starpack, the
#                       function returns the supplied parameter unchanged.
#
#       See also:       tcl3dGetExtFile
#
###############################################################################

proc tcl3dGenExtName { fileName } {
    if { [string first "vfs" [file system $fileName]] >= 0 } {
        set extDirName [file join [tcl3dGetTmpDir] "tcl3dData.tmp"]
        if { ! [file isdirectory $extDirName] } {
            file mkdir $extDirName
        }
        return [file join $extDirName [file tail $fileName]]
     } else {
         return $fileName
     }
}

###############################################################################
#[@e
#       Name:           tcl3dGetExtFile - Get a name on the file system.
#
#       Synopsis:       tcl3dGetExtFile { fileName { forceOverwrite false } }
#
#       Description:    fileName : string
#
#                       Return a valid path name on the file system generated
#                       from the file name specified in "fileName".
#                       Use this function, if a file is needed for reading
#                       from an external Tcl3D library, like font files (used by
#                       FTGL) or shader files and the script may be executed 
#                       from within a virtual file system (ex. starkit vfs).
#                       The file included in the virtual file system is
#                       transparently copied onto the file system and that path
#                       name is returned. If "forceOverwrite" is set to true,
#                       an existing file with the same name is overwritten.
#                       The path name is built using a system-wide temporary
#                       directory as returned by tcl3dGetTmpDir.
#                       If the script is not executed from within a virtual
#                       file system, the function returns the supplied parameter
#                       unchanged.
#
#       See also:       tcl3dGenExtName
#                       tcl3dGetTmpDir
#
###############################################################################

proc tcl3dGetExtFile { fileName { forceOverwrite false } } {
    if { [string first "vfs" [file system $fileName]] >= 0 } {
        set extDirName [file join [tcl3dGetTmpDir] "tcl3dData.tmp"]
        if { ! [file isdirectory $extDirName] } {
            file mkdir $extDirName
        }
        set extFileName [file join $extDirName [file tail $fileName]]
        if { [file exists $extFileName] && ! $forceOverwrite } {
            # puts "\t$extFileName already exists. No action."
        } else {
            # puts "\tCopy $fileName to $extDirName"
            file copy -force $fileName $extDirName
        }
        # puts "\tReturning <$extFileName>"
        return $extFileName
    }
    # puts "No Starpack: Returning <$fileName>"
    return $fileName
}

###############################################################################
#[@e
#       Name:           tcl3dGetDirList - Get the contents of a directory.
#
#       Synopsis:       tcl3dGetDirList {dirName
#                           {showDirs 1} {showFiles 1}
#                           {showHiddenDirs 1} {showHiddenFiles 1}
#                           {dirPattern *} {filePattern *}}
#
#       Description:    dirName         : string
#                       showDirs        : bool
#                       showFiles       : bool
#                       showHiddenDirs  : bool
#                       showHiddenFiles : bool
#                       dirPattern      : string
#                       filePattern     : string
#
#                       Scan directory "dirName" and return a two-element list
#                       consisting of all directories and files of the scanned
#                       directory.
#                       The first element contains the directory list, where the
#                       pathnames of the directories are absolute pathes.
#                       The second element contains the file list with no path
#                       information.
#                       The result list can be filtered by specifying the other
#                       procdure parameters and should be self-explaining.
#
#       See also:       tcl3dCreateTmpDir
#
###############################################################################

proc tcl3dGetDirList {dirName \
                      {showDirs 1} {showFiles 1} \
                      {showHiddenDirs 1} {showHiddenFiles 1} \
                      {dirPattern *} {filePattern *}} {
    global tcl_platform

    set curDir [pwd]
    set catchVal [catch {cd $dirName}]
    if { $catchVal } {
        return [list]
    }

    set absDirList  [list]
    set relFileList [list]

    if { $showDirs } {
        set relDirList [glob -nocomplain -types d {*}$dirPattern]
        foreach dir $relDirList {
            if { [string index $dir 0] eq "~" } {
                set dir [format "./%s" $dir]
            }
            set absName [file join $dirName $dir]
            lappend absDirList $absName
        }
        if { $showHiddenDirs } {
            set relHiddenDirList \
                [glob -nocomplain -types {d hidden} {*}$dirPattern]
            foreach dir $relHiddenDirList {
                if { $dir eq "." || $dir eq ".." } {
                    continue
                }
                set absName [file join $dirName $dir]
                lappend absDirList $absName
            }
        }
    }
    if { $showFiles } {
        set relFileList [glob -nocomplain -types f {*}$filePattern]
        if { $showHiddenFiles } {
            set relHiddenFileList \
                [glob -nocomplain -types {f hidden} {*}$filePattern]
            if { [llength $relHiddenFileList] != 0 } {
                set relFileList [concat $relFileList $relHiddenFileList]
            }
        }
    }
    cd $curDir

    return [list $absDirList $relFileList]
}

