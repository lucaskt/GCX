.model medium, basic
.386

.code
    oldint9 dd 0
    keybuff db 128 dup (?)

    ; SUB ()
    public installkeyb
    installkeyb proc far
	cmp   dword ptr cs:[oldint9], 0
	jnz   installkeybexit

	xor   ax, ax
	mov   es, ax
	mov   bx, offset keybhandler
	cli
	mov   eax, dword ptr es:[36]
	mov   word ptr es:[36], bx
	mov   word ptr es:[38], cs
	sti
	mov   dword ptr cs:[oldint9], eax

	mov   ax, cs
	mov   es, ax
	mov   cx, 32

	xor   eax, eax
	mov   edi, offset keybuff

	rep   stosd

    installkeybexit:
	retf
    installkeyb endp

    ; SUB ()
    public uninstallkeyb
    uninstallkeyb proc far
	cmp   dword ptr cs:[oldint9], 0
	jz    uninstallkeybexit

	xor   ax, ax
	mov   es, ax
	mov   eax, dword ptr cs:[oldint9]
	cli
	mov   dword ptr es:[36], eax
	sti

	mov   dword ptr cs:[oldint9], 0

    uninstallkeybexit:
	retf
    uninstallkeyb endp

    ; SUB (KeyNum%)
    ; Stack:
    ; bp + 06: KeyNum%
    ; bp + 04: Return Segment
    ; bp + 02: Return Offset
    ; bp + 00: Old bp
    public keydown
    keydown proc far
	push  bp
	mov   bp, sp

	mov   bx, word ptr ss:[bp + 06]
	and   bx, 7Fh

	xor   ah, ah
	mov   al, byte ptr cs:[keybuff + bx]

	pop   bp
	retf  02
    keydown endp

    ; Callback
    keybhandler proc far
	push  ax
	push  bx

	xor   ah, ah
	in    al, 60h

	mov   bx, ax
	and   bx, 7Fh

	test  al, al
	js    keybhandlerbreak

	mov   al, -1
	jmp   keybhandlerexit

  keybhandlerbreak:
	xor   al, al

  keybhandlerexit:
	mov   byte ptr cs:[keybuff + bx], al

	pop   bx
	pop   ax
	jmp   dword ptr cs:[oldint9]
    keybhandler endp
end
