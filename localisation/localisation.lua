do
	local localisation = {}
	
	local localisations = {}
	local parsestringparams = function( s )
		local r = {}
		s:gsub("(%w+)=([^,]+)",function( k , v ) r[k] = v end)
		return r
	end
	local function getlocalisation( language , text , params )
		-- Gets the localisation string associated with language and text, and substitute params into it.
		-- string language
		-- string text
		-- optional table params = string->string
		-- return string = localisation string
		-- return false if not available
		local r = localisations[language][text] -- if this line errors, the language isn't supported properly
		if not r then return false end
		return r:gsub( "#([%w_]+){(.-)}" , function( t , ap )
			-- Parses additional localisation string with additional parameters.
			-- string t
			-- string ap
			-- return string
			local newparams = {}
			for k , v in pairs( params ) do newparams[k] = v end
			for k , v in pairs(parsestringparams( ap )) do
				newparams[k] = v
			end
			local s = getlocalisation( language , t , newparams )
			if s then return s
			else return "#" .. t .. "{" .. ap .. "}" end
		end ):gsub( "#([%w_]+)" , function( t )
			-- Parses additional localisation string
			-- string t
			-- return string
			local s = getlocalisation( language , t , params )
			if s then return s
			else return "#" .. t end
		end ):gsub( "%%(%w+)" , function( p )
			-- Parses param inclusion
			-- string p
			-- return string
			return params[p] or ( "%" .. p )
		end )
	end
	
	localisation.getlocalisationstring = getlocalisation
	localisation.getlocalisationstring2 = function( language , text , params )
		-- Same as lib.localisation.getlocalisation, but does not return false (only returns string values)
		return getlocalisation( language , text , params ) or ( "#" .. text )
	end
	localisation.tableimport = function( t )
		-- Directly imports a localisation table.
		-- table t
		-- Caution: no error checking
		for lang , tt in pairs( t ) do
			if not localisations[lang] then localisations[lang] = {} end
			for text , str in pairs( tt ) do
				localisations[lang][text] = str
			end
		end
	end
	localisation.addlocalisationstring = function( language , text , str )
		-- Adds a localisation string.
		-- string language
		-- string text
		-- string str
		if not localisations[language] then localisations[language] = {} end
		localisations[language][text] = str
	end
	
	_G.localisation = localisation
end