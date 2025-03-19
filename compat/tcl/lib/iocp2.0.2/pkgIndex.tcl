# Core iocp package
package ifneeded iocp 2.0.2 \
    [list apply [list {dir} {
        package require platform
        set initName [string totitle iocp]
        if {[package vsatisfies [package require Tcl] 9]} {
            set fileName "tcl9iocp202.dll"
        } else {
            set fileName "iocp202.dll"
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
                return
            }
        }
        error "Could not locate $fileName in directories [join $searchPaths {, }]"
    }] $dir]

# iocp_inet doesn't need anything other than core iocp
package ifneeded iocp_inet 2.0.2 \
    "package require iocp"

if {1} {
    # iocp_bt needs supporting script files
    package ifneeded iocp_bt 2.0.2 \
        "[list source [file join $dir bt.tcl]]"
}

