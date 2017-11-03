-- database2 by Leafileaf

do
	local db2 = {}
	-- notes on encoding:
	-- [settings (1)][magic (2)][version (0-7)][ data ]
	-- settings:
	--     bits 0-2: length of version field
	--        bit 3: is always set
	--            4: is magic number enabled?
	--            5: is always set
	--            6: reserved
	--            7: set if 8-bit encoding, can't be set on 7-bit anyway (param USE_EIGHTBIT = true)
	-- magic: (param USE_MAGIC = false)
	--     bits 0-13: 10010000001000 in little-endian
	--        bit 15: set if in 8-bit mode
	-- version: version number in little-endian (param USE_VERSION = n to force n bytes, otherwise dynamically scaled)
	-- 
	-- can decode legacy db1 strings, use param USE_LEGACY = true in decode
	-- when decoding legacy strings, use a separate list of schemas using LegacyUnsignedInt and LegacyVarChar.
	--
	-- schemas:
	-- a list of datatypes in the order to be encoded
	-- field VERSION with the schema version, omit if no versioning is to be done
	--
	-- functions:
	--
	-- db2.UnsignedInt{ size = n , key = k }
	-- Creates an UnsignedInt datatype using n bytes at key k
	-- Encodes an unsigned integer
	--
	-- db2.LegacyUnsignedInt{ size = n , key = k }
	-- Creates a LegacyUnsignedInt datatype using n bytes at key k
	-- For decoding db1 strings, cannot encode
	--
	-- db2.Float{ key = k }
	-- Creates a Float datatype at key k
	-- Encodes a floating-point number
	-- Uses 4 bytes
	-- IEEE754 single-precision encoding for 8-bit-per-byte encoding, otherwises uses a 7-bit exponent and a 20-bit significand
	--
	-- db2.Double{ key = k }
	-- Creates a Double datatype at key k
	-- Encodes a floating-point number
	-- Uses 8 bytes
	-- IEEE754 double-precision encoding for 8-bit-per-byte encoding, otherwise uses a 10-bit exponent and a 45-bit significand
	--
	-- db2.VarChar{ size = n , key = k }
	-- Creates a VarChar datatype at key k
	-- Encodes a string of maximum length n
	-- [length (x)][data...]
	-- x is the minimum number of bytes required to encode maximum length n
	-- Uses x+len(data) bytes
	--
	-- db2.FixedChar{ size = n , key = k }
	-- Creates a FixedChar datatype at key k
	-- Encodes a string of length n
	-- [data...]
	-- Uses n bytes
	-- Shorter strings will be right-padded with \x00
	--
	-- db2.Bitset{ size = n , key = k }
	-- Creates a Bitset datatype at key k
	-- Encodes n boolean values
	-- Uses ceil(n/bpb) bytes
	--
	-- db2.VarBitset{ size = n , key = k }
	-- Creates a VarBitset datatype at key k
	-- Encodes up to n boolean values
	-- Uses ceil(len(data)/bpb) + ceil(log(n+1)/log(2^bpb)) bytes
	--
	-- db2.VarDataList{ size = n , key = k , datatype = d }
	-- Creates a VarDataList datatype at key k
	-- Encodes a list at key k of up to n data encodable by d
	-- Uses ceil(log(n+1)/log(2^bpb)) + [...encodeddata] bytes
	--
	-- db2.FixedDataList{ size = n , key = k , datatype = d }
	-- Creates a FixedDataList datatype at key k
	-- Encodes a list at key k of exactly n data encodable by d
	-- Uses [...encodeddata] bytes
	-- if the list has less than n objects, an error is thrown
	--
	-- db2.VarObjectList{ size = n , key = k , schema = s }
	-- Creates a VarObjectList datatype at key k
	-- Encodes a list at key k of up to n objects with structure s
	-- Uses ceil(log(n+1)/log(2^bpb)) + [...encodeddata] bytes
	-- if s has a VERSION field, it will be ignored
	--
	-- db2.FixedObjectList{ size = n , key = k , schema = s }
	-- Creates a FixedObjectList datatype at key k
	-- Encodes a list at key k of exactly n objects with structure s
	-- Uses [...encodeddata] bytes
	-- if s has a VERSION field, it will be ignored
	-- if the list has less than n objects, an error is thrown
	--
	-- db2.encode( schema , data , optional params )
	-- Encodes data with the given schema
	-- Optionally applies params to the encoding
	--
	-- db2.decode( schemalist , encoded , optional params )
	-- Decodes data with the given schema
	-- Optionally applies params to the encoding
	-- If a settings byte is present, it overrides params
	-- If no version is present, treats schemalist as a single schema
	--
	-- db2.test( encoded , optional params )
	-- Tests if encoded is a valid db2 string with optional params
	--
	-- db2.errorfunc( func )
	-- Instead of throwing errors, db2 will now call func if it encounters an error
	--
	-- db2.bytestonumber( bytes , bpb )
	-- Converts bytes to an integer using bpb bits per byte
	-- Uses little-endian encoding
	--
	-- db2.numbertobytes( num , bpb , len )
	-- Converts num to a string of length len using bpb bits per byte
	-- Uses little-endian encoding
	--
	-- db2.lbtn( bytes , bpb )
	-- Converts bytes to an integer using bpb bits per byte
	-- Legacy function for decoding db1 strings
	-- Uses big-endian encoding
	--
	-- db2.lntb( num , bpb , expected_length )
	-- Converts num to a string of length expected_length using bpb bits per byte
	-- Legacy function for encoding db1 strings - unused
	-- Uses big-endian encoding
	-- Warning: unsafe; if num is too big to fit in expected_length bytes output will be bigger than expected
	--
	-- Valid parameters to db2.encode and db2.decode:
	-- USE_SETTINGS (default true): whether to encode a byte with encoding settings in front
	-- USE_MAGIC (default true): whether to use magic bytes to ensure read string is db2
	-- USE_EIGHTBIT (default false): whether to use 8-bit encoding
	-- USE_VERSION (default nil): force a specific number of version bytes, if nil scales dynamically
	-- USE_LEGACY (default false): legacy mode decoding, throws an error when used with db2.encode
	-- USE_SCHEMALIST (default false): never treat schemalist as a single schema when decoding, throws an error when used with db2.encode
	
	local error = error
	
	local log2 = math.log(2)
	
	db2.info = 0
	-- INFO ENUMS --
	db2.INFO_OK = 0
	db2.INFO_ENCODE_DATAERROR = 1 -- invalid parameter
	db2.INFO_ENCODE_DATASIZEERROR = 2 -- data is too large to store
	db2.INFO_ENCODE_GENERICERROR = 3
	db2.INFO_DECODE_BADSTRING = 4 -- not a db2 string
	db2.INFO_DECODE_MISSINGSCHEMA = 5 -- schema with given version doesn't exist
	db2.INFO_DECODE_CORRUPTSTRING = 6 -- end of parsing but not end of string or vice versa
	db2.INFO_DATATYPE_ERROR = 7 -- errors when initialising datatypes
	db2.INFO_GENERICERROR = 8
	-- END INFO ENUMS --
	
	local lbtn = function( str , b ) -- big-endian byte to number
		local n = 0
		local mult = 2^b
		for i = 1 , str:len() do
			n = n * mult + str:byte( i )
		end
		return n
	end
	local lntb = function( num , b , expected_length ) -- legacy; shouldn't be needed here actually
		local str = ""
		local mult = 2^b
		while num ~= 0 do
			local x = num % mult
			str = string.char( x ) .. str
			num = math.floor( num / mult )
		end
		while str:len() < expected_length do str = string.char( 0 ) .. str end
		return str
	end
	local bytestonumber = function( str , bpb )
		local n = 0
		local mult = 2^bpb
		for i = 1 , str:len() do
			n = n + str:byte(i)*(mult^(i-1))
		end
		return n
	end
	local numbertobytes = function( num , bpb , len )
		local t = {}
		local mult = 2^bpb
		for i = 1 , len do -- ensures no overflow, and forces length to be exactly len
			local x = num % mult
			t[i] = string.char( x )
			num = math.floor( num / mult )
		end
		return table.concat( t )
	end
	
	db2.UnsignedInt = function( params )
		db2.info = 0
		
		local bytes = params.size
		if type(bytes) ~= "number" then db2.info = 7 return error( "db2: UnsignedInt: Expected number, found " .. type(bytes) , 2 ) end
		if math.floor(bytes) ~= bytes then db2.info = 7 return error( "db2: UnsignedInt: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: UnsignedInt: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "number" then db2.info = 1 return error( "db2: UnsignedInt: encode: Expected number, found " .. type(data) ) end
				if math.floor(data) ~= data or data < 0 then db2.info = 1 return error( "db2: UnsignedInt: encode: Can only encode unsigned integers" ) end
				return numbertobytes( data , bpb , bytes )
			end,
			decode = function( enc , ptr , bpb )
				local r = bytestonumber( enc:sub( ptr.ptr , ptr.ptr + bytes - 1 ) , bpb )
				ptr.ptr = ptr.ptr + bytes
				return r
			end,
			key = params.key
		}
	end
	
	db2.LegacyUnsignedInt = function( params ) -- old database.CustomInt, all other Int types can be derived from this
		db2.info = 0
		
		local bytes = params.size
		if type(bytes) ~= "number" then db2.info = 7 return error( "db2: LegacyUnsignedInt: Expected number, found " .. type(bytes) , 2 ) end
		if math.floor(bytes) ~= bytes then db2.info = 7 return error( "db2: LegacyUnsignedInt: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: LegacyUnsignedInt: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				db2.info = 8
				return error( "db2: LegacyUnsignedInt: encode: Read-only datatype" )
			end,
			decode = function( enc , ptr , bpb )
				local r = lbtn( enc:sub( ptr.ptr , ptr.ptr + bytes - 1 ) , bpb )
				ptr.ptr = ptr.ptr + bytes
				return r
			end,
			key = params.key
		}
	end
	
	db2.Float = function( params ) -- single-bit precision floats -- https://stackoverflow.com/questions/14416734/lua-packing-ieee754-single-precision-floating-point-numbers
		db2.info = 0
		
		if params.key == nil then db2.info = 7 return error( "db2: Float: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "number" then db2.info = 1 return error( "db2: Float: encode: Expected number, found " .. type(data) ) end
				
				local fullbits = 2^bpb - 1 -- 1111111(1)
				local msb = 2^(bpb-1) -- 1000000(0)
				local fmsb = msb - 1 -- 0111111(1)
				local bytesep = 2^bpb
				
				if data == 0 then
					return string.char( 0 , 0 , 0 , 0 )
				elseif data ~= data then
					return string.char( fullbits , fullbits , fullbits , fullbits ) -- nan
				else
					local sign = 0
					if data < 0 then
						sign = msb
						data = -data
					end
					
					local mant , expo = math.frexp( data )
					
					expo = expo + fmsb
					if expo < 0 then -- small number
						mant = math.ldexp( mant , expo - 1 )
						expo = 0
					elseif expo > 0 then
						if expo >= fullbits then
							return string.char( 0 , 0 , msb , sign + fmsb )
						elseif expo == 1 then
							expo = 0
						else
							mant = mant * 2 - 1
							expo = expo - 1
						end
					end
					mant = math.floor( math.ldexp( mant , 3 * bpb - 1 ) + 0.5 ) -- round to nearest integer mantissa
					return string.char(
						mant % bytesep,
						math.floor( mant / bytesep ) % bytesep,
						( expo % 2 ) * msb + math.floor( mant / bytesep / bytesep ),
						sign + math.floor( expo / 2 )
					)
				end
			end,
			decode = function( enc , ptr , bpb )
				local b4 , b3 , b2 , b1 = enc:byte( ptr.ptr , ptr.ptr + 3 )
				ptr.ptr = ptr.ptr + 4
				
				local fullbits=  2^bpb - 1
				local msb = 2^(bpb-1)
				local fmsb = msb - 1
				local bytesep = 2^bpb
				
				local expo = ( b1 % msb ) * 2 + math.floor( b2 / msb )
				local mant = math.ldexp( ( ( b2 % msb ) * bytesep + b3 ) * bytesep + b4 , -( 3 * bpb - 1 ) )
				
				if expo == fullbits then
					if mant > 0 then
						return 0/0
					else
						mant = math.huge
						expo = fmsb
					end
				elseif expo > 0 then
					mant = mant + 1
				else
					expo = expo + 1
				end
				if b1 >= msb then
					mant = -mant
				end
				return math.ldexp( mant , expo - fmsb )
			end,
			key = params.key
		}
	end
	
	db2.Double = function( params )
		db2.info = 0
		
		if params.key == nil then db2.info = 7 return error( "db2: Double: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "number" then db2.info = 1 return error( "db2: Double: encode: Expected number, found " .. type(data) ) end
				
				local fullbits = 2^bpb - 1 -- 1111111(1)
				local msb = 2^(bpb-1) -- 1000000(0)
				local fmsb = msb - 1 -- 0111111(1)
				local fullexpo = 2^(bpb+3) - 1 -- 1111111111(1), full bits of expo field
				local mpe = 2^(bpb+2) - 1 -- 0111111111(1), making expo positive
				local top4 = fullbits - ( 2^(bpb-4) - 1 ) -- 1111000(0), top 4 bits filled
				local top4msb = 2^(bpb-4) -- 0001000(0), encoding expo
				local bytesep = 2^bpb
				
				if data == 0 then
					return string.char( 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 )
				elseif data ~= data then
					return string.char( fullbits , fullbits , fullbits , fullbits , fullbits , fullbits , fullbits , fullbits ) -- nan
				else
					local sign = 0
					if data < 0 then
						sign = msb
						data = -data
					end
					
					local mant , expo = math.frexp( data )
					
					expo = expo + mpe
					if expo < 0 then -- small number
						mant = math.ldexp( mant , expo - 1 )
						expo = 0
					elseif expo > 0 then
						if expo >= fullexpo then
							return string.char( 0 , 0 , 0 , 0 , 0 , 0 , top4 , sign + fmsb )
						elseif expo == 1 then
							expo = 0
						else
							mant = mant * 2 - 1
							expo = expo - 1
						end
					end
					mant = math.floor( math.ldexp( mant , 7 * bpb - 4 ) + 0.5 ) -- round to nearest integer mantissa
					return numbertobytes( mant , bpb , 6 ) .. string.char(
						( expo % 16 ) * top4msb + math.floor( mant / ( bytesep ^ 6 ) ),
						sign + math.floor( expo / 16 )
					)
				end
			end,
			decode = function( enc , ptr , bpb )
				local b2 , b1 = enc:byte( ptr.ptr + 6 , ptr.ptr + 7 )
				local b38 = enc:sub( ptr.ptr , ptr.ptr + 5 )
				ptr.ptr = ptr.ptr + 8
				
				local fullbits=  2^bpb - 1
				local msb = 2^(bpb-1)
				local fmsb = msb - 1
				local fullexpo = 2^(bpb+3) - 1
				local mpe = 2^(bpb+2) - 1
				local top4 = fullbits - ( 2^(bpb-4) - 1 )
				local top4msb = 2^(bpb-4)
				local bytesep = 2^bpb
				
				local expo = ( b1 % msb ) * 16 + math.floor( b2 / top4msb )
				local mant = math.ldexp( ( b2 % top4msb ) * ( bytesep ^ 6 ) + bytestonumber( b38 , bpb ) , -( 7 * bpb - 4 ) )
				
				if expo == fullexpo then
					if mant > 0 then
						return 0/0
					else
						mant = math.huge
						expo = fmsb
					end
				elseif expo > 0 then
					mant = mant + 1
				else
					expo = expo + 1
				end
				if b1 >= msb then
					mant = -mant
				end
				return math.ldexp( mant , expo - mpe )
			end,
			key = params.key
		}
	end
	
	db2.VarChar = function( params )
		db2.info = 0
		
		local sz , nbits = params.size , math.log( params.size + 1 ) / log2 + 1
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarChar: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarChar: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: VarChar: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "string" then db2.info = 1 return error( "db2: VarChar: encode: Expected string, found " .. type(data) ) end
				if data:len() > sz then db2.info = 2 return error( "db2: VarChar: encode: Data is bigger than is allocated for" ) end
				local lsz = math.ceil(nbits/bpb) -- length of size
				return numbertobytes( data:len() , bpb , lsz ) .. data
			end,
			decode = function( enc , ptr , bpb )
				local lsz = math.ceil(nbits/bpb)
				local len = bytestonumber( enc:sub( ptr.ptr , ptr.ptr + lsz - 1 ) , bpb )
				ptr.ptr = ptr.ptr + lsz + len
				return enc:sub( ptr.ptr - len , ptr.ptr - 1 )
			end,
			key = params.key
		}
	end
	
	db2.LegacyVarChar = function( params )
		db2.info = 0
		
		local sz , nbits = params.size , math.log( params.size + 1 ) / log2 + 1
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: LegacyVarChar: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: LegacyVarChar: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: LegacyVarChar: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				db2.info = 8
				return error( "db2: LegacyVarChar: encode: Read-only datatype" )
			end,
			decode = function( enc , ptr , bpb )
				local lsz = math.ceil(nbits/bpb)
				local len = lbtn( enc:sub( ptr.ptr , ptr.ptr + lsz - 1 ) , bpb )
				ptr.ptr = ptr.ptr + lsz + len
				return enc:sub( ptr.ptr - len , ptr.ptr - 1 )
			end,
			key = params.key
		}
	end
	
	db2.FixedChar = function( params )
		db2.info = 0
		
		local sz = params.size
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: FixedChar: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: FixedChar: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: FixedChar: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "string" then db2.info = 1 return error( "db2: FixedChar: encode: Expected string, found " .. type(data) ) end
				if data:len() > sz then db2.info = 2 return error( "db2: FixedChar: encode: Data is bigger than is allocated for" ) end
				return data .. string.char(0):rep( sz - data:len() )
			end,
			decode = function( enc , ptr , bpb )
				local r = enc:sub( ptr.ptr , ptr.ptr + sz - 1 )
				ptr.ptr = ptr.ptr + sz
				return r
			end,
			key = params.key
		}
	end
	
	db2.Bitset = function( params )
		db2.info = 0
		
		local sz = params.size
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: Bitset: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: Bitset: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: Bitset: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "table" then db2.info = 1 return error( "db2: Bitset: encode: Expected table, found " .. type(data) ) end
				if #data > sz then db2.info = 2 return error( "db2: Bitset: encode: Data is bigger than is allocated for" ) end
				local r = {}
				for i = 1 , math.ceil( sz / bpb ) do
					local n = 0
					for j = 1 , bpb do
						n = n + ( data[(i-1)*bpb+j] and 1 or 0 ) * 2^(j-1)
					end
					table.insert( r , string.char(n) )
				end
				return table.concat( r )
			end,
			decode = function( enc , ptr , bpb )
				local r = {}
				for i = 1 , math.ceil( sz / bpb ) do
					local n = enc:byte( ptr.ptr + i - 1 )
					for j = 1 , bpb do
						table.insert( r , n%2 == 1 )
						n = math.floor( n / 2 )
					end
				end
				ptr.ptr = ptr.ptr + math.ceil( sz / bpb )
				return r
			end,
			key = params.key
		}
	end
	
	db2.VarBitset = function( params )
		db2.info = 0
		
		local sz , nbits = params.size , math.log( params.size + 1 ) / log2 + 1
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarBitset: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarBitset: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: VarBitset: Expected key, found nil" , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "table" then db2.info = 1 return error( "db2: VarBitset: encode: Expected table, found " .. type(data) ) end
				if #data > sz then db2.info = 2 return error( "db2: VarBitset: encode: Data is bigger than is allocated for" ) end
				local lsz = math.ceil(nbits/bpb)
				local r = { numbertobytes( #data , bpb , lsz ) }
				for i = 1 , math.ceil( #data / bpb ) do
					local n = 0
					for j = 1 , bpb do
						n = n + ( data[(i-1)*bpb+j] and 1 or 0 ) * 2^(j-1)
					end
					table.insert( r , string.char(n) )
				end
				return table.concat( r )
			end,
			decode = function( enc , ptr , bpb )
				local lsz = math.ceil(nbits/bpb)
				local num = bytestonumber( enc:sub( ptr.ptr , ptr.ptr + lsz - 1 ) , bpb )
				local r = {}
				for i = 1 , math.ceil( num / bpb ) do
					local n = enc:byte( ptr.ptr + lsz + i - 1 )
					for j = 1 , bpb do
						table.insert( r , n%2 == 1 )
						if #r == num then break end
						n = math.floor( n / 2 )
					end
				end
				ptr.ptr = ptr.ptr + lsz + math.ceil( num / bpb )
				return r
			end,
			key = params.key
		}
	end
	
	db2.VarDataList = function( params )
		db2.info = 0
		
		local sz , nbits , dt = params.size , math.log( params.size + 1 ) / log2 + 1 , params.datatype
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarDataList: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarDataList: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: VarDataList: Expected key, found nil" , 2 ) end
		if type(schema) ~= "table" or not ( datatype.encode and datatype.decode and datatype.key ) then db2.info = 7 return error( "db2: VarDataList: Expected datatype, found " .. type(schema) , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "table" then db2.info = 1 return error( "db2: VarDataList: encode: Expected table, found " .. type(data) ) end
				if #data > sz then db2.info = 2 return error( "db2: VarDataList: encode: Data is bigger than is allocated for" ) end
				local lsz = math.ceil(nbits/bpb) -- length of size
				local enc = { numbertobytes( #data , bpb , lsz ) }
				for i = 1 , #data do
					table.insert( enc , dt.encode( data[i] , bpb ) )
				end
				return table.concat( enc )
			end,
			decode = function( enc , ptr , bpb )
				local lsz = math.ceil(nbits/bpb)
				local n = bytestonumber( enc:sub( ptr.ptr , ptr.ptr + lsz - 1 ) , bpb ) -- size of list
				ptr.ptr = ptr.ptr + lsz
				local out = {}
				for i = 1 , n do
					out[i] = dt.decode( enc , ptr , bpb )
				end
				return out
			end,
			key = params.key,
		}
	end
	
	db2.FixedDataList = function( params )
		db2.info = 0
		
		local sz , dt = params.size , params.datatype
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: FixedDataList: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: FixedDataList: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: FixedDataList: Expected key, found nil" , 2 ) end
		if type(schema) ~= "table" or not ( datatype.encode and datatype.decode and datatype.key ) then db2.info = 7 return error( "db2: FixedDataList: Expected datatype, found " .. type(schema) , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "table" then db2.info = 1 return error( "db2: FixedDataList: encode: Expected table, found " .. type(data) ) end
				if #data ~= sz then db2.info = 2 return error( "db2: FixedDataList: encode: Data size is not as declared" ) end
				local enc = {}
				for i = 1 , sz do
					table.insert( enc , dt.encode( data[i] , bpb ) )
				end
				return table.concat( enc )
			end,
			decode = function( enc , ptr , bpb )
				local out = {}
				for i = 1 , sz do
					out[i] = dt.decode( enc , ptr , bpb )
				end
				return out
			end,
			key = params.key,
		}
	end
	
	db2.VarObjectList = function( params )
		db2.info = 0
		
		local sz , nbits , schema = params.size , math.log( params.size + 1 ) / log2 + 1 , params.schema
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarObjectList: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarObjectList: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: VarObjectList: Expected key, found nil" , 2 ) end
		if type(schema) ~= "table" then db2.info = 7 return error( "db2: VarObjectList: Expected table, found " .. type(schema) , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "table" then db2.info = 1 return error( "db2: VarObjectList: encode: Expected table, found " .. type(data) ) end
				if #data > sz then db2.info = 2 return error( "db2: VarObjectList: encode: Data is bigger than is allocated for" ) end
				local lsz = math.ceil(nbits/bpb) -- length of size
				local enc = { numbertobytes( #data , bpb , lsz ) }
				for i = 1 , #data do
					for j = 1 , #schema do -- same loop as db2.encode
						table.insert( enc , schema[j].encode( data[i][schema[j].key] , bpb ) )
					end
				end
				return table.concat( enc )
			end,
			decode = function( enc , ptr , bpb )
				local lsz = math.ceil(nbits/bpb)
				local n = bytestonumber( enc:sub( ptr.ptr , ptr.ptr + lsz - 1 ) , bpb ) -- size of list
				ptr.ptr = ptr.ptr + lsz
				local out = {}
				for i = 1 , n do
					out[i] = {}
					for j = 1 , #schema do -- same loop as db2.decode
						out[i][schema[j].key] = schema[j].decode( enc , ptr , bpb )
					end
				end
				return out
			end,
			key = params.key,
		}
	end
	
	db2.FixedObjectList = function( params )
		db2.info = 0
		
		local sz , schema = params.size , params.schema
		if type(sz) ~= "number" then db2.info = 7 return error( "db2: FixedObjectList: Expected number, found " .. type(sz) , 2 ) end
		if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: FixedObjectList: Expected integer" , 2 ) end
		if params.key == nil then db2.info = 7 return error( "db2: FixedObjectList: Expected key, found nil" , 2 ) end
		if type(schema) ~= "table" then db2.info = 7 return error( "db2: FixedObjectList: Expected table, found " .. type(schema) , 2 ) end
		
		return {
			encode = function( data , bpb )
				if type(data) ~= "table" then db2.info = 1 return error( "db2: FixedObjectList: encode: Expected table, found " .. type(data) ) end
				if #data ~= sz then db2.info = 2 return error( "db2: FixedObjectList: encode: Data size is not as declared" ) end
				local enc = {}
				for i = 1 , sz do
					for j = 1 , #schema do
						table.insert( enc , schema[j].encode( data[i][schema[j].key] , bpb ) )
					end
				end
				return table.concat( enc )
			end,
			decode = function( enc , ptr , bpb )
				local out = {}
				for i = 1 , sz do
					out[i] = {}
					for j = 1 , #schema do
						out[i][schema[j].key] = schema[j].decode( enc , ptr , bpb )
					end
				end
				return out
			end,
			key = params.key,
		}
	end
	
	local encode = function( schema , data , params ) -- schema , data
		db2.info = 0
		
		params = params or {}
		local USE_SETTINGS = params.USE_SETTINGS or true
		local USE_EIGHTBIT = params.USE_EIGHTBIT or false
		local USE_MAGIC = params.USE_MAGIC or true
		
		if params.USE_LEGACY then db2.info = 3 return error("db2: encode: Cannot encode in legacy mode",2) end
		if params.USE_SCHEMALIST then db2.info = 3 return error("db2: encode: Cannot treat schema as a list",2) end
		
		local bpb = USE_EIGHTBIT and 8 or 7
		
		local vl = params.USE_VERSION or ( ( not schema.VERSION ) and 0 or math.ceil((math.log(schema.VERSION+1)/log2+1)/bpb) )
		local enc = {
			USE_SETTINGS and numbertobytes( vl + 8 + ( USE_MAGIC and 16 or 0 ) + 32 + ( USE_EIGHTBIT and 128 or 0 ) , bpb , 1 ),
			USE_MAGIC and numbertobytes( 9224 + ( USE_EIGHTBIT and 32768 or 0 ) , bpb , 2 ),
			numbertobytes( schema.VERSION or 0 , bpb , vl ),
		}
		for i = 1 , #schema do
			table.insert( enc , schema[i].encode( data[schema[i].key] , bpb ) )
			if db2.info ~= 0 then return end
		end
		return table.concat( enc )
	end
	
	local decode = function( t , enc , params )
		db2.info = 0
		
		params = params or {}
		local USE_SETTINGS = params.USE_SETTINGS or true
		local USE_EIGHTBIT = params.USE_EIGHTBIT or false
		local USE_MAGIC = params.USE_MAGIC or true
		local USE_VERSION = params.USE_VERSION or nil
		
		local bytestonumber = bytestonumber
		
		if params.USE_LEGACY then
			USE_SETTINGS = false
			USE_MAGIC = false
			USE_VERSION = params.USE_VERSION or 2
			bytestonumber = lbtn
		end
		
		local bpb = USE_EIGHTBIT and 8 or 7
		
		local ptr = 1
		local vl = USE_VERSION
		
		if USE_SETTINGS then
			local settings = enc:byte(ptr)
			
			if not ( settings % 2^6 >= 2^5 and settings % 2^4 >= 2^3 ) then db2.info = 4 return error("db2: decode: Invalid settings byte",2) end
			
			vl = settings % 2^3
			USE_MAGIC = settings % 2^5 >= 2^4
			USE_EIGHTBIT = settings >= 2^7
			bpb = USE_EIGHTBIT and 8 or 7
			
			ptr = ptr + 1
		end
		
		if USE_MAGIC then
			local n = bytestonumber( enc:sub(ptr,ptr+1) , bpb )
			if ( not ( n % 32768 == 9224 ) ) or ( n > 32768 and n - 32768 ~= 9224 ) then db2.info = 4 return error("db2: decode: Invalid magic number",2) end
			
			ptr = ptr + 2
		end
		
		local vn = bytestonumber( enc:sub(ptr,ptr+vl-1) , bpb )
		ptr = ptr + vl
		
		local schema = vl == 0 and ( not params.USE_SCHEMALIST and t or t[0] ) or t[vn]
		
		if not schema then db2.info = 5 return error("db2: decode: Missing schema",2) end
		
		local dat = {}
		local p = { ptr = ptr }
		for i = 1 , #schema do
			dat[ schema[i].key ] = schema[i].decode( enc , p , bpb )
			if p.ptr > enc:len() + 1 then db2.info = 6 return error("db2: decode: End of string reached while parsing",2) end
			if db2.info ~= 0 then return end
		end
		
		if p.ptr ~= enc:len() + 1 then db2.info = 6 return error("db2: decode: End of schema reached while parsing",2) end
		
		return dat
	end
	
	local test = function( enc , params )
		db2.info = 0
		
		params = params or {}
		local USE_SETTINGS = params.USE_SETTINGS or true
		local USE_EIGHTBIT = params.USE_EIGHTBIT or false
		local USE_MAGIC = params.USE_MAGIC or true
		
		local bpb = USE_EIGHTBIT and 8 or 7
		
		local ptr = 1
		
		if USE_SETTINGS then
			local settings = enc:byte(ptr)
			
			if not ( settings % 2^6 >= 2^5 and settings % 2^4 >= 2^3 ) then db2.info = 4 return false end
			
			USE_MAGIC = settings % 2^5 >= 2^4
			USE_EIGHTBIT = settings >= 2^7
			bpb = USE_EIGHTBIT and 8 or 7
			
			ptr = ptr + 1
		end
		
		if USE_MAGIC then
			local n = bytestonumber( enc:sub(ptr,ptr+1) , bpb )
			if ( not ( n % 32768 == 9224 ) ) or ( n > 32768 and n - 32768 ~= 9224 ) then db2.info = 4 return false end
			
			ptr = ptr + 2
		end
		
		return true
	end
	local errorfunc = function( f )
		db2.info = 0
		
		if type(f) == "function" then error = f
		else db2.info = 8 return error( "db2: errorfunc: Expected function, found " .. type(f) , 2 ) end
	end
	
	db2.encode = encode
	db2.decode = decode
	db2.test = test
	db2.errorfunc = errorfunc
	db2.bytestonumber = bytestonumber
	db2.numbertobytes = numbertobytes
	db2.lbtn = lbtn
	db2.lntb = lntb
	
	_G.db2 = db2
end
