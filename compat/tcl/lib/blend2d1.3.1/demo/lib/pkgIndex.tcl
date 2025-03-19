# just for Modules (*.tm)

# -- internal packages (under $dir/lib ) --
package ifneeded EbuttonColor 1.0.1 [list apply {
	{thisDir} {
		source [file join $thisDir EbuttonColor-1.0.1.tm]
		package provide EbuttonColor 1.0.1
	}} $dir ]

package ifneeded Eseparator 1.0 [list apply {
	{thisDir} {
		source [file join $thisDir Eseparator-1.0.tm]
		package provide Eseparator 1.0
	}} $dir ]
	
package ifneeded hatching 1.0 [list apply {
	{thisDir} {
		source [file join $thisDir hatching-1.0.tm]
		package provide hatching 1.0
	}} $dir ]
	
package ifneeded IKscale 1.0.1 [list apply {
	{thisDir} {
		source [file join $thisDir IKscale-1.0.1.tm]
		package provide IKscale 1.0.1
	}} $dir ]
	
package ifneeded sketchline 1.0 [list apply {
	{thisDir} {
		source [file join $thisDir sketchline-1.0.tm]
		package provide sketchline 1.0
	}} $dir ]

package ifneeded OOClassvar 1.0 [list apply {
	{thisDir} {
		source [file join $thisDir OOClassvar-1.0.tm]
		package provide OOClassvar 1.0
	}} $dir ]
	
package ifneeded HexCells 0.1 [list apply {
	{thisDir} {
		source [file join $thisDir HexCells-0.1.tm]
		package provide HexCells 0.1
	}} $dir ]

package ifneeded RandGen 0.1 [list apply {
	{thisDir} {
		source [file join $thisDir RandGen-0.1.tm]
		package provide RandGen 0.1
	}} $dir ]

	