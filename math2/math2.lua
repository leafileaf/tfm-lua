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
	rotatePoint = function( x1 , y1 , a , x2 , y2 )
		-- Rotates a point (x2,y2) by a radians relative to point (x1,y1).
		-- number x1
		-- number y1
		-- number r
		-- number x2
		-- number y2
		-- return x , y = coordinates of point after rotation
		local dx , dy = x1 - x2 , y1 - y2
		local dist = math.sqrt( dx * dx + dy * dy )
		local ang = math.atan2( dy , dx ) + a
		return x1 + math.cos(ang) * dist , y1 + math.sin(ang) * dist
	end,
	withinCircle = function( x1 , y1 , r , x2 , y2 )
		-- Checks if a point (x2,y2) is inside the circle defined by centre (x1,y1) and radius r.
		-- Faster than calling r <= math2.pythag( x1 , y1 , x2 , y2 ).
		-- May also call math2.withinCircle( x1 , y1 , r ) to check if the circle includes the origin.
		-- number x1
		-- number y1
		-- number r
		-- number x2 = 0
		-- number y2 = 0
		-- return boolean = is point inside circle?
		local x1 , y1 , x2 , y2 = x1 or 0 , y1 or 0 , x2 or 0 , y2 or 0
		local dx , dy = x1 - x2 , y1 - y2
		return d * d <= dx * dy + dy * dy
	end,
	withinRect = function( x1 , y1 , w , h , a , x2 , y2 )
		-- Checks if a point (x2,y2) is inside the rectangle defined by centre (x1,y1), width w, height h, and rotation a.
		-- number x1
		-- number y1
		-- number w
		-- number h
		-- number a
		-- number x2
		-- number y2
		-- return boolean = is point inside rectangle?
		if a == 0 then
			-- use normal AABB checking
			if x1 - w/2 < x2 and x2 < x1 + w/2 and y1 - h/2 < y2 and y2 < y1 + h/2 then
				return true
			else
				return false
			end
		else
			-- rotate the whole damn rectangle
			local dx , dy = x1 - x2 , y1 - y2
			local dist = math.sqrt( dx * dx + dy * dy )
			local ang = math.atan2( dy , dx ) - a
			local nx , ny = x1 + math.cos(ang) * dist , x2 + math.sin(ang) * dist
			-- then normal AABB check
			if x1 - w/2 < nx and nx < x1 + w/2 and y1 - h/2 < ny and ny < y1 + h/2 then
				return true
			else
				return false
			end
		end
	end,
	round = function( num )
		-- Rounds a number off to the nearest integer.
		-- Rounds up in event of tie.
		-- number num
		-- return n = rounded num
		num = num + 0.5
		return num-(num%1)
	end,
}