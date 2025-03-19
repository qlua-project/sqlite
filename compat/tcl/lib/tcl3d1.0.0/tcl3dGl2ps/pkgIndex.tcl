#******************************************************************************
#
#       Copyright:      2006-2022 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dGl2ps
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the tcl3dGl2ps package.
#
#******************************************************************************

proc __tcl3dGl2psSourcePkgs { dir } {
    source -encoding utf-8 [file join $dir tcl3dGl2psQuery.tcl]
    load [file join $dir tcl3dGl2ps[info sharedlibextension]] Tcl3dgl2ps
    source -encoding utf-8 [file join $dir tcl3dGl2psUtil.tcl]
}

if { ! [package vsatisfies [package provide Tcl] 8.6-] } {
    return
}
package ifneeded tcl3dgl2ps 1.0.0 "[list __tcl3dGl2psSourcePkgs $dir]"
