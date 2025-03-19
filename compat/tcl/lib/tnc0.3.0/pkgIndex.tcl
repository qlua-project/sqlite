if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded tnc 0.3.0 [list load [file join $dir tcl9tnc030.dll]] 
} else { 
package ifneeded tnc 0.3.0 [list load [file join $dir tnc030.dll]] 
} 
