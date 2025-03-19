package ifneeded Mtx 1.1 [list source [file join $dir Mtx.tcl]]
package ifneeded HSB 1.3 [list source [file join $dir HSB.tcl]]

package ifneeded BL::SVG 1.0.2 [list apply { dir {
	source [file join $dir t2dsvg.tcl]
	package provide BL::SVG 1.0.2
}} $dir] ;# end of lambda apply

package ifneeded BL::Filter 1.0.1 [list apply { dir {
	source [file join $dir t2d_filters.tcl]
	package provide BL::Filter 1.0.1
}} $dir] ;# end of lambda apply

package ifneeded tkBlend2d 1.3.1 [list apply { dir  {
	source [file join $dir t2d.tcl]
	load [BL::_findDLL $dir "tkBlend2d"] T2d
	package provide tkBlend2d 1.3.1
}} $dir] ;# end of lambda apply

package ifneeded tclBlend2d 1.3.1 [list apply { dir  {
	source [file join $dir t2d.tcl]
	load [BL::_findDLL $dir "tclBlend2d"] T2d
	package provide tclBlend2d 1.3.1
}} $dir] ;# end of lambda apply

# --- Alias
package ifneeded Blend2d 1.3.1 [list apply { dir  {
	set ver 1.3.1
	package require -exact tkBlend2d $ver
	package provide Blend2d $ver
}} $dir] ;# end of lambda apply
