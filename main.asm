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
ascii_conversion:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $D6, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $20, $21, $22, $23, $00, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $C1, $5C, $5D, $5E, $5F, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E, $00
	repeat 128
		db % + 127
	end repeat

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

cur_jmp_id = $EE

off: 				db false
terminate: 	db false
jmp_target: db 0
a_call_arg: db 0
write_a:    db false

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

	ld (test_block + 3), a  ;if we are off set a to true
	ld hl, test_block
	ld a, (off)
	ld l, a
	ld (hl), true
	ld a, (test_block + 3)
	
	turn_off_if_a
	
end macro

macro jmp_dest id
; if jmp_target = id enable execution

	ld a, id
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
		
	turn_on_if_a	

end macro

macro call_if_a adr
	; calls an adress

	ld hl, (stack_p2)                 ;(stack_p2) = adr
	ld (test_block + 0), hl    
	ld hl, dummy_block
	ld (test_block + 3), hl
	ld hl, test_block
	ld a, (off)
	ld l, a
	ld hl, (hl)
	ld bc, adr
	ld (hl), bc

	ld hl, (stack_p2)
	ld (test_block + 0), hl
	ld (test_block + 3), sp
	ld hl, test_block
	ld l, a
	ld hl, (hl)
	ld (test_block), hl
	ld sp, (test_block)

	ld a, true              ; 
	jmp_if_a cur_jmp_id	- 0 ;>+
	jmp_dest cur_jmp_id - 1 ;<+-+
	ld a, true              ; | |
	jmp_if_a cur_jmp_id - 2 ;>+-+-+
	jmp_dest cur_jmp_id - 0 ;<+ | |
	ld a, true              ;   | |
	jmp_if_a cur_jmp_id - 1 ;>--+ |
	jmp_dest cur_jmp_id - 2 ;<----+
	
	cur_jmp_id = cur_jmp_id - 3
end macro

macro mem_pointer_is_0
	ld a, false
	ld (test_block), a
	ld hl, (mem_pointer)
	ld a, (hl)
	ld hl, test_block
	ld l, a
	ld a, true
	ld (hl), a
	ld a, (test_block)
end macro

macro maybe_write_a
	ld d, a
	ld hl, dummy_block
	ld (test_block + 0), hl
	ld hl, (mem_pointer)
	ld (test_block + 3), hl
	ld hl, test_block
	ld a, (write_a)
	ld l, a
	ld hl, (hl)
	ld (hl), d
	ld a, false
	ld (write_a), a
end macro

;------------------------------------------------------------------------------


;inc/dec ----------------------------------------------------------------------

mem_pointer: dl mem_block

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

	ld hl, (mem_pointer)
	ld (mem_block - 3), hl


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

	ld hl, (mem_pointer)
	ld (mem_block - 3), hl

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


;commands ---------------------------------------------------------------------

macro bf_plus
	ld hl, (mem_pointer)
	inc_hl_p
end macro

macro bf_minus
	ld hl, (mem_pointer)
	dec_hl_p
end macro

macro bf_left
	dec_mem_pointer
end macro

macro bf_right
	inc_mem_pointer
end macro

macro bf_period
	call_if_a ti.PutC
	ld hl, (mem_pointer)
	ld a, (hl)
	ld (a_call_arg), a
end macro

macro bf_comma
	ld a, true
	ld (test_block + 0), a
	ld a, (write_a)
	ld (test_block + 3), a
	ld hl, test_block
	ld a, (off)
	ld l, a
	ld a, (hl)
	ld (write_a), a
	call_if_a ti.GetKey
end macro

top_id = 0
bracket_ids =: 0

macro bf_open_b
	bracket_ids =: top_id

	display '['
	repeat 1, value: top_id, value2: bracket_ids
	display `value, '|', `value2, 10
	end repeat

	jmp_dest top_id + 0   ;<-- This destination triggers the bf_period loop around
	mem_pointer_is_0
	jmp_if_a top_id + 1
	
	top_id = top_id + 2
end macro

macro bf_close_b

	display ']'
	repeat 1, value: bracket_ids
	display `value, 10
	end repeat

	ld a, true
	jmp_if_a bracket_ids + 0
	jmp_dest bracket_ids + 1

	restore bracket_ids
	
end macro

calminstruction bf commands&
loop:
	match =+ commands?, commands
	jyes plus
	match =- commands?, commands
	jyes minus
	match =< commands?, commands
	jyes left
	match => commands?, commands
	jyes right
	match =[ commands?, commands
	jyes enter
	match =] commands?, commands
	jyes leave
	match =. commands?, commands
	jyes output
	match =, commands?, commands
	jyes input
	match commands commands?, commands
	jyes loop
	exit
plus:
	execute =bf_plus
	jump loop
minus:
	execute =bf_minus
	jump loop
left:
	execute =bf_left
	jump loop
right:
	execute =bf_right
	jump loop
enter:
	execute =bf_open_b
	jump loop
leave:
	execute =bf_close_b
	jump loop
output:
	execute =bf_period
	jump loop
input:
	execute =bf_comma
	jump loop
end calminstruction
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

	;open_debugger

	maybe_write_a
	add_code_start_to_stack
	
	bf +++++++++++\
>+>>>>++++++++++++++++++++++++++++++++++++++++++++\
>++++++++++++++++++++++++++++++++<<<<<<[>[>>>>>>+>\
+<<<<<<<-]>>>>>>>[<<<<<<<+>>>>>>>-]<[>++++++++++[-\
<-[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<[>>>+<<<\
-]>>[-]]<<]>>>[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]\
>[<<+>>[-]]<<<<<<<]>>>>>[+++++++++++++++++++++++++\
+++++++++++++++++++++++.[-]]++++++++++<[->-<]>++++\
++++++++++++++++++++++++++++++++++++++++++++.[-]<<\
<<<<<<<<<<[>>>+>+<<<<-]>>>>[<<<<+>>>>-]<-[>>.>.<<<\
[-]]<<[>>+>+<<<-]>>>[<<<+>>>-]<<[<+>-]>[<+>-]<<<-]	
	terminate_if_on	
	
;	open_debugger
	
	ld hl, ascii_conversion
	ld a, (a_call_arg)	
	ld l, a
	ld a, (hl)
	
	ret