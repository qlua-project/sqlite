# Copyright: 2007-2024 Paul Obermeier (obermeier@poSoft.de)
# Distributed under BSD license.

namespace eval Cawt {

    namespace ensemble create

    namespace export ClearClipboard
    namespace export SetClipboardWaitTime
    namespace export WaitClipboardReady

    variable sWaitTime 200

    proc ClearClipboard {} {
        twapi::open_clipboard
        twapi::empty_clipboard
        twapi::close_clipboard
    }

    proc SetClipboardWaitTime { waitTime } {
        # Set the time to wait until clipboard content is ready.
        #
        # waitTime - Wait time in milliseconds.
        #
        # Returns no value.
        #
        # See also: WaitClipboardReady

        variable sWaitTime

        set sWaitTime [expr int($waitTime)]
    }

    proc WaitClipboardReady {} {
        # Wait until clipboard content is ready.
        #
        # **Note:**
        # Currently this is simply implemented by waiting a specified amount
        # of milliseconds, which can be specified by [SetClipboardWaitTime].
        # Default value is 200 milliseconds.
        #
        # Returns no value.
        #
        # See also: SetClipboardWaitTime

        variable sWaitTime

        after $sWaitTime
    }
}
