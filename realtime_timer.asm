.include "m128def.inc"
								; cooling chamber 	- cc
								; freezing chamber 	- fc
.def temp		= r16			; temporary buffer register
.def temp2		= r17			; temporary buffer #2 register (for or/and ops, etc)
.def sreg_temp	= r18			; temporary buffer for SREG
.def flag_temp	= r19			; temporary buffer for current byte of flags
.def flag_temp2 = r20
.def key_id 	= r21			; buffer for key id (temp select/humidity select...)
.def key_val	= r22			; buffer for key value (for numeric keys)
; r23
; ...
; r27
.def cnt_sec_l	= r0			; seconds count (ones)
.def cnt_sec_h	= r1			; seconds count (decimals)
.def cnt_mnt_l	= r2			; minutes count (ones)
.def cnt_mnt_h	= r3			; minutes count (decimals)
.def cnt_hours	= r4			; hours count (common counter)
.def cnt_hours_l= r5			; hours count (ones)
.def cnt_hours_h= r6			; hours count (decimals)
.def cnt_100ms	= r7			; 100ms count (common for realtime timer)
; r8
; ...
; r15
.org 0x00						; reset vector
	jmp start
.org 0x1c						; t/c1 ovf vector
	jmp inttc1					
.org 0x36						; first cseg address (no not interfere with interrupt vectors)
start:
	ldi temp,	LOW(RAMEND)
	out spl,	temp			; move stack pointer (lower part)
	ldi temp,	HIGH(RAMEND)
	out sph,	temp			; move stack pointer (higher part)
	call restore_ptrs			; set flag base pointer (YH, YL), pt base pointer (ZH, ZL)
	call flags_init				; set all flags to 0
	call timers_init			; set timers to initial values
	call ports_init				; set ports data direction registers to initial values
	ldi temp,	0x04
	out timsk, 	temp			; enable local interrupt by t/c1 overflow
	call tc1restore				; set timer/counter 1 (16-byte clk/1024 prescaler ~100ms @16MHz, ~200ms @4Mhz)
	sei	
background:
; first flag byte fetch
	ldd flag_temp,	y+0
; analyze flag bytes
	sbrc flag_temp,	7			; F1
		nop
	sbrc flag_temp, 6			; F3
		nop
	sbrc flag_temp, 5			; F5
		call analyze_command
	sbrc flag_temp, 4			; F6
		nop
	sbrc flag_temp, 3			; F8
		nop
	sbrc flag_temp, 2			; F10
		nop
	sbrc flag_temp, 1			; F11
		nop
	sbrc flag_temp, 0			; F12
		nop
; second flag byte fetch
	ldd flag_temp,	y+1
; analyze flag bytes
	sbrc flag_temp,	7			; F13
		nop
	sbrc flag_temp, 6			; F14
		nop
	sbrc flag_temp, 5			; F19
		nop
	sbrc flag_temp, 4			; F20
		nop
	sbrc flag_temp, 3			; F21
		call red_light_en
	sbrc flag_temp, 2			; F22
		nop
	sbrc flag_temp, 1			; F23
		nop
	sbrc flag_temp, 0			; F26
		nop
; third flag byte fetch
	ldd flag_temp,	y+2
; analyze flag bytes
	sbrc flag_temp,	7			; F27
		nop
	sbrc flag_temp, 6			; F28
		nop
	sbrc flag_temp, 5			; F29
		nop
	sbrc flag_temp, 4			; F30
		nop
	sbrc flag_temp, 3			; F31
		nop
	sbrc flag_temp, 2			; F32
		nop
	sbrc flag_temp, 1			; F33
		nop
	sbrc flag_temp, 0			; FT
		nop
; fourth flag byte fetch
	ldd flag_temp,	y+3
; analyze flag bytes
	sbrc flag_temp,	7			; T1
		call mbt
	sbrc flag_temp, 6			; PT2
		nop
	sbrc flag_temp, 5			; PT3
		nop
	sbrc flag_temp, 4			; PT4
		nop
	sbrc flag_temp, 3			; PT5
		nop
	sbrc flag_temp, 2			; F35
		nop
	sbrc flag_temp, 1			; F36
		nop
	sbrc flag_temp, 0			; F34
		nop
; fifth flag byte fetch
	ldd flag_temp,	y+4
; analyze flag bytes
	sbrc flag_temp,	7			; F37
		nop
	sbrc flag_temp, 6			; F38
		nop
	sbrc flag_temp, 5			; PT6
		nop
	sbrc flag_temp, 4			; PT7
		nop
	sbrc flag_temp, 3			; F39
		nop
	sbrc flag_temp, 2			; PT8
		nop
	sbrc flag_temp, 1			; PT9
		nop
	sbrc flag_temp, 0			; F40
		nop
; sixth flag byte fetch
	ldd flag_temp,	y+5
; analyze flag bytes
	sbrc flag_temp,	7			; F41
		call cc_light_en
	sbrc flag_temp, 6			; PT10
		nop
	sbrc flag_temp, 5			; F42
		call cc_mode_change_exp
	sbrc flag_temp, 4			; F43
		call cc_light_en
	sbrc flag_temp, 3			; PT11
		nop
	sbrc flag_temp, 2			; F44
		call cc_temp_change_exp
	sbrc flag_temp, 1			; PT12
		nop
	sbrc flag_temp, 0			; F45
		call cc_light_en
; seventh flag byte fetch
	ldd flag_temp,	y+6
; analyze flag bytes
	sbrc flag_temp,	7			; PT13
		nop
	sbrc flag_temp, 6			; F46
		call cc_hum_change_exp
	sbrc flag_temp, 5			; F47
		call cc_light_en
	sbrc flag_temp, 4			; F48
		call cc_pres_change_exp
	sbrc flag_temp, 3			; F49
		nop
	sbrc flag_temp, 2			; F50
		nop
	sbrc flag_temp, 1			; F51
		nop
	sbrc flag_temp, 0			; F52
		nop
; eighth flag byte fetch
	ldd flag_temp,	y+7
; analyze flag bytes
	sbrc flag_temp,	7			; F53
		nop
	sbrc flag_temp, 6			; F54
		call fc_light_en
	sbrc flag_temp, 5			; F55
		call fc_mode_change_exp
	sbrc flag_temp, 4			; PT14
		nop
	sbrc flag_temp, 3			; F56
		call fc_light_en
	sbrc flag_temp, 2			; F57
		call fc_temp_change_exp
	sbrc flag_temp, 1			; PT15
		nop
	sbrc flag_temp, 0			; F58
		call fc_light_en
; ninth flag byte fetch
	ldd flag_temp,	y+8
; analyze flag bytes
	sbrc flag_temp,	7			; F59
		call fc_hum_change_exp
	sbrc flag_temp, 6			; PT16
		nop
	sbrc flag_temp, 5			; F60
		call fc_light_en
	sbrc flag_temp, 4			; F61
		call fc_pres_change_exp
	sbrc flag_temp, 3			; PT17
		nop
	sbrc flag_temp, 2			; F62
		nop
	sbrc flag_temp, 1			; F63
		nop
	sbrc flag_temp, 0			; F64
		nop
; ninth flag byte fetch
	ldd flag_temp,	y+9
; analyze flag bytes
	sbrc flag_temp,	7			; F65
		nop
	sbrc flag_temp, 6			; F66
		nop
; jump over a cycle
	jmp background
flags_init:
	clr temp
	ldi xh,		0x01
	ldi xl,		0x00
fil: st x+, temp				; clear $100 up to $109
	cpi xl,		0x0a
	brne fil
	ret
timers_init:
	clr temp					; no timer flags set
	std y+10,	temp			; first bank FS
	std y+11,	temp			; second bank FS
	ldi temp,	0xff
	std z+0,	temp			; PT2
	ldi temp,	0xfe
	std	z+1,	temp			; PT3
	ldi temp,	0x88
	std z+2,	temp			; PT4
	std z+3,	temp			; PT5
	ldi temp,	0xec
	std z+4,	temp			; PT6
	std z+5,	temp			; PT7
	std z+6,	temp			; PT8
	std z+7,	temp			; PT9
	ldi temp,	0xf6
	ldi xh,		0x01
	ldi xl,		0x14
til:st x+,		temp			; clear $114 up to 11b
	cpi xl,		0x1c
	brne til
	ldi temp,	0xf6
	mov cnt_100ms,	temp		; cnt_100ms
	ret
ports_init:
	ldi temp,	0x3f			; 0..5 bits for Write, 6..7 for read
	out ddra,	temp
	ldi temp,	0xff
	ret
inttc1:
	push temp
	ldd temp,	y+3				; load fourth byte of flags
	ori temp,	0x80			; set T1
	std y+3,	temp			; save fourth byte of flags in memory
	call tc1restore				; restore timer/counter1 state
	pop temp
	reti
tc1restore:
	; atomic timer state set (due to datasheet)
	in temp,	tccr1b
	ldi temp2,	0x05
	neg temp2
	and temp,	temp2			; stop timer
	out tccr1b,	temp			; set contolling frequency to the (no input)
	;ldi temp, 	0xf9			; for 16 MHz
	ldi temp,	0xfe			; for 4 MHz
	out tcnt1h,	temp			; load timerH
	;ldi temp,	0xe5			; for 16 MHz
	ldi temp,	0x79			; for 4 MHz
	out tcnt1l,	temp			; load timerL
	in temp, tccr1b
	ori temp,	0x05			; start timer
	out tccr1b,	temp			; set contolling frequency to the exact match f(OSC)/1024 (w/prescaler)
	ret
restore_ptrs:
	ldi yh,	0x01				; load top of flag base in memory 		(FLAGS_BASE_HIGH)
	ldi yl,		0x00			; load bottom of flag base in memory 	(FLAGS_BASE_LOW)
	ldi zh,		0x01			; load top of pt base in memory 		(PT_BASE_HIGH)
	ldi zl,		0x0c			; load bottom of pt base in memory 		(PT_BASE_LOW)
	ret
program_timers:
	ldd flag_temp2,	y+10		; FS flags first byte fetch 
fs2:sbrs flag_temp2,7
	jmp fs3
	ldd temp,		z+0			; fetch PT2
	inc temp					; increment PT2
	brbc 1,			fs2nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+1			; fetch $101 flags
	ori temp,		0x10		; set F20
	std y+1,		temp		; store $101 flags
	ldd temp,		y+3			; fetch $103 flags
	ori temp,		0x40		; set PT2 flag
	std y+3,		temp		; store $103 flags
	andi flag_temp2,0x7f		; clear FS2
	std y+10, flag_temp2		; store FS2
	ldi temp,		0xff		; reset PT2
fs2nc:std z+0,		temp		; store PT2
fs3:sbrs flag_temp2,6
	jmp fs4
	ldd temp,		z+1			; fetch PT3
	inc temp					; increment PT3
	brbc 1,			fs3nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+3			; fetch $103 flags
	ori temp,		0x20		; set PT3 flag
	std y+3,		temp		; store $103 flags
	andi flag_temp2,0xbf		; clear FS3
	std y+10, flag_temp2		; store FS3
	ldi temp,		0xfe		; reset PT3
fs3nc:std z+1,		temp		; store PT3
fs4:sbrs flag_temp2,5
	jmp fs5
	ldd temp,		z+2			; fetch PT4
	inc temp					; increment PT4
	brbc 1,			fs4nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+3			; fetch $103 flags
	ori temp,		0x10		; set PT4 flag
	std y+3,		temp		; store $103 flags
	andi flag_temp2,0xdf		; clear FS4
	std y+10, flag_temp2		; store FS4
	ldi temp,		0x88		; reset PT4
fs4nc:std z+2,		temp		; store PT4
fs5:sbrs flag_temp2,4
	jmp fs6
	ldd temp,		z+3			; fetch PT5
	inc temp					; increment PT5
	brbc 1,			fs5nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+3			; fetch $103 flags
	ori temp,		0x08		; set PT5 flag
	std y+3,		temp		; store $103 flags
	andi flag_temp2,0xef		; clear FS5
	std y+10, flag_temp2		; store FS5
	ldi temp,		0x88		; reset PT5
fs5nc:std z+3,		temp		; store PT5
fs6:sbrs flag_temp2,3
	jmp fs7
	ldd temp,		z+4			; fetch PT6
	inc temp					; increment PT6
	brbc 1,			fs6nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+4			; fetch $104 flags
	ori temp,		0x20		; set PT6 flag
	std y+4,		temp		; store $104 flags
	andi flag_temp2,0xf7		; clear FS6
	std y+10, flag_temp2		; store FS6
	ldi temp,		0xec		; reset PT6
fs6nc:std z+4,		temp		; store PT6
fs7:sbrs flag_temp2,2
	jmp fs8
	ldd temp,		z+5			; fetch PT7
	inc temp					; increment PT7
	brbc 1,			fs7nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+4			; fetch $104 flags
	ori temp,		0x10		; set PT7 flag
	std y+4,		temp		; store $104 flags
	andi flag_temp2,0xfb		; clear FS7
	std y+10, flag_temp2		; store FS7
	ldi temp,		0xec		; reset PT7
fs7nc:std z+5,		temp		; store PT7
fs8:sbrs flag_temp2,1
	jmp fs9
	ldd temp,		z+6			; fetch PT8
	inc temp					; increment PT8
	brbc 1,			fs8nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+4			; fetch $104 flags
	ori temp,		0x04		; set PT8 flag
	std y+4,		temp		; store $104 flags
	andi flag_temp2,0xfd		; clear FS8
	std y+10, flag_temp2		; store FS8
	ldi temp,		0xec		; reset PT8
fs8nc:std z+6,		temp		; store PT8
fs9:sbrs flag_temp2,0
	jmp fs10
	ldd temp,		z+7			; fetch PT9
	inc temp					; increment PT9
	brbc 1,			fs9nc		; skip reinit if no carry flag set (SREG)
	ldd temp,		y+4			; fetch $104 flags
	ori temp,		0x02		; set PT9 flag
	std y+4,		temp		; store $104 flags
	andi flag_temp2,0xfe		; clear FS9
	std y+10, flag_temp2		; store FS9
	ldi temp,		0xec		; reset PT9
fs9nc:std z+7,		temp		; store PT9
fs10:ldd flag_temp2,y+11
	sbrs flag_temp2, 7
	jmp fs11
	ldd temp,		z+8			; fetch PT10
	inc temp					; increment PT10
	brbc 1,			fs10nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+5			; fetch $105 flags
	ori temp,		0x40		; set PT10 flag
	std y+5,		temp		; store $105 flags
	andi flag_temp2,0x7f		; clear FS10
	std y+11, flag_temp2		; store FS10
	ldi temp,		0xf6		; reset PT10
fs10nc:std z+8,		temp		; store PT10
fs11:sbrs flag_temp2,6
	jmp fs12
	ldd temp,		z+9			; fetch PT11
	inc temp					; increment PT11
	brbc 1,			fs11nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+5			; fetch $105 flags
	ori temp,		0x08		; set PT11 flag
	std y+5,		temp		; store $105 flags
	andi flag_temp2,0xbf		; clear FS11
	std y+11, flag_temp2		; store FS11
	ldi temp,		0xf6		; reset PT11
fs11nc:std z+9,		temp		; store PT11
fs12:sbrs flag_temp2,5
	jmp fs13
	ldd temp,		z+10		; fetch PT12
	inc temp					; increment PT12
	brbc 1,			fs12nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+5			; fetch $105 flags
	ori temp,		0x02		; set PT12 flag
	std y+5,		temp		; store $105 flags
	andi flag_temp2,0xdf		; clear FS12
	std y+11, flag_temp2		; store FS12
	ldi temp,		0xf6		; reset PT12
fs12nc:std z+10,	temp		; store PT12
fs13:sbrs flag_temp2,4
	jmp fs14
	ldd temp,		z+11		; fetch PT13
	inc temp					; increment PT13
	brbc 1,			fs13nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+6			; fetch $106 flags
	ori temp,		0x80		; set PT13 flag
	std y+6,		temp		; store $106 flags
	andi flag_temp2,0xef		; clear FS13
	std y+11, flag_temp2		; store FS13
	ldi temp,		0xf6		; reset PT13
fs13nc:std z+11,	temp		; store PT13
fs14:sbrs flag_temp2,3
	jmp fs15
	ldd temp,		z+12		; fetch PT14
	inc temp					; increment PT14
	brbc 1,			fs14nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+7			; fetch $107 flags
	ori temp,		0x10		; set PT14 flag
	std y+7,		temp		; store $107 flags
	andi flag_temp2,0xf7		; clear FS14
	std y+11, flag_temp2		; store FS14
	ldi temp,		0xf6		; reset PT14
fs14nc:std z+12,	temp		; store PT14
fs15:sbrs flag_temp2,2
	jmp fs16
	ldd temp,		z+13		; fetch PT15
	inc temp					; increment PT15
	brbc 1,			fs15nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+7			; fetch $107 flags
	ori temp,		0x02		; set PT15 flag
	std y+7,		temp		; store $107 flags
	andi flag_temp2,0xfb		; clear FS15
	std y+11, flag_temp2		; store FS15
	ldi temp,		0xf6		; reset PT15
fs15nc:std z+13,	temp		; store PT15
fs16:sbrs flag_temp2,1
	jmp fs17
	ldd temp,		z+14		; fetch PT16
	inc temp					; increment PT16
	brbc 1,			fs16nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+8			; fetch $108 flags
	ori temp,		0x40		; set PT16 flag
	std y+8,		temp		; store $108 flags
	andi flag_temp2,0xfd		; clear FS16
	std y+11, flag_temp2		; store FS16
	ldi temp,		0xf6		; reset PT16
fs16nc:std z+14,	temp		; store PT16
fs17:sbrs flag_temp2,0
	ret
	ldd temp,		z+15		; fetch PT17
	inc temp					; increment PT17
	brbc 1,			fs17nc		; skip reinit if no carry flag set (SREG)
	ldd temp, 		y+8			; fetch $108 flags
	ori temp,		0x08		; set PT17 flag
	std y+8,		temp		; store $108 flags
	andi flag_temp2,0xfe		; clear FS17
	std y+11, flag_temp2		; store FS17
	ldi temp,		0xf6		; reset PT17
fs17nc:std z+15,	temp		; store PT17
	ret
proc_ind:
	nop
	ret
mbt:
	call proc_ind
	call program_timers
	inc cnt_100ms
	brbc 1,				rtt_reset	; skip reinit if no carry flag set (SREG)
	ldi temp,			0xf6
	mov cnt_100ms,		temp		; reinit 100ms counter
	inc cnt_sec_l
	ldi temp,			0x0a		; const 10
	cpse cnt_sec_l,		temp
		jmp rtt_reset				; if sec_l is not equal to 10 (no ovf)
	clr cnt_sec_l
	inc cnt_sec_h
	ldi temp,			0x06		; const 6
	cpse cnt_sec_h, 	temp
		jmp rtt_reset				; if sec_h is not equal to 6 (no ovf)
	clr cnt_sec_h
	inc cnt_mnt_l
	ldi temp,			0x0a		; const 10
	cpse cnt_mnt_l, 	temp
		jmp rtt_reset				; if mnt_l is not equal to 10 (no ovf)
	clr cnt_mnt_l
	inc cnt_mnt_h
	ldi temp,			0x06		; const 6
	cpse cnt_mnt_h, 	temp
		jmp rtt_reset				; if mnt_h is not equal to 6 (no ovf)
	clr cnt_mnt_h
	inc cnt_hours
	ldi temp,			0x18		; const 24
	cpse cnt_hours, 	temp
		jmp add_hours				; if hours not equal to 24
	clr cnt_hours
	clr cnt_hours_l
	clr cnt_hours_h
	jmp rtt_reset
add_hours: inc cnt_hours_l
	ldi temp,			0x0a
	cpse cnt_hours_l,	temp
		jmp rtt_reset				; if hours_l is not equal to 10 (no ovf)
	clr cnt_hours_l
	inc cnt_hours_h
rtt_reset: ldd temp,	y+3			; load $103 flags
	andi temp,			0x7f		; clear T1 flag (t/c1 ovf)
	std	y+3,			temp		; store $103 flags
	ret
analyze_command:
	cpi key_id,			0x01		; compare id with 1 (if CC mode select key has been pressed)
	brbc 1,				ac_2
	clr key_id						; clear key id register (key_id = 0)
	clr key_val						; clear key value register (key_value = 0)
	ldd temp,			y+5			; load $105 flags
	andi temp,			0x4e		; clear F41, F42, F43, F45 flags
	ori temp,			0x80		; set F41 flag
	std y+5,			temp		; store $105 flags
	ldd temp,			y+6			; load $106 flags
	andi temp,			0xdf		; clear F47 flag
	std y+6,			temp		; store $106 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x80		; set PT10 flag
	std y+11,			temp		; store $10B flags
	ret
ac_2:cpi key_id,		0x02		; compare id with 2 (if CC temp select key has been pressed)
	brbc 1,				ac_3
	clr key_id						; clear key id register (key_id = 0)
	clr key_val						; clear key value register (key_value = 0)
	ldd temp,			y+5			; load $105 flags
	andi temp,			0x7a		; clear F41, F43, F44, F45 flags
	ori temp,			0x10		; set F43 flag
	std y+5,			temp		; store $105 flags
	ldd temp,			y+6			; load $106 flags
	andi temp,			0xdf		; clear F47 flag
	std y+6,			temp		; store $106 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x40		; set PT11 flag
	std y+0,			temp		; store $10B flags
	ret
ac_3:cpi key_id,		0x03		; compare id with 3 (if CC humidity select key has been pressed)
	brbc 1,				ac_4
	clr key_id						; clear key id register (key_id = 0)
	clr key_val						; clear key value register (key_value = 0)
	ldd temp,			y+5			; load $105 flags
	andi temp,			0x6e		; clear F41, F43, F45 flags
	ori temp,			0x01		; set F45 flag
	std y+5,			temp		; store $105 flags
	ldd temp,			y+6			; load $106 flags
	andi temp,			0x9f		; clear F46, F47 flags
	std y+6,			temp		; store $106 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x20		; set PT12 flag
	std y+11, 			temp		; store $10B flags
	ret
ac_4:cpi key_id,		0x04		; compare id with 4 (if CC pressure select key has been pressed)
	brbc 1,				ac_5
	clr key_id
	clr key_val
	ldd temp,			y+5			; load $105 flags
	andi temp,			0x6e		; clear F41, F43, F45 flags
	std y+5,			temp		; store $105 flags
	ldd temp,			y+6			; load $106 flags
	andi temp,			0xef		; clear F48 flag
	ori temp,			0x20		; set F47 flag
	std y+6,			temp		; store $106 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x10		; set PT13
	std y+11, 			temp		; store $10B flags
	ret
ac_5:cpi key_id,		0x05		; compare id with 5 (if FC mode select key has been pressed)
	brbc 1,				ac_6
	clr key_id
	clr key_val
	ldd temp,			y+7			; load $107 flags
	andi temp,			0xb6		; clear F55, F56, F58 flags
	ori temp,			0x40		; set F54 flag
	std y+7,			temp		; store $107 flags
	ldd temp,			y+8			; load $108 flags
	andi temp,			0xdf		; clear F60 flags
	std y+8,			temp		; store $108 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x08		; set PT14
	std y+11, 			temp		; store $10B flags
	ret
ac_6:cpi key_id,		0x06		; compare id with 6 (if FC temperature select key has been pressed)
	brbc 1,				ac_7
	clr key_id
	clr key_val
	ldd temp,			y+7			; load $107 flags
	andi temp,			0xb2		; clear F54, F56, F57, F58 flags
	ori temp,			0x08		; set F56 flag
	std y+7,			temp		; store $107 flags
	ldd temp,			y+8			; load $108 flags
	andi temp,			0xdf		; clear F60 flags
	std y+8,			temp		; store $108 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x04		; set PT15
	std y+11, 			temp		; store $10B flags
	ret
ac_7:cpi key_id,		0x07		; compare id with 7 (if FC humidity select key has been pressed)
	brbc 1,				ac_8
	clr key_id
	clr key_val
	ldd temp,			y+7			; load $107 flags
	andi temp,			0xb6		; clear F54, F56, F58 flags
	ori temp,			0x01		; set F58 flag
	std y+7,			temp		; store $107 flags
	ldd temp,			y+8			; load $108 flags
	andi temp,			0x5f		; clear F60, F61 flags
	std y+8,			temp			; store $108 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x02		; set PT15
	std y+11,			temp		; store $10B flags
	ret
ac_8:cpi key_id,		0x08		; compare id with 8 (if FC pressure select key has been pressed)
	brbc 1,				ac_9
	clr key_id
	clr key_val
	ldd temp,			y+7			; load $107 flags
	andi temp,			0xb6		; clear F54, F56, F58 flags
	ori temp,			0x01		; set F58 flag
	std y+7,			temp		; store $107 flags
	ldd temp,			y+8			; load $108 flags
	andi temp,			0xcf		; clear F60, F61 flags
	ori temp,			0x20		; set F60
	std y+8,			temp		; store $108 flags
	ldd temp,			y+0			; load $100 flags
	andi temp,			0xdf		; clear F5 flag
	std y+0,			temp		; store $100 flags
	ldd temp,			y+11		; load $10B flags
	ori temp,			0x01		; set PT15
	std y+11, 			temp		; store $10B flags
	ret
ac_9:cpi key_id,		0x09		; compare id with 9 (if pause or number key has been pressed)
	brbc 1,				ac_ac		; jmp to after key check
ac_ac:ret
	ret
cc_mode_change_exp:					; cooling chamber mode change timer exceeded 		(F42)
	call cc_light_dis
	ldd temp,			y+5			; fetch $105 flags
	andi temp, 			0x7f		; clear F41 flag
	std y+5,			temp		; store $105 flags
	ret
cc_temp_change_exp:					; cooling chamber temperature change timer exceeded	(F44)
	call cc_light_dis
	ldd temp,			y+5			; fetch $105 flags
	andi temp, 			0xef		; clear F43 flag
	std y+5,			temp		; store $105 flags
	ret
cc_hum_change_exp:					; cooling chamber humidity change timer exceeded	(F46)
	call cc_light_dis
	ldd temp,			y+5			; fetch $105 flags
	andi temp, 			0xfe		; clear F45 flag
	std y+5,			temp		; store $105 flags
	ret
cc_pres_change_exp:					; cooling chamber pressure change timer exceeded	(F48)
	call cc_lights_dis
	ldd temp,			y+6			; fetch $106 flags
	andi temp, 			0xdf		; clear F47 flag
	std y+6,			temp		; store $106 flags
	ret
fc_mode_change_exp:					; freezing chamber mode change timer exceeded		(F55)
	call fc_light_dis
	ldd temp,			y+7			; fetch $107 flags
	andi temp, 			0xbf		; clear F54 flag
	std y+7,			temp		; store $107 flags
	ret
fc_temp_change_exp:					; freezing chamber temperature change timer exceeded(F57)
	call fc_light_dis
	ldd temp,			y+7			; fetch $107 flags
	andi temp, 			0xf7		; clear F56 flag
	std y+7,			temp		; store $107 flags
	ret
fc_hum_change_exp:					; freezing chamber humidity change timer exceeded	(F59)
	call fc_light_dis
	ldd temp,			y+7			; fetch $107 flags
	andi temp, 			0xfe		; clear F58 flag
	std y+7,			temp		; store $107 flags
	ret
fc_pres_change_exp:					; freezing chamber pressure change timer exceeded	(F61)
	call fc_light_dis
	ldd temp,			y+8			; fetch $108 flags
	andi temp, 			0xdf		; clear F60 flag
	std y+8,			temp		; store $107 flags
	ret
gen_light_en:						; should have bit mask in temp2
	in temp, 			porta		; read current portA value
	or temp,			temp2		; set bits by mask
	out porta,			temp
	ret
gen_light_dis:						; should have bit mask (not inverted) in temp2
	in temp,			porta		; read current portA value
	neg temp2						; negate temp2
	and temp,			temp2		; reset bits by inverted mask
	out porta,			temp
	ret
cc_light_en:
	ldi temp2,	0x01		; 0-bit mask
	call gen_light_en		; enable cc light
	ret
cc_light_dis:
	ldi temp2,	0x01		; 0-bit mask
	call gen_light_dis		; disable cc light
	ret
fc_light_en:
	ldi temp2,	0x02		; 1-bit mask
	call gen_light_en		; enable fc light
	ret
fc_light_dis:
	ldi temp2,	0x02		; 1-bit mask
	call gen_light_dis		; disable fc light
	ret
red_light_en:
	ldi temp2,	0x04		; 2-bit mask
	call gen_light_en		; enable red light
	ret
red_light_dis:
	ldi temp2,	0x04		; 2-bit mask
	call gen_light_dis		; disable red light
	ret
green_light_en:
	ldi temp2,	0x08		; 3-bit mask
	call gen_light_en		; enable green light
	ret
green_light_dis:
	ldi temp2,	0x08		; 3-bit mask
	call gen_light_dis		; disable green light
	ret
blue_light_en:
	ldi temp2,	0x10		; 4-bit mask
	call gen_light_en		; enable blue light
	ret
blue_light_dis:
	ldi temp2,	0x10		; 4-bit mask
	call gen_light_dis		; disable blue light
	ret
yellow_light_en:
	ldi temp2,	0x20		; 5-bit mask
	call gen_light_en		; enable yellow light
	ret
yellow_light_dis:
	ldi temp2,	0x20		; 5 bit mask
	call gen_light_dis		; disable yellow light
	ret
