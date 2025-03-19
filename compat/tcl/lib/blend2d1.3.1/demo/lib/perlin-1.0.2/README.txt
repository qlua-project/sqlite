Perlin

Usage:
	package require perlin
	set x 23.2323
	set y -12.231313
	set z 0.234234
	set v [perlin $x $y $z]
	
	# result is a floating number between -1 and +1
	
NOTE:
  if x,y,z are integers, result is 0.0