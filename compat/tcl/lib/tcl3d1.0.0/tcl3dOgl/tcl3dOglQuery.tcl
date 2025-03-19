#******************************************************************************
#
#       Copyright:      2007-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dOglQuery.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with query procedures related to
#                       the OpenGL module.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dOglGetVersion - Get OpenGL version string.
#
#       Synopsis:       tcl3dOglGetVersion {}
#
#       Description:    Return the version string of the wrapped OpenGL library.
#                       The version string does not have a specific format.
#                       It depends on the vendor of the OpenGL implementation.
#                       Some examples:
#                       1.4 APPLE-1.6.18
#                       2.1.2 NVIDIA 173.14.12
#
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function returns an 
#                       empty string.
#
#       See also:       tcl3dOglGetVersions
#                       tcl3dGetLibraryInfo
#                       tcl3dOglHaveVersion
#
###############################################################################

proc tcl3dOglGetVersion {} {
    if { [info commands glGetString] ne "" } {
        return [glGetString GL_VERSION]
    } else {
        return ""
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetVersionNumber - Get OpenGL version number.
#
#       Synopsis:       tcl3dOglGetVersionNumber {}
#
#       Description:    Return the OpenGL version number as a dictionary
#                       containing the following elements:
#                       major: int
#                       minor: int
#                       patch: int
#
#                       If a component of the OpenGL version number is not
#                       supplied by the OpenGL driver, the corresponding element
#                       is set to -1.
#
#                       Note: The version number of the OpenGL implementation
#                             is extracted from the string returned by calling
#                             "glGetString GL_VERSION". As some vendors format
#                             the version in an unusual way, this function may
#                             not work correctly on all platforms.
#
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function returns an 
#                       empty dictionary.
#
#       See also:       tcl3dOglGetVersions
#                       tcl3dOglGetVersion
#                       tcl3dOglHaveVersion
#
###############################################################################

proc tcl3dOglGetVersionNumber {} {
    set versionStr [tcl3dOglGetVersion]
    if { $versionStr eq "" } {
        return [dict create]
    }

    if {3 != [scan $versionStr "%d.%d.%d" majorHave minorHave patchHave] } {
        set patchHave -1
        if {2 != [scan $versionStr "%d.%d" majorHave minorHave] } {
            set minorHave -1
            if {1 != [scan $versionStr "%d" majorHave] } {
                set majorHave -1
            }
        }
    }
    dict set versionDict "major" $majorHave
    dict set versionDict "minor" $minorHave
    dict set versionDict "patch" $patchHave
    return $versionDict
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetGlewVersion - Get GLEW version string.
#
#       Synopsis:       tcl3dOglGetGlewVersion {}
#
#       Description:    Return the version string of the GLEW wrapper library.
#                       The version is returned as "Major.Minor.Patch".
#
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the function returns an 
#                       empty string.
#
#       See also:       tcl3dOglGetVersion
#                       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglGetGlewVersion {} {
    if { [info commands glewGetString] ne "" } {
        # 1 corresponds to GLEW_VERSION.
        # GLEW_* defines and variables are not wrapped.
        return [glewGetString 1]
    } else {
        return ""
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetInfoString - Get environment info string.
#
#       Synopsis:       tcl3dOglGetInfoString {}
#
#       Description:    Return a string containing information about the
#                       following environment values:
#                           Operating system
#                           OpenGL Renderer
#                           OpenGL version
#                           Tk     version
#                           Tcl/Tk bit size
#                       
#                       If no OpenGL context has been established (i.e. a Togl
#                       window has not been created), the returned string does
#                       not contain OpenGL information.
#
#       See also:       tcl3dOglGetVersion
#                       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglGetInfoString {} {
    set widget3D "Togl"
    if { [tcl3dHaveTkgl] } {
        set widget3D "Tkgl"
    }
    return [format "Using Tcl3D %s (%s based) on %s %s with a %s (OpenGL %s, Tk %s %d-bit)" \
           [package versions tcl3d] $widget3D \
           $::tcl_platform(os) $::tcl_platform(osVersion) \
           [glGetString GL_RENDERER] \
           [glGetString GL_VERSION] $::tk_patchLevel \
           [expr $::tcl_platform(pointerSize) == 4? 32: 64]]
}

###############################################################################
#[@e
#       Name:           tcl3dOglHaveFunc - Check availability of a specific
#                       OpenGL function.
#
#       Synopsis:       tcl3dOglHaveFunc { glFuncName }
#
#       Description:    glFuncName : string
#
#                       Return 1, if the OpenGL function "glFuncName" is
#                       provided by the underlying OpenGL implementation.
#                       Otherwise return 0. 
#                   
#                       Example: tcl3dOglHaveFunc glGenQueriesARB
#                                checks the availability of the occlussion query
#                                related ARB extension function glGenQueriesARB.
#
#                       Note: A Togl window (and therefore a graphics context)
#                             must have been created before issuing a call to
#                             this function.
#
#       See also:       tcl3dOglHaveExtension
#
###############################################################################

proc tcl3dOglHaveFunc { glFuncName } {
    set checkCmd [format "__%sAvail" $glFuncName]
    if { [info commands $checkCmd] eq "" } {
        if { [info commands $glFuncName] eq "" } {
            return 0
        } else { 
            return 1
        }
    } else {
        return [$checkCmd]
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglHaveExtension - Check availability of a specific
#                       OpenGL extension.
#
#       Synopsis:       tcl3dOglHaveExtension { toglwin extensionName }
#
#       Description:    toglwin       : Togl window
#                       extensionName : string
#
#                       Return 1, if the OpenGL extension "extensionName" is
#                       provided by the underlying OpenGL implementation.
#                       Otherwise return 0. 
#                   
#                       Example: tcl3dOglHaveExtension $toglwin GL_ARB_multitexture
#                                checks the availability of the multitexturing
#                                extension.
#
#       See also:       tcl3dOglGetExtensions
#
###############################################################################

proc tcl3dOglHaveExtension { toglwin extensionName } {
    set found [lsearch -exact [tcl3dOglGetExtensions $toglwin "all"] $extensionName]
    if { $found >= 0 } {
        return 1
    }
    return 0
}

###############################################################################
#[@e
#       Name:           tcl3dOglHaveVersion - Check availability of a specific
#                       OpenGL version.
#
#       Synopsis:       tcl3dOglHaveVersion { majorWanted { minorWanted -1 }
#                                           { patchWanted -1 } }
#
#       Description:    majorWanted : int
#                       minorWanted : int
#                       patchWanted : int
#
#                       Return 1, if the OpenGL version offered by the driver
#                       is equal to or greater than the supplied
#                       major, minor and patch level numbers.
#                       Otherwise return 0.
#
#                       Note: The version number of the OpenGL implementation
#                             is extracted from the string returned by calling
#                             "glGetString GL_VERSION". As some vendors format
#                             the version in an unusual way, this function may
#                             not work correctly on all platforms.
#
#                             If no OpenGL context has been established 
#                             (i.e. a Togl window has not been created), the
#                             function returns 0. 
#
#       See also:       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglHaveVersion { majorWanted { minorWanted -1 } { patchWanted -1 } } {
    set versionDict [tcl3dOglGetVersionNumber]
    if { [dict size $versionDict] == 0 } {
        return 0
    }

    set majorHave [dict get $versionDict "major"]
    set minorHave [dict get $versionDict "minor"]
    set patchHave [dict get $versionDict "patch"]

    if { $majorHave > $majorWanted } {
        return 1
    } elseif { $majorHave < $majorWanted } {
        return 0
    } else {
        # Major versions are identical.
        if { $minorHave > $minorWanted || $minorHave < 0 } {
            return 1
        } elseif { $minorHave < $minorWanted } {
            return 0
        } else {
            # Minor versions are identical.
            if { $patchHave >= $patchWanted || $patchHave < 0 } {
                return 1
            } else {
                return 0
            }
        }
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetVersions - Get OpenGL version information.
#
#       Synopsis:       tcl3dOglGetVersions { toglwin }
#
#       Description:    Return OpenGL version information as a list of 
#                       (key,value) pairs. 
#                       Keys are the following OpenGL version types: 
#                       GL_VENDOR, GL_RENDERER, GL_VERSION, GLU_VERSION,
#                       GL_SHADING_LANGUAGE_VERSION, GLEW_VERSION.
#                       Values are the corresponding version strings as returned
#                       by the underlying OpenGL implementation.
#
#                       Example:
#                       {GL_VENDOR {Intel Inc.}}
#                       {GL_RENDERER {Intel GMA 950 OpenGL Engine}}
#                       {GL_VERSION {1.2 APPLE-1.4.56}}
#                       {GLU_VERSION {1.3 MacOSX}}
#
#       See also:       tcl3dOglHaveVersion
#                       tcl3dOglGetExtensions
#
###############################################################################

proc tcl3dOglGetVersions { toglwin } {
    set versList {}

    set version [glGetString GL_VENDOR]
    lappend versList [list GL_VENDOR $version]
    set version [glGetString GL_RENDERER]
    lappend versList [list GL_RENDERER $version]
    set version [glGetString GL_VERSION]
    lappend versList [list GL_VERSION $version]
    if { [info exists ::GLU_VERSION_1_1] } {
        set version [gluGetString GLU_VERSION]
        lappend versList [list GLU_VERSION $version]
    } else {
        lappend versList [list GLU_VERSION "1.0"]
    }
    if { [info global GL_SHADING_LANGUAGE_VERSION] ne "" } {
        set version [glGetString GL_SHADING_LANGUAGE_VERSION]
        lappend versList [list GL_SHADING_LANGUAGE_VERSION $version]
    }
    set version [tcl3dOglGetGlewVersion]
    lappend versList [list GLEW_VERSION $version]

    return $versList
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetExtensions - Get supported OpenGL extensions.
#
#       Synopsis:       tcl3dOglGetExtensions { toglwin {what "all"} }
#
#       Description:    Return a list containing OpenGL, GLU or platform
#                       specific extension information.
#
#                       If "what" is equal to "gl", all OpenGL extension names
#                       are returned.
#                       If "what" is equal to "glu", all GLU extension names
#                       are returned.
#                       If "what" is equal to "platform", all platform specific
#                       extension names are returned: GLX_*, WGL_*.
#                       If "what" is equal to "all", all OpenGL, GLU andplatform
#                       specific extension names are returned.
#
#       See also:       tcl3dOglHaveExtension
#                       tcl3dOglGetVersions
#
###############################################################################

proc tcl3dOglGetExtensions { toglwin { what "all" } } {
    set versList {}

    switch -exact -- $what {
        "all" {
            return [list \
                {*}[$toglwin extensions -gl] \
                {*}[$toglwin extensions -glu] \
                {*}[$toglwin extensions -platform] \
            ]
        }
        "gl" {
            return [$toglwin extensions -gl]
        }
        "glu" {
            return [$toglwin extensions -glu]
        }
        "platform" {
            return [$toglwin extensions -platform]
        }
    }
    return [list]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetBooleanState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetBooleanState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query a boolean OpenGL state
#                       variable with glGetBooleanv.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as an 
#                       integer scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See chapter 6.2 of the OpenGL reference 
#                             specification for a list of state variables.
#
#       See also:       tcl3dOglGetIntegerState
#                       tcl3dOglGetFloatState
#                       tcl3dOglGetDoubleState
#
###############################################################################

proc tcl3dOglGetBooleanState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLboolean $numVals]
    glGetBooleanv $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetIntegerState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetIntegerState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query an integer OpenGL state
#                       variable with glGetIntegerv.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as an 
#                       integer scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See chapter 6.2 of the OpenGL reference 
#                             specification for a list of state variables.
#
#       See also:       tcl3dOglGetBooleanState
#                       tcl3dOglGetFloatState
#                       tcl3dOglGetDoubleState
#
###############################################################################

proc tcl3dOglGetIntegerState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLint $numVals]
    glGetIntegerv $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetFloatState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetFloatState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query a 32-bit floating point
#                       OpenGL state variable with glGetFloatv.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as a
#                       float scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See chapter 6.2 of the OpenGL reference 
#                             specification for a list of state variables.
#
#       See also:       tcl3dOglGetBooleanState
#                       tcl3dOglGetIntegerState
#                       tcl3dOglGetDoubleState
#
###############################################################################

proc tcl3dOglGetFloatState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLfloat $numVals]
    glGetFloatv $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetDoubleState - Get OpenGL state variable.
#
#       Synopsis:       tcl3dOglGetDoubleState { state { numVals 1 } }
#
#       Description:    state    : GLenum
#                       numVals  : int
#
#                       Utility function to query a 64-bit floating point
#                       OpenGL state variable with glGetDoublev.
#                       The state variable to be queried is specified as an
#                       GLenum in parameter "state".
#
#                       The value of the state variable is returned as a
#                       double scalar value, if "numVals" is 1. If "numVals" is
#                       greater than 1, a Tcl list is returned.
#
#                       Note: See chapter 6.2 of the OpenGL reference 
#                             specification for a list of state variables.
#
#       See also:       tcl3dOglGetBooleanState
#                       tcl3dOglGetIntegerState
#                       tcl3dOglGetFloatState
#
###############################################################################

proc tcl3dOglGetDoubleState { state { numVals 1 } } {
    if { $numVals <= 0 } {
        error "Number of values must be greater than zero"
    }
    set vec [tcl3dVector GLdouble $numVals]
    glGetDoublev $state $vec
    if { $numVals == 1 } {
        set val [$vec get 0]
    } else {
        set val [tcl3dVectorToList $vec $numVals]
    }
    $vec delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetMaxTextureSize - Get maximum texture size.
#
#       Synopsis:       tcl3dOglGetMaxTextureSize {} 
#
#       Description:    Utility function to get maximum size of a texture.
#                       The maximum texture size is returned as integer value.
#                       This function corresponds to querying state variable
#                       GL_MAX_TEXTURE_SIZE.
#
#       See also:       tcl3dOglGetIntegerState
#                       tcl3dOglGetMaxTextureUnits
#
###############################################################################

proc tcl3dOglGetMaxTextureSize {} {
    return [tcl3dOglGetIntegerState GL_MAX_TEXTURE_SIZE]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetMaxTextureUnits - Get maximum texture units.
#
#       Synopsis:       tcl3dOglGetMaxTextureUnits {} 
#
#       Description:    Utility function to get maximum number of texture units.
#                       The maximum number of texture units is returned as an
#                       integer value.
#                       This function corresponds to querying state variable
#                       GL_MAX_TEXTURE_UNITS.
#
#       See also:       tcl3dOglGetIntegerState
#                       tcl3dOglGetMaxTextureSize
#
###############################################################################

proc tcl3dOglGetMaxTextureUnits {} {
    return [tcl3dOglGetIntegerState GL_MAX_TEXTURE_UNITS]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetViewport - Get current viewport.
#
#       Synopsis:       tcl3dOglGetViewport {}
#
#       Description:    Utility function to get the current viewport.
#                       The viewport is returned as a 4-element Tcl list:
#                       { LowerLeftX LowerLeftY Width Height }
#                       This function corresponds to querying state variable
#                       GL_VIEWPORT.
#
#       See also:       tcl3dOglGetIntegerState
#
###############################################################################

proc tcl3dOglGetViewport {} {
    return [tcl3dOglGetIntegerState GL_VIEWPORT 4]
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetProfile - Get OpenGL profile settings.
#
#       Synopsis:       tcl3dOglGetProfile { toglwin }
#
#       Description:    Utility function to get the currently available OpenGL
#                       profile.
#
#                       The wished profile (Core or Compatibility profile, 
#                       OpenGL major and minor version) are set when creating a
#                       Togl window with the following command line options:
#                           "-coreprofile bool" "-major int" "-minor int"
#
#                       As the wished combination might not be available with
#                       the installed OpenGL driver, the following situations
#                       can occur:
#                       1. An error is generated at Togl creation time.
#                       2. A compatibility profile is automatically selected by
#                          the driver.
#
#                       To check for the second case, issue a call to 
#                       tcl3dOglGetProfile after Togl creation to check, if your
#                       wished profile has been established.
#                       
#                       The procedure returns a dictionary with the following
#                       entries:
#                       coreprofile true|false
#                       major       int
#                       minor       int
#
#       See also:       tcl3dOglHaveVersion
#                       tcl3dOglGetVersionNumber
#                       tcl3dOglGetIntegerState
#
###############################################################################

proc tcl3dOglGetProfile { toglwin } {
    set haveCoreProfile false
    # Call GetError function here to clear previous OpenGL errors.
    # Otherwise we cannot determine, whether the driver supports the
    # GL_CONTEXT_PROFILE_MASK enumeration.
    set errMsg [tcl3dOglGetError]
    set profile [tcl3dOglGetIntegerState GL_CONTEXT_PROFILE_MASK]
    set errMsg [tcl3dOglGetError]
    if { $errMsg eq "" } {
        if { $profile == 1 } {
            set haveCoreProfile true
        }
        set major [tcl3dOglGetIntegerState GL_MAJOR_VERSION]
        set minor [tcl3dOglGetIntegerState GL_MINOR_VERSION]
    } else {
        set versionDict [tcl3dOglGetVersionNumber]
        set major [dict get $versionDict "major"]
        set minor [dict get $versionDict "minor"]
    }

    dict set profileDict "coreprofile" $haveCoreProfile
    dict set profileDict "major" $major
    dict set profileDict "minor" $minor
    return $profileDict
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetExtSuffixes - Get OpenGL extension suffixes.
#
#       Synopsis:       tcl3dOglGetExtSuffixes {}
#
#       Description:    Return a list of all OpenGL extension suffixes.
#                       Currently these are:
#                       "ARB" "EXT" "NV" "ATI" "SGI" "SGIX" "SGIS"
#                       "SUN" "WIN" "MESA" "INTEL" "IBM" "HP"
#
#       See also:       tcl3dOglGetExtensions
#
###############################################################################

proc tcl3dOglGetExtSuffixes {} {
    return { "ARB" "EXT" "NV" "ATI" "SGI" "SGIX" "SGIS" \
             "SUN" "WIN" "MESA" "INTEL" "IBM" "HP" }
}

###############################################################################
#[@e
#       Name:           tcl3dOglFindFunc - Find an OpenGL function.
#
#       Synopsis:       tcl3dOglFindFunc { glFunc }
#
#       Description:    Return the name of an OpenGL function implemented in
#                       the available OpenGL driver.
#                       First it is checked, if the function is available 
#                       as a native implementation. If the OpenGL version does
#                       not supply the function, all possible extension names
#                       are checked in the order as returned by
#                       tcl3dOglGetExtSuffixes.
#                       If none of these checks succeed, an empty string is
#                       returned.
#
#       See also:       tcl3dOglGetExtSuffixes
#
###############################################################################

proc tcl3dOglFindFunc { glFunc } {
    if { [tcl3dOglHaveFunc $glFunc] } {
        return $glFunc
    } else {
        foreach ext [tcl3dOglGetExtSuffixes] {
            set func "${glFunc}${ext}"
            if { [tcl3dOglHaveFunc $func] } {
                return $func
            }
        }
    }
    return ""
}

###############################################################################
#[@e
#       Name:           tcl3dOglIsStateVar - Check for state variable.
#
#       Synopsis:       tcl3dOglIsStateVar { enumName }
#
#       Description:    Check, if given enumeration name is an OpenGL
#                       state variable. 
#
#       See also:       
#
###############################################################################

proc tcl3dOglIsStateVar { enumName } {
    set isStateVar 0
    if { [lsearch -index 0 -exact [__tcl3dGetStateList] $enumName] >= 0 } {
        set isStateVar 1
    }
    return $isStateVar
}

# Internal procedure to find a specific OpenGL extension.
# "type" may be either "cmd" to find an OpenGL extension command: gl*
# "val" is the command or enumeration prefix to be searched in the list
# of extension suffixes.

proc __tcl3dOglFindExtension { type val } {
    set extList [tcl3dOglGetExtSuffixes]
    if { [string compare $type "cmd"] == 0 } {
        set typeList [info commands gl*]
        set fmtStr "%s%s"
    } else {
        set typeList [info globals GL_*]
        set fmtStr "%s_%s"
    }
    set result {}
    foreach ext $extList {
        set typeExt [format $fmtStr $val $ext]
        if { [lsearch -exact $typeList $typeExt] >= 0 } {
            lappend result $typeExt
        }
    }
    return $result
}
