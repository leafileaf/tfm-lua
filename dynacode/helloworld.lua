--[[

1 : 60 01         mov r0 , 1
3 : 61 10         mov r1 , 16
5 : 62 0A         mov r2 , 10
7 : 80 80         int 80h
9 : 7F            hlt
10: 60 00         mov r0 , 0
12: 3A            pop r2
13: 53 82 00 58   mov [r0+44],r2
17: 20            inc r0
18: 7B F8         jecxnz -8
20: 60 02         mov r0 , 2
22: 61 20         mov r1 , 32
24: 80 80         int 80h
26: 7F            hlt

]]

script = "60016110620A80807F60003A53820058207BF86002612080807F"
s2 = {}
for i = 1 , script:len() , 2 do
	s2[#s2+1] = tonumber( script:sub(i,i+1) , 16 )
end
script = string.char( table.unpack( s2 ) ) .. "\000\000\000\000\000Hello World " .. ("\000"):rep(32)

os = dyna:new( dyna.sys.tfm )

os:load( script )
os:reset()
os:exec()

function eventChatCommand( p , m )
	p = p .. "\000"
	os:event( 0x10 , p:byte( 1 , p:len() ) )
end