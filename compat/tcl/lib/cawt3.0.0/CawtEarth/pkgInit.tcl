# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

proc _InitCawtEarth { dir version } {
    package provide cawtearth $version

    source [file join $dir earthBasic.tcl]
}
