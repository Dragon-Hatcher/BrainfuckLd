include 'ti84pceg.inc'

false := 0
true  := 3

first_block := $D0EB00
block_size 	:= $100

test_block  := first_block + block_size * 0
dummy_block := first_block + block_size * 2
mem_block		:= first_block + block_size * 4


;math tables ----------------------------------------------------------------------

rb (-$) and $FF
inc_table:  make_inc_table
dec_table:  make_dec_table
same_table: make_same_table

macro make_inc_table
	repeat 255
		db %
	end repeat
	db 0
end macro

macro make_dec_table
	db $FF
	repeat 255
		db % - 1
	end repeat
end macro

macro make_same_table
	repeat 256
		db % - 1
	end repeat
end macro

;------------------------------------------------------------------------------


;conditionals -----------------------------------------------------------------

macro offset_hl base, offset
; puts a pointer in hl using a <256 byte offset and a base % 256
	ld hl, base
	ld l, offset
end macro

macro hl_p_is_zero
; returns if (hl) = 0
; args:
;  (hl) : the byte to check if it zero
; return:
;  a : if (hl) = 0
; destroyed:
;  bc
	ld a, false
	ld (test_block), a
	ld bc, test_block
	ld c, (hl)
	ld a, true
	ld (bc), a
	ld a, (test_block)
end macro

macro is_correct_block block
; tests if the given block is the block we are searching for
; args:
;  block : the block we are checking against
; return:
;  a : block = (jmp_loc)
; destroyed:
;  bc
	ld a, false
	ld (test_block + block), a
	ld bc, test_block
	ld c, (jmp_loc)
	ld a, true
	ld (bc), a
	ld a, (test_block + block)
end macro

macro select_pointer p1, p2
; returns p1 if a = false or p2 when a = true
; args:
;  a : which pointer to select
; return:
;  hl : the selected pointer
	ld hl, p1
	ld (test_block), hl
	ld hl, p2
	ld (test_block + true), hl
	ld hl, test_block
	ld l, a
	ld hl, (hl)
end macro

macro select_pointer_bc p1, p2
; returns p1 if a = false or p2 when a = true
; args:
;  a : which pointer to select
; return:
;  bc : the selected pointer
; destroyes:
;  de
	ld d, h
	ld e, l
	ld hl, p1
	ld (test_block), hl
	ld hl, p2
	ld (test_block + true), hl
	ld hl, test_block
	ld l, a
	ld bc, (hl)
	ld h, d
	ld l, e
end macro


;------------------------------------------------------------------------------


;control flow ------------------------------------------------------------------

cur_jmp_id = 0

off: 				db false
terminate: 	db false
jmp_target: db 0

inc_table_dum: dl inc_table
dec_table_dum: dl dec_table

macro turn_on_if_a
; enables execution if a = true
	ld (test_block  + 0), dummy_block
	ld (test_block  + 3), test_block
	ld (test_block  + 6), inc_table
	ld (test_block  + 9), dec_table
	ld (dummy_block + 6), same_table
	ld (dummy_block + 9), same_table
	;-----------------; setup inc_table_dum
	ld hl, test_block
	ld l, a
	ld hl, (hl)				;load dummy or real block
	ld l, 6
	ld bc, (hl)				;find inc_table or same_table
	ld hl, inc_table_dum
	ld (hl), bc
	;-----------------; setup dec_table_dum
	ld hl, test_block
	ld l, a
	ld hl, (hl)				;load dummy or real block
	ld l, 9
	ld bc, (hl)				;find dec_table or same_table
	ld hl, dec_table_dum
	ld (hl), bc
	;-----------------; setup off
	ld (test_block + 0), true
	ld (test_block + 3), false
	ld hl, test_block
	ld l, a
	ld b, (hl)
	ld hl, off
	ld (hl), b
end macro

macro turn_off_if_a
; disables execution if a = true
	ld (test_block  + 0), test_block
	ld (test_block  + 3), dummy_block
	ld (test_block  + 6), inc_table
	ld (test_block  + 9), dec_table
	ld (dummy_block + 6), same_table
	ld (dummy_block + 9), same_table
	;-----------------; setup inc_table_dum
	ld hl, test_block
	ld l, a
	ld hl, (hl)				;load dummy or real block
	ld l, 6
	ld bc, (hl)				;find inc_table or same_table
	ld hl, inc_table_dum
	ld (hl), bc
	;-----------------; setup dec_table_dum
	ld hl, test_block
	ld l, a
	ld hl, (hl)				;load dummy or real block
	ld l, 9
	ld bc, (hl)				;find dec_table or same_table
	ld hl, dec_table_dum
	ld (hl), bc
	;-----------------; setup off
	ld hl, off
	ld (hl), a
end macro

macro jmp_if_a to
; jumps to the given location if a = true
; args:
;  a : whether to jump
; returns:
;  n/a
	ld (hl), a  ;if a is true we will be stoppped
	ld a, to
	ld (jmp_loc), a
end macro

macro call_if_a adr
	; calls an adress if a = true
	
	; running = false
	; stack_p1 = code_start
	; stack_p2 = adr
	; sp = stack_p2
	
	cur_jmp_id = cur_jmp_id + 1
end macro

;------------------------------------------------------------------------------


;inc/dec ----------------------------------------------------------------------

macro inc_hl_p
; increments the byte pointed to by hl (unless jumping)
; args:
;	 (hl) : the byte to increment
; return:
;  n/a
; destroyed:
;  bc, a
	ld a, (jumping)
	select_pointer_bc inc_block, same_block
	ld c, (hl)
	ld a, (bc)
	ld (hl), a
end macro

macro dec_hl_p
; decrements the byte pointed to by hl (unless jumping)
; args:
;	 (hl) : the byte to decrement
; return:
;  n/a
; destroyed:
;  bc, a
	ld a, (jumping)
	select_pointer_bc dec_block, same_block
	ld c, (hl)
	ld a, (bc)
	ld (hl), a
end macro

;------------------------------------------------------------------------------


;stack ------------------------------------------------------------------------

stack_p0: dl $D1A800
stack_p1: dl 0
stack_p2: dl 0

macro init_stacks
	;ld (stack_p0), sp
	plus_one_init stack_p0, stack_p1
	plus_one_init stack_p1, stack_p2
end macro

macro plus_one_init from, to
	ld hl, dec_table
	ld a, (from + 0)
	ld l, a
	ld a, (hl)
	ld (to + 0), a			; inc least sig byte
	ld hl, from + 0 		
	ld hl, test_block + $FF
	ld bc, same_table
	ld (hl), bc
	ld a, (to + 0)
	ld l, a
	ld bc, dec_table
	ld (hl), bc
	ld hl, test_block + $FF
	ld hl, (hl)					; hl contains same/dec_table depending on if we
											;  should dec second byte
	ld a, (from + 1)
	ld l, a
	ld a, (hl)
	ld (to + 1), a			; inc second byte
	ld hl, test_block + $FF
	ld bc, same_table
	ld (hl), bc
	ld l, a							; a contains (to + 1)
	ld bc, dec_table
	ld (hl), bc
	ld hl, test_block + $FF
	ld hl, (hl)					; hl contains same/dec_table depending on if we
											;  should dec third byte
	ld a, (from + 2)
	ld l, a
	ld a, (hl)
	ld (to + 2), a			; inc second byte
end macro

;------------------------------------------------------------------------------


macro open_debugger
	scf
	sbc    hl,hl
	ld     (hl),2
end macro

jumping:  db false
jmp_loc: 	db 0

public _main
_main:
	init_stacks
	open_debugger
code_start:
	ret
	