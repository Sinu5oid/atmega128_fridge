; flag bytes
.equ fb_1 			= $0100
.equ fb_2 			= $0101
.equ fb_3 			= $0102
.equ fb_4 			= $0103
.equ fb_5 			= $0104
.equ fb_6 			= $0105
.equ fb_7 			= $0106
.equ fb_8 			= $0107
.equ fb_9 			= $0108
.equ fb_10 			= $0109

; program timers set flag bytes
.equ fsb_1 			= $010a
.equ fsb_2 			= $010b

; program timers
.equ pt_2 			= $010c
.equ pt_3 			= $010d
.equ pt_4 			= $010e
.equ pt_5 			= $010f
.equ pt_6 			= $0110
.equ pt_7			= $0111
.equ pt_8 			= $0112
.equ pt_9 			= $0113
.equ pt_10 			= $0114
.equ pt_11 			= $0115
.equ pt_12			= $0116
.equ pt_13 			= $0117
.equ pt_14 			= $0118
.equ pt_15 			= $0119
.equ pt_16 			= $011a
.equ pt_17 			= $011b
.equ pt_18 			= $011c

; current time section
.equ time_h 		= $011d
.equ time_hp 		= $011e
.equ time_mp 		= $011f
.equ time_sp 		= $0120

; current settings section
; cooling chamber
.equ p_cc_mode 		= $0121
.equ p_cc_temp 		= $0122
.equ p_cc_hum 		= $0123
.equ p_cc_pres 		= $0124
; freezing chamber
.equ p_fc_mode		= $0125
.equ p_fc_temp		= $0126
.equ p_fc_hum		= $0127
.equ p_fc_pres 		= $0128
; default 50% setting
.equ settings_default=0x7f

; port
; port A ddr
.equ porta_ddr 		= 0x3f

; bit masks definition
.equ led_cc 		= 0x01
.equ led_fc 		= 0x02
.equ led_red 		= 0x04
.equ led_green 		= 0x08
.equ led_blue 		= 0x10
.equ led_yellow 	= 0x20

; hardware timer complement to overflow
; takes about 100ms to reach overflow
.equ time_4mhz_h	= 0xfe
.equ time_16mhz_h	= 0xf9
.equ time_4mhz_l	= 0x79
.equ time_16mhz_l	= 0xe5

; hardware timer prescaler settings
.equ prescaler_1024	= 0x05

; program timers complement to overflow
.equ t_100ms 		= 0xff
.equ t_200ms 		= 0xfe
.equ t_1s 			= 0xf6
.equ t_2s			= 0xec
.equ t_12s 			= 0x88

; reset masks for analyze_command function
.equ reset_105 		= 0x4a
.equ reset_106 		= 0x87
.equ reset_107 		= 0x92
.equ reset_108 		= 0x67
.equ reset_109 		= 0x5f

; consts
.equ chigh			= 0xcc
.equ cnormal		= 0x96
.equ clower			= 0x32
.equ clow			= 0x19
.equ mod4			= 0x11
