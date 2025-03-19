# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

proc _InitCawtOffice { dir version } {
    package provide cawtoffice $version

    source [file join $dir officeConst.tcl]
    source [file join $dir officeBasic.tcl]
}
