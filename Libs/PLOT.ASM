.model medium, basic
.386

.code
    vpage dd 13440 dup (?)

    ; SUB (X, Y, *Msk, *Img)
    ; Stack:
    ; bp + 16: X
    ; bp + 14: Y
    ; bp + 12: Msk Segment
    ; bp + 10: Msk Offset
    ; bp + 08: Img Segment
    ; bp + 06: Img Offset
    ; bp + 04: Return Segment
    ; bp + 02: Return Offset
    ; bp + 00: old ds
    public putx
    putx proc far
	push  bp
	mov   bp, sp

	mov   di, offset vpage
	mov   dx, word ptr ss:[bp + 14]
	xchg  dh, dl
	add   di, dx
	shr   dx, 02
	add   di, dx
	add   di, word ptr ss:[bp + 16]

	mov   fs, word ptr ss:[bp + 12]
	mov   bx, word ptr ss:[bp + 10]
	mov   gs, word ptr ss:[bp + 08]
	mov   si, word ptr ss:[bp + 06]

	mov   cx, 16
    drawyloop:
	    push  cx
	    mov   cx, 04
    drawxloop:
		mov   eax, dword ptr fs:[bx]
		mov   edx, dword ptr gs:[si]

		and   dword ptr cs:[di], eax
		or    dword ptr cs:[di], edx

		add   bx, 04
		add   si, 04
		add   di, 04
	    loopnz drawxloop
	    add  di, 304
	    pop  cx
	    dec  cx
	jnz   drawyloop

	pop   bp
	retf  12
    putx endp

    ; SUB (X%, Y%, C%)
    ; Stack:
    ; bx + 08: X%
    ; bx + 06: Y%
    ; bx + 04: C%
    ; bx + 02: Return Segment
    ; bx + 00: Return Offset
    public plot
    plot proc far
	mov   bx, sp

	mov   di, offset vpage
	mov   dx, word ptr ss:[bx + 06]
	xchg  dh, dl
	add   di, dx
	shr   dx, 02
	add   di, word ptr ss:[bx + 08]
	add   di, dx

	mov   bh, byte ptr ss:[bx + 04]

	mov   byte ptr cs:[di], bh

	retf  06
    plot endp

    ; SUB ()
    public clrscr
    clrscr proc far
	xor   eax, eax
	mov   cx, 13440

	push  cs
	pop   es
	mov   edi, offset vpage

	rep   stosd
	retf
    clrscr endp

    ; SUB ()
    public dump
    dump proc far
	push  ds

	cld

	push  cs
	pop   ds
	mov   esi, offset vpage

	mov   ax, 0A000h
	mov   es, ax
	mov   edi, 2560

	mov   cx, 13440

	rep   movsd

	pop   ds
	retf
    dump endp
end
