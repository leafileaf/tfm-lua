--[[

	Calculates the Nth fibonacci number.
	
	Input: n = %eax
	Output:  = %eax
	
	push ebx
	push ecx
	mov ecx , eax
	dec ecx
	jz +10
	mov eax , 1
	mov ebx , 0
	xchg eax , ebx
	add eax , ebx
	loop -6
	pop ecx
	pop ebx
	hlt

]]

--script = "\x31\x32\x78\x02\x2A\x44\x0A\x60\x01\x61\x00\x51\x08\x01\x08\x5E\xFA\x3A\x39\x7F"
script = "\049\050\120\002\042\068\010\096\001\097\000\081\008\001\008\094\250\058\057\127"

os = dyna:new( dyna.sys.tfm )
os:load( script )
os:reset()
os.__r[0] = 59
os:exec()

--[[

	Increments 65025 times.
	
	mov eax , 255
	mov edx , eax
	mul
	mov ecx , eax
	mov eax , 0
	inc eax
	loop -3
	hlt

]]

--script = "\x60\xFF\x78\x03\x70\x78\x02\x60\x00\x20\x5E\xFD\x7F"
script = "\096\255\120\003\112\120\002\096\000\032\094\253\127"