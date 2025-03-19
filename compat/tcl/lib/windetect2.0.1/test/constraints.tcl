#
# Test constraints for windetect gui-integration tests.
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

# Tcl/Tk bugs
testConstraint bug_Tcl_6235d23a76 \
		[expr {($tcl_platform(platform) ne "windows") || ! [isBugVersion tcl {} {}]}]
testConstraint bug_Tk_e3888d5820 [expr {! [isBugVersion tk {} [list 8.6.11 8.7a5]]}]
testConstraint bug_Tk_9e1312f32c \
		[expr {($tcl_platform(platform) ne "windows") || ! [isBugVersion tk {} [list 8.6.12 8.7a5]]}]
testConstraint bug_Tk_9e1312f32c_withDetectionDetails [testConstraint bug_Tk_9e1312f32c]
testConstraint bug_Tk_22349fc78a \
		[expr {($tcl_platform(platform) ne "windows") || ! [isBugVersion tk {} [list 9.0b3]]}]
testConstraint bug_Tk_22349fc78a_withDetectionDetails [testConstraint bug_Tk_22349fc78a]

# Window manager and toplevel windows related
testConstraint includeWmNotInvolved [expr {! $testconf(-wmonly)}]
testConstraint includeWmInvolved [expr {! $testconf(-nowm)}]
testConstraint wmPresent [expr {$Generic(wm) ne "none"}]
testConstraint failsWithWindowMaker [expr {$Generic(wm) ne "WindowMaker"}]

# Various uncategorized
setTestConstraintConditionally noPracticalUseCase 0
setTestConstraintConditionally wmIssueDetailFieldToplevelCrossing 0
testConstraint no_tkwintrack [expr {$Generic(pkgName) ne "tkwintrack"}]
testConstraint x11 [expr {[tk windowingsystem] eq "x11"}]
