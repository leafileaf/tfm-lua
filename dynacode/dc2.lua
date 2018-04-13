-- dynacode
-- a lua-interpreted os
-- by Leafileaf

do
	local dyna = {}
	dyna.sys = {}
	
	local dynamt = { __index = dyna }
	
	-- constants
	dyna.EXECUTE_OK = 0
	dyna.EXECUTE_BADSTATE = 1 -- the machine is in a bad state and cannot run
	dyna.EXECUTE_OPERROR = 2 -- invalid opcode, etc
	dyna.EXECUTE_ARGERROR = 3 -- invalid arguments to operation
	dyna.EXECUTE_SEGFAULT = 4 -- bad memory access
	dyna.EXECUTE_INVACTION = 5 -- invalid action
	
	--- Creates a new Dynacode environment.
	--
	-- @param       {dyna}     c      Base class
	-- @param       {DynaSys}  sys    System flavour (pick from dyna.sys)
	-- @param[opt]  {Function} func   Call this function after every instruction
	-- @return      {DynaEnv}         The constructed Environment
	--
	dyna.new = function( c , sys , func )
		local env = setmetatable( {} , dynamt )
		
		env.__s = sys
		env.__f = func
		env.__h = {} -- hooks
		env.__run = false -- running
		
		env.__s.__init( env )
		
		return env
	end
	
	--- Hooks an interrupt for a Dynacode Environment.
	--- Will not overwrite existing hooks, returns false instead.
	--
	-- @param       {DynaEnv}  env    The Environment to hook
	-- @param       {Integer}  n      Hook number
	-- @param       {Function} f      Callback function
	-- @return      {bool}            Hook successful?
	--
	dyna.hook = function( env , n , f )
		if env.__h[n] then return false end
		env.__h[n] = f return true
	end
	
	--- Removes an interrupt hook from a Dynacode environment.
	--
	-- @param       {DynaEnv}  env    The Environment to remove a hook from
	-- @param       {Integer}  n      Hook number
	-- @return      {bool}            Hook exists and removed?
	--
	dyna.unhook = function( env , n )
		if not env.__h[n] then return false end
		env.__h[n] = nil return true
	end
	
	--- Checks if Environment is running
	--
	-- @param       {DynaEnv}  env    The Environment to check run state
	-- @return      {bool}            Is Environment running?
	--
	dyna.running = function( env )
		return env.__run
	end
	
	do
		-- Transformice DynaSys
		-- A basic executable environment meant for map-scripting
		-- Think ROMs
		--
		local tfmsys = setmetatable( {} , dynamt )
		local tfmsysmt = { __index = tfmsys }
		
		local RETURN_CONTROL = {}
		tfmsys.RETURN_CONTROL = RETURN_CONTROL
		
		local ops = {
			[0x00] = { -- NOP
				d = 0,
				f = function() end
			},
			[0x01] = { -- ADD r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = env.__r[r1] + env.__r[r2]
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r1] = k
				end
			},
			[0x02] = { -- ADD %r0,i8
				d = 1,
				f = function( env , x )
					local k = env.__r[0] + x
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x03] = { -- ADD r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8 -- shouldn't be needed, but hey
					local k = env.__r[r] + x2
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x04] = { -- ADD r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = env.__r[r] + x2 + x3*256
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x05] = { -- OR r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = bit32.bor( env.__r[r1] , env.__r[r2] )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r1] = k
				end
			},
			[0x06] = { -- OR %r0,i8
				d = 1,
				f = function( env , x )
					local k = bit32.bor( env.__r[0] , x )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x07] = { -- OR r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8
					local k = bit32.bor( env.__r[r] , x2 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x08] = { -- OR r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = bit32.bor( env.__r[r] , x2 + x3*256 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x09] = { -- AND r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = bit32.band( env.__r[r1] , env.__r[r2] )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r1] = k
				end
			},
			[0x0A] = { -- AND %r0,i8
				d = 1,
				f = function( env , x )
					local k = bit32.band( env.__r[0] , x )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x0B] = { -- AND r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8
					local k = bit32.band( env.__r[r] , x2 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x0C] = { -- AND r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = bit32.band( env.__r[r] , x2 + x3*256 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x0D] = { -- SUB r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = env.__r[r1] - env.__r[r2]
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r1] = k
				end
			},
			[0x0E] = { -- SUB %r0,i8
				d = 1,
				f = function( env , x )
					local k = env.__r[0] - x
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x0F] = { -- SUB r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8
					local k = env.__r[r] - x2
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x10] = { -- SUB r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = env.__r[r] - ( x2 + x3*256 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x11] = { -- XOR r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = bit32.bxor( env.__r[r1] , env.__r[r2] )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r1] = k
				end
			},
			[0x12] = { -- XOR %r0,i8
				d = 1,
				f = function( env , x )
					local k = bit32.bxor( env.__r[0] , x )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x13] = { -- XOR r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8
					local k = bit32.bxor( env.__r[r] , x2 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x14] = { -- XOR r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = bit32.bxor( env.__r[r] , x2 + x3*256 )
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[r] = k
				end
			},
			[0x15] = { -- CMP r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = env.__r[r1] - env.__r[r2]
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x16] = { -- CMP %r0,i8
				d = 1,
				f = function( env , x )
					local k = env.__r[0] - x
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x17] = { -- CMP r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8
					local k = env.__r[r] - x2
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x18] = { -- CMP r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = env.__r[r] - ( x2 + x3*256 )
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x19] = { -- TEST r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					local k = bit32.band( env.__r[r1] , env.__r[r2] )
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x1A] = { -- TEST %r0,i8
				d = 1,
				f = function( env , x )
					local k = bit32.band( env.__r[0] , x )
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x1B] = { -- TEST r,i8
				d = 2,
				f = function( env , x1 , x2 )
					local r = x1%8
					local k = bit32.band( env.__r[r] , x2 )
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x1C] = { -- TEST r,i16
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r = x1%8
					local k = bit32.band( env.__r[r] , x2 + x3*256 )
					
					env.__s = k < 0
					env.__z = k == 0
				end
			},
			[0x20] = { -- INC %r0
				d = 0,
				f = function( env )
					local k = env.__r[0] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x21] = { -- INC %r1
				d = 0,
				f = function( env )
					local k = env.__r[0] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x22] = { -- INC %r2
				d = 0,
				f = function( env )
					local k = env.__r[2] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[2] = k
				end
			},
			[0x23] = { -- INC %r3
				d = 0,
				f = function( env )
					local k = env.__r[3] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[3] = k
				end
			},
			[0x24] = { -- INC %r4
				d = 0,
				f = function( env )
					local k = env.__r[4] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[4] = k
				end
			},
			[0x25] = { -- INC %r5
				d = 0,
				f = function( env )
					local k = env.__r[5] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[5] = k
				end
			},
			[0x26] = { -- INC %r6
				d = 0,
				f = function( env )
					local k = env.__r[6] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[6] = k
				end
			},
			[0x27] = { -- INC %r7
				d = 0,
				f = function( env )
					local k = env.__r[7] + 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[7] = k
				end
			},
			[0x28] = { -- DEC %r0
				d = 0,
				f = function( env )
					local k = env.__r[0] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x29] = { -- DEC %r1
				d = 0,
				f = function( env )
					local k = env.__r[0] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[0] = k
				end
			},
			[0x2A] = { -- DEC %r2
				d = 0,
				f = function( env )
					local k = env.__r[2] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[2] = k
				end
			},
			[0x2B] = { -- DEC %r3
				d = 0,
				f = function( env )
					local k = env.__r[3] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[3] = k
				end
			},
			[0x2C] = { -- DEC %r4
				d = 0,
				f = function( env )
					local k = env.__r[4] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[4] = k
				end
			},
			[0x2D] = { -- DEC %r5
				d = 0,
				f = function( env )
					local k = env.__r[5] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[5] = k
				end
			},
			[0x2E] = { -- DEC %r6
				d = 0,
				f = function( env )
					local k = env.__r[6] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[6] = k
				end
			},
			[0x2F] = { -- DEC %r7
				d = 0,
				f = function( env )
					local k = env.__r[7] - 1
					
					env.__s = k < 0
					env.__z = k == 0
					
					env.__r[7] = k
				end
			},
			[0x30] = { -- PUSH %r0
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[0]
				end
			},
			[0x31] = { -- PUSH %r1
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[0]
				end
			},
			[0x32] = { -- PUSH %r2
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[2]
				end
			},
			[0x33] = { -- PUSH %r3
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[3]
				end
			},
			[0x34] = { -- PUSH %r4
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[4]
				end
			},
			[0x35] = { -- PUSH %r5
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[5]
				end
			},
			[0x36] = { -- PUSH %r6
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[6]
				end
			},
			[0x37] = { -- PUSH %r7
				d = 0,
				f = function( env )
					env.__q[#env.__q+1] = env.__r[7]
				end
			},
			[0x38] = { -- POP %r0
				d = 0,
				f = function( env )
					env.__r[0] = table.remove( env.__q )
				end
			},
			[0x39] = { -- POP %r1
				d = 0,
				f = function( env )
					env.__r[1] = table.remove( env.__q )
				end
			},
			[0x3A] = { -- POP %r2
				d = 0,
				f = function( env )
					env.__r[2] = table.remove( env.__q )
				end
			},
			[0x3B] = { -- POP %r3
				d = 0,
				f = function( env )
					env.__r[3] = table.remove( env.__q )
				end
			},
			[0x3C] = { -- POP %r4
				d = 0,
				f = function( env )
					env.__r[4] = table.remove( env.__q )
				end
			},
			[0x3D] = { -- POP %r5
				d = 0,
				f = function( env )
					env.__r[5] = table.remove( env.__q )
				end
			},
			[0x3E] = { -- POP %r6
				d = 0,
				f = function( env )
					env.__r[6] = table.remove( env.__q )
				end
			},
			[0x3F] = { -- POP %r7
				d = 0,
				f = function( env )
					env.__r[7] = table.remove( env.__q )
				end
			},
			[0x40] = { -- PUSHA
				d = 0,
				f = function( env )
					local l = #env.__q + 1
					for i = 0 , 7 do
						env.__q[l+i] = env.__r[i]
					end
				end
			},
			[0x41] = { -- POPA
				d = 0,
				f = function( env )
					local l = #env.__q - 7
					for i = 0 , 7 do
						env.__r[i] = env.__q[l+i]
						env.__q[l+i] = nil
					end
				end
			},
			[0x42] = { -- PUSH i8
				d = 1,
				f = function( env , x )
					env.__q[#env.__q+1] = x
				end
			},
			[0x43] = { -- PUSH i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__q[#env.__q+1] = x1 + x2*256
				end
			},
			[0x44] = { -- JZ/JE r8
				d = 1,
				f = function( env , x )
					if env.__z then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x45] = { -- JNZ/JNE r8
				d = 1,
				f = function( env , x )
					if not env.__z then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x46] = { -- JB/JNAE/JL/JNGE/JS r8
				d = 1,
				f = function( env , x )
					if env.__s then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x47] = { -- JNB/JAE/JNL/JGE/JNS r8
				d = 1,
				f = function( env , x )
					if not env.__s then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x48] = { -- JBE/JNA/JLE/JNG r8
				d = 1,
				f = function( env , x )
					if env.__s or env.__z then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x49] = { -- JNBE/JA/JNLE/JG r8
				d = 1,
				f = function( env , x )
					if not env.__s and not env.__z then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x50] = { -- ADD/OR/AND/SUB/XOR/CMP/TEST/LEA r,m/m,r
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r1 = x1%8
					local typ = ((x1-r1)/8)%8
					local d = ((x1-(x1%128))/128)%128 == 1
					local r2 = x2%8
					local r3 = ((x2-r2)/8)%8
					local c1 = ((x2-r2-r3*8)/64)%4
					c1 = c1*2 + x3%2
					local c2 = (x3-x3%2)/2
					
					local m = env.__r[r2] + c1*env.__r[r3] + c2
					local o1 = d and env.__m[m] or env.__r[r1]
					local o2 = d and env.__r[r1] or env.__m[m]
					local k = 0
					
					if typ < 4 then
						if typ < 2 then
							if typ == 0 then
								k = o1 + o2
							else
								k = bit32.bor( o1 , o2 )
							end
						else
							if typ == 2 then
								k = bit32.band( o1 , o2 )
							else
								k = o1 - o2
							end
						end
					else
						if typ < 6 then
							if typ == 4 then
								k = bit32.bxor( o1 , o2 )
							else
								k = o1 - o2
							end
						else
							if typ == 6 then
								k = bit32.band( o1 , o2 )
							else
								k = m
							end
						end
					end
					
					if not ( typ == 5 or typ == 6 ) then
						if typ == 7 or not d then
							env.__r[r1] = k
						else
							env.__m[m] = k
						end
					end
					
					if not typ == 7 then
						env.__s = k < 0
						env.__z = k == 0
					end
				end
			},
			[0x51] = { -- XCHG r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					env.__r[r1] , env.__r[r2] = env.__r[r2] , env.__r[r1]
				end
			},
			[0x52] = { -- XCHG r,m
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r1 = x1%8
					local r2 = x2%8
					local r3 = ((x2-r2)/8)%8
					local c1 = ((x2-r2-r3*8)/64)%4
					c1 = c1*2 + x3%2
					local c2 = (x3-x3%2)/2
					
					local m = env.__r[r2] + c1*env.__r[r3] + c2
					
					env.__r[r1] , env.__m[m] = env.__m[m] , env.__r[r1]
				end
			},
			[0x53] = { -- MOV r,m/m,r
				d = 3,
				f = function( env , x1 , x2 , x3 )
					local r1 = x1%8
					local d = ((x1-(x1%128))/128)%128 == 1
					local r2 = x2%8
					local r3 = ((x2-r2)/8)%8
					local c1 = ((x2-r2-r3*8)/64)%4
					c1 = c1*2 + x3%2
					local c2 = (x3-x3%2)/2
					
					local m = env.__r[r2] + c1*env.__r[r3] + c2
					
					if d then
						env.__m[m] = env.__r[r1]
					else
						env.__r[r1] = env.__m[m]
					end
				end
			},
			[0x54] = { -- REP/REPE prefix
				d = 0,
				f = function( env )
					env.__rep = 1
				end
			},
			[0x55] = { -- REPNE prefix
				d = 0,
				f = function( env )
					env.__rep = 2
				end
			},
			[0x56] = { -- MOVS
				d = 0,
				f = function( env )
					if env.__rep then
						while env.__r[2] > 0 do
							env.__m[env.__r[4]] = env.__m[env.__r[5]]
							env.__r[4] , env.__r[5] = env.__r[4] + 1 , env.__r[5] + 1
							env.__r[2] = env.__r[2] - 1
						end
					else
						env.__m[env.__r[4]] = env.__m[env.__r[5]]
						env.__r[4] , env.__r[5] = env.__r[4] + 1 , env.__r[5] + 1
					end
					env.__rep = false
				end
			},
			[0x57] = { -- CMPS
				d = 0,
				f = function( env )
					if env.__rep == 1 then
						while env.__r[2] > 0 do
							if env.__m[env.__r[4]] ~= env.__m[env.__r[5]] then
								env.__z = false
								env.__s = ( env.__m[env.__r[4]] - env.__m[env.__r[5]] ) < 0
								break
							end
							env.__r[4] , env.__r[5] = env.__r[4] + 1 , env.__r[5] + 1
							env.__r[2] = env.__r[2] - 1
						end
					elseif env.__rep == 2 then
						while env.__r[2] > 0 do
							if env.__m[env.__r[4]] == env.__m[env.__r[5]] then
								env.__z = true
								env.__s = false
								break
							end
							env.__r[4] , env.__r[5] = env.__r[4] + 1 , env.__r[5] + 1
							env.__r[2] = env.__r[2] - 1
						end
					else
						local k = env.__m[env.__r[4]] - env.__m[env.__r[5]]
						
						env.__s = k < 0
						env.__z = k == 0
						
						env.__r[4] , env.__r[5] = env.__r[4] + 1 , env.__r[5] + 1
					end
					env.__rep = false
				end
			},
			[0x58] = { -- STOS
				d = 0,
				f = function( env )
					if env.__rep then
						while env.__r[2] > 0 do
							env.__m[env.__r[4]] = env.__r[0]
							env.__r[4] = env.__r[4] + 1
							env.__r[2] = env.__r[2] - 1
						end
					else
						env.__m[env.__r[4]] = env.__r[0]
						env.__r[4] = env.__r[4] + 1
					end
					env.__rep = false
				end
			},
			[0x59] = { -- LODS
				d = 0,
				f = function( env )
					if env.__rep then
						while env.__r[2] > 0 do
							env.__r[0] = env.__m[env.__r[4]]
							env.__r[4] = env.__r[4] + 1
							env.__r[2] = env.__r[2] - 1
						end
					else
						env.__r[0] = env.__m[env.__r[4]]
						env.__r[4] = env.__r[4] + 1
					end
					env.__rep = false
				end
			},
			[0x5A] = { -- SCAS
				d = 0,
				f = function( env )
					if env.__rep == 1 then
						while env.__r[2] > 0 do
							if env.__m[env.__r[4]] ~= env.__r[0] then
								env.__z = false
								env.__s = ( env.__m[env.__r[4]] - env.__r[0] ) < 0
								break
							end
							env.__r[4] = env.__r[4] + 1
							env.__r[2] = env.__r[2] - 1
						end
					elseif env.__rep == 2 then
						while env.__r[2] > 0 do
							if env.__m[env.__r[4]] == env.__r[0] then
								env.__z = true
								env.__s = false
								break
							end
							env.__r[4] = env.__r[4] + 1
							env.__r[2] = env.__r[2] - 1
						end
					else
						local k = env.__m[env.__r[4]] - env.__r[0]
						
						env.__s = k < 0
						env.__z = k == 0
						
						env.__r[4] = env.__r[4] + 1
					end
					env.__rep = false
				end
			},
			[0x5B] = { -- CALL r8
				d = 1,
				f = function( env , x )
					if x > 127 then n = n - 256 end
					env.__q[#env.__q+1] = env.__i
					env.__i = env.__i + x
				end
			},
			[0x5C] = { -- CALL i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__q[#env.__q+1] = env.__i
					env.__i = x1 + x2*256
				end
			},
			[0x5D] = { -- RET
				d = 0,
				f = function( env )
					local l = #env.__q
					if env.__q[l] == RETURN_CONTROL then
						env.__run = false
					else
						env.__i = env.__q[l]
					end
					env.__q[l] = nil
				end
			},
			[0x5E] = { -- LOOP r8
				d = 1,
				f = function( env , x )
					env.__r[2] = env.__r[2] - 1
					if env.__r[2] > 0 then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x5F] = { -- JMP i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__i = x1 + x2*256
				end
			},
			[0x60] = { -- MOV %r0,i8
				d = 1,
				f = function( env , x )
					env.__r[0] = x
				end
			},
			[0x61] = { -- MOV %r1,i8
				d = 1,
				f = function( env , x )
					env.__r[1] = x
				end
			},
			[0x62] = { -- MOV %r2,i8
				d = 1,
				f = function( env , x )
					env.__r[2] = x
				end
			},
			[0x63] = { -- MOV %r3,i8
				d = 1,
				f = function( env , x )
					env.__r[3] = x
				end
			},
			[0x64] = { -- MOV %r4,i8
				d = 1,
				f = function( env , x )
					env.__r[4] = x
				end
			},
			[0x65] = { -- MOV %r5,i8
				d = 1,
				f = function( env , x )
					env.__r[5] = x
				end
			},
			[0x66] = { -- MOV %r6,i8
				d = 1,
				f = function( env , x )
					env.__r[6] = x
				end
			},
			[0x67] = { -- MOV %r7,i8
				d = 1,
				f = function( env , x )
					env.__r[7] = x
				end
			},
			[0x68] = { -- MOV %r0,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[0] = x1 + x2*256
				end
			},
			[0x69] = { -- MOV %r1,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[1] = x1 + x2*256
				end
			},
			[0x6A] = { -- MOV %r2,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[2] = x1 + x2*256
				end
			},
			[0x6B] = { -- MOV %r3,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[3] = x1 + x2*256
				end
			},
			[0x6C] = { -- MOV %r4,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[4] = x1 + x2*256
				end
			},
			[0x6D] = { -- MOV %r5,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[5] = x1 + x2*256
				end
			},
			[0x6E] = { -- MOV %r6,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[6] = x1 + x2*256
				end
			},
			[0x6F] = { -- MOV %r7,i16
				d = 2,
				f = function( env , x1 , x2 )
					env.__r[7] = x1 + x2*256
				end
			},
			[0x70] = { -- MUL %r0,%r3
				d = 0,
				f = function( env )
					env.__r[0] = env.__r[0] * env.__r[3]
				end
			},
			[0x71] = { -- DIV %r0,%r3
				d = 0,
				f = function( env )
					env.__r[0] = env.__r[0] / env.__r[3]
					env.__r[0] = env.__r[0] - ( env.__r[0] % 1 )
				end
			},
			[0x72] = { -- JZ/JE r
				d = 1,
				f = function( env , x )
					if env.__z then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x73] = { -- JNZ/JNE r
				d = 1,
				f = function( env , x )
					if not env.__z then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x74] = { -- JB/JNAE/JL/JNGE/JS r
				d = 1,
				f = function( env , x )
					if env.__s then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x75] = { -- JNB/JAE/JNL/JGE/JNS r
				d = 1,
				f = function( env , x )
					if not env.__s then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x76] = { -- JBE/JNA/JLE/JNG r
				d = 1,
				f = function( env , x )
					if env.__s or env.__z then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x77] = { -- JNBE/JA/JNLE/JG r
				d = 1,
				f = function( env , x )
					if not env.__s and not env.__z then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x78] = { -- MOV r,r
				d = 1,
				f = function( env , x )
					local r1 , r2 = x%8 , ((x-(x%8))/8)%8
					env.__r[r1] = env.__r[r2]
				end
			},
			[0x79] = { -- JECXZ r8
				d = 1,
				f = function( env , x )
					if env.__r[2] == 0 then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x7A] = { -- JECXZ r
				d = 1,
				f = function( env , x )
					if env.__r[2] == 0 then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x7B] = { -- JECXNZ r8
				d = 1,
				f = function( env , x )
					if env.__r[2] ~= 0 then
						if x > 127 then x = x - 256 end
						env.__i = env.__i + x
					end
				end
			},
			[0x7C] = { -- JECXNZ r
				d = 1,
				f = function( env , x )
					if env.__r[2] ~= 0 then
						env.__i = env.__r[x%8]
					end
				end
			},
			[0x7F] = { -- HLT
				d = 0,
				f = function( env )
					env.__run = false
				end
			},
			[0x80] = { -- INT i8
				d = 1,
				f = function( env , x )
					if env.__h[x] then
						env.__h[x]( env )
					end
				end
			},
		}
		
		local mathlib = function( env ) -- method in r0, arguments in stack
			--
		end
		local syscall = function( env ) -- pass method in r0
			local typ = env.__r[0]
			if typ == 0x01 then -- register event handler
				local etyp = env.__r[1]
				local hloc = env.__r[2]
				if not env.__e[etyp] then env.__e[etyp] = {} end
				env.__e[etyp][ #env.__e[etyp] + 1 ] = hloc
			elseif typ == 0x02 then -- print
				local sloc = env.__r[1]
				local c,cc = 0,1
				local sa = {}
				while true do
					c = env.__m[sloc]
					if c and c ~= 0 then
						sa[cc] = c
					else
						break
					end
					sloc , cc = sloc + 1 , cc + 1
				end
				local str = string.char( table.unpack( sa ) )
				
				print(str)
			end
		end
		
		tfmsys.__init = function( env )
			setmetatable( env , tfmsysmt )
			
			-- machine state
			env.__m = {} -- memory
			env.__e = {} -- event handlers
			env.__q = {} -- stack
			env.__a = false -- alive
			env.__i = 0 -- instruction pointer
			env.__s = false -- sign flag
			env.__z = false -- zero flag
			env.__rep = false -- repeat string operation
			
			-- registers
			env.__r = { 0 , 0 , 0 , 0 , 0 , 0 , 0 , [0] = 0 }
			
			-- interrupt
			env.__h[0x0F] = mathlib
			env.__h[0x80] = syscall
		end
		
		--- Loads a program into memory
		--- Previous program will be cleared
		--
		-- @param       {DynaEnv}  env    The Environment to load data into
		-- @param       {string}   s      Data to be loaded
		--
		tfmsys.load = function( env , s )
			env.__m , env.__e , env.__q , env.__a = { s:byte( 1 , s:len() ) } , {} , {} , false
		end
		
		--- Execute the program
		--
		-- @param       {DynaEnv}  env    The Environment to execute
		-- @param[opt]  {Integer}  ent    Use a different Entry Point, default=1
		-- @return      {Integer}         Execution status
		--
		local exec = function( env , ent )
			if not env.__a then return dyna.EXECUTE_BADSTATE end
			env.__i = ent or 1
			local ins = ops[0x00]
			local ci = env.__i
			local ret = 0
			env.__run = true
			while env.__run and env.__a do
				if env.__m[env.__i] then
					ins = ops[env.__m[env.__i]]
					if ins then
						ci = env.__i
						env.__i = env.__i + ins.d + 1
						ret = ins.f( env , table.unpack( env.__m , ci + 1 , ci + ins.d ) )
						if env.__f then env.__f( env ) end
						if ret then return ret end
					else -- bad operation!
						env.__a = false
						return dyna.EXECUTE_OPERROR
					end
				else -- bad memory!
					env.__a = false
					return dyna.EXECUTE_SEGFAULT
				end
			end
			env.__run = false
			return dyna.EXECUTE_OK
		end
		tfmsys.exec = exec
		
		--- Reset the Environment
		--- Run this function after loading into memory
		--
		-- @param       {DynaEnv}  env    The Environment to reset
		--
		tfmsys.reset = function( env )
			env.__r = { 0 , 0 , 0 , 0 , 0 , 0 , 0 , [0] = 0 }
			env.__a = true
		end
		
		--- Emit an event to the Environment
		--
		-- @param       {DynaEnv}  env    The Environment to fire event
		-- @param       {Integer}  id     The Event to fire
		-- @param[opt]  {Integer}  ...    Additional arguments
		-- @return      {Integer}         Execution status
		--
		tfmsys.event = function( env , id , ... )
			if not env.__e[id] then return dyna.EXECUTE_OK end
			local n = #env.__q + 1
			local arg = { ... }
			local l = #arg
			local stat = 0
			for i = 1 , #env.__e[id] do
				env.__q[n] = RETURN_CONTROL
				for j = 1 , l do
					env.__q[n+l-j] = arg[j]
				end
				stat = exec( env , env.__e[id][i] )
				if stat ~= dyna.EXECUTE_OK then return stat end
				if #env.__q < n then return dyna.EXECUTE_INVACTION end
			end
			
			return dyna.EXECUTE_OK
		end
		
		dyna.sys.tfm = tfmsys
	end
	
	_G.dyna = dyna
end