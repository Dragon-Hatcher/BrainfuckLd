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


;control flow ------------------------------------------------------------------

cur_jmp_id = 0

off: 				db false
terminate: 	db false
jmp_target: db 0

; these vars contain the correct value if execution is on
;  otherwise they contain dummy values
inc_table_dum:  dl inc_table		
dec_table_dum:  dl dec_table
jmp_target_dum: dl jmp_target

macro turn_on_if_a
; enables execution if a = true
	ld hl, dummy_block 
	ld (test_block  + 0), hl
	ld hl, test_block 
	ld (test_block  + 3), hl
	ld hl, inc_table 
	ld (test_block  + 6), hl 
	ld hl, dec_table 
	ld (test_block  + 9), hl
	ld hl, jmp_target 
	ld (test_block + 12), hl
	ld hl, same_table
	ld (dummy_block + 6), hl
	ld (dummy_block + 9), hl
	ld hl, dummy_block
	ld (dummy_block + 12), hl
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
	;-----------------; setup jmp_target_dum
	ld l, 12
	ld bc, (hl)				
	ld (jmp_target_dum), bc
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
	ld hl, test_block 
	ld (test_block  + 0), hl
	ld hl, dummy_block 
	ld (test_block  + 3), hl
	ld hl, inc_table 
	ld (test_block  + 6), hl 
	ld hl, dec_table 
	ld (test_block  + 9), hl
	ld hl, jmp_target 
	ld (test_block + 12), hl
	ld hl, same_table
	ld (dummy_block + 6), hl
	ld (dummy_block + 9), hl
	ld hl, dummy_block
	ld (dummy_block + 12), hl
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
	;-----------------; setup jmp_target_dum
	ld l, 12
	ld bc, (hl)				
	ld (jmp_target_dum), bc
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

macro terminate_if_on
	ld hl, (stack_p0)
	ld (test_block + 0), hl
	ld (test_block + 3), sp
	ld hl, test_block
	ld a, (off)
	ld l, a
	ld hl, (hl)
	ld (test_block), hl		
	ld sp, (test_block) 	;the final ret will now exit the program if we were on
end macro

macro jmp_if_a to
; jumps to the given location if a = true and we are on
; args:
;  a : whether to jump
; returns:
;  n/a
	ld hl, dummy_block
	ld (test_block + 0), hl
	ld hl, (jmp_target_dum)
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
		
	; turn on if a
	turn_on_if_a	
end macro

macro call_if_a adr
	; calls an adress if a = true
	ld d, a

	ld hl, dummy_block                 ;(stack_p2) = adr
	ld (test_block + 0), hl    
	ld hl, (stack_p2)
	ld (test_block + 3), hl
	ld hl, test_block
	ld a, (off)
	ld l, a
	ld bc, dummy_block
	ld (hl), bc
	ld l, d
	ld hl, (hl)
	ld bc, adr
	ld (hl), bc

	ld hl, (stack_p1)
	ld (test_block + 0), hl
	ld hl, (stack_p2)
	ld (test_block + 3), hl
	ld hl, test_block
	;ld a, (off)          ;already done
	ld l, a
	ld bc, (stack_p1)
	ld (hl), bc
	ld l, d
	ld hl, (hl)
	ld (test_block), hl
	ld sp, (test_block)

	ld a, d                             ; jmp_dest x
	jmp_dest cur_jmp_id	
	ld a, d                             ; ld_jmp x
	jmp_if_a cur_jmp_id
	
	cur_jmp_id = cur_jmp_id + 1
end macro

;------------------------------------------------------------------------------


;inc/dec ----------------------------------------------------------------------

mem_pointer: dl $D100FF;mem_block

macro inc_mem_pointer
; 24 bit increments the mem pointer
	ld hl, (inc_table_dum)
	ld a, (mem_pointer)
	ld l, a
	ld a, (hl)
	ld (mem_pointer), a
	
	;----------
	
	ld a, (mem_pointer + 1)
	ld (test_block + $00), a            ;test_block + $00	
	ld hl, (inc_table_dum)
	ld a, (mem_pointer + 1)
	ld l, a
	ld d, (hl)	;d contains (mem_pointer + 1) + 1
	ld hl, test_block
	ld a, (mem_pointer + 0)
	ld l, a
	ld (hl), d
	ld a, (test_block + $00)
	ld (mem_pointer + 1), a

	;----------

	;ld a, (mem_pointer + 2)
	;ld (test_block + $00), a            ;test_block + $00	
	;ld hl, (inc_table_dum)
	;ld a, (mem_pointer + 2)
	;ld l, a
	;ld d, (hl)	;d contains (mem_pointer + 1) + 1
	;ld hl, test_block
	;ld a, (mem_pointer)
	;ld l, a
	;ld (hl), d
	;ld a, (test_block + $00)
	;ld (mem_pointer + 2), a
	
end macro

macro dec_mem_pointer
; 24 bit decrements the mem pointer
	ld hl, (dec_table_dum)
	ld a, (mem_pointer)
	ld l, a
	ld a, (hl)
	ld (mem_pointer), a
	
	;----------
	
	ld a, (mem_pointer + 1)
	ld (test_block + $FF), a            ;test_block + $FF
	ld hl, (dec_table_dum)
	ld a, (mem_pointer + 1)
	ld l, a
	ld d, (hl)	;d contains (mem_pointer + 1) + 1
	ld hl, test_block
	ld a, (mem_pointer + 0)
	ld l, a
	ld (hl), d
	ld a, (test_block + $FF)
	ld (mem_pointer + 1), a

	;----------

	;ld a, (mem_pointer + 2)
	;ld (test_block + $FF), a            ;test_block + $FF
	;ld hl, (dec_table_dum)
	;ld a, (mem_pointer + 2)
	;ld l, a
	;ld d, (hl)	;d contains (mem_pointer + 1) + 1
	;ld hl, test_block
	;ld a, (mem_pointer + 1)
	;ld l, a
	;ld (hl), d
	;ld a, (test_block + $FF)
	;ld (mem_pointer + 2), a
	
end macro

macro inc_hl_p
; increments the byte pointed to by hl when on
	ld bc, (inc_table_dum)
	ld a, (hl)
	ld c, a
	ld a, (bc)
	ld (hl), a
end macro

macro dec_hl_p
; decrements the byte pointed to by hl when pn
	ld bc, (dec_table_dum)
	ld a, (hl)
	ld c, a
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
				
code_start:
	add_code_start_to_stack

	open_debugger

	ld hl, mem_pointer

	inc_mem_pointer
	
	terminate_if_on
	ret
	