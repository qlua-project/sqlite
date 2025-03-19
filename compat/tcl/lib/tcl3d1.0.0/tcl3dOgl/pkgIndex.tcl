#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       pkgIndex.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl index file for the tcl3dOgl package.
#
#******************************************************************************

proc __tcl3dOglSourcePkgs { dir } {
    # Source the files from sub-module tcl3dOgl
    source -encoding utf-8 [file join $dir tcl3dOglQuery.tcl]
    source -encoding utf-8 [file join $dir tcl3dOglStateList.tcl]
    source -encoding utf-8 [file join $dir tcl3dOglHelp.tcl]
    source -encoding utf-8 [file join $dir tcl3dOglFormats.tcl]
    source -encoding utf-8 [file join $dir tcl3dOglShaderUtil.tcl]

    load [file join $dir tcl3dOgl[info sharedlibextension]] Tcl3dogl

    source -encoding utf-8 [file join $dir tcl3dShapesGlut.tcl]
    source -encoding utf-8 [file join $dir tcl3dShapesGlus.tcl]
    # Note: This file must be loaded after the wrapped OGL library,
    # because of the redefined glMultiDrawElements function.
    source -encoding utf-8 [file join $dir tcl3dOglUtil.tcl]

    # Source the file from former sub-module tcl3dDemoUtil
    source -encoding utf-8 [file join $dir tcl3dDemoHeightMap.tcl]

    # Source the files from former sub-module tcl3dUtil
    source -encoding utf-8 [file join $dir tcl3dGuiAutoscroll.tcl]
    source -encoding utf-8 [file join $dir tcl3dGuiDirSelect.tcl]
    source -encoding utf-8 [file join $dir tcl3dGuiWidgets.tcl]
    source -encoding utf-8 [file join $dir tcl3dGuiConsole.tcl]
    source -encoding utf-8 [file join $dir tcl3dGuiToolhelp.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilColors.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilImg.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilInfo.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilFile.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilTrackball.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilLogo.tcl]
    source -encoding utf-8 [file join $dir tcl3dUtilCapture.tcl]
    source -encoding utf-8 [file join $dir tcl3dVecMath.tcl]
    source -encoding utf-8 [file join $dir tcl3dGeoMath.tcl]
    source -encoding utf-8 [file join $dir tcl3dVector.tcl]
}

if { ! [package vsatisfies [package provide Tcl] 8.6-] } {
    return
}
package ifneeded tcl3dogl 1.0.0 "[list __tcl3dOglSourcePkgs $dir]"
