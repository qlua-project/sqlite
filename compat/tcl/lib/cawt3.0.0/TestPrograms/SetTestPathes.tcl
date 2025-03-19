# Set next line to true to use the tcl9-migrate runtime checker.
set useTcl9Migrate false

set cawtDir [file join [pwd] ".."]
set auto_path [linsert $auto_path 0 $cawtDir]

set haveTcl9Migrate $useTcl9Migrate
if { $useTcl9Migrate } {
    set retVal [catch {package require tcl9migrate} version]
    if { $retVal == 0 } {
        set retVal [catch { tcl9migrate::runtime::enable }]
        if { $retVal == 0 } {
            set haveTcl9Migrate true
        } else {
            set haveTcl9Migrate false
        }
    }
}
puts "Using Tcl9 Migration checker: $haveTcl9Migrate"
