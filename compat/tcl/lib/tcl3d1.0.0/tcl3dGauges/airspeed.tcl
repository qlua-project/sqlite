#!/bin/sh
# the next line restarts using wish \
exec wish "$0" -- ${1+"$@"}

#------------------------------------------------------------------------------
# airspeed v1.00 2005/11/14 11:36:23 vbonilla
# Copyright (c) 2005, Victor G. Bonilla
#
# Tcl3D based widget.
#
# Contributions by Paul Obermeier
#------------------------------------------------------------------------------

namespace eval airspeed {
    variable data
    set data(validArgs) { \
        $f,-width 256 $f,-height 256 $f,-size 256 \
        $f,-background black \
        $f,-variable ::airspeed::data($f,var) $f,var 0 \
        $f,-backImage airspeedBack \
        $f,-baseImage airspeedBaseOdo \
        $f,-lArrowImage airspeedLArrow \
        $f,-odo1Image airspeedOdo1 \
        $f,-odo2Image airspeedOdo2 \
        $f,-odo3Image airspeedOdo3 \
        $f,-odo4Image airspeedOdo4 \
        $f,-odo5Image airspeedOdo5 \
        $f,-coverImage airspeedCover}
    array set data {aboutXaxis {1 0 0} aboutYaxis {0 1 0} aboutZaxis {0 0 1}}

    # These variables are only needed for the demonstration.
    # autoRotate: 0=> clockwise rotation, 1=> no rotation, 2=> counter clockwise
    set data(autoRotate) 1
    set data(updateRate) 50
    set data(step) 0.25
}

#------------------------------------------------------------------------------
# Name: initPackages
#------------------------------------------------------------------------------
# Arguments: A list of packages to load
#------------------------------------------------------------------------------
# Logic: Loop through args and load packages,
#        save versions in global data structure
#------------------------------------------------------------------------------
proc ::airspeed::initPackages { args } {
    variable data

    foreach pkg $args {
        set retVal [catch {package require $pkg} data(ext,$pkg,version)]
        set data(ext,$pkg,avail) [expr !$retVal]
    }
}

#------------------------------------------------------------------------------
# Name: toglCreate
#------------------------------------------------------------------------------
# Arguments: tk path
#------------------------------------------------------------------------------
# Logic: Gets called by the togl routine to create the scene.
#        Sets the background clear color.
#        Create a tcl3dVector to hold the texture identifiers.
#        Enables blending and sets blending function.
#------------------------------------------------------------------------------
proc ::airspeed::toglCreate {f} {
    variable data

    eval glClearColor [tcl3dName2rgbaf $::airspeed::data($f,-background)]
    glShadeModel GL_FLAT
 
    glPixelStorei GL_UNPACK_ALIGNMENT 1
 
    set ::airspeed::data($f,textureIds) [tcl3dVector GLuint $data($f,numTexs)]
    glGenTextures $data($f,numTexs) $::airspeed::data($f,textureIds)

    glEnable GL_BLEND
    glBlendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
}

#------------------------------------------------------------------------------
# Name:  toglDisplay
#------------------------------------------------------------------------------
# Arguments: tk path
#------------------------------------------------------------------------------
# Logic: Gets called by the togl routine to display the scene.
#        Clears the color buffer.
#        Enables textures.
#        Positions and rotates the textured quads.
#        Flushes the pipeline and swaps the buffers (displays rendered scene).
#------------------------------------------------------------------------------
proc ::airspeed::toglDisplay {f} {
    variable data

    glClear GL_COLOR_BUFFER_BIT
    glEnable GL_TEXTURE_2D
    glTexEnvf GL_TEXTURE_ENV GL_TEXTURE_ENV_MODE $::GL_MODULATE

    for {set i 0} {$i < $data($f,numQuads)} {incr i} {
        glLoadIdentity
        eval glRotatef $data($f,rotate,$i) $data(aboutZaxis)
        drawQuad $f $i
    }

    glFlush
    glDisable GL_TEXTURE_2D
    $f swapbuffers
}

#------------------------------------------------------------------------------
# Name:  toglReshape
#------------------------------------------------------------------------------
# Arguments:  tk path, new width, and new height
#------------------------------------------------------------------------------
# Logic: Gets called by the togl routine when the frame gets re-shaped.
#        Sets the width equal to the height to maintain aspect ratio.
#        Save the information for later use.
#        Set the new viewport size.
#        Set up the orthographic projection.
#------------------------------------------------------------------------------
proc ::airspeed::toglReshape {f { w -1 } { h -1 }} {
    variable data

    set w [$f width]
    set h [$f height]

    if { $w < $h } {
        set h $w
    } else {
        set w $h
    }

    $f configure -width $w -height $h

    set data($f,-width)  $w
    set data($f,-height) $h

    glViewport 0 0 $w $h
    glMatrixMode GL_PROJECTION
    glLoadIdentity
    gluOrtho2D \
        [expr {-0.5 * $data($f,-width)}]  [expr {0.5 * $data($f,-width)}] \
        [expr {-0.5 * $data($f,-height)}] [expr {0.5 * $data($f,-height)}]

    glMatrixMode GL_MODELVIEW
    glLoadIdentity
}

#------------------------------------------------------------------------------
# Name:  drawQuad
#------------------------------------------------------------------------------
# Arguments:  tk path, and quad id
#------------------------------------------------------------------------------
# Logic: Bind the correct texture for this quad.
#        Calculate the x1,y1 and x2,y2 of the quad.
#        Make the quad and create texture coordinates.
#------------------------------------------------------------------------------
proc ::airspeed::drawQuad {f num} {
    variable data

    glBindTexture GL_TEXTURE_2D [$data($f,textureIds) get $num]

    set y1 [expr 0.5 * $data($f,-height)]
    set x1 $y1
    set y2 [expr -1.0 * $y1]
    set x2 [expr -1.0 * $x1]

    glBegin GL_QUADS
        glTexCoord2f 0.0 0.0
        glVertex2f $x2 $y2
        glTexCoord2f 0.0 1.0
        glVertex2f $x2 $y1
        glTexCoord2f 1.0 1.0
        glVertex2f $x1 $y1
        glTexCoord2f 1.0 0.0
        glVertex2f $x1 $y2
    glEnd
}

#------------------------------------------------------------------------------
# Name:  new
#------------------------------------------------------------------------------
# Arguments:  tk path and misc options
#------------------------------------------------------------------------------
# Logic: Gets called to create a new airspeed.
#        Dump elements into the data array for all valid options.
#        Iterate through arguments and set only those options enumerated
#            in data(validArgs).
#        Save the args for later use.
#        Create the togl frame and create the callbacks.
#        Read the three images that make up the airspeed.
#        Create the traced variable.
#            If none passed in, defaults to data("tk path",var).
#------------------------------------------------------------------------------
proc ::airspeed::new {f args} {
    variable data

    array set data [subst $data(validArgs)]

    foreach {t v} $args {
        if {[info exists data($f,$t)]} {
            set data($f,$t) $v
        }
    }

    set data($f,numQuads) 0
    set data($f,numTexs)  7

    togl $f -width $data($f,-width) -height $data($f,-height) \
            -double true \
            -createcommand  ::airspeed::toglCreate \
            -displaycommand ::airspeed::toglDisplay \
            -reshapecommand ::airspeed::toglReshape

    readImg $f $data($f,-backImage)   0 $data($f,-size)
    readImg $f $data($f,-odo1Image)   1 $data($f,-size)
    readImg $f $data($f,-odo2Image)   2 $data($f,-size)
    readImg $f $data($f,-odo3Image)   3 $data($f,-size)
    readImg $f $data($f,-baseImage)   4 $data($f,-size)
    readImg $f $data($f,-lArrowImage) 5 $data($f,-size)
    readImg $f $data($f,-coverImage)  6 $data($f,-size)

    trace add variable $::airspeed::data($f,-variable) write "::airspeed::update $f"

    return $f
}

#------------------------------------------------------------------------------
# Name:  delete
#------------------------------------------------------------------------------
# Arguments:  tk path
#------------------------------------------------------------------------------
# Logic: Gets called to delete the widget.
#        Free all tcl3dVectors.
#        Delete the widget itself.
#------------------------------------------------------------------------------
proc ::airspeed::delete {f} {
    variable data

    if { [info exists data($f,textureIds)] } {
        glDeleteTextures $data($f,numTexs) [$data($f,textureIds) get 0]
        $data($f,textureIds) delete
        unset data($f,textureIds)
    }

    if { [info exists data($f,numQuads)] } {
        for { set i 0 } { $i < $data($f,numQuads) } { incr i } {
            if { [info exists data($f,vecImg,$i)] } {
                $data($f,vecImg,$i) delete
                unset data($f,vecImg,$i)
            }
        }
    }
    catch { unset data($f,var) }
    catch { unset data($f,variable) }
    destroy $f
}

#------------------------------------------------------------------------------
# Name:  setSpeed
#------------------------------------------------------------------------------
# Arguments:  tk path, value
#------------------------------------------------------------------------------
# Logic: Set the traced variable (speed) to the value.
#------------------------------------------------------------------------------
proc ::airspeed::setValue {f val} {
    ::airspeed::setSpeed $f $val
}

proc ::airspeed::setSpeed {f val} {
    variable data
    set $data($f,-variable) $val
}

#------------------------------------------------------------------------------
# Name:  getSpeed
#------------------------------------------------------------------------------
# Arguments:  tk path
#------------------------------------------------------------------------------
# Logic: Return the value of the traced variable.
#------------------------------------------------------------------------------
proc ::airspeed::getValue {f} {
    return [::airspeed::getSpeed $f]
}

proc ::airspeed::getSpeed {f} {
    variable data
    return [subst $$data($f,-variable)]
}

#------------------------------------------------------------------------------
# Name:  update
#------------------------------------------------------------------------------
# Arguments: tk path, variable name, index, and operator
#------------------------------------------------------------------------------
# Logic:  Gets called by trace write.
#         Set the rotation and re-display the airspeed.
#------------------------------------------------------------------------------
proc ::airspeed::update {f var idx oper} {
    variable data

    if {$idx == {}} {
        set airspeed [expr $$var]
    } else {
        set airspeed [expr $${var}($idx)]
    }

    # Convert to integer, otherwise the modulo operator does not work.
    set airspeed [expr int ($airspeed)]

    set data($f,rotate,1) [expr ($airspeed /   1) % 10 * -36]
    set data($f,rotate,2) [expr ($airspeed /  10) % 10 * -36]
    set data($f,rotate,3) [expr ($airspeed / 100) % 10 * -36]

    set data($f,rotate,5) [expr $airspeed / 750.0 * -300.0]

    $f postredisplay
}

#------------------------------------------------------------------------------
# Name:  demo
#------------------------------------------------------------------------------
# Arguments:  title width height size background color
#------------------------------------------------------------------------------
# Logic: Creates the top level and airspeed widget, assigns bindings.
#------------------------------------------------------------------------------
proc ::airspeed::demo {title {width 300} {height 300} {size 256} {bg blue}} {
    global tcl_platform 
    variable data

    toplevel .demo
    wm withdraw .

    wm title .demo $title
    wm minsize .demo 100 100
    set sw [winfo screenwidth .demo]
    set sh [winfo screenheight .demo]
    wm maxsize .demo [expr $sw -20] [expr $sh -40]

    set f [::airspeed::new .demo.airspeed \
           -width $width -height $height -size $size \
           -background $bg -variable ::myAirspeed]
    pack $f -expand 1 -fill both -side top
    set s [scale .demo.scale -variable ::myAirspeed \
           -from 0.0 -to 750.0 -resolution 0.25 -orient horizontal]
    pack $s -expand 1 -fill both -side top

    if { [string compare $tcl_platform(os) "windows"] == 0 } {
        bind $f <Alt-F4>    exit 
    }
    wm protocol .demo WM_DELETE_WINDOW exit

    increment $f

    return $f
}

#------------------------------------------------------------------------------
# Name:  reset
#------------------------------------------------------------------------------
# Arguments:  tk path, args
#------------------------------------------------------------------------------
# Logic: Resets the rotations of the images.
#------------------------------------------------------------------------------
proc ::airspeed::reset {f args} {
    variable data

    $f configure -width $data($f,-width) -height $data($f,-height)
    for { set i 0 } { $i < $data($f,numQuads) } { incr i } {
        set data($f,rotate,$i) 0
    }
    $f postredisplay
}

#------------------------------------------------------------------------------
# Name:  readImg
#------------------------------------------------------------------------------
# Arguments:  tk path, image name, numeric id, and texture size
#------------------------------------------------------------------------------
# Logic: Gets called to load an image into texture memory.
#        Create photo image.
#        Convert to texture (vector or array).
#        Setup the texture options.
#        Display the results.
#------------------------------------------------------------------------------
proc ::airspeed::readImg {f name num size} {
    variable data

    set imgName [format "gaugeImg::%s-%d" $name $size]
    set retVal [catch {set phImg [image create photo -data [$imgName]]} err1]

    if { $retVal != 0 } {
        set retVal [catch {set phImg [image create photo -file $name]} err1]
    }

    if { $retVal != 0 } {
        error "Failure reading image $name"
    } else {
        set w [image width  $phImg]
        set h [image height $phImg]

        set data(imgOrigWidth)  $w
        set data(imgOrigHeight) $h
        set data(texScaleS) 1.0
        set data(texScaleT) 1.0

        set data($f,vecImg,$num) [tcl3dVector GLubyte [expr $w * $h * 4]]
        tcl3dPhotoToVector $phImg $data($f,vecImg,$num) -1 1.0 0.0
        image delete $phImg
        glBindTexture GL_TEXTURE_2D [$::airspeed::data($f,textureIds) get $num]
        glTexParameteri GL_TEXTURE_2D GL_TEXTURE_WRAP_S $::GL_CLAMP
        glTexParameteri GL_TEXTURE_2D GL_TEXTURE_WRAP_T $::GL_CLAMP
        glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER $::GL_LINEAR
        glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER $::GL_LINEAR
        glTexImage2D GL_TEXTURE_2D 0 $::GL_RGBA $w $h 0 GL_RGBA \
                     GL_UNSIGNED_BYTE $data($f,vecImg,$num)

        $f postredisplay

        incr data($f,numQuads)
        set data($f,rotate,$num) 0
    }
}

#------------------------------------------------------------------------------
# Name:  increment
#------------------------------------------------------------------------------
# Arguments:  tk path
#------------------------------------------------------------------------------
# Logic: Part of the demo.
#------------------------------------------------------------------------------
proc ::airspeed::increment {f} {
    variable data

    set v [expr ($data(autoRotate) % 3) - 1]
    if {$v} {
        set $data($f,-variable) [expr $$data($f,-variable) + $data(step) * $v]
    }
    after $data(updateRate) "::airspeed::increment $f"
}

#------------------------------------------------------------------------------
# Create demo and setup bindings
# Only execute this part, if this file has been started standalone.
#------------------------------------------------------------------------------

::airspeed::initPackages Img tcl3dutil tcl3dtogl tcl3dogl

if { [file tail [info script]] == [file tail $::argv0] } {
    set auto_path [linsert $auto_path 0 [file dirname [info script]]]
    ::airspeed::initPackages tcl3dgauges

    set c [::airspeed::demo "Airspeed Demo"]

    bind $c <Button-1> {set x %x; set y %y; set ::airspeed::data(autoRotate) 1}
    bind $c <Button-2> {console show}
    bind $c <Button-3> {incr ::airspeed::data(autoRotate)}

    bind $c <B1-Motion> { 
        set $::airspeed::data($::c,-variable) \
            [expr $$::airspeed::data($::c,-variable) + $x - %x] 
            
        set x %x
        set y %y
            
        $::c postredisplay
    }
}
