#******************************************************************************
#
#       Copyright:      2011-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dGeoMath.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module for handling geographic coordinate
#                       conversions. The used reference ellipsoid is WGS84,
#                       as used for GPS navigation or in DIS/HLA simulations.
#
#******************************************************************************

proc _Abs { a } {
    if { $a < 0 } {
        return [expr {-$a}]
    } else {
        return $a
    }
}

###############################################################################
#[@e
#       Name:           tcl3dDecToDMS - Convert decimal degree to DMS notation.
#
#       Synopsis:       tcl3dDecToDMS { decDeg { asString true }
#                                       { numDigits 5 } }
#
#       Description:    decDeg   : double (angle in degrees)
#                       asString : bool
#                       numDigits: integer
#
#                       Convert angle "decDeg" into the DMS notation
#                       (i.e. Degree, Minute, Seconds).
#                       If "asString" is true, the DMS value is returned as a
#                       string in the format (+-)D°M'S". Example: -32°15'1.23"
#                       Otherwise the DMS values are returned as a list in the
#                       following order: { D M S Sign }
#                       "numDigits" specifies the number of digits for the S
#                       value.
#
#       See also:       tcl3dDMSToDec
#
###############################################################################

proc tcl3dDecToDMS { decDeg { asString true } { numDigits 5 } } {
    set scale [expr {wide (pow (10, $numDigits)) }]
    set scale3600 [expr {$scale*3600}]

    set angleInt [expr {wide (([_Abs $decDeg] + 1.0/($scale3600*60)) * $scale3600) }]
    set degrees  [expr {$angleInt / 3600 / $scale}]
    set minutes  [expr {($angleInt - $degrees*$scale3600) / 60 / $scale }]
    set seconds  [expr {double ($angleInt - $degrees*$scale3600 - $minutes*60*$scale) / \
                        double ($scale) }]

    if { $decDeg < 0.0 } {
        set sign -1
        set signStr "-"
    } else {
        set sign 1
        set signStr " "
    }
    if { $asString } {
        return [format "%s%d°%d'%f\"" $signStr $degrees $minutes $seconds]
    } else {
        return [list $degrees $minutes $seconds $sign]
    }
}

###############################################################################
#[@e
#       Name:           tcl3dDMSToDec - Convert DMS notation into decimal degree.
#
#       Synopsis:       tcl3dDMSToDec { deg min sec sign }
#
#       Description:    deg : integer (degrees of the angle)
#                       min : integer (minutes of the angle)
#                       sec : double  (seconds of the angle)
#                       sign: integer
#
#                       Convert an angle specified in the DMS notation into a
#                       decimal value. The converted value is returned as a
#                       double value.
#
#       See also:       tcl3dDecToDMS
#
###############################################################################

proc tcl3dDMSToDec { deg min sec sign } {
    set absVal [expr {[_Abs $deg] + $min/60.0 + $sec/3600.0 }]
    if { $sign < 0 } {
        return [expr {-$absVal}]
    } else {
        return $absVal
    }
}

###############################################################################
#[@e
#       Name:           tcl3dGeodeticToGeocentric - Position conversion. 
#
#       Synopsis:       tcl3dGeodeticToGeocentric { lat lon alt }
#
#       Description:    lat : double (Latitude in radian)
#                       lon : double (Longitude in radian)
#                       alt : double (Altitude in radian)
#
#                       Convert a geodetic position specified with latitide,
#                       longitude and altitude into geocentric coordinates.
#                       The used reference ellipsoid is WGS84.
#                       The converted coordinates are returned as a 3-element
#                       list containing the ECEF x, y and z values in meter.
#
#       See also:       tcl3dGeocentricToGeodetic
#                       tcl3dLocalToGeoOrient
#                       tcl3dGeoToLocalOrient
#
###############################################################################

proc tcl3dGeodeticToGeocentric { lat lon alt } {
    return [tcl3dGeodetic2Geocentric $lat $lon $alt $::WGS_1984]
}

###############################################################################
#[@e
#       Name:           tcl3dGeocentricToGeodetic - Position conversion. 
#
#       Synopsis:       tcl3dGeocentricToGeodetic { x y z }
#
#       Description:    x : double (ECEF x coordinate in meter)
#                       y : double (ECEF y coordinate in meter)
#                       z : double (ECEF z coordinate in meter)
#
#                       Convert a geocentric ECEF position specified with 
#                       x, y and z into geodetic coordinates.
#                       The used reference ellipsoid is WGS84.
#                       The converted coordinates are returned as a 3-element
#                       list containing the latitude, longitude and altitude 
#                       values in radian.
#
#       See also:       tcl3dGeodeticToGeocentric
#                       tcl3dLocalToGeoOrient
#                       tcl3dGeoToLocalOrient
#
###############################################################################

proc tcl3dGeocentricToGeodetic { x y z } {
    return [tcl3dGeocentric2Geodetic $x $y $z $::WGS_1984]
}

###############################################################################
#[@e
#       Name:           tcl3dLocalToGeoOrient - Orientation conversion. 
#
#       Synopsis:       tcl3dLocalToGeoOrient { head pitch roll lat lon }
#
#       Description:    head : double (Euler angle in radian)
#                       pitch: double (Euler angle in radian)
#                       roll : double (Euler angle in radian)
#                       lat  : double (Latitude in radian)
#                       lon  : double (Longitude in radian)
#
#                       Convert Euler angles (measured in a NED coordinate 
#                       system located at (lat, lon) into global orientation
#                       angles.
#                       The converted orientations are returned as a 3-element
#                       list containing the psi, theta and phi values in radian.
#
#       See also:       tcl3dGeodeticToGeocentric
#                       tcl3dGeocentricToGeodetic
#                       tcl3dGeoToLocalOrient
#
###############################################################################

proc tcl3dLocalToGeoOrient { head pitch roll lat lon } {
    return [tcl3dLocal2GeoOrient $head $pitch $roll $lat $lon]
}

###############################################################################
#[@e
#       Name:           tcl3dGeoToLocalOrient - Orientation conversion. 
#
#       Synopsis:       tcl3dGeoToLocalOrient { psi theta phi lat lon }
#
#       Description:    psi  : double (Orientation angle in radian)
#                       theta: double (Orientation angle in radian)
#                       phi  : double (Orientation angle in radian)
#                       lat  : double (latitude in radian)
#                       lon  : double (longitude in radian)
#
#                       Convert global orientation angles into Euler angles
#                       measured in a NED coordinate system located at 
#                       (lat, lon).
#                       The converted orientations are returned as a 3-element
#                       list containing the head, pitch and roll values in 
#                       radian.
#
#       See also:       tcl3dGeodeticToGeocentric
#                       tcl3dGeocentricToGeodetic
#                       tcl3dLocalToGeoOrient
#
###############################################################################

proc tcl3dGeoToLocalOrient { psi theta phi lat lon } {
    return [tcl3dGeo2LocalOrient $psi $theta $phi $lat $lon]
}

