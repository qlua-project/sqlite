#******************************************************************************
#
#       Copyright:      2005-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dVector.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module to handle tcl3dVectors, i.e. contiguous
#                       pieces of memory.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dVector - Create a new Tcl3D Vector
#
#       Synopsis:       tcl3dVector { type size }
#
#       Description:    type : string
#                       size : int
#
#                       Create a new Tcl3D Vector of size "size" by calling
#                       the memory allocation routine new_"type" and create
#                       a new Tcl procedure.
#                       The contents of the new Tcl3D Vector are uninitialized.
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#                       The following base types are currently supported:
#                       GLbitfield      GLboolean       GLbyte    GLclampd
#                       GLclampf        GLdouble        GLenum    GLfloat
#                       GLint           GLshort         GLsizei   GLubyte
#                       GLuint          GLushort        double    float
#                       int             short           uint      ushort
#
#                       Note: To get an up-to-date list of wrapped types, issue
#                             the command "info commands new_*" after loading
#                             Tcl3D or use the script "vectorTypes.tcl" in
#                             directory "tcl3dUtil/test".
#
#                             A detailed description of Tcl3D Vectors can be
#                             found in the Tcl3D manual.
#
#       See also:       tcl3dVectorFromArgs
#                       tcl3dVectorFromByteArray
#                       tcl3dVectorFromList
#                       tcl3dVectorFromPhoto
#                       tcl3dVectorFromString
#
###############################################################################

proc tcl3dVector { type size } {
    set ptr [new_$type $size]
    set code {
        set method [lindex $args 0]
        set parms [concat $ptr [lrange $args 1 end]]
        switch $method {
            elemsize {return [eval "${type}_elemsize   $parms"]}
            get      {return [eval "${type}_getitem    $parms"]}
            set      {return [eval "${type}_setitem    $parms"]}
            setrgb   {return [eval "${type}_setrgb     $parms"]}
            setrgba  {return [eval "${type}_setrgba    $parms"]}
            setvec   {return [eval "${type}_setvector  $parms"]}
            addvec   {return [eval "${type}_addvector  $parms"]}
            mulvec   {return [eval "${type}_mulvector  $parms"]}
            delete   {eval "delete_$type $ptr; rename $ptr {}"}
        }
    }
    # Create a procedure for the new Tcl3D Vector.
    uplevel #0 "proc $ptr args {set ptr $ptr; set type $type;$code}"
    return $ptr
}

###############################################################################
#[@e
#       Name:           tcl3dVectorInd - Get index of a Tcl3D Vector.
#
#       Synopsis:       tcl3dVectorInd { vec type ind }
#
#       Description:    vec  : string (Tcl3D Vector Identifier)
#                       type : string
#                       ind  : int
#
#                       Return the "pointer" to the "ind" element of a Tcl3D
#                       Vector. The base Tcl3D Vector is specified with "vec",
#                       the type of the Vector is given with "type".
#
#                       Note: See the description of tcl3dVector for a list
#                             of usable types.
#                             This function may be used in conjunction with
#                             OpenGL interleaved vertex arrays. See RedBook
#                             demo "aapolyStride.tcl" for an example usage.
#
#       See also:       tcl3dVector
#
###############################################################################

proc tcl3dVectorInd { vec type ind } {
    eval "${type}_ind $vec $ind"
}

###############################################################################
#[@e
#       Name:           tcl3dVectorPrint - Print contents of a Tcl3D Vector.
#
#       Synopsis:       tcl3dVectorPrint { vec num { precisionString "%6.3f" } }
#
#       Description:    vec : string (Tcl3D Vector Identifier)
#                       num : num
#                       precisionString: string, optional
#
#                       Print the first "num" elements of Tcl3D Vector "vec"
#                       onto standard output.
#
#                       Note: Tcl3D Vectors behave like C vectors, i.e. they
#                             do not have information about its length.
#
#       See also:       tcl3dVector
#
###############################################################################

proc tcl3dVectorPrint { vec num  { precisionString "%6.3f" } } {
    for { set i 0 } { $i < $num } { incr i } {
        puts [format "%4d: $precisionString" $i [$vec get $i]]
    }
}

###############################################################################
#[@e
#       Name:           tcl3dVectorFromArgs - Create new Tcl3D Vector from
#                       an argument list.
#
#       Synopsis:       tcl3dVectorFromArgs { type args }
#
#       Description:    type  : string
#                       args  : list
#
#                       Create a new Tcl3D Vector of type "type" from given
#                       variable argument list.
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#                       Note: See the description of tcl3dVector for a list
#                             of usable types.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromByteArray
#                       tcl3dVectorFromList
#                       tcl3dVectorFromPhoto
#                       tcl3dVectorFromString
#
###############################################################################

proc tcl3dVectorFromArgs { type args } {
    set len [llength $args]
    if { $len == 0 } {
        error "Vector init has zero length"
    }
    set a [tcl3dVector $type $len]
    set i 0
    foreach elem $args {
        ${type}_setitem $a $i $elem
        incr i
    }
    return $a
}

###############################################################################
#[@e
#       Name:           tcl3dVectorFromList - Create new Tcl3D Vector from a
#                       list.
#
#       Synopsis:       tcl3dVectorFromList { type l { maxElems -1 } }
#
#       Description:    type     : string
#                       l        : list
#                       maxElems : int
#
#                       Create a new Tcl3D Vector of type "type" from given
#                       Tcl list "l". If "maxElems" is given and greater than
#                       zero, only the first "maxElems" are used.
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#                       Note: See the description of tcl3dVector for a list
#                             of usable types.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromArgs
#                       tcl3dVectorFromByteArray
#                       tcl3dVectorFromPhoto
#                       tcl3dVectorFromString
#
###############################################################################

proc tcl3dVectorFromList { type l { maxElems -1 } } {
    set len [llength $l]
    if { $len == 0 } {
        error "List has zero length"
    }
    if { $maxElems > 0 } {
        if { $maxElems < $len } {
            set len $maxElems
        }
    }
    set a [tcl3dVector $type $len]
    set fastCmd "tcl3dListToVector_$type"
    if { [info commands $fastCmd] eq $fastCmd } {
        $fastCmd $l $a $len
    } else {
        set i 0
        foreach elem $l {
            ${type}_setitem $a $i $elem
            incr i
        }
    }
    return $a
}

###############################################################################
#[@e
#       Name:           tcl3dCharToNum - Convert character to integer.
#
#       Synopsis:       tcl3dCharToNum { char }
#
#       Description:    char : character
#
#                       Convert an ASCII character into the corresponding
#                       numeric value.
#
#       See also:       tcl3dNumToChar
#
###############################################################################

proc tcl3dCharToNum { char } {
    scan $char %c value
    return $value
}

###############################################################################
#[@e
#       Name:           tcl3dNumToChar - Convert integer to character.
#
#       Synopsis:       tcl3dNumToChar { num }
#
#       Description:    num : int
#
#                       Convert a numeric value into the corresponding ASCII
#                       character.
#
#       See also:       tcl3dCharToNum
#
###############################################################################

proc tcl3dNumToChar { num } {
    return [format "%c" $num]
}

###############################################################################
#[@e
#       Name:           tcl3dVectorFromString - Create new Tcl3D Vector from a
#                       string.
#
#       Synopsis:       tcl3dVectorFromString { type str }
#
#       Description:    type : string
#                       str  : string
#
#                       Create a new Tcl3D Vector of type "type" from given
#                       string "str".
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#                       Note: This version is very slow and is intended only
#                             for converting the characters of short text
#                             strings into it's numerical values to be used by
#                             display lists rendering raster fonts.
#                             As the bitmap fonts only support ranges from 0 to 255,
#                             all characters larger than 255 are replaced by a
#                             question mark.
#                             See the description of tcl3dVector for a list
#                             of usable types.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromArgs
#                       tcl3dVectorFromByteArray
#                       tcl3dVectorFromList
#                       tcl3dVectorFromPhoto
#
###############################################################################

proc tcl3dVectorFromString { type str } {
    set len [string length $str]
    if { $len == 0 } {
        error "String has zero length"
    }
    set a [tcl3dVector $type $len]
    set i 0
    foreach elem [split $str ""] {
        set val [tcl3dCharToNum $elem]
        # puts "Setting a($i) to: $elem ( $val )"
        if { $val > 255 } {
            set val [tcl3dCharToNum "?"]
        }
        $a set $i $val
        incr i
    }
    return $a
}

###############################################################################
#[@e
#       Name:           tcl3dVectorFromByteArray - Create new Tcl3D Vector from
#                       binary string.
#
#       Synopsis:       tcl3dVectorFromByteArray { type str }
#
#       Description:    type : string
#                       str  : string
#
#                       Create a new Tcl3D Vector of type "type" from given
#                       binary string "str".
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#                       Note: See the description of tcl3dVector for a list
#                             of usable types.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromArgs
#                       tcl3dVectorFromList
#                       tcl3dVectorFromPhoto
#                       tcl3dVectorFromString
#
###############################################################################

proc tcl3dVectorFromByteArray { type str } {
    set len [string length $str]
    if { $len == 0 } {
        error "String has zero length"
    }
    set a [tcl3dVector $type $len]
    tcl3dByteArray2Vector $str $a $len 0 0
    return $a
}

###############################################################################
#[@e
#       Name:           tcl3dVectorFromPhoto - Create new Tcl3D Vector from
#                       a Tk photo.
#
#       Synopsis:       tcl3dVectorFromPhoto { phImg { numChans -1 }
#                       { scl 1.0 } { off 0.0 }  }
#
#       Description:    phImg    : string (Photo image identifier)
#                       numChans : int
#                       scl      : double
#                       off      : double
#
#                       Create a new Tcl3D Vector containing the image data
#                       of Tk photo "phImg". The created Tcl3D Vector is of type
#                       GL_UNSIGNED_BYTE. If "numChans" is specified and between
#                       1 and 4, only the first "numChans" are copied into
#                       the Tcl3D Vector. Otherwise all channels available in
#                       the photo image are used.
#                       "scl" and "off" can be used to scale and offset the
#                       pixel values while converting.
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromArgs
#                       tcl3dVectorFromByteArray
#                       tcl3dVectorFromList
#                       tcl3dVectorFromString
#
###############################################################################

proc tcl3dVectorFromPhoto { phImg { numChans -1 } { scl 1.0 } { off 0.0 } { vecType GLubyte }  } {
    set w [image width  $phImg]
    set h [image height $phImg]
    set n [tcl3dPhotoChans $phImg]
    if { $numChans > $n || $numChans <= 0 } {
        set numChans $n
    }
    set texImg [tcl3dVector $vecType [expr {$w * $h * $numChans}]]
    if { $vecType eq "GLubyte" } {
        tcl3dPhotoToVector $phImg $texImg $numChans $scl $off
    } else {
        tcl3dPhotoToFloatVector $phImg $texImg $numChans $scl $off
    }
    return $texImg
}

###############################################################################
#[@e
#       Name:           tcl3dPhotoFromVector - Create new Tk photo image from
#                       a Tcl3D vector.
#
#       Synopsis:       tcl3dPhotoFromVector { vec width height numChans
#                       { vecIsBottomUp 1 }
#
#       Description:    vec           : string (Tcl3D Vector Identifier)
#                       width         : int
#                       height        : int
#                       numChans      : int
#                       vecIsBottomUp : int
#
#                       Create a new Tk photo containing the image data
#                       of Tcl3D Vector "vec". The Tcl3D Vector must be of type
#                       GL_UNSIGNED_BYTE. The image contained in the Tcl3D Vector
#                       is of size "width" by "height" and contains "numChans"
#                       channels. Possible values for "numChans" are from 1 to 4.
#                       If "vecIsBottomUp" is set to 1, the scanlines of the Tcl3D
#                       vector are stored in bottom-up order. If set to 0, the
#                       scanlines are assumed to be in top-down order.
#
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new photo image.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromPhoto
#
###############################################################################

proc tcl3dPhotoFromVector { vec width height numChans { vecIsBottomUp 1 } } {
    set phImg [image create photo]
    tcl3dVectorToPhoto2 $phImg $vec $width $height $numChans $vecIsBottomUp
    return $phImg
}

###############################################################################
#[@e
#       Name:           tcl3dVectorFromLinspace - Create new linearly spaced
#                       Tcl3D Vector.
#
#       Synopsis:       tcl3dVectorFromLinspace { type s e n }
#
#       Description:    type : string
#                       s    : Start value of type "type"
#                       e    : End value of type "type"
#                       n    : int
#
#                       Create a new Tcl3D Vector of type "type" and length "n"
#                       containing "n" data values linearly spaced between and
#                       including "s" and "e".
#                       Type can be any of the following:
#                       GLubyte, GLushort, GLuint, GLfloat, GLdouble,
#                       float, double.
#
#                       Return the identifier (i.e. the name of the created Tcl
#                       procedure) of the new Tcl3D Vector.
#
#                       This command implements the functionality of the MATLAB
#                       linspace command.
#
#       See also:       tcl3dVector
#                       tcl3dVectorFromArgs
#                       tcl3dVectorFromByteArray
#                       tcl3dVectorFromList
#                       tcl3dVectorFromString
#
###############################################################################

proc tcl3dVectorFromLinspace { type s e n } {
    if { $s > $e } {
        error "Start value ($s) greater than end value ($e)"
    }
    if { $n <= 0 } {
        error "Vector length ($n) not positive."
    }
    if { [info commands tcl3dVectorLinspace_$type] eq "" } {
        error "Linspace command not supported for type ($type)."
    }
    set a [tcl3dVector $type $n]
    tcl3dVectorLinspace_$type $a $s $e $n
    return $a
}

###############################################################################
#[@e
#       Name:           tcl3dVectorToList - Copy Tcl3D Vector into a list.
#
#       Synopsis:       tcl3dVectorToList { vec num }
#
#       Description:    vec : string (Tcl3D Vector Identifier)
#                       num : int
#
#                       Copy "num" elements of Tcl3D Vector "vec" into a Tcl
#                       list and return that list.
#
#                       Note: This version is slow and is intended only for
#                             converting 3D vectors or transformation matrices
#                             into Tcl lists.
#
#       See also:       tcl3dVectorFromList
#                       tcl3dVectorToByteArray
#                       tcl3dVectorToString
#
###############################################################################

proc tcl3dVectorToList { vec num } {
    set l {}
    for { set i 0 } { $i < $num } { incr i } {
        set val [$vec get $i]
        lappend l $val
    }
    return $l
}

###############################################################################
#[@e
#       Name:           tcl3dVectorToString - Copy Tcl3D Vector into a string.
#
#       Synopsis:       tcl3dVectorToString { vec }
#
#       Description:    vec : string (Tcl3D Vector Identifier)
#
#                       Interpret the elements of Tcl3D Vector "vec"
#                       (which must be of type GLubyte) as a
#                       null-terminated string and return that string.
#
#                       Note: This version is slow and is intended only for
#                             short text strings. Use this function for example
#                             to convert the information returned by a GLSL
#                             shader.
#
#       See also:       tcl3dVectorFromString
#                       tcl3dVectorToByteArray
#                       tcl3dVectorToList
#
###############################################################################

proc tcl3dVectorToString { vec } {
    set i 0
    set str ""
    while { 1 } {
        set val [$vec get $i]
        if { $val == 0 } {
            break
        }
        append str [tcl3dNumToChar $val]
        incr i
    }
    return $str
}

###############################################################################
#[@e
#       Name:           tcl3dVectorToByteArray - Copy Tcl3D Vector into a binary
#                       string.
#
#       Synopsis:       tcl3dVectorToByteArray { vec numBytes {srcOff 0}
#                       {destOff 0} } {
#
#       Description:    vec      : string (Tcl3D Vector Identifier)
#                       numBytes : int
#                       srcOff   : int
#                       destOff  : int
#
#                       Copy "numBytes" elements of Tcl3D Vector "vec" into
#                       a Tcl binary string and return that string. The
#                       Tcl3D Vector has be of type GLubyte.
#                       "srcOff" and "destOff" may be used optionally to specify
#                       an offset into the source and the destination.
#
#       See also:       tcl3dVectorFromByteArray
#                       tcl3dVectorToList
#                       tcl3dVectorToString
#
###############################################################################

proc tcl3dVectorToByteArray { vec numBytes {srcOff 0} {destOff 0} } {
    if { $numBytes == 0 } {
        error "Vector has zero length"
    }
    # First generate a binary string of appropriate size.
    set bytes [binary format a$numBytes 0]
    tcl3dVector2ByteArray $vec $bytes $numBytes $srcOff $destOff
    return $bytes
}
