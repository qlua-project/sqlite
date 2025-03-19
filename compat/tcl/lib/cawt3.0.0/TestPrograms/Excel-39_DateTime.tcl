# Test CawtExcel procedures related to dates and times.
#
# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

if { [file exists "SetTestPathes.tcl"] } {
    source "SetTestPathes.tcl"
}
package require cawt

set inPath  [file join [pwd] "testIn"]
set outPath [file join [pwd] "testOut"]

# Test file with date cells.
set xlsInFile [file join $inPath "DateTime.xlsx"]

# Open new Excel instance, open the workbook and select first worksheet.
set appId [Excel OpenNew]
set workbookId [Excel OpenWorkbook $appId $xlsInFile -readonly true]
set worksheetId [Excel GetWorksheetIdByIndex $workbookId 1]

# Get the worksheet data cell by cell and display the date and time
# in the format as stored in Excel (DateValue, TimeValue), as displayed
# by Excel (DateString, TimeString) as well as the cell formats.
puts [format "%-10s | %-10s | %-12s | %-9s | %-12s | %-22s" \
     "DateValue" "DateString" "DateFormat" "TimeValue" "TimeString" "TimeFormat"]
for { set row 2 } { $row <= [Excel GetNumUsedRows $worksheetId] } { incr row } {
    set dateVal [Excel GetCellValue $worksheetId $row 1 ]
    set timeVal [Excel GetCellValue $worksheetId $row 2 ]
    set dateStr [Excel GetCellValue $worksheetId $row 1 "display"]
    set timeStr [Excel GetCellValue $worksheetId $row 2 "display"]
    set dateRange [Excel SelectCellByIndex $worksheetId $row 1]
    set timeRange [Excel SelectCellByIndex $worksheetId $row 2]
    set dateFormat [Excel GetRangeFormat $dateRange]
    set timeFormat [Excel GetRangeFormat $timeRange]
    puts [format "%10.1f | %10s | %12s | %9.5f | %12s | %-22s" \
         $dateVal $dateStr $dateFormat $timeVal $timeStr $timeFormat]

    set dateTimeStr "$dateStr $timeStr"
    Cawt CheckString $dateTimeStr [Cawt OfficeDateToIsoDate [expr $dateVal + $timeVal]] "OfficeDate" false
}

# Faster alternative to get the displayed values:
# Copy the cell range into the clipboard, get the clipboard data
# in CSV format using the Twapi extension and convert the CSV data 
# into a Tcl matrix (list of lists).
# Note: The CSV data has to be copied from the clipboard before Excel is 
# closed. Otherwise the data is not available in CSV format anymore.

Excel ShowAlerts $appId false

set cellId [Excel SelectRangeByIndex $worksheetId 2 1 [Excel GetNumUsedRows $worksheetId] 2]
$cellId Copy

set matrix [Excel ClipboardToMatrix -timeout 0.5]
if { [llength $matrix] == 0 } {
    puts "Error: Clipboard does not contain CSV data."
} else {
    puts ""
    puts [format "%-10s | %-12s" "DateString" "TimeString"]
    foreach row $matrix {
        lassign $row dateStr timeStr
        puts [format "%-10s | %-12s" $dateStr $timeStr]
    }
    puts ""
}

# Create large worksheet to test performance.
set worksheetId2 [Excel AddWorksheet $workbookId "LargeMatrix"]
set numRows 1000
for { set row 1 } { $row <= $numRows } { incr row } {
    lappend rangeList [list "Row-${row}_Col-1" "Row-${row}_Col-2"]
}
Excel SetMatrixValues $worksheetId2 $rangeList 1 1

set cellId [Excel SelectRangeByIndex $worksheetId2 1 1 [Excel GetNumUsedRows $worksheetId2] 2]
$cellId Copy

set matrix [Excel ClipboardToMatrix -timeout 2]
if { [llength $matrix] == 0 } {
    puts "Error: Clipboard does not contain CSV data."
} else {
    Cawt CheckMatrix $rangeList $matrix "Large matrix"
}

Cawt PrintNumComObjects

if { [lindex $argv 0] eq "auto" } {
    Excel Quit $appId false
    Cawt Destroy
    exit 0
}
Cawt Destroy
