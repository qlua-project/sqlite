# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

namespace eval Cawt {

    namespace ensemble create

    namespace export IsoDateToSeconds
    namespace export XmlDateToSeconds
    namespace export OutlookDateToSeconds
    namespace export OfficeDateToSeconds

    namespace export SecondsToIsoDate
    namespace export SecondsToXmlDate
    namespace export SecondsToOutlookDate
    namespace export SecondsToOfficeDate

    namespace export IsoDateToXmlDate
    namespace export XmlDateToIsoDate

    namespace export IsoDateToOutlookDate
    namespace export IsoDateToOfficeDate
    namespace export OutlookDateToIsoDate
    namespace export OfficeDateToIsoDate

    # Reference for calculating Office days into Tcl seconds and vice versa.
    #
    # Office days start at 1900-01-01.
    # Notes (see OfficeDateToSeconds and SecondsToOfficeDate):
    # 1. 1900-01-01 is day 1, not the number of days since 1900-01-01.
    # 2. According to Excel date 1900-02-29 exists. A bug in their code they refuse to fix.

    variable sOfficeDay

    set ::Cawt::sOfficeDate(Sec1900) [clock scan "1900-01-01 00:00:00" -format {%Y-%m-%d %H:%M:%S} -timezone :UTC]
    set ::Cawt::sOfficeDate(Day1900) [clock format $::Cawt::sOfficeDate(Sec1900) -format {%J}]

    proc IsoDateToSeconds { isoDate } {
        # Return ISO date string as seconds.
        #
        # isoDate - Date string in format `%Y-%m-%d %H:%M:%S`.
        #
        # Returns corresponding seconds as integer.
        #
        # See also: SecondsToIsoDate XmlDateToSeconds OfficeDateToSeconds

        return [clock scan $isoDate -format {%Y-%m-%d %H:%M:%S}]
    }

    proc XmlDateToSeconds { xmlDate } {
        # Return XML date string as seconds.
        #
        # xmlDate - Date string in format `%Y-%m-%dT%H:%M:%S.000Z`.
        #
        # Returns corresponding seconds as integer.
        #
        # See also: SecondsToXmlDate IsoDateToSeconds OfficeDateToSeconds

        return [clock scan $xmlDate -format {%Y-%m-%dT%H:%M:%S.000Z}]
    }

    proc OutlookDateToSeconds { outlookDate } {
        # Obsolete: Replaced with [OfficeDateToSeconds] in version 2.4.4
        #
        # outlookDate - Floating point number representing days since `1900/01/01`.
        #
        # Returns corresponding seconds as integer.
        #
        # See also: SecondsToOutlookDate IsoDateToSeconds XmlDateToSeconds

        return [Cawt::OfficeDateToSeconds $outlookDate]
    }

    proc OfficeDateToSeconds { officeDate } {
        # Return Office date as seconds.
        #
        # officeDate - Floating point number representing days since `1900/01/01`.
        #
        # $officeDate must be in the range from 1.0 to 9999.0.
        #
        # Returns corresponding seconds as integer.
        #
        # See also: SecondsToOfficeDate OfficeDateToIsoDate IsoDateToSeconds XmlDateToSeconds

        variable sOfficeDate

        set julDay  [expr { int ($officeDate) }]
        set julRest [expr { $officeDate - $julDay }]

        set julDay1900 [expr { $sOfficeDate(Day1900) + $julDay - 1 }]
        if { $julDay > 60 } {
            incr julDay1900 -1
        }
        set julSec1900 [clock scan $julDay1900 -format {%J}]

        # 86400 = 60 * 60 * 24
        return [expr { $julSec1900 + round ($julRest * 86400.0) }]
    }

    proc SecondsToIsoDate { sec } {
        # Return date in seconds as ISO date string.
        #
        # sec - Date in seconds as returned by `clock seconds`.
        #
        # Returns corresponding date as ISO date string.
        #
        # See also: IsoDateToSeconds SecondsToXmlDate SecondsToOfficeDate

        return [clock format $sec -format {%Y-%m-%d %H:%M:%S}]
    }

    proc SecondsToXmlDate { sec } {
        # Return date in seconds as XML date string.
        #
        # sec - Date in seconds as returned by `clock seconds`.
        #
        # Returns corresponding date as XML date string.
        #
        # See also: XmlDateToSeconds SecondsToIsoDate SecondsToOfficeDate

        return [clock format $sec -format {%Y-%m-%dT%H:%M:%S.000Z}]
    }

    proc SecondsToOutlookDate { sec } {
        # Obsolete: Replaced with [SecondsToOfficeDate] in version 2.4.4
        #
        # sec - Date in seconds as returned by `clock seconds`.
        #
        # Returns corresponding date as floating point number
        # representing days since `1900/01/01`.
        #
        # See also: OutlookDateToSeconds SecondsToIsoDate SecondsToXmlDate

        return [Cawt::SecondsToOfficeDate $sec]
    }

    proc SecondsToOfficeDate { sec } {
        # Return date in seconds as Office date.
        #
        # sec - Date in seconds as returned by `clock seconds`.
        #
        # Returns corresponding date as floating point number
        # representing days since `1900/01/01`.
        #
        # See also: OfficeDateToSeconds IsoDateToOfficeDate SecondsToIsoDate SecondsToXmlDate

        variable sOfficeDate

        set julDay [clock format $sec -format {%J}]

        set day [expr { $julDay - $sOfficeDate(Day1900) + 1 }]
        if { $day > 60 } {
            incr day
        }

        set julSec [clock scan $julDay -format {%J}]
        # 86400 = 60 * 60 * 24
        set julRest [expr { ($sec - $julSec) / 86400.0 }]
        return [expr { $day + $julRest }]
    }

    proc XmlDateToIsoDate { xmlDate } {
        # Return XML date string as ISO date string.
        #
        # xmlDate - Date string in format `%Y-%m-%dT%H:%M:%S.000Z`.
        #
        # Returns corresponding date as ISO date string.
        #
        # See also: IsoDateToXmlDate XmlDateToSeconds

        return [Cawt::SecondsToIsoDate [XmlDateToSeconds $xmlDate]]
    }

    proc OutlookDateToIsoDate { outlookDate } {
        # Obsolete: Replaced with [OfficeDateToIsoDate] in version 2.4.4
        #
        # outlookDate - Floating point number representing days since `1900/01/01`.
        #
        # Returns corresponding date as ISO date string.
        #
        # See also: IsoDateToOutlookDate OutlookDateToSeconds

        return [Cawt::SecondsToIsoDate [Cawt::OfficeDateToSeconds $outlookDate]]
    }

    proc OfficeDateToIsoDate { officeDate } {
        # Return Office date as ISO date string.
        #
        # officeDate - Floating point number representing days since `1900/01/01`.
        #
        # Returns corresponding date as ISO date string.
        #
        # See also: IsoDateToOfficeDate OfficeDateToSeconds

        return [Cawt::SecondsToIsoDate [Cawt::OfficeDateToSeconds $officeDate]]
    }

    proc IsoDateToXmlDate { isoDate } {
        # Return ISO date string as XML date string.
        #
        # isoDate - Date string in format `%Y-%m-%d %H:%M:%S`.
        #
        # Returns corresponding date as XML date string.
        #
        # See also: XmlDateToIsoDate IsoDateToSeconds IsoDateToOfficeDate

        return [Cawt::SecondsToXmlDate [Cawt::IsoDateToSeconds $isoDate]]
    }

    proc IsoDateToOutlookDate { isoDate } {
        # Obsolete: Replaced with [IsoDateToOfficeDate] in version 2.4.4
        #
        # isoDate - Date string in format `%Y-%m-%d %H:%M:%S`.
        #
        # Returns corresponding date as floating point number
        # representing days since `1900/01/01`.
        #
        # See also: OutlookDateToIsoDate IsoDateToSeconds IsoDateToXmlDate

        return [Cawt::SecondsToOfficeDate [Cawt::IsoDateToSeconds $isoDate]]
    }

    proc IsoDateToOfficeDate { isoDate } {
        # Return ISO date string as Office date.
        #
        # isoDate - Date string in format `%Y-%m-%d %H:%M:%S`.
        #
        # Returns corresponding date as floating point number
        # representing days since 1900/01/01.
        #
        # See also: OfficeDateToIsoDate IsoDateToSeconds IsoDateToXmlDate

        return [Cawt::SecondsToOfficeDate [Cawt::IsoDateToSeconds $isoDate]]
    }
}
