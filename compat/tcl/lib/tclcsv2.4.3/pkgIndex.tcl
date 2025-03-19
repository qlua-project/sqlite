#
# Tcl package index file
#
package ifneeded tclcsv 2.4.3 \
[list apply [list {dir} {
        package require platform
        set package_ns ::tclcsv
        set initName [string totitle tclcsv]
        if {[package vsatisfies [package require Tcl] 9]} {
            set fileName "tcl9tclcsv243.dll"
        } else {
            set fileName "tclcsv243.dll"
        }
        set platformId [platform::identify]
        set searchPaths [list [file join $dir $platformId] \
                             {*}[lmap platformId [platform::patterns $platformId] {
                                 file join $dir $platformId
                             }] \
                             $dir]
        foreach path $searchPaths {
            set lib [file join $path $fileName]
            if {[file exists $lib]} {
                uplevel #0 [list load $lib $initName]
                # Load was successful
                set ${package_ns}::dll_path $lib
                set ${package_ns}::package_dir $dir
                uplevel #0 [list source [file join $dir csv.tcl]]
                return
            }
        }
        error "Could not locate $fileName in directories [join $searchPaths {, }]"
}] $dir]
