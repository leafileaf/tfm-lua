local sosm = { -- type->schema
	[1] = {
		db2.VarChar{ size = 127 , key = "bleh" },
		db2.UnsignedInt{ size = 3 , key = "blah" },
	},
	[2] = {
		db2.VarChar{ size = 127 , key = "blah" },
		db2.UnsignedInt{ size = 3 , key = "bleh" },
	}
}

local schema = {
	VERSION = 24,
	db2.UnsignedInt{ size = 2 , key = "apple" },
	db2.UnsignedInt{ size = 1 , key = "pear" },
	db2.VarObjectList{ size = 3 , key = "meme" , schema = {
		db2.UnsignedInt{ size = 3 , key = "banana" },
		db2.VarChar{ size = 120 , key = "nope" },
	} },
	db2.FixedObjectList{ size = 3 , key = "owo" , schema = {
		db2.UnsignedInt{ size = 1 , key = "lmao" }
	} },
	db2.VarDataList{ size = 5 , key = "aaa" , datatype = db2.UnsignedInt{ size = 2 } },
	db2.FixedDataList{ size = 2 , key = "bbb" , datatype = db2.UnsignedInt{ size = 2 } },
	db2.VarChar{ size = 20 , key = "kek" },
	db2.FixedChar{ size = 5 , key = "kak" },
	db2.Float{ key = "test" },
	db2.Double{ key = "ieee754sucks" },
	db2.Bitset{ size = 14 , key = "bstest" },
	db2.VarBitset{ size = 20 , key = "vbstest" },
	db2.VarBitset{ size = 250 , key = "ltest" },
	db2.VarChar{ size = 5 , key = "endt" },
	db2.SwitchObject{ typekey = "type" , typedt = db2.UnsignedInt{ size = 2 } , schemamap = sosm , key = "sot1" },
	db2.SwitchObject{ typekey = "type" , typedt = db2.UnsignedInt{ size = 2 } , schemamap = sosm , key = "sot2" },
}

local lt = {}
for i = 1 , 230 do
	lt[i] = math.random(1,2) == 1
end

local source = { apple = 50 , pear = 20 , kek = "kekekeke" , kak = "kakak" , endt = "hello" , test = 3.141592653589793238 , ieee754sucks = 2.7182818284590452356 , meme = {
	{ banana = 162343 , nope = "nananana!" },
	{ banana = 42 , nope = "the universe and everything" },
} , owo = {
	{ lmao = 100 },
	{ lmao = 42 },
	{ lmao = 7 },
} , aaa = {
	1 , 4 , 2
} , bbb = {
	24 , 8
} , bstest = {
	true, true, false, true, false, false, true,
	false, true, false, true, false, false, true
} , vbstest = {
	true, false, true
} , ltest = lt , sot1 = {
	type = 2,
	bleh = 50,
	blah = "sot1ok"
} , sot2 = {
	type = 1,
	bleh = "sot2 ok!",
	blah = 123
} }

local e = db2.encode( schema , source , { USE_MAGIC = false } )

local d = db2.decode( { [24] = schema } , e )

local function rcheck( t , s , n )
	local f = true
	for k , v in pairs( s ) do
		if type(v) == "table" then
			if not rcheck( t[k] , s[k] , n.."."..k ) then f = false end
		elseif s[k] ~= t[k] then
			print(n.."."..k..": "..tostring(s[k]).." ~= "..tostring(t[k]))
			f = false
			if type(s[k]) == "number" and type(t[k]) == "number" then
				local diff = math.abs(s[k]-t[k])
				print("difference = "..diff)
				if diff < 1e-6 then f = true end
			end
		end
	end
	return f
end

print("AC = "..tostring(rcheck(d,source,"")))