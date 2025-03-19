#******************************************************************************
#
#       Copyright:      2011-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dShapesGlus.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl package to supply basic shapes in the style of the
#                       GLUT library for usage with OpenGL 3 using the core profile.
#                       The original C code for the GLUS shapes comes from Norbert Nopper's
#                       OpenGL demos at http://nopper.tv
#                       GLUS - OpenGL 3 Utilities. Copyright (C) 2010 Norbert Nopper
#
#******************************************************************************

proc glusCreatePlane { { horizontalExtend 1.0 } { verticalExtend 1.0 } } {
    set numVertices 4
    set numIndices  6

    set xy_vertices {
        -1.0 -1.0 0.0 +1.0
        +1.0 -1.0 0.0 +1.0  
        -1.0 +1.0 0.0 +1.0
        +1.0 +1.0 0.0 +1.0
    }

    set xy_normals {
        0.0 0.0 1.0
        0.0 0.0 1.0
        0.0 0.0 1.0
        0.0 0.0 1.0
    }

    set xy_tangents {
        1.0 0.0 0.0
        1.0 0.0 0.0
        1.0 0.0 0.0
        1.0 0.0 0.0
    }

    set xy_texCoords {
        0.0 0.0
        1.0 0.0
        0.0 1.0
        1.0 1.0
    }

    set xy_indices {
        0 1 2
        1 3 2
    }

    dict set shapeDict "numVertices" $numVertices
    dict set shapeDict "numIndices"  $numIndices

    for { set i 0 } { $i < $numVertices } { incr i } {
        set ind [expr {$i*4+0}]
        lset xy_vertices $ind [expr {[lindex $xy_vertices $ind] * $horizontalExtend }]
        incr ind
        lset xy_vertices $ind [expr {[lindex $xy_vertices $ind] * $verticalExtend }]
    }
    set vertices [tcl3dVectorFromList GLfloat $xy_vertices]
    dict set shapeDict "vertexVec" $vertices

    set normals [tcl3dVectorFromList GLfloat $xy_normals]
    dict set shapeDict "normalVec" $normals

    set tangents [tcl3dVectorFromList GLfloat $xy_tangents]
    dict set shapeDict "tangentVec" $tangents

    set texCoords [tcl3dVectorFromList GLfloat $xy_texCoords]
    dict set shapeDict "texCoordVec" $texCoords

    set indices [tcl3dVectorFromList GLuint $xy_indices]
    dict set shapeDict "indexVec" $indices

    return $shapeDict
}

proc glusCreateCube { { halfExtend 1.0 } } {
    set numVertices 24
    set numIndices  36

    set cubeVertices {
      -1.0 -1.0 -1.0 +1.0
      -1.0 -1.0 +1.0 +1.0
      +1.0 -1.0 +1.0 +1.0
      +1.0 -1.0 -1.0 +1.0
      -1.0 +1.0 -1.0 +1.0
      -1.0 +1.0 +1.0 +1.0
      +1.0 +1.0 +1.0 +1.0
      +1.0 +1.0 -1.0 +1.0
      -1.0 -1.0 -1.0 +1.0
      -1.0 +1.0 -1.0 +1.0
      +1.0 +1.0 -1.0 +1.0
      +1.0 -1.0 -1.0 +1.0
      -1.0 -1.0 +1.0 +1.0
      -1.0 +1.0 +1.0 +1.0
      +1.0 +1.0 +1.0 +1.0
      +1.0 -1.0 +1.0 +1.0
      -1.0 -1.0 -1.0 +1.0
      -1.0 -1.0 +1.0 +1.0
      -1.0 +1.0 +1.0 +1.0
      -1.0 +1.0 -1.0 +1.0
      +1.0 -1.0 -1.0 +1.0
      +1.0 -1.0 +1.0 +1.0
      +1.0 +1.0 +1.0 +1.0
      +1.0 +1.0 -1.0 +1.0
    }

    set cubeNormals {
       0.0 -1.0  0.0
       0.0 -1.0  0.0
       0.0 -1.0  0.0
       0.0 -1.0  0.0
       0.0 +1.0  0.0
       0.0 +1.0  0.0
       0.0 +1.0  0.0
       0.0 +1.0  0.0
       0.0  0.0 -1.0
       0.0  0.0 -1.0
       0.0  0.0 -1.0
       0.0  0.0 -1.0
       0.0  0.0 +1.0
       0.0  0.0 +1.0
       0.0  0.0 +1.0
       0.0  0.0 +1.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0
    }

    set cubeTangents {
      -1.0  0.0  0.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0

      +1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0

      -1.0  0.0  0.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0
      -1.0  0.0  0.0

      +1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0
      +1.0  0.0  0.0

       0.0  0.0 +1.0
       0.0  0.0 +1.0
       0.0  0.0 +1.0
       0.0  0.0 +1.0

       0.0  0.0 -1.0
       0.0  0.0 -1.0
       0.0  0.0 -1.0
       0.0  0.0 -1.0
    }

    set cubeTexCoords {
      0.0 0.0
      0.0 1.0
      1.0 1.0
      1.0 0.0
      1.0 0.0
      1.0 1.0
      0.0 1.0
      0.0 0.0
      0.0 0.0
      0.0 1.0
      1.0 1.0
      1.0 0.0
      0.0 0.0
      0.0 1.0
      1.0 1.0
      1.0 0.0
      0.0 0.0
      0.0 1.0
      1.0 1.0
      1.0 0.0
      0.0 0.0
      0.0 1.0
      1.0 1.0
      1.0 0.0
    }
   
    set cubeIndices {
      0  2  1
      0  3  2
      4  5  6
      4  6  7
      8  9 10
      8 10 11
     12 15 14
     12 14 13
     16 17 18
     16 18 19
     20 23 22
     20 22 21
    }

    dict set shapeDict "numVertices" $numVertices
    dict set shapeDict "numIndices"  $numIndices

    for { set i 0 } { $i < $numVertices } { incr i } {
        set ind [expr {$i*4}]
        lset cubeVertices $ind [expr [lindex $cubeVertices $ind] * $halfExtend]
        incr ind
        lset cubeVertices $ind [expr [lindex $cubeVertices $ind] * $halfExtend]
        incr ind
        lset cubeVertices $ind [expr [lindex $cubeVertices $ind] * $halfExtend]
    }
    set vertices [tcl3dVectorFromList GLfloat $cubeVertices]
    dict set shapeDict "vertexVec" $vertices

    set normals [tcl3dVectorFromList GLfloat $cubeNormals]
    dict set shapeDict "normalVec" $normals

    set tangents [tcl3dVectorFromList GLfloat $cubeTangents]
    dict set shapeDict "tangentVec" $tangents

    set texCoords [tcl3dVectorFromList GLfloat $cubeTexCoords]
    dict set shapeDict "texCoordVec" $texCoords

    set indices [tcl3dVectorFromList GLuint $cubeIndices]
    dict set shapeDict "indexVec" $indices

    return $shapeDict
}

proc glusCreateSphere { radius numSlices } {
    set numParallels $numSlices
    set numVertices  [expr { ($numParallels + 1) * ($numSlices + 1) }]
    set numIndices   [expr { $numParallels * $numSlices * 6 }]

    set angleStep [expr { (2.0 * 3.1415926535897932384626433832795) / $numSlices }]

    set helpVector [tcl3dVectorFromArgs GLfloat 0.0 1.0 0.0]

    dict set shapeDict "numVertices" $numVertices
    dict set shapeDict "numIndices"  $numIndices

    set vertices  [tcl3dVector GLfloat [expr { 4 * $numVertices }]]
    set normals   [tcl3dVector GLfloat [expr { 3 * $numVertices }]]
    set tangents  [tcl3dVector GLfloat [expr { 3 * $numVertices }]]
    set texCoords [tcl3dVector GLfloat [expr { 2 * $numVertices }]]
    set indices   [tcl3dVector GLuint $numIndices]
    dict set shapeDict "vertexVec" $vertices
    dict set shapeDict "normalVec" $normals
    dict set shapeDict "tangentVec" $tangents
    dict set shapeDict "texCoordVec" $texCoords
    dict set shapeDict "indexVec" $indices

    for { set i 0 } { $i <= $numParallels } { incr i } {
        for { set j 0 } { $j <= $numSlices } { incr j } {
            set vertexIndex    [expr { ($i * ($numSlices + 1) + $j ) * 4 }]
            set normalIndex    [expr { ($i * ($numSlices + 1) + $j ) * 3 }]
            set tangentIndex   [expr { ($i * ($numSlices + 1) + $j ) * 3 }]
            set texCoordsIndex [expr { ($i * ($numSlices + 1) + $j ) * 2 }]

            set iAngle [expr { $angleStep * $i }]
            set jAngle [expr { $angleStep * $j }]
            $vertices set [expr {$vertexIndex + 0}] [expr { $radius * sin ($iAngle) * sin ($jAngle) }]
            $vertices set [expr {$vertexIndex + 1}] [expr { $radius * cos ($iAngle) }]
            $vertices set [expr {$vertexIndex + 2}] [expr { $radius * sin ($iAngle) * cos ($jAngle) }]
            $vertices set [expr {$vertexIndex + 3}] 1.0

            $normals set [expr {$normalIndex + 0}] [expr [$vertices get [expr {$vertexIndex + 0}]] / $radius]
            $normals set [expr {$normalIndex + 1}] [expr [$vertices get [expr {$vertexIndex + 1}]] / $radius]
            $normals set [expr {$normalIndex + 2}] [expr [$vertices get [expr {$vertexIndex + 2}]] / $radius]

            tcl3dVec3fCrossProduct [GLfloat_ind $normals $normalIndex] \
                                   $helpVector \
                                   [GLfloat_ind $tangents $tangentIndex]

            if { [tcl3dVec3fLength [GLfloat_ind $tangents $tangentIndex]] == 0.0 } {
                $tangents set [expr {$tangentIndex + 0}] 1.0
                $tangents set [expr {$tangentIndex + 1}] 0.0
                $tangents set [expr {$tangentIndex + 2}] 0.0
            }

            $texCoords set [expr {$texCoordsIndex + 0}] [expr {double ($j) / double ($numSlices)}]
            $texCoords set [expr {$texCoordsIndex + 1}] [expr {(1.0 - $i) / double ($numParallels - 1)}]
        }
    }

    set index 0
    for { set i 0 } { $i < $numParallels } { incr i } {
        for { set j 0 } { $j < $numSlices } { incr j } {
            $indices set $index [expr { $i      * ($numSlices + 1) + $j}]       ; incr index
            $indices set $index [expr {($i + 1) * ($numSlices + 1) + $j}]       ; incr index
            $indices set $index [expr {($i + 1) * ($numSlices + 1) + ($j + 1)}] ; incr index

            $indices set $index [expr {$i       * ($numSlices + 1) + $j}]       ; incr index
            $indices set $index [expr {($i + 1) * ($numSlices + 1) + ($j + 1)}] ; incr index
            $indices set $index [expr {$i       * ($numSlices + 1) + ($j + 1)}] ; incr index
        }
    }
    $helpVector delete
    return $shapeDict
}

#
# @author Pablo Alonso-Villaverde Roza
#
proc glusCreateTorus { innerRadius outerRadius numSides numFaces } {
    # t, s = parametric values of the equations, in the range [0,1]
    set t 0.0
    set s 0.0
    set PI2 [expr 2.0 * 3.1415926535897932384626433832795]
    
    # used later to help us calculating tangents vectors
    set helpVector [tcl3dVectorFromArgs GLfloat 0.0 1.0 0.0]

    if { $numSides < 3 || $numFaces < 3 } {
        error "Invalid number of sides or faces"
    }

    set numVertices [expr ($numFaces+1) * ($numSides+1)]
    # 2 triangles per face * 3 indices per triangle
    set numIndices  [expr $numFaces * $numSides * 2 * 3]

    dict set shapeDict "numVertices" $numVertices
    dict set shapeDict "numIndices"  $numIndices

    set vertices  [tcl3dVector GLfloat [expr 4*$numVertices]]
    set normals   [tcl3dVector GLfloat [expr 3*$numVertices]]
    set tangents  [tcl3dVector GLfloat [expr 3*$numVertices]]
    set texCoords [tcl3dVector GLfloat [expr 2*$numVertices]]
    set indices   [tcl3dVector GLuint $numIndices]
    dict set shapeDict "vertexVec" $vertices
    dict set shapeDict "normalVec" $normals
    dict set shapeDict "tangentVec" $tangents
    dict set shapeDict "texCoordVec" $texCoords
    dict set shapeDict "indexVec" $indices

    # incr_t, incr_s are increment values aplied to t and s on each loop iteration
    # to generate the torus.
    set tIncr [expr 1.0 / $numFaces]
    set sIncr [expr 1.0 / $numSides]

    # generate vertices and its attributes
    for { set sideCount 0 } { $sideCount <= $numSides } { incr sideCount } {
        set s [expr { $s + $sIncr }]

        # precompute some values
        set cos2PIs [expr { cos ($PI2 * $s) }]
        set sin2PIs [expr { sin ($PI2 * $s) }]

        set t 0.0
        for { set faceCount 0 } { $faceCount <= $numFaces } { incr faceCount } {
            set t [expr { $t + $tIncr }]

            # precompute some values
            set cos2PIt [expr {cos ($PI2 * $t) }]
            set sin2PIt [expr {sin ($PI2 * $t) }]
            
            # generate vertex and stores it in the right position
            set indexVertices [expr {(($sideCount * ($numFaces +1)) + $faceCount)* 4 }]
            $vertices set [expr {$indexVertices + 0}] [expr {($outerRadius + $innerRadius * $cos2PIt) * $cos2PIs }]
            $vertices set [expr {$indexVertices + 1}] [expr {($outerRadius + $innerRadius * $cos2PIt) * $sin2PIs }]
            $vertices set [expr {$indexVertices + 2}] [expr {$innerRadius * $sin2PIt }]
            $vertices set [expr {$indexVertices + 3}] 1.0

            # generate normal and stores it in the right position
            # NOTE: cos (2PIx) = cos (x) and sin (2PIx) = sin (x) so, we can use this formula
            #       normal = {cos(2PIs)cos(2PIt) , sin(2PIs)cos(2PIt) ,sin(2PIt)}      
            set indexNormals [expr {(($sideCount * ($numFaces +1)) + $faceCount)* 3 }]
            $normals set [expr {$indexNormals + 0}] [expr {$cos2PIs * $cos2PIt }]
            $normals set [expr {$indexNormals + 1}] [expr {$sin2PIs * $cos2PIt }]
            $normals set [expr {$indexNormals + 2}] [expr {$sin2PIt }]

            # tangent vector can be calculated with a cross product between the helper vector,
            # and the normal vector. We must take care if both the normal and helper are parallel
            # (cross product = 0, that's not a valid tangent!)            
            set indexTangents [expr {(($sideCount * ($numFaces +1)) + $faceCount)* 3 }]
            tcl3dVec3fCrossProduct [GLfloat_ind $normals $indexNormals] \
                                   $helpVector \
                                   [GLfloat_ind $tangents $indexTangents]

            if { [tcl3dVec3fLength [GLfloat_ind $tangents $indexTangents]] == 0.0 } {
                $tangents set [expr {$indexTangents + 0}] 1.0
                $tangents set [expr {$indexTangents + 1}] 0.0
                $tangents set [expr {$indexTangents + 2}] 0.0
            }

            # generate texture coordinates and stores it in the right position
            set indexTexCoords [expr {(($sideCount * ($numFaces +1)) + $faceCount)* 2 }]
            $texCoords set [expr {$indexTexCoords + 0}] $t
            $texCoords set [expr {$indexTexCoords + 1}] $s
        }
    }
    
    # generate indices
    set indexIndices 0
    for { set sideCount 0 } { $sideCount < $numSides } { incr sideCount } {
        for { set faceCount 0 } { $faceCount < $numFaces } { incr faceCount } {
            # get the number of the vertices for a face of the torus. They must be < numVertices
            set v0 [expr {(( $sideCount    * ($numFaces +1)) + $faceCount) }]
            set v1 [expr {((($sideCount+1) * ($numFaces +1)) + $faceCount) }]
            set v2 [expr {((($sideCount+1) * ($numFaces +1)) + ($faceCount+1)) }]
            set v3 [expr {(( $sideCount    * ($numFaces +1)) + ($faceCount+1)) }]
            
            # first triangle of the face, counter clock wise winding       
            $indices set $indexIndices $v0 ; incr indexIndices
            $indices set $indexIndices $v1 ; incr indexIndices
            $indices set $indexIndices $v2 ; incr indexIndices

            # second triangle of the face, counter clock wise winding
            $indices set $indexIndices $v0 ; incr indexIndices
            $indices set $indexIndices $v2 ; incr indexIndices
            $indices set $indexIndices $v3 ; incr indexIndices
        }
    }
    $helpVector delete
    return $shapeDict
}

proc glusDestroyShape { shapeDict } {
    if { [dict exists $shapeDict vertexVec] } {
        [dict get $shapeDict vertexVec] delete
        dict unset shapeDict vertexVec
    }

    if { [dict exists $shapeDict normalVec] } {
        [dict get $shapeDict normalVec] delete
        dict unset shapeDict normalVec
    }

    if { [dict exists $shapeDict tangentVec] } {
        [dict get $shapeDict tangentVec] delete
        dict unset shapeDict tangentVec
    }

    if { [dict exists $shapeDict texCoordVec] } {
        [dict get $shapeDict texCoordVec] delete
        dict unset shapeDict texCoordVec
    }

    if { [dict exists $shapeDict indexVec] } {
        [dict get $shapeDict indexVec] delete
        dict unset shapeDict indexVec
    }

    dict unset $shapeDict numVertices
    dict unset $shapeDict numIndices
}
