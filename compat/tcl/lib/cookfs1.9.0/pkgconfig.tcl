namespace eval cookfs {}

proc cookfs::pkgconfig {{command ""} {value ""} {newValue ""}} {
    variable pkgconfig
    variable pkgconfigInitialized

    if {![info exists pkgconfigInitialized]} {
	array set pkgconfig {
	    package-version	"1.9.0"

	    c-vfs		"1"
	    c-pages		"1"
	    c-fsindex		"1"
	    c-readerchannel	"1"
	    c-writerchannel	"1"
	    c-writer		"1"
	    c-crypto		"1"

	    tcl-commands	"1"
	    tcl-callbacks	"1"

	    feature-aside    "1"
	    feature-bzip2    "0"
	    feature-lzma     "1"
	    feature-zstd     "0"
	    feature-brotli   "0"
	    feature-metadata "1"
	    feature-crypto   "1"

	    platform         "unknown"
	}
	set pkgconfigInitialized 1
    }

    if {$command == "set"} {
	if {[info exists pkgconfig($value)]} {
	    set pkgconfig($value) $newValue
	    return $pkgconfig($value)
	}  elseif  {$value != ""} {
	    set an [lsort [array names pkgconfig]]
	    error "Unknown field \"$value\"; should be one of: [join [lrange $an 0 end-1] {, }] or [lindex $an end]."
	}
    }  elseif {$newValue == ""} {
	switch -- $command {
	    get {
		if {[info exists pkgconfig($value)]} {
		    return $pkgconfig($value)
		}  elseif  {$value != ""} {
		    set an [lsort [array names pkgconfig]]
		    error "Unknown field \"$value\"; should be one of: [join [lrange $an 0 end-1] {, }] or [lindex $an end]."
		}
	    }
	    list {
		if {$value == ""} {
		    return [lsort [array names pkgconfig]]
		}
	    }
	}
    }
    error "Usage: ::cookfs::pkgconfig list|get paramName"
}

package provide cookfs::tcl::pkgconfig 1.9.0

