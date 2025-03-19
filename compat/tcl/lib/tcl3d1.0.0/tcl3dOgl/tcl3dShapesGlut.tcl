#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dShapesGlut.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl package to supply basic shapes in the style of the
#                       GLUT library. The functions are identical in parameter
#                       signature to the corresponding GLUT functions.
#                       For a detailed description of the functions see the
#                       standard OpenGL documentation, ex. the Red Book.
#
#                       Note: The teapot implementation differs in the original 
#                       and the freeglut implementation. If using the solid 
#                       teapot in a benchmark application, note that:
#                       Freeglut uses 7 for the grid parameter.
#                       Original GLUT and Tcl3D use 14 as grid parameter.
#
#******************************************************************************

proc glutSolidCube { size } {
    tcl3dDrawBox $size GL_QUADS
}

proc glutWireCube { size } {
    tcl3dDrawBox $size GL_LINE_LOOP
}

proc glutSolidCone { base height slices stacks } {
    set quadObj [gluNewQuadric]
    gluQuadricDrawStyle $quadObj GLU_FILL
    gluQuadricNormals $quadObj GLU_SMOOTH
    gluCylinder $quadObj $base 0.0 $height $slices $stacks
    gluDeleteQuadric $quadObj
}

proc glutWireCone { base height slices stacks } {
    set quadObj [gluNewQuadric]
    gluQuadricDrawStyle $quadObj GLU_LINE
    gluQuadricNormals $quadObj GLU_SMOOTH
    gluCylinder $quadObj $base 0.0 $height $slices $stacks
    gluDeleteQuadric $quadObj
}

proc glutSolidSphere { radius slices stacks } {
    set quadObj [gluNewQuadric]
    gluQuadricDrawStyle $quadObj GLU_FILL
    gluQuadricNormals $quadObj GLU_SMOOTH
    gluSphere $quadObj $radius $slices $stacks
    gluDeleteQuadric $quadObj
}

proc glutWireSphere { radius slices stacks } {
    set quadObj [gluNewQuadric]
    gluQuadricDrawStyle $quadObj GLU_LINE
    gluQuadricNormals $quadObj GLU_SMOOTH
    gluSphere $quadObj $radius $slices $stacks
    gluDeleteQuadric $quadObj
}

proc glutSolidTorus { innerRadius outerRadius nsides rings } {
    tcl3dDoughnut $innerRadius $outerRadius $nsides $rings
}

proc glutWireTorus { innerRadius outerRadius nsides rings } {
    glPushAttrib GL_POLYGON_BIT
    glPolygonMode GL_FRONT_AND_BACK GL_LINE
    tcl3dDoughnut $innerRadius $outerRadius $nsides $rings
    glPopAttrib
}

proc glutSolidTetrahedron {} {
    tcl3dTetrahedron GL_TRIANGLES
}

proc glutWireTetrahedron {} {
    tcl3dTetrahedron GL_LINE_LOOP
}

proc glutSolidOctahedron {} {
    tcl3dOctahedron GL_TRIANGLES
}

proc glutWireOctahedron {} {
    tcl3dOctahedron GL_LINE_LOOP
}

proc glutSolidDodecahedron {} {
    tcl3dDodecahedron GL_TRIANGLE_FAN
}

proc glutWireDodecahedron {} {
    tcl3dDodecahedron GL_LINE_LOOP
}

proc glutSolidIcosahedron {} {
    tcl3dIcosahedron GL_TRIANGLES
}

proc glutWireIcosahedron {} {
    tcl3dIcosahedron GL_LINE_LOOP
}

# Attention: If using the teapot in a benchmark application, note that
# Freeglut uses 7 for the grid parameter.
# Original GLUT uses 14 as grid parameter.

proc glutSolidTeapot { scale { grid 14 } } {
    tcl3dTeapot $grid $scale GL_FILL
}

proc glutWireTeapot { scale { grid 10 } } {
    tcl3dTeapot $grid $scale GL_LINE
}
