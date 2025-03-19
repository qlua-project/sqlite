#******************************************************************************
#
#       Copyright:      2010-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dUtilImg.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl utility module for handling images.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dReadImg - Read an image from file.
#
#       Synopsis:       tcl3dReadImg { imgName { ignoreAlphaChannel false } }
#
#       Description:    imgName           : string
#                       ignoreAlphaChannel: bool
#
#                       Try to read the image data stored in file "imgName" and
#                       creates a Tcl3D Vector, which can be used to supply a
#                       texture to OpenGL glTexImg* functions.
#                       If "ignoreAlphaChannel" is set to true, an alpha channel
#                       available in the image file, is ignored.
#
#                       Return a dictionary with the following keys containing
#                       information about the photo image:
#                       "data"   : The Tcl3D Vector.
#                       "width"  : Width of the image.
#                       "height" : Height of the image.
#                       "chans"  : Number of image channels.
#                       "format" : $::GL_RGB  (3-channel images) or
#                                  $::GL_RBGA (4-channel images)
#
#                       If the file contains no image data or an unsupported 
#                       format, a Tcl error is thrown.
#
#                       Notes:
#                       You should include a "package require Img" to have 
#                       support for a large number of image file formats.
#                       You are responsible to free the memory allocated for
#                       the Tcl3D Vector.
#
#                       Example:
#                       # Create the Tcl3D Vector containing the image data.
#                       set img [tcl3dReadImg "myImage.tga"]
#                       # Use the information from the dictionary for texturing.
#                       glTexImage2D GL_TEXTURE_2D 0 [dict get $img format] \
#                                   [dict get $img width] [dict get $img height] \
#                                   0 [dict get $img format] GL_UNSIGNED_BYTE \
#                                   [dict get $img data]
#                       # Free the memory of the Tcl3D Vector.
#                       [dict get $img data] delete
#
#       See also:       tcl3dVectorFromPhoto
#
###############################################################################

proc tcl3dReadImg { imgName { ignoreAlphaChannel false } } {
    global g_Demo

    set retVal [catch {set phImg [image create photo -file $imgName]} err1]
    if { $retVal != 0 } {
        error "Error reading image $imgName ($err1)"
    } else {
        set w [image width  $phImg]
        set h [image height $phImg]
        set n [tcl3dPhotoChans $phImg]
        if { $ignoreAlphaChannel } {
            incr n -1
        }
        set texImg [tcl3dVectorFromPhoto $phImg $n]
        image delete $phImg
    }

    if { $n == 3 } {
        set type $::GL_RGB
    } else {
       set type $::GL_RGBA
    }

    dict set imgDict "data"   $texImg
    dict set imgDict "width"  $w
    dict set imgDict "height" $h
    dict set imgDict "format" $type
    dict set imgDict "chans"  $n
    return $imgDict
}
