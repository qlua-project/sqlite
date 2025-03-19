#******************************************************************************
#
#       Copyright:      2007-2022 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dGl2ps
#       Filename:       tcl3dGl2psQuery.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with query procedures related to
#                       the GL2PS module.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dGl2psGetVersion - Get GL2PS version string.
#
#       Synopsis:       tcl3dGl2psGetVersion {}
#
#       Description:    Return the version string of the wrapped GL2PS library.
#                       The version is returned as "Major.Minor.Patch".
#
#       See also:       tcl3dOglGetVersions
#                       tcl3dGetLibraryInfo
#
###############################################################################

proc tcl3dGl2psGetVersion {} {
    if { [info exists ::GL2PS_MAJOR_VERSION] }  {
        return [format "%d.%d.%d" \
                $::GL2PS_MAJOR_VERSION \
                $::GL2PS_MINOR_VERSION \
                $::GL2PS_PATCH_VERSION]
    } else {
        return ""
    }
}
