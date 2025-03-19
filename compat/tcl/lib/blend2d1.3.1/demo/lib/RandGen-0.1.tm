# RandGen
#
# Utility for an easy an interactive control of the pseudo-random number generator (rand()).
#
#  - Inspired by contextfreeart.org
#

if 0 {
--- Overview ----
-----------------
When running simulations based on random-numbers generators, we often need to
repeat the simulation with exactly the same random behaviour.

Usually a simulation is started with a numerical *seed* initialized from the
internal clock, and this is the reason why each run produces different results.
But, we can force the initial seed to a given known value, so that each run
started with that seed will produce exactly the same results.

NOTE: we assume that the simulation is not driven by other kinds of'random'
      inputs, such as sys-time, mouse movements ...

With Tcl, in order to set a a fixed *seed*, we must just call  the "srand(_n_)"
function before the first call of "rand()"
  e.g.    expr {srand(1942271223456)}
but this numeric seed can be very long and difficult to remember.

For these reason, we can use this RandGen package, and use a short alphabetic *code*
that is automatically converted in a numeric seed for the "srand()" initialization function.
 e.g.    RandGen::SeedInit "HELLO"

This package provide just two commands:
   RandGen::SeedInit
   RandGen::widget  - a simple megawidget for interactively set the RandGen *code*
--------------------
--------------------
}

namespace eval RandGen {
	namespace export SeedInit NewCode IsValidCode NextCode PrevCode

	 # at least one [A-Z]
	proc IsValidCode {str} {
		regexp {^[A-Z]+$} $str
	}

	 # Initialize the srand() generator with a numeric-seed derived by the code string.
	 # If code is "" or it's not a valid code, then the srand() generator is initialized with a random code.
	 # Return the code.
	proc SeedInit {code} {
		if { ![IsValidCode $code] } {
			set code [NewCode]
		}
		set seed [_CodeToSeed $code]
		expr {srand($seed)}  ;# reinitialize pseudo-random generator
		return $code
	}

	proc NewCode {} {
		set x [expr {rand()}]
		 # consider x as a string; Don't take all digits (it will produce a long Variation-Code);
		 # Insted, take only the first 8 digits (after discard the leading "0.") ;
		 # this will produce a Variation-Code of 5 characters.
		set xStr [string range $x 2 8]
		 # remove leading "0"s , or it will be interpreted as a (sometimes wrong) octal number.
		set xStr [string trimleft $xStr "0"]
		# convert xStr to a seed-number:
		#  warning : DON'T use [expr {int($xStr)}],
		#  because if xStr is a large "number", result is a negative integer !
		set seed [expr {wide($xStr)}]
		return [_SeedToCode $seed]
	}

	  # if n>0, return a valid alphanumeric code
	  # else return ""
	proc _SeedToCode {n} {
	    set code ""
		set len 0
		set range 1
		while { $n >= $range } {
			incr len
			incr n -$range
			set range [expr {$range*26}]
		}
		while {$len > 0} {
			set v [expr {$n%26}]
			set n [expr {($n-$v)/26}]
			append code [format %c [expr {$v+65}]]   ;#  65 is for 'A'
			incr len -1
		}
		string reverse $code
	}

	 #  Return a numeric seed (>=1)
	 #  If str is not a valid code, return 0
	proc _CodeToSeed {str} {
	# no ..	set str [string trim $str]  ;#  trim 'white-spaces'
		if { ![IsValidCode $str] } { return 0 }

		set n 0
		set offset 0
		set range 1

		foreach ch [split $str ""] {
			incr offset $range

			set n [expr {$n*26}]
			incr n [expr {[scan $ch %c]-65}]

			set range [expr {$range*26}]
		}
		expr {$n+$offset}
	}

	 # if code is empty or invalid, return "A"
	 # else return .. the next code
	proc NextCode {code} {
		set n [_CodeToSeed $code]
		_SeedToCode [incr n]
	}

	  # if code is empty or invalid, return "A"
	  # else return .. the prev code  (NOTE: _prevCode "A"  is  "A")
	proc PrevCode {code} {
		set n [_CodeToSeed $code]
		set n [expr {max(1,$n-1)}]
		_SeedToCode $n
	}

}



if 0 {
 # ==== TEST ===============
 # =========================

 proc ASSERT {script -> expectedResult } {
	if { ${->} != "->" } {
        set thisProc [lindex [info level 0] 0]
		error "syntax error: should be \"$thisProc [info args $thisProc]\""
	}

	set res [uplevel 1 $script]
	if {$res != $expectedResult } {
		puts "ERROR: expectedResult is \"$expectedResult\" . Actual result is \"$res\""
	}
 }

 namespace import RandGen::*

 ASSERT { IsValidCode "" } -> 0
 ASSERT { IsValidCode "HELLO"} -> 1
 ASSERT { IsValidCode "Invalid Code"} -> 0

   #  not exported
  ASSERT { RandGen::_SeedToCode [RandGen::_CodeToSeed "HELLO"] } -> "HELLO"
  ASSERT { RandGen::_CodeToSeed [RandGen::_SeedToCode 975310] }  -> 975310

 ASSERT { NextCode ""} -> "A"
 ASSERT { NextCode "Invalid Code"} -> "A"
 ASSERT { NextCode "JAZZ" } -> "JBAA"

 ASSERT { PrevCode "Invalid Code"} -> "A"
 ASSERT { PrevCode ""} -> "A"
 ASSERT { PrevCode "A" } -> "A"
 ASSERT { PrevCode "AAA" } -> "ZZ"

 ASSERT { PrevCode [NextCode "JAZZ"] } -> "JAZZ"

 ASSERT { IsValidCode [SeedInit ""] } -> 1 ;#  a new random valid code
 ASSERT { IsValidCode [SeedInit "Invalid Code"] } -> 1 ;# a new random value
 ASSERT { SeedInit "HELLO" } -> "HELLO"

 # ============================================================================
}
  


if 0 {
---- DESCRIPTION -----------
----------------------------
RandGen::widget is an interactive widget for setting RandGen *codes*.
Codes can be generated by pressing the prev/next buttons or by typing A-Z
characters (and <Return>) in the entry sub-widget.
 Note: lower-case character are automatically converted to uppercase,
       since a valid *code* is made of only A..Z (uppercase) characters.
When a code changes, a virtual event <<Changed>> is generated, carrying the
new code in its user-data field "%d"

Be aware that this widget does only return a new code; it does not reinitialize
the rand() generator with a new seed.
It is caller's responsability to get the new code and pass it to
the function "Randgen::SeedInit"
-----------------------------
-----------------------------
}


package require snit

snit::widget RandGen::widget {
	hulltype ttk::frame
	delegate option * to hull  ;# allow the frame to be configured

	component label_comp
	delegate option -label to label_comp as -text

	variable lastNotifiedCode ""

	constructor {} {
		install label_comp using \
			ttk::label $win.label  -text "Variation Code "
		ttk::entry $win.e -width 10
		ttk::button $win.next -text "\u25ba" -width 1
		ttk::button $win.prev -text "\u25c4" -width 1
		
		pack $win.label $win.e $win.prev $win.next -side left
		
		$win.e configure \
			-validate key \
			-validatecommand [myproc _validateAndConvert %W %d %i %S]
		
		$win.next configure -command [mymethod _nextCode]
		$win.prev configure -command [mymethod _prevCode]
		
        bind $win.e <Key-Return> [mymethod _OnKeyReturn]
	}

	proc IsValid {str} { regexp -nocase {^[A-Z]+$} $str }

	method _OnKeyReturn {} {
		set code [$win get]
		if { $code == "" } { set code [NewCode] ; $win set $code }
		if { $code == $lastNotifiedCode } { set code [NextCode $code] ; $win set $code }
		$win _notifyChanges
	}

	method _notifyChanges {} {
		set lastNotifiedCode [$win get]
		event generate $win <<Changed>> -data $lastNotifiedCode
	}

	proc  _validateAndConvert {w op i newChars} {
		if { $op == 1 } { ;# insert
			set isValid [IsValid $newChars]
			if {$isValid} {
				$w insert $i [string toupper $newChars]			
			} else {
				bell
			}
		} else {
			set isValid 1
		}
		return $isValid
	}

	method _nextCode {} { $win set [NextCode [$win get]] ; $win _notifyChanges }
	method _prevCode {} { $win set [PrevCode [$win get]] ; $win _notifyChanges }

	 # method get always return a valid code or ""
	method get {} { $win.e get }

	 # lower-case letter are automatically converted to upper-case
	 # if str is not valid, then nothing changes
	method set {str} { 
		if { [IsValid $str] } {
			$win.e delete 0 end
			$win.e insert 0 $str
		}
	}

}

if 0 {
# === RandGen::widget test ========================

 # print 3 random numbers (truncated to 3 decimals)
proc printRandomSequence {} {
	for {set i 0} {$i<3} {incr i} {
		set x [expr {rand()}]
		append seq "[format " %.3f" $x]  "
	}
	puts "$seq ..."
}

pack [RandGen::widget .rg]
# extra, optional settings
.rg configure -label "Variation:"
.rg configure -borderwidth 4 -relief raised

.rg set "HELLO"

bind .rg <<Changed>> {
	puts "Got a new code \"%d\""
	RandGen::SeedInit %d
	printRandomSequence
}

# ===================================================
}

