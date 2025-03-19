#
# This script performs various actions that prepare for the windetect
# gui-integration testing proper.
# Also used by any tkwintrack package installed alongside windetect.
#

#
# Copyright 2020 Erik Leunissen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# load test utilities
source [file join $Dir(test) windetect-test_utils.tcl]

#
# SET GENERIC TEST PROPERTIES
#
getPackageInfo $Dir(install) Generic(pkgName) Generic(pkgVersion)
set Generic(testType) gui

#
# ARGUMENT HANDLING
#
process_cmdline_args gui


#
# LOAD TEST HARNESS, TK AND ACCESSORY PACKAGES
#
package require tcltest 2.2
namespace import -force ::tcltest::*

if {! [info exists ::env(TCLTEST_MASTER_SCRIPT)]} {
	tcltest::configure -verbose {body pass error}
} elseif {$::env(TCLTEST_MASTER_SCRIPT) eq "WINDETECT_WS_PERFORMANCE"} {
	tcltest::configure -verbose {error pass}
}
if {[array size tcltestconf] > 0} {
	# pass command line arguments to tcltest
	eval tcltest::configure [array get tcltestconf]
}
unset tcltestconf

# load Tk, with the root window withdrawn
package require -exact Tk $tcl_patchLevel
wm withdraw .

# load accessory utilities
source [file join $Dir(install) utils osshell.tcl]
source [file join $Dir(install) utils gn.tcl]
namespace import gn::*


#
# INITIALIZATION OF TEST UTILITIES
#

if {$testconf(-eyefriendly)} {
	foreach proc {controlPointerWarpTiming waitForReporting} {
		trace add execution $proc leave [list pause 1000]
	}
	unset proc
}

# Determine the windowing system and desktop environment
foreach component {wm de} {
	if {[catch {osshell::info $component name} result]} {
		puts "warning: $result"
		set Generic($component) unknown
	} else {
		set Generic($component) $result
	}
}

if {$testconf(-extrawindowevents)} {
	if {! ($testconf(-detectiondetails) || $testconf(-checkclean))} {
		puts stderr "error: option -extrawindowevents isn't useful without option -detectiondetails."
		exit 1
	}
	notifyExtraWindowEvents
}

if {$testconf(-timing)} {
	dt.reset
	regexp -- {^[.0-9]+} [time {dt.get} 1000] dt
	lappend initMsgs "\t* Each timing call consumes an extra $dt microseconds on average\n"
	unset dt
}

if {$testconf(-checkclean)} {
	set testconf(-detectiondetails) 1
	if {! $testconf(-extrawindowevents)} {
		notifyExtraWindowEvents
	}
	checkTestsClean
}

if {$::Generic(pkgName) eq "tkwintrack"} {
	set publicOptions [list -checkclean -eyefriendly -nowm]
}


#
# INTRODUCTORY OUTPUT
#
if {! $testconf(-skipintro)} {
	puts "\n[set starline [string repeat * 46]]\n* [string totitle $Generic(pkgName)] $Generic(pkgVersion) [expr {$Generic(pkgName) eq "windetect"?" gui-integration tests":""}]\n*\n* DO NOT HANDLE THE MOUSE DURING THESE TESTS\n$starline\n"
	unset starline
	flush stdout
	after 2000

	# Output relevant system properties for issue reporting
	array set platform [array get tcl_platform]
	unset -nocomplain platform(user) platform(byteOrder) platform(machine) platform(pathSeparator) platform(pointerSize) platform(wordSize)
	puts "Test environment\n----------------"
	puts "executable          = [file tail [info nameofexecutable]]"
	puts "tk patch level      = $tk_patchLevel"
	puts "withNotifyInferior  = [tkWithNotifyInferior]"
	parray platform
	puts "windowing system    = [tk windowingsystem]"
	puts "window manager      = $Generic(wm)"
	puts "desktop environment = $Generic(de)"
	puts ""
	puts "Test configuration\n------------------"
	foreach key [lsort [array names testconf]] {
		if {($Generic(pkgName) eq "tkwintrack") && ($key ni $publicOptions)} {
			continue
		}
		set spaces [string repeat " " [expr {18 - [string length $key]}]]
		puts "testconf($key)$spaces = $testconf($key)"
	}
	unset platform spaces
}
if {! $testconf(-nowm) && ($Generic(wm) ne "none")} {
	if {[osshell::info wm tiling]} {
		puts stderr "Multiple tests in this package require toplevel windows to overlap. However, the current window manager opposes that (it seems to be a tiling window manager). Aborting test script execution.\nYou may retry, supplying the option -nowm to skip the pertaining tests."
		exit 1
	}
}
no_leak_drawing_events ws .

if {[info exists initMsgs]} {
	foreach msg $initMsgs {
		puts \n$msg
	}
	unset msg initMsgs
}
puts ""

# EOF
