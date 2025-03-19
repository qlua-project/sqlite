if { [package vsatisfies [package provide Tcl] 9.0-] } {
    package ifneeded cookfs::c 1.9.0 \
        [list load [file join $dir tcl9cookfs190.dll] [string totitle cookfs]]
} else {
    package ifneeded cookfs::c 1.9.0 \
        [list load [file join $dir cookfs190.dll] [string totitle cookfs]]
}

package ifneeded cookfs::tcl::pkgconfig 1.9.0 [list source [file join $dir pkgconfig.tcl]]
package ifneeded cookfs::tcl::writerchannel 1.9.0 [list source [file join $dir writerchannel.tcl]]
package ifneeded cookfs::tcl::vfs 1.9.0 [list source [file join $dir vfs.tcl]]
package ifneeded cookfs::tcl::readerchannel 1.9.0 [list source [file join $dir readerchannel.tcl]]
package ifneeded cookfs::tcl::writer 1.9.0 [list source [file join $dir writer.tcl]]
package ifneeded cookfs::tcl::pages 1.9.0 [list source [file join $dir pages.tcl]]
package ifneeded cookfs::tcl::fsindex 1.9.0 [list source [file join $dir fsindex.tcl]]
package ifneeded cookfs::asyncworker::process 1.9.0 [list source [file join $dir asyncworker_process.tcl]]
package ifneeded cookfs::asyncworker::thread 1.9.0 [list source [file join $dir asyncworker_thread.tcl]]

package ifneeded cookfs 1.9.0 [list ::apply {{ dir } {
    # As for now, always load C module
    package require cookfs::c 1.9.0
    if { ![llength [info commands cookfs::pkgconfig]] } {
        package require cookfs::tcl::pkgconfig 1.9.0
    }
    if { ![cookfs::pkgconfig get c-pages] } {
        package require cookfs::tcl::pages 1.9.0
    }
    if { ![cookfs::pkgconfig get c-fsindex] } {
        package require cookfs::tcl::fsindex 1.9.0
    }
    if { ![cookfs::pkgconfig get c-vfs] } {
        package require cookfs::tcl::vfs 1.9.0
    }
    if { ![cookfs::pkgconfig get c-writer] } {
        package require cookfs::tcl::writer 1.9.0
    }
}} $dir]

package ifneeded vfs::cookfs 1.9.0 [list ::apply {{ dir } {
    package require cookfs 1.9.0
    package provide vfs::cookfs 1.9.0
}} $dir]
