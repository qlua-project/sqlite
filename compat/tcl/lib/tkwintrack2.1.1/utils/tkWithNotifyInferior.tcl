#
#	Determines how the current Tk version handles binding scripts for
#	crossing events with detail field "NotifyInferior"
#
#	The path of this script file is passed as the first argument of a tclsh
#	command line. The second argument of that command line is the tk version
#	that needs to be loaded by this script. Sample invocation:
#
#	exec [info nameofexecutable] [file join $dir tkWithNotifyInferior.tcl] \
#			[package present Tk]
#
# Results: 0: Tk ignores the binding script
#          1: Tk invokes the binding script
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

set tkVersion [lindex $argv 0]
package require -exact Tk $tkVersion

# make root window as inconspicuous as possible.
wm withdraw .
wm overrideredirect . 1
. configure -bg {}
wm geometry . 1x1-100-400

# determine the result
set result 0
bind . <Leave> {set result 1}
wm deiconify .
tkwait visibility .
event generate . <Leave> -mode NotifyNormal -detail NotifyInferior

# return 
puts $result
exit

# EOF
