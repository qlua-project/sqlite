#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the Tcl3D package.
#
#******************************************************************************

# All Tcl3D packages need at least Tcl/Tk 8.6
if { ! [package vsatisfies [package provide Tcl] 8.6-] } {
    return
}

# Extend the auto_path to make Tcl3D subpackages available
if {[lsearch -exact $::auto_path $dir] == -1} {
    lappend ::auto_path $dir
}

proc __tcl3dSourcePkgs { dir } {
    set subPkgs [list tcl3dogl tcl3dgauges tcl3dftgl tcl3dsdl tcl3dgl2ps tcl3dosg]
    foreach pkg $subPkgs {
        set retVal [catch {package require $pkg} ::__tcl3dPkgInfo($pkg,version)]
        set ::__tcl3dPkgInfo($pkg,avail) [expr !$retVal]
    }

    # Check, if extension Tkgl (a newer version of Togl) is available.
    # If yes, make the command tkgl available as togl, so Tcl3D scripts
    # run without modifications. The built-in Togl is renamed to toglv1.
    # If Tkgl is not available, the built-in Togl widget is used.
    # Note, that the Togl widget is not available on MacOS.
    set pkg Tkgl
    set retVal [catch {package require $pkg} ::__tcl3dPkgInfo($pkg,version)]
    set ::__tcl3dPkgInfo($pkg,avail) [expr !$retVal]
    if { $retVal == 0 } {
        proc ::MyTogl { args } {
            ::tkgl {*}$args -tcl3d true
        }

        if { [info commands togl] eq "togl" } {
            rename ::togl ::toglv1
        }
        interp alias {} ::togl {} ::MyTogl
    }

    package provide tcl3d 1.0.0
}

package ifneeded tcl3d 1.0.0 "[list __tcl3dSourcePkgs $dir]"
