#******************************************************************************
#
#       Copyright:      2009-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dOglFormats.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with procedures related to image and texture
#                       formats and types.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dOglGetFormatList - Get OpenGL formats.
#
#       Synopsis:       tcl3dOglGetFormatList { { patt * } }
#
#       Description:    Return a sorted list of OpenGL format names.
#
#       See also:       
#
###############################################################################

proc tcl3dOglGetFormatList { { patt * } } {
    return [lsort [array names ::__tcl3dOglFormats $patt]]
}

# Key is format name. Value is number of channels.
array set ::__tcl3dOglFormats {
    GL_RED              1
    GL_GREEN            1
    GL_BLUE             1
    GL_ALPHA            1
    GL_RGB              3
    GL_BGR              3
    GL_RGBA             4
    GL_BGRA             4
    GL_LUMINANCE        1
    GL_LUMINANCE_ALPHA  2
    GL_COLOR_INDEX      1
    GL_STENCIL_INDEX    1
    GL_DEPTH_COMPONENT  1
}

# Key is type name. Value is number of bytes and storage type name.
array set ::__tcl3dOglTypes {
    GL_UNSIGNED_BYTE               {1 GLubyte}
    GL_BYTE                        {1 GLbyte}
    GL_BITMAP                      {1 GLubyte}
    GL_UNSIGNED_SHORT              {2 GLushort}
    GL_SHORT                       {2 GLshort}
    GL_UNSIGNED_INT                {4 GLuint}
    GL_INT                         {4 GLint}
    GL_FLOAT                       {4 GLfloat}
    GL_UNSIGNED_BYTE_3_3_2         {1 GLubyte}
    GL_UNSIGNED_BYTE_2_3_3_REV     {1 GLubyte}
    GL_UNSIGNED_SHORT_5_6_5        {2 GLushort}
    GL_UNSIGNED_SHORT_5_6_5_REV    {2 GLushort}
    GL_UNSIGNED_SHORT_4_4_4_4      {2 GLushort}
    GL_UNSIGNED_SHORT_4_4_4_4_REV  {2 GLushort}
    GL_UNSIGNED_SHORT_5_5_5_1      {2 GLushort}
    GL_UNSIGNED_SHORT_1_5_5_5_REV  {2 GLushort}
    GL_UNSIGNED_INT_8_8_8_8        {4 GLuint}
    GL_UNSIGNED_INT_8_8_8_8_REV    {4 GLuint}
    GL_UNSIGNED_INT_10_10_10_2     {4 GLuint}
    GL_UNSIGNED_INT_2_10_10_10_REV {4 GLuint}
}

# The internal formats of the specified texture.
# Key is format name. Value is number of channels.
array set ::__tcl3dOglInternalFormats {
    GL_ALPHA                            1
    GL_ALPHA4                           1
    GL_ALPHA8                           1
    GL_ALPHA12                          1
    GL_ALPHA16                          1
    GL_COMPRESSED_ALPHA                 1
    GL_COMPRESSED_LUMINANCE             1
    GL_COMPRESSED_LUMINANCE_ALPHA       2
    GL_COMPRESSED_INTENSITY             1
    GL_COMPRESSED_RGB                   3
    GL_COMPRESSED_RGBA                  4
    GL_DEPTH_COMPONENT                  1
    GL_DEPTH_COMPONENT16                1
    GL_DEPTH_COMPONENT24                1
    GL_DEPTH_COMPONENT32                1
    GL_LUMINANCE                        1
    GL_LUMINANCE4                       1
    GL_LUMINANCE8                       1
    GL_LUMINANCE12                      1
    GL_LUMINANCE16                      1
    GL_LUMINANCE_ALPHA                  2
    GL_LUMINANCE4_ALPHA4                2
    GL_LUMINANCE6_ALPHA2                2
    GL_LUMINANCE8_ALPHA8                2
    GL_LUMINANCE12_ALPHA4               2
    GL_LUMINANCE12_ALPHA12              2
    GL_LUMINANCE16_ALPHA16              2
    GL_INTENSITY                        1
    GL_INTENSITY4                       1
    GL_INTENSITY8                       1
    GL_INTENSITY12                      1
    GL_INTENSITY16                      1
    GL_R3_G3_B2                         3
    GL_RGB                              3
    GL_RGB4                             3
    GL_RGB5                             3
    GL_RGB8                             3
    GL_RGB10                            3
    GL_RGB12                            3
    GL_RGB16                            3
    GL_RGBA                             4
    GL_RGBA2                            4
    GL_RGBA4                            4
    GL_RGB5_A1                          4
    GL_RGBA8                            4
    GL_RGB10_A2                         4
    GL_RGBA12                           4
    GL_RGBA16                           4
    GL_SLUMINANCE                       1
    GL_SLUMINANCE8                      1
    GL_SLUMINANCE_ALPHA                 2
    GL_SLUMINANCE8_ALPHA8               2
    GL_SRGB                             3
    GL_SRGB8                            3
    GL_SRGB_ALPHA                       4
    GL_SRGB8_ALPHA8                     4
    GL_RGBA32F_ARB                      4
}
