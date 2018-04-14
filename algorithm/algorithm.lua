algorithm = {
	shuffle = function( t1 , inplace , t2 )
		-- Runs the Fisher-Yates shuffle on t1.
		-- If inplace is true, shuffles t1 directly.
		-- Otherwise, places shuffled result in t2.
		-- table t1
		-- boolean inplace = true
		-- table t2 = {}
		-- return table = the shuffled table
		-- * will modify either t1 or t2
		local t = t1
		if not inplace then
			t = t2 or {}
			for i = 1 , #t1 do t[i] = t1[i] end -- copy to t2
		end
		for i = 1 , #t do
			local j = math.random( i , #t ) -- select shuffle target
			t[i] , t[j] = t[j] , t[i] -- swap positions
		end
		return t
	end,
}