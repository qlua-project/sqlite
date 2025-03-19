if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded parser 1.9 [list load [file join $dir tcl9tclparser19.dll]] 
} else { 
package ifneeded parser 1.9 [list load [file join $dir tclparser19.dll]] 
} 
