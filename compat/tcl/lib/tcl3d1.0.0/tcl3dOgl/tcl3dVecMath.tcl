#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dVecMath.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module to handle vectors and transformation
#                       matrices.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dVec3Print - Print contents of a 3D vector. 
#
#       Synopsis:       tcl3dVec3Print { vec { precisionString "%6.3f" } }
#
#       Description:    vec : string (Tcl3D Vector Identifier)
#                       precisionString: string, optional
#
#                       Print the contents of 3D Vector "vec" onto
#                       standard output. "vec" is a Tcl3D Vector of size 3
#                       and type float or double.
#
#       See also:       tcl3dMatPrint
#
###############################################################################

proc tcl3dVec3Print { vec { precisionString "%6.3f" } } {
    for { set i 0 } { $i < 3 } { incr i } {
        puts -nonewline [format "$precisionString " [$vec get $i]]
    }
    puts ""
}

###############################################################################
#[@e
#       Name:           tcl3dMatPrint - Print contents of a transformation 
#                       matrix. 
#
#       Synopsis:       tcl3dMatPrint { mat { precisionString "%6.3f" } }
#
#       Description:    mat : string (Tcl3D Vector Identifier)
#                       precisionString: string, optional
#
#                       Print the contents of transformation matrix "mat" onto
#                       standard output. "mat" is a Tcl3D Vector of size 16
#                       and type float or double.
#
#       See also:       tcl3dVec3Print
#
###############################################################################

proc tcl3dMatPrint { mat { precisionString "%6.3f" } } {
    for { set i 0 } { $i < 4 } { incr i } {
        for { set j 0 } { $j < 4 } { incr j } {
            puts -nonewline [format "$precisionString " [$mat get [expr 4*$j + $i]]]
        }
        puts ""
    }
}

###############################################################################
#[@e
#       Name:           tcl3dRadToDeg  - Convert angle from radians to degrees.
#
#       Synopsis:       tcl3dRadToDeg { ang }
#
#       Description:    ang : double
#
#                       Return angle "ang" specified in radians in degrees.
#
#       See also:       tcl3dDegToRad
#
###############################################################################

proc tcl3dRadToDeg { ang } {
    return [expr {$ang * 180.0 / 3.1415926535897932384626433832795}]
}

###############################################################################
#[@e
#       Name:           tcl3dDegToRad  - Convert angle from degrees to radians.
#
#       Synopsis:       tcl3dDegToRad { ang }
#
#       Description:    ang : double
#
#                       Return angle "ang" specified in degress in radians.
#
#       See also:       tcl3dRadToDeg
#
###############################################################################

proc tcl3dDegToRad { ang } {
    return [expr {$ang * 3.1415926535897932384626433832795 / 180.0}]
}
