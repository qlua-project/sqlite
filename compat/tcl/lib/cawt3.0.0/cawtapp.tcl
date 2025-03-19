# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

if { $argc == 0 } {
    package require Tk
    console show
} else {
    # If other command line parameters are supplied, assume the first
    # is the name of a Tcl script, which will be sourced.
    # Decrement the command argument counter and remove the sourced file
    # name from the command line parameter list.
    set i 0
    set tclScript [file normalize [lindex $argv $i]]
    incr argc -1
    set argv [lrange $argv [expr $i+1] end]
    set argv0 [file dirname [vfs::filesystem fullynormalize $argv0]]
    console show
    source $tclScript
}
