local schema = {
	VERSION = 24,
	db2.UnsignedInt{ size = 2 , key = "apple" },
	db2.UnsignedInt{ size = 1 , key = "pear" },
	db2.VarList{ size = 3 , key = "meme" , schema = {
		db2.UnsignedInt{ size = 3 , key = "banana" },
		db2.VarChar{ size = 120 , key = "nope" },
	} },
	db2.FixedList{ size = 3 , key = "owo" , schema = {
		db2.UnsignedInt{ size = 1 , key = "lmao" }
	} },
	db2.VarChar{ size = 20 , key = "kek" },
	db2.FixedChar{ size = 5 , key = "kak" },
	db2.Float{ key = "test" },
	db2.Double{ key = "ieee754sucks" },
	db2.Bitset{ size = 14 , key = "bstest" },
	db2.VarBitset{ size = 20 , key = "vbstest" },
	db2.VarBitset{ size = 250 , key = "ltest" },
	db2.VarChar{ size = 5 , key = "endt" },
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
} , bstest = {
	true, true, false, true, false, false, true,
	false, true, false, true, false, false, true
} , vbstest = {
	true, false, true
} , ltest = lt } , {
	USE_MAGIC = false
}

local e = db2.encode( schema , source )

local d = db2.decode( { [24] = schema } , e )

local function rcheck( t , s , n )
	local f = true
	for k , v in pairs( t ) do
		if type(v) == "table" then
			if not rcheck( t[k] , s[k] , n.."."..k ) then f = false end
		elseif t[k] ~= s[k] then
			print(n.."."..k.." ("..tostring(t[k])..") ~= "..tostring(s[k]))
			f = false
		end
	end
	return f
end

print("AC = "..tostring(rcheck(d,source,"")))