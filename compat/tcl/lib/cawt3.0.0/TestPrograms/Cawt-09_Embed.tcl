# Test embedding procedures of the CawtCore package.
#
# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

if { [file exists "SetTestPathes.tcl"] } {
    source "SetTestPathes.tcl"
}

package require Tk
package require cawt

set twapiVersion [Cawt GetPkgVersion "twapi"]

set inFile [file join [pwd] "testIn" "MediaWikiTable.txt"]

proc Quit {} {
    Word Quit $::appId
    Cawt Destroy
    exit 0
}

# Create the Tk user interface. One frame is a container frame
# for embedding the Notepad application window.
wm title . "Cawt-09_Embed"
wm geometry . "1000x800"

set statFr [frame .statFr]
set infoFr [frame .infoFr]
set appFr  [frame .appFr -container true -borderwidth 0]
grid $statFr -row 0 -column 0 -sticky news -columnspan 2
grid $infoFr -row 1 -column 0 -sticky news
grid $appFr  -row 1 -column 1 -sticky news
grid rowconfigure    . 1 -weight 1
grid columnconfigure . 1 -weight 1

label $statFr.version -text "Embedding Word using Tcl [info patchlevel] and Twapi $twapiVersion"
pack $statFr.version -side top

label $infoFr.file
pack $infoFr.file -side top -anchor w
update

puts "Starting Word instance with file [file tail $inFile] ..."
set appId [Word OpenNew true]
set docId [Word OpenDocument $appId $inFile]

puts "Embedding Word ..."
Cawt SetEmbedTimeout 0.5

set catchVal [catch { Cawt EmbedApp $appFr -filename $inFile } retVal]
$infoFr.file configure -text "File: [file tail $inFile]"

Cawt PrintNumComObjects

bind . <Escape> "Quit"
wm protocol . WM_DELETE_WINDOW "Quit"

if { [lindex $argv 0] eq "auto" } {
    Word Quit $appId
    Cawt Destroy
    exit 0
}
