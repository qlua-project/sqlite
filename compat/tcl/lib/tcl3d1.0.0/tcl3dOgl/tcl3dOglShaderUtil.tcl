#******************************************************************************
#
#       Copyright:      2010-2024 Paul Obermeier (obermeier@tcl3d.org)
#
#                       See the file "Tcl3D_License.txt" for information on
#                       usage and redistribution of this file, and for a
#                       DISCLAIMER OF ALL WARRANTIES.
#
#       Module:         Tcl3D -> tcl3dOgl
#       Filename:       tcl3dOglShaderUtil.tcl
#
#       Author:         Paul Obermeier
#
#       Description:    Tcl module with miscellaneous utility
#                       procedures related to shader programming.
#
#******************************************************************************

###############################################################################
#[@e
#       Name:           tcl3dOglGetShaderState - Get shader parameter status.
#
#       Synopsis:       tcl3dOglGetShaderState { shader status }
#
#       Description:    shader : Shader object
#                       status : OpenGL enumeration.
#                                  GL_SHADER_TYPE
#                                  GL_DELETE_STATUS
#                                  GL_COMPILE_STATUS
#                                  GL_INFO_LOG_LENGTH
#                                  GL_SHADER_SOURCE_LENGTH
#
#                       Utility function for easier use of OpenGL function
#                       glGetShaderiv.
#                       Given the shader object (as returned by function
#                       glCreateShader), the function returns the
#                       value of the specified status parameter.
#
#       See also:       tcl3dOglCompileProgram
#                       tcl3dOglGetProgramState
#
###############################################################################

proc tcl3dOglGetShaderState { shader status } {
    set statusFlag [tcl3dVector GLint 1]
    glGetShaderiv $shader $status $statusFlag
    set val [$statusFlag get 0]
    $statusFlag delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetProgramState - Get program parameter status.
#
#       Synopsis:       tcl3dOglGetProgramState { program status }
#
#       Description:    program : Program object
#                       status  : OpenGL enumeration.
#                                  GL_DELETE_STATUS
#                                  GL_LINK_STATUS
#                                  GL_VALIDATE_STATUS
#                                  GL_INFO_LOG_LENGTH
#                                  GL_ATTACHED_SHADERS
#                                  GL_ACTIVE_ATTRIBUTES
#                                  GL_ACTIVE_ATTRIBUTE_MAX_LENGTH
#                                  GL_ACTIVE_UNIFORMS
#                                  GL_ACTIVE_UNIFORM_MAX_LENGTH
#
#                       Utility function for easier use of OpenGL function
#                       glGetProgramiv.
#                       Given the program object (as returned by function
#                       glCreateProgram), the function returns the
#                       value of the specified status parameter.
#
#       See also:       tcl3dOglLinkProgram
#                       tcl3dOglGetShaderState
#
###############################################################################

proc tcl3dOglGetProgramState { program status } {
    set statusFlag [tcl3dVector GLint 1]
    glGetProgramiv $program $status $statusFlag
    set val [$statusFlag get 0]
    $statusFlag delete
    return $val
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetInfoLogARB - Get shader object log.
#
#       Synopsis:       tcl3dOglGetInfoLogARB { object }
#
#       Description:    object  : Shader object
#
#                       Utility function for easier use of OpenGL function
#                       glGetInfoLogARB.
#                       Given the shader object (as returned by function
#                       glCreateProgramObjectARB), the function returns the
#                       information log message as a Tcl string.
#
#       See also:       tcl3dOglGetShaderInfoLog
#                       tcl3dOglGetProgramInfoLog
#                       tcl3dOglGetShaderSource
#
###############################################################################

proc tcl3dOglGetInfoLogARB { object } {
    set infoLenVec [tcl3dVector GLint 1]
    glGetObjectParameterivARB $object GL_OBJECT_INFO_LOG_LENGTH_ARB $infoLenVec
    set infoLen [$infoLenVec get 0]
    set infoStr ""
    if { $infoLen > 0 } {
        set infoStrVec [tcl3dVector GLubyte $infoLen]
        glGetInfoLogARB $object $infoLen "NULL" $infoStrVec
        set infoStr [tcl3dVectorToString $infoStrVec]
        $infoStrVec delete
    }
    $infoLenVec delete
    return $infoStr
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetShaderInfoLog - Get shader object log.
#
#       Synopsis:       tcl3dOglGetShaderInfoLog { shader }
#
#       Description:    shader  : Shader object
#
#                       Utility function for easier use of OpenGL function
#                       glGetShaderInfoLog.
#                       Given the shader object (as returned by function
#                       glCreateShader), the function returns the
#                       information log message as a Tcl string.
#
#       See also:       tcl3dOglGetProgramInfoLog
#                       tcl3dOglGetShaderSource
#                       tcl3dOglGetInfoLogARB
#
###############################################################################

proc tcl3dOglGetShaderInfoLog { shader } {
    set infoLenVec [tcl3dVector GLint 1]
    glGetShaderiv $shader GL_INFO_LOG_LENGTH $infoLenVec
    set infoLen [$infoLenVec get 0]
    set infoStr ""
    if { $infoLen > 0 } {
        set infoStrVec [tcl3dVector GLubyte $infoLen]
        glGetShaderInfoLog $shader $infoLen "NULL" $infoStrVec
        set infoStr [tcl3dVectorToString $infoStrVec]
        $infoStrVec delete
    }
    $infoLenVec delete
    return $infoStr
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetProgramInfoLog - Get shader program log.
#
#       Synopsis:       tcl3dOglGetProgramInfoLog { shader }
#
#       Description:    shader  : Shader program
#
#                       Utility function for easier use of OpenGL function
#                       glGetProgramInfoLog.
#                       Given the shader program (as returned by function
#                       glCreateProgram), the function returns the
#                       information log message as a Tcl string.
#
#       See also:       tcl3dOglGetShaderInfoLog
#                       tcl3dOglGetShaderSource
#                       tcl3dOglGetInfoLogARB
#
###############################################################################

proc tcl3dOglGetProgramInfoLog { program } {
    set infoLenVec [tcl3dVector GLint 1]
    glGetProgramiv $program GL_INFO_LOG_LENGTH $infoLenVec
    set infoLen [$infoLenVec get 0]
    set infoStr ""
    if { $infoLen > 0 } {
        set infoStrVec [tcl3dVector GLubyte $infoLen]
        glGetProgramInfoLog $program $infoLen "NULL" $infoStrVec
        set infoStr [tcl3dVectorToString $infoStrVec]
        $infoStrVec delete
    }
    $infoLenVec delete
    return $infoStr
}

###############################################################################
#[@e
#       Name:           tcl3dOglGetShaderSource - Get shader object source.
#
#       Synopsis:       tcl3dOglGetShaderSource { shader }
#
#       Description:    shader  : Shader object
#
#                       Utility function for easier use of OpenGL function
#                       glGetShaderSource.
#                       Given the shader object (as returned by function
#                       glCreateShader), the function returns the
#                       shader source code as a Tcl string.
#
#       See also:       tcl3dOglGetShaderInfoLog
#                       tcl3dOglGetProgramInfoLog
#                       tcl3dOglGetInfoLogARB
#                       tcl3dOglShaderSource
#
###############################################################################

proc tcl3dOglGetShaderSource { shader } {
    set srcLenVec [tcl3dVector GLint 1]
    glGetShaderiv $shader GL_SHADER_SOURCE_LENGTH $srcLenVec
    set srcLen [$srcLenVec get 0]
    set srcStr ""
    if { $srcLen > 0 } {
        set srcStrVec [tcl3dVector GLubyte $srcLen]
        glGetShaderSource $shader $srcLen "NULL" $srcStrVec
        set srcStr [tcl3dVectorToString $srcStrVec]
        $srcStrVec delete
    }
    $srcLenVec delete
    return $srcStr
}

###############################################################################
#[@e
#       Name:           tcl3dOglShaderSource - Wrapper for glShaderSource.
#
#       Synopsis:       tcl3dOglShaderSource { shaderId shaderString }
#
#       Description:    shaderId     : Shader handle
#                       shaderString : string
#       
#                       Wrapper for easier use of OpenGL function glShaderSource.
#                       In contrast to glShaderSource only the shader program
#                       identifier (created with a call to glCreateShaderObject)
#                       and the shader source have to be specified.
#
#       See also:       tcl3dOglGetShaderSource
#
###############################################################################

proc tcl3dOglShaderSource { shaderId shaderString } {
    set shaderStringList [list $shaderString]
    set lenList [list [string length $shaderString]]
    glShaderSource $shaderId 1 $shaderStringList $lenList
}

###############################################################################
#[@e
#       Name:           tcl3dOglReadShaderFile - Read a shader file.
#
#       Synopsis:       tcl3dOglReadShaderFile { pathName }
#
#       Description:    pathName : Shader file name
#       
#                       Read shader file "pathName" and return it's contents
#                       as a string. The path name is transparently mapped with
#                       tcl3dGetExtFile, so that this procedure can be used from
#                       within a starpack.
#
#       See also:       tcl3dOglShaderSource
#                       tcl3dGetExtFile
#
###############################################################################

proc tcl3dOglReadShaderFile { pathName } {
    set realPath [tcl3dGetExtFile $pathName true]
    set retVal [catch {open $realPath r} fp]
    if { $retVal == 0 } {
        set buffer [read $fp]
        close $fp
    } else {
        error "Cannot open shader file $realPath"
    }
    return $buffer
}

###############################################################################
#[@e
#       Name:           tcl3dOglCompileProgram - Compile a shader program.
#
#       Synopsis:       tcl3dOglCompileProgram { vertexSource controlSource
#                               evaluationSource geometrySource fragmentSource }
#
#       Description:    vertexSource    : string
#                       controlSource   : string
#                       evaluationSource: string
#                       geometrySource  : string
#                       fragmentSource  : string
#       
#                       Compile and attach the specified shader sources.
#                       Vertex and fragment shader sources must be given. All
#                       other parameters can be supplied as an empty string, if
#                       the corresponding render stage should  not be used.
#
#       See also:       tcl3dOglBuildProgram
#                       tcl3dOglLinkProgram
#                       tcl3dOglDestroyProgram
#
###############################################################################

proc tcl3dOglCompileProgram { vertexSource controlSource evaluationSource \
                              geometrySource fragmentSource } {
    if { $vertexSource eq "" || $fragmentSource eq "" } {
        error "No vertex or fragment shader source specified"
    }
    if { ! [tcl3dOglHaveFunc "glCreateShader"] } {
        error "No shader support available (glCreateShader missing)"
    }
    set vertexShader [glCreateShader GL_VERTEX_SHADER]
    tcl3dOglShaderSource $vertexShader $vertexSource
    glCompileShader $vertexShader

    set compiled [tcl3dOglGetShaderState $vertexShader $::GL_COMPILE_STATUS]
    if { ! $compiled } {
        set infoStr [tcl3dOglGetShaderInfoLog $vertexShader]
        error "Vertex shader compile error: $infoStr"
    }

    if { $controlSource ne "" } {
        set controlShader [glCreateShader GL_TESS_CONTROL_SHADER]
        tcl3dOglShaderSource $controlShader $controlSource
        glCompileShader $controlShader

        set compiled [tcl3dOglGetShaderState $controlShader $::GL_COMPILE_STATUS]
        if { ! $compiled } {
            set infoStr [tcl3dOglGetShaderInfoLog $controlShader]
            error "Control shader compile error: $infoStr"
        }
    }

    if { $evaluationSource ne "" } {
        set evaluationShader [glCreateShader GL_TESS_EVALUATION_SHADER]
        tcl3dOglShaderSource $evaluationShader $evaluationSource
        glCompileShader $evaluationShader

        set compiled [tcl3dOglGetShaderState $evaluationShader $::GL_COMPILE_STATUS]
        if { ! $compiled } {
            set infoStr [tcl3dOglGetShaderInfoLog $evaluationShader]
            error "Evaluation shader compile error: $infoStr"
        }
    }

    if { $geometrySource ne "" } {
        set geometryShader [glCreateShader GL_GEOMETRY_SHADER]
        tcl3dOglShaderSource $geometryShader $geometrySource
        glCompileShader $geometryShader

        set compiled [tcl3dOglGetShaderState $geometryShader $::GL_COMPILE_STATUS]
        if { ! $compiled } {
            set infoStr [tcl3dOglGetShaderInfoLog $geometryShader]
            error "Geometry shader compile error: $infoStr"
        }
    }

    set fragmentShader [glCreateShader GL_FRAGMENT_SHADER]
    tcl3dOglShaderSource $fragmentShader $fragmentSource
    glCompileShader $fragmentShader

    set compiled [tcl3dOglGetShaderState $fragmentShader $::GL_COMPILE_STATUS]
    if { ! $compiled } {
        set infoStr [tcl3dOglGetShaderInfoLog $fragmentShader]
        error "Fragment shader compile error: $infoStr"
    }

    set program [glCreateProgram]

    glAttachShader $program $vertexShader

    if { [info exists controlShader] } {
        glAttachShader $program $controlShader
    }

    if { [info exists evaluationShader] } {
        glAttachShader $program $evaluationShader
    }

    if { [info exists geometryShader] } {
        glAttachShader $program $geometryShader
    }

    glAttachShader $program $fragmentShader

    dict set programDict "program"  $program
    dict set programDict "vertex"   $vertexShader
    if { [info exists controlShader] } {
        dict set programDict "control" $controlShader
    }
    if { [info exists evaluationShader] } {
        dict set programDict "evaluation" $evaluationShader
    }
    if { [info exists geometryShader] } {
        dict set programDict "geometry" $geometryShader
    }
    dict set programDict "fragment" $fragmentShader
    return $programDict
}

###############################################################################
#[@e
#       Name:           tcl3dOglLinkProgram - Link a shader program.
#
#       Synopsis:       tcl3dOglLinkProgram { programDict }
#
#       Description:    programDict : Program dictionary
#       
#                       Link the program specified in the program dictionary.
#                       "programDict" is the dictionary returned by
#                       tcl3dOglCompileProgram.
#
#       See also:       tcl3dOglBuildProgram
#                       tcl3dOglCompileProgram
#                       tcl3dOglDestroyProgram
#
###############################################################################

proc tcl3dOglLinkProgram { programDict } {
    if { ! [dict exists $programDict program] } {
        error "Shader program not in programDict"
    }
    set program [dict get $programDict program]
    glLinkProgram $program

    set linked [tcl3dOglGetProgramState $program $::GL_LINK_STATUS]
    if { ! $linked } {
        set infoStr [tcl3dOglGetProgramInfoLog $program]
        error "Shader program link error: $infoStr"
    }
}

###############################################################################
#[@e
#       Name:           tcl3dOglBuildProgram - Build a shader program.
#
#       Synopsis:       tcl3dOglBuildProgram { vertexSource controlSource
#                               evaluationSource geometrySource fragmentSource }
#
#       Description:    vertexSource    : string
#                       controlSource   : string
#                       evaluationSource: string
#                       geometrySource  : string
#                       fragmentSource  : string
#       
#                       Compile and link the specified shader sources.
#                       Vertex and fragment shader sources must be given. All
#                       other parameters can be supplied as an empty string, if
#                       the corresponding render stage should  not be used.
#       
#       See also:       tcl3dOglCompileProgram
#                       tcl3dOglLinkProgram
#                       tcl3dOglDestroyProgram
#
###############################################################################

proc tcl3dOglBuildProgram { vertexSource controlSource evaluationSource \
                            geometrySource fragmentSource } {
    set programDict [tcl3dOglCompileProgram $vertexSource \
                                            $controlSource \
                                            $evaluationSource \
                                            $geometrySource \
                                            $fragmentSource]
    tcl3dOglLinkProgram $programDict
    return $programDict
}

###############################################################################
#[@e
#       Name:           tcl3dOglDestroyProgram - Destroy a shader program.
#
#       Synopsis:       tcl3dOglDestroyProgram { programDict }
#
#       Description:    programDict : Program dictionary
#       
#                       Destroy the program specified in the program dictionary.
#                       "programDict" is the dictionary returned by
#                       tcl3dOglCompileProgram or tcl3dOglBuildProgram.
#
#       See also:       tcl3dOglBuildProgram
#                       tcl3dOglCompileProgram
#                       tcl3dOglLinkProgram
#
###############################################################################

proc tcl3dOglDestroyProgram { programDict } {
    if { [dict exists $programDict program] } {
        glDeleteProgram [dict get $programDict program]
        dict unset programDict program
    }

    if { [dict exists $programDict fragment] } {
        glDeleteShader [dict get $programDict fragment]
        dict unset programDict fragment
    }

    if { [dict exists $programDict geometry] } {
        glDeleteShader [dict get $programDict geometry]
        dict unset programDict geometry
    }

    if { [dict exists $programDict vertex] } {
        glDeleteShader [dict get $programDict vertex]
        dict unset programDict vertex
    }

    if { [dict exists $programDict control] } {
        glDeleteShader [dict get $programDict control]
        dict unset programDict control
    }

    if { [dict exists $programDict evaluation] } {
        glDeleteShader [dict get $programDict evaluation]
        dict unset programDict evaluation
    }
}
