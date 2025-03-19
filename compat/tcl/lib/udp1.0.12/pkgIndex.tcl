# -*- tcl -*-
# Tcl package index file, version 1.1
#
if {[package vsatisfies [package provide Tcl] 9.0-]} {
    package ifneeded udp 1.0.12 [list apply {{dir} {
	# Load library
	load [file join $dir tcl9udp1012.dll] [string totitle udp]

	# Source init file
	set initScript [file join $dir udp.tcl]
	if {[file exists $initScript]} {
	    source -encoding utf-8 $initScript
	}
    }} $dir]
} else {
    if {![package vsatisfies [package provide Tcl] 8.5]} {return}
    package ifneeded udp 1.0.12 [list apply {{dir} {
	# Load library
	if {[string tolower [file extension udp1012.dll]] in [list .dll .dylib .so]} {
	    # Load dynamic library
	    load [file join $dir udp1012.dll] [string totitle udp]
	} else {
	    # Static library
	    load {} [string totitle udp]
	}

	# Source init file
	set initScript [file join $dir udp.tcl]
	if {[file exists $initScript]} {
	    source -encoding utf-8 $initScript
	}
    }} $dir]
}
