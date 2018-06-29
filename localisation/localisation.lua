do
	local localisation = {}
	
	local parsestringparams = function( s )
		local r = {}
		s:gsub("(%w+)=([^,]+)",function( k , v ) r[k] = v end)
		return r
	end
	local function getlocalisation( L , language , text , params )
		-- Gets the localisation string associated with language and text, and substitute params into it.
		-- LocalisationHandler L
		-- string language
		-- string text
		-- optional table params = string->string
		-- return string = localisation string
		-- return false if not available
		local r = L.__localisations[language][text] -- if this line errors, the language isn't supported properly
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
			local s = getlocalisation( L , language , t , newparams )
			if s then return s
			else return "#" .. t .. "{" .. ap .. "}" end
		end ):gsub( "#([%w_]+)" , function( t )
			-- Parses additional localisation string
			-- string t
			-- return string
			local s = getlocalisation( L , language , t , params )
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
	localisation.getlocalisationstring2 = function( L , language , text , params )
		-- Same as lib.localisation.getlocalisation, but does not return false (only returns string values)
		return getlocalisation( L , language , text , params ) or ( "#" .. text )
	end
	localisation.tableimport = function( L , t )
		-- Directly imports a localisation table.
		-- LocalisationHandler L
		-- table t
		-- Caution: no error checking
		for lang , tt in pairs( t ) do
			if not L.__localisations[lang] then L.__localisations[lang] = {} end
			for text , str in pairs( tt ) do
				L.__localisations[lang][text] = str
			end
		end
	end
	localisation.addlocalisationstring = function( L , language , text , str )
		-- Adds a localisation string.
		-- LocalisationHandler L
		-- string language
		-- string text
		-- string str
		if not L.__localisations[language] then L.__localisations[language] = {} end
		L.__localisations[language][text] = str
	end
	localisation.new = function( c )
		-- Creates a new LocalisationHandler instance.
		-- lib.localisation c
		-- return LocalisationHandler
		return setmetatable( {__localisations={}} , c )
	end
	localisation.__index = localisation
	
	_G.localisation = localisation
end