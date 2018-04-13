-- events
-- event-handling system
-- by Leafileaf

do
	local events = {}
	
	local registered = setmetatable( {} , {__mode = "k"} ) -- registered[obj][event][#]
	
	local coe = function( obj , e )
		if not registered[obj] then
			registered[obj] = {}
		end
		if e and not registered[obj][e] then
			registered[obj][e] = { __n = 0 , __i = 0 , __On = 0 , __Oi = 0 , __R = {} , __O = {} }
			-- number of handlers, current primary key, ditto once, ditto once, recurrent handlers, once handlers
		end
	end
	
	events.on = function( obj , e , cb )
		coe( obj , e )
		local l = registered[obj][e]
		l.__n , l.__i = l.__n + 1 , l.__i + 1
		l.__R[l.__i] = cb
		return l.__i
	end
	
	events.once = function( obj , e , cb )
		coe( obj , e )
		local l = registered[obj][e]
		l.__On , l.__Oi = l.__On + 1 , l.__Oi + 1
		l.__O[l.__Oi] = cb
		return l.__Oi
	end
	
	events.removelistener = function( obj , e , id )
		coe( obj , e )
		local l = registered[obj][e]
		if not l.__R[id] then return false end
		l.__R[id] = nil
		l.__n = l.__n - 1
		return true
	end
	
	events.removeoncelistener = function( obj , e , id )
		coe( obj , e )
		local l = registered[obj][e]
		if not l.__O[id] then return false end
		l.__O[id] = nil
		l.__On = l.__On - 1
		return true
	end
	
	events.removealllisteners = function( obj , e )
		coe( obj )
		registered[obj][e] = nil
	end
	
	events.emit = function( obj , e , ... )
		coe( obj , e )
		local l = registered[obj][e]
		for i , f in pairs( l.__O ) do
			if f( ... ) == false then return false end
		end
		l.__O = {}
		l.__On = 0
		l.__Oi = 0
		for i , f in pairs( l.__R ) do
			if f( ... ) == false then return false end
		end
	end
	
	events.eventnames = function( obj )
		coe( obj )
		local r = {}
		for k in pairs( registered[obj] ) do
			table.insert( r , k )
		end
		return r
	end
	
	events.listenercount = function( obj , e )
		coe( obj , e )
		return registered[obj][e].__n
	end
	
	events.oncelistenercount = function( obj , e )
		coe( obj , e )
		return registered[obj][e].__On
	end
	
	events.listeners = function( obj , e )
		coe( obj , e )
		local r = {}
		for i , f in pairs( registered[obj][e].__R ) do
			r[i] = f
		end
		return r
	end
	
	events.oncelisteners = function( obj , e )
		coe( obj , e )
		local r = {}
		for i , f in pairs( registered[obj][e].__O ) do
			r[i] = f
		end
		return r
	end
	
	local mt = { __index = events }
	local EventEmitter = function( obj )
		return setmetatable( obj or {} , mt )
	end
	
	local e = EventEmitter()
	e.EventEmitter = EventEmitter
	
	_G.events = e
end