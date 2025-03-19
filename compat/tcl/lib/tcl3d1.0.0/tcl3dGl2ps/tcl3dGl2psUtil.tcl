#******************************************************************************
#
#       Copyright:      2006-2022 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dGl2ps
#       Filename:       tcl3dGl2psUtil.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with miscellaneous utility
#                       procedures related to the GL2PS module.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dGl2psCreateFile - Create file from OpenGL content.
#
#       Synopsis:       tcl3dGl2psCreateFile { toglwin filename format
#                               { title "Tcl3D Screenshot" }
#                               { drawBackground 0 }
#                               { producer "Tcl3D" } }
#
#       Description:    toglwin        : string (Togl identifier)
#                       filename       : string
#                       format         : string
#                       title          : string
#                       drawBackground : boolean
#                       producer       : string
#
#                       Create an image file from current Togl window content.
#                       The image file is written in format "format".
#                       "format" can be one of the following format strings:
#                       "PS", "EPS", "PDF", "SVG", "TEX", PGF".
#                       The file is created from the Togl window identified by
#                       "toglwin" and written to file "filename".
#                       The following optional parameters set format specific
#                       values:
#                       "title" is the name of the document title.
#                       If "drawBackground" is set to true, the background
#                       color of the Togl window is also used as the background
#                       color of the output file. Otherwise the background
#                       color is set to white.
#                       "procuder" is the name of the producer property.
#
#       See also:
#
###############################################################################

proc tcl3dGl2psCreateFile { toglwin filename format \
                            { title "Tcl3D Screenshot" } \
                            { drawBackground 0 } { producer "Tcl3D" } } {

    switch -nocase -exact -- $format {
        PS   { set fmt $::GL2PS_PS }
        EPS  { set fmt $::GL2PS_EPS}
        PDF  { set fmt $::GL2PS_PDF}
        SVG  { set fmt $::GL2PS_SVG}
        TEX  { set fmt $::GL2PS_TEX}
        PGF  { set fmt $::GL2PS_PGF}
        default { error "Unknown format string \"$format\"" }
    }

    set retVal [catch {open $filename wb} fp]
    if { $retVal != 0 } {
        error "Could not open file $filename for writing"
    }

    set opt [expr {$::GL2PS_OCCLUSION_CULL | \
                   $::GL2PS_USE_CURRENT_VIEWPORT | \
                   $::GL2PS_SILENT}]
    if { $drawBackground } {
        set opt [expr {$opt | $::GL2PS_DRAW_BACKGROUND}]
    }

    set bufSize 0
    set state $::GL2PS_OVERFLOW
    while { $state == $::GL2PS_OVERFLOW } {
        set bufSize [expr {$bufSize + 1024*1024}]
        set retVal [gl2psBeginPage $title $producer NULL $fmt \
                                   $::GL2PS_SIMPLE_SORT $opt $::GL_RGBA \
                                   0 NULL 0 0 0 \
                                   $bufSize $fp $title]
        if { $retVal == $::GL2PS_ERROR } {
            error "Could not initialize PDF creation: gl2psBeginPage"
        }

        $toglwin render

        set state [gl2psEndPage]
        if { $state == $::GL2PS_ERROR } {
            error "Could not write PDF: gl2psEndPage"
        }
    }
    fclose $fp
}

###############################################################################
#[@e
#       Name:           tcl3dGl2psCreatePdf - Create PDF from OpenGL content.
#
#       Synopsis:       tcl3dGl2psCreatePdf { toglwin filename
#                               { title "Tcl3D Screenshot" }
#                               { drawBackground 0 }
#                               { producer "Tcl3D" } }
#
#       Description:    toglwin        : string (Togl identifier)
#                       filename       : string
#                       title          : string
#                       drawBackground : boolean
#                       producer       : string
#
#                       Create a PDF file from current Togl window content.
#                       The PDF is created from the Togl window identified by
#                       "toglwin" and written to file "filename".
#                       The following optional parameters set PDF specific
#                       values:
#                       "title" is the name of the document title as
#                       listed in the document properties of the PDF file.
#                       If "drawBackground" is set to true, the background
#                       color of the Togl window is also used as the background
#                       color of the PDf document. Otherwise the PDF background
#                       color is set to white.
#                       "procuder" is the name of the producer property as
#                       listed in the document properties of the PDF file.
#
#       See also:
#
###############################################################################

proc tcl3dGl2psCreatePdf { toglwin filename { title "Tcl3D Screenshot" } \
                         { drawBackground 0 } { producer "Tcl3D" } } {
    tcl3dGl2psCreateFile $toglwin $filename "PDF" $title $drawBackground $producer
}
