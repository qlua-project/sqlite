#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dDemoHeightMap.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module to create a heightmap from a photo image.
#                       This functionality is needed for NeHe tutorial 45.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dDemoUtilHeightmapFromPhoto - Create a heightmap 
#                       from an image.
#
#       Synopsis:       tcl3dDemoUtilHeightmapFromPhoto {
#                               phImg flHeightScale flResolution }
#
#       Description:    phImg           : string (Photo image identifier)
#                       flHeightScale   : float
#                       flResolution    : float
#
#                       Create two Tcl3D vectors containing the vertices and
#                       texture coordinates of a heightmap created from the image
#                       data of photo image "phImg".
#                       The height values can be scaled with "flHeightScale".
#                       "flResolution" indicates how many pixels form a vertex.
#
#                       The two vectors and the number of vertices generated are
#                       returned as a Tcl list:
#                       Index 0: Vertex vector
#                       Index 1: Texture coordinates vector
#                       Index 2: Number of vertices
#
#       See also:
#
###############################################################################

proc tcl3dDemoUtilHeightmapFromPhoto { phImg flHeightScale flResolution } {
    set w [image width  $phImg]
    set h [image height $phImg]
    set n [tcl3dPhotoChans $phImg]
    if { $n < 3 } {
        error "Photo must have 3 or more channels"
    }
    set numVtx [expr {int ($w * $h * 6 / ($flResolution * $flResolution))}]

    set vtxVec [tcl3dVector GLfloat [expr {3 * $numVtx}]]
    set texVec [tcl3dVector GLfloat [expr {2 * $numVtx}]]
    tcl3dDemoUtilPhoto2Heightmap $phImg $vtxVec $texVec \
                                 $flHeightScale $flResolution
    return [list $vtxVec $texVec $numVtx]
}
