#******************************************************************************
#
#       Copyright:      2005-2022 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dGauges
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the tcl3dGauges package.
#
#******************************************************************************

proc __tcl3dGaugesSourcePkgs { dir } {
    source -encoding utf-8 [file join $dir gaugeImgs.tcl]
    source -encoding utf-8 [file join $dir airspeed.tcl]
    source -encoding utf-8 [file join $dir altimeter.tcl]
    source -encoding utf-8 [file join $dir compass.tcl]
    source -encoding utf-8 [file join $dir tiltmeter.tcl]

    package provide tcl3dgauges 1.0.0
}

if { ! [package vsatisfies [package provide Tcl] 8.6-] } {
    return
}

# All modules are exported as package tcl3dgauges
package ifneeded tcl3dgauges 1.0.0 "[list __tcl3dGaugesSourcePkgs $dir]"
