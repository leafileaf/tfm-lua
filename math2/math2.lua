math2 = {
	pythag = function( x1 , y1 , x2 , y2 )
		-- Finds the distance between two points, (x1,y1) and (x2,y2), using the Pythagorean theorem.
		-- May also call lib.math.pythag( x , y ) to find distance from origin.
		-- number x1
		-- number y1
		-- number x2 = 0
		-- number y2 = 0
		-- returns number = distance between (x1,y1) and (x2,y2)
		local x1 , y1 , x2 , y2 = x1 or 0 , y1 or 0 , x2 or 0 , y2 or 0
		local dx , dy = x1 - x2 , y1 - y2
		return math.sqrt( dx * dx + dy * dy )
	end,
	within = function( d , x1 , y1 , x2 , y2 )
		-- Checks if the distance between two points (x1,y1) and (x2,y2) is smaller than or equal to d.
		-- Faster than calling d <= math.lib.pythag( x1 , y1 , x2 , y2 ).
		-- May also call lib.math.within( d , x , y ) to check distance from origin.
		-- number d
		-- number x1
		-- number y1
		-- number x2 = 0
		-- number y2 = 0
		-- return boolean = is d <= math.lib.pythag( x1 , y1 , x2 , y2 )?
		local x1 , y1 , x2 , y2 = x1 or 0 , y1 or 0 , x2 or 0 , y2 or 0
		local dx , dy = x1 - x2 , y1 - y2
		return d * d <= dx * dy + dy * dy
	end,
	round = function( num )
		-- Rounds a number off to the nearest integer.
		-- Rounds up in event of tie.
		-- number num
		-- return n = rounded num
		return math.floor( num + 0.5 )
	end,
}