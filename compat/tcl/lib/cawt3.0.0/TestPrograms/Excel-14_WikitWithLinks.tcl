# Test CawtExcel procedures to export an Excel workbook as Wikit tables with hyperlinks.
#
# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

if { [file exists "SetTestPathes.tcl"] } {
    source "SetTestPathes.tcl"
}
package require cawt

set excelFile [file join "testIn"  "SampleWikitTable.xlsx"]
set wikiFile  [file join "testOut" "SampleWikitTable.txt"]

# Create testOut directory, if it does not yet exist.
file mkdir testOut

proc ConvertValue { value address } {
    set tmp [string map {\n\r "<<br>>"} $value]
    set tmp [string map {"|" "<<pipe>>"} $tmp]
    if { $address ne "" } {
        return [format "%s%%|%%%s%%|%%" $address $tmp]
    }
    return $tmp
}

proc ExcelFileToWikitFile { excelFile wikiFileName { useHeader true } } {
    set appId [Excel OpenNew true]
    set workbookId [Excel OpenWorkbook $appId $excelFile -readonly true]
    set numSheets [Excel GetNumWorksheets $workbookId]

    set catchVal [catch {open $wikiFileName w} fp]
    if { $catchVal != 0 } {
        error "Could not open file \"$wikiFileName\" for writing."
    }

    for { set s 1 } { $s <= $numSheets } { incr s } {
        set worksheetId [Excel GetWorksheetIdByIndex $workbookId [expr int($s)]]
        set worksheetName [Excel GetWorksheetName $worksheetId]

        set numRows [Excel GetLastUsedRow $worksheetId]
        set numCols [Excel GetLastUsedColumn $worksheetId]
        puts "Exporting $numRows rows and $numCols columns from sheet $worksheetName"
        set startRow 1
        puts $fp "\n***$worksheetName***\n"
        if { $useHeader } {
            set headerList [Excel GetMatrixValues $worksheetId $startRow 1 $startRow $numCols]
            set worksheetName [Excel GetWorksheetName $worksheetId]
            Excel::_WriteWikitHeader $fp [lindex $headerList 0] $worksheetName
            incr startRow
        }
        for { set row $startRow } { $row <= $numRows } { incr row } {
            puts -nonewline $fp "&|"
            for { set col 1 } { $col <= $numCols } { incr col } {
                set value [Excel GetCellValue $worksheetId $row $col]
                set range [Excel SelectCellByIndex $worksheetId $row $col]
                set address ""
                set hyperlinks [$range Hyperlinks]
                if { [$hyperlinks Count] >= 1 } {
                    set hyperlink [$hyperlinks Item [expr int(1)]]
                    set address [$hyperlink Address]
                    Cawt Destroy $hyperlink
                }
                Cawt Destroy $hyperlinks
                Cawt Destroy $range
                set wikiValue [ConvertValue $value $address]
                puts -nonewline $fp $wikiValue
                if { $col < $numCols } {
                    puts -nonewline $fp "|"
                }
            }
            puts $fp "|&"
        }
        puts $fp "\n----"
    }
    close $fp
    Excel Quit $appId
}

ExcelFileToWikitFile $excelFile $wikiFile true

Cawt PrintNumComObjects

if { [lindex $argv 0] eq "auto" } {
    Cawt Destroy
    exit 0
}
Cawt Destroy
