# Test CawtPpt procedures for handling PowerPoint comments.
#
# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

if { [file exists "SetTestPathes.tcl"] } {
    source "SetTestPathes.tcl"
}
package require cawt

set appId [Ppt Open]

set inFile [file join [pwd] ".." "Documentation" "UserManual" "CawtFigures.ppt"]

# Delete export files from previous test run.
file mkdir testOut
set pptFile [file join [pwd] "testOut" "Ppt-08_Comments"]
append pptFile [Ppt GetExtString $appId]
file delete -force $pptFile

set presId [Ppt OpenPres $appId $inFile]

set numSlides [Ppt GetNumSlides $presId]
for { set slideNum 1 } { $slideNum <= $numSlides } { incr slideNum } {
    set slideId [Ppt GetSlideId $presId $slideNum]
    puts "Comments of slide $slideNum: "
    foreach comment [Ppt GetComments $slideId] {
        set key [Ppt GetCommentKeyValue $slideId "Export"]
        Cawt CheckString $key [string trim [lindex [split $comment ":"] 1]] "Comment key"
    }
    set pos [Ppt GetCommentKeyPosition $slideId "Export"]
    Cawt CheckNumber [lindex $pos 0] [Ppt GetCommentKeyTopPosition  $slideId "Export"] "Position Top"
    Cawt CheckNumber [lindex $pos 1] [Ppt GetCommentKeyLeftPosition $slideId "Export"] "Position Left"
    Cawt Destroy $slideId
}

puts "Saving as PowerPoint file: $pptFile"
Ppt SaveAs $presId $pptFile

Cawt PrintNumComObjects

if { [lindex $argv 0] eq "auto" } {
    Ppt Quit $appId
    Cawt Destroy
    exit 0
}
Cawt Destroy
