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

; these vars contain the correct value if execution is on
;  otherwise they contain dummy values
inc_table_dum: dl inc_table		
dec_table_dum: dl dec_table

macro turn_on_if_a
; enables execution if a = true
	ld hl, dummy_block ;ed
	ld (test_block  + 0), hl
	ld hl, test_block ;eb
	ld (test_block  + 3), hl
	ld hl, inc_table ;ab
	ld (test_block  + 6), hl 
	ld hl, dec_table ;ac
	ld (test_block  + 9), hl
	ld hl, same_table ;ad
	ld (dummy_block + 6), hl
	ld (dummy_block + 9), hl
	;-----------------; load dummy or real block
	ld hl, test_block
	ld l, a
	ld hl, (hl)				;
	;-----------------; setup inc_table_dum
	ld l, 6
	ld bc, (hl)				
	ld (inc_table_dum), bc
	;-----------------; setup dec_table_dum
	ld l, 9
	ld bc, (hl)				
	ld (dec_table_dum), bc
	;-----------------; setup off
	ld d, a
	ld a, true
	ld (test_block + 0), a
	ld a, false
	ld (test_block + 3), a
	ld hl, test_block
	ld l, d
	ld a, (hl)
	ld (off), a
end macro


macro turn_off_if_a
; disables execution if a = true
	ld hl, test_block ;eb
	ld (test_block  + 0), hl
	ld hl, dummy_block ;ed
	ld (test_block  + 3), hl
	ld hl, inc_table ;ab
	ld (test_block  + 6), hl 
	ld hl, dec_table ;ac
	ld (test_block  + 9), hl
	ld hl, same_table ;ad
	ld (dummy_block + 6), hl
	ld (dummy_block + 9), hl
	;-----------------; load dummy or real block
	ld hl, test_block
	ld l, a
	ld hl, (hl)				;
	;-----------------; setup inc_table_dum
	ld l, 6
	ld bc, (hl)				
	ld (inc_table_dum), bc
	;-----------------; setup dec_table_dum
	ld l, 9
	ld bc, (hl)				
	ld (dec_table_dum), bc
	;-----------------; setup off
	ld hl, off
	ld (hl), a
end macro


macro add_code_start_to_stack
	; adds code_start to the stack at stack_p1
	ld hl, (stack_p1)
	ld bc, code_start
	ld (hl), bc
	ld sp, (stack_p1)
end macro

macro terminate_if_a
	turn_off_if_a
	ld sp, (stack_p0) 	;the final ret will now exit the program
end macro

macro jmp_if_a to
; jumps to the given location if a = true
; args:
;  a : whether to jump
; returns:
;  n/a
	ld hl, dummy_block
	ld (test_block + 0), hl
	ld hl, jmp_target
	ld (test_block + 3), hl
	ld hl, test_block
	ld l, a
	ld hl, (hl)
	ld (hl), to
	turn_off_if_a
end macro

macro jmp_dest id
; if jmp_target = id enable execution
	ld a, 0
	ld (test_block), a
	ld a, false
	ld (test_block + id), a
	ld a, (jmp_target)
	ld hl, test_block
	ld l, a
	ld (hl), true
	ld a, (test_block + id) ;a = id == jmp_target
	ld (test_block), a			;test_block[0] contains id == jmp
	ld hl, test_block
	ld a, (off)
	ld l, a
	ld (hl), true   				;if we were on we wrote true to test_block[0]
	ld a, (test_block)
	
	; unconditionally turn off	
	ld hl, inc_table
	ld (inc_table_dum), hl
	ld hl, dec_table
	ld (dec_table_dum), hl
	ld hl, off
	ld (hl), true
	
	; turn on if a
	turn_on_if_a	
end macro

macro call_if_a adr
	; calls an adress if a = true
	
	; jmp_dest x
	;   stack_p2 = adr  
	;   sp = stack_p2
	; 	ld_jmp x
	
	cur_jmp_id = cur_jmp_id + 1
end macro

;------------------------------------------------------------------------------


;inc/dec ----------------------------------------------------------------------

macro inc_hl_p ;x
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

macro dec_hl_p ;x
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

stack_p0: dl 0
stack_p1: dl 0
stack_p2: dl 0
stack_xx: dl 0

macro init_stacks
	ld (stack_p0), sp
	plus_one_init stack_p0, stack_p1
	plus_one_init stack_p1, stack_xx
	plus_one_init stack_xx, stack_p1

	plus_one_init stack_p1, stack_p2
	plus_one_init stack_p2, stack_xx
	plus_one_init stack_xx, stack_p2
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

	;add_code_start_to_stack

	ld a, true
	jmp_if_a $0A
	
	nop
	nop
	nop
	
	jmp_dest $0B

	;ld a, true
	;terminate_if_a

	ret
	