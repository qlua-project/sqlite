	if {[catch {package require Tcl 9.0} o]} return
	set script ""
	if {![info exists ::env(TREECTRL_LIBRARY)]
	   && [file exists [file join $dir treectrl.tcl]]} {
	    append script "[list set ::treectrl_library $dir]\n"
	}
	append script [list load [file join $dir tcl9treectrl25.dll]]
	package ifneeded treectrl 2.5 $script
