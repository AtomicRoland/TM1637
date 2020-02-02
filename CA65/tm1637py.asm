;	TM1637 DISPLAY DRIVER
;	BY ROLAND LEURS
;	VERSION 1.0  1 FEB 2020
;	BASED ON PYTHON VERSION FOR RASPBERRY PI

atmhdr = 1

.if	(atmhdr = 1)        
AtmHeader:
	       .SEGMENT "HEADER"
	       .byte    "TM1637PY"
	       .word    0,0,0,0
	       .word    StartAddr
	       .word    StartAddr
	       .word    EndAddr - StartAddr
.endif

	       .SEGMENT "CODE"

StartAddr:

PORTA	     = $B811        ; VIA A-port
DRA	         = $B813        ; VIA Data Direction Register for A-port
WAIT	     = $FE66        ; Short wait routine
ADDR_AUTO	 = $40
ADDR_FIXED	 = $44
START_ADDR	 = $C0
	
API_INIT:	 JMP INIT
API_SHOW:	 JMP SHOW
API_CLEAR:	 JMP CLEAR
API_BRIGHT:	 JMP SET_BRIGHTNESS
API_POINT:	 JMP SET_DOUBLE_POINT
	
BRIGHTNESS:	.BYTE 7
POINT_DATA:	.BYTE 0
HEX_DIGITS:	.BYTE $3F,$06,$5B,$4F,$66,$6D,$7D,$07
            .BYTE $7F,$6F,$77,$7C,$39,$5E,$79,$71
DATA:       .BYTE 0,0,0,0
	
; Initialize the via and reset the display
INIT:
	JSR SET_CLOCK_PIN_OUT
	JSR SET_DATA_PIN_OUT
	JSR SET_DATA_HIGH
	JSR SET_CLOCK_HIGH
	LDA #4
	STA BRIGHTNESS
	LDA #0
	STA POINT_DATA
	JMP CLEAR
	
; Define port A-0 as output
SET_CLOCK_PIN_OUT:
	LDA DRA
	ORA #$01
	STA DRA
	RTS
	
; Define port A-1 as output
SET_DATA_PIN_OUT:
	LDA DRA
	ORA #$02
	STA DRA
	RTS 
	
; Define port A-0 as input
SET_CLOCK_PIN_IN:
	LDA DRA
	AND #$FE
	STA DRA
	RTS
	
; Define port A-1 as input
SET_DATA_PIN_IN:
	LDA DRA
	AND #$FD
	STA DRA
	RTS
	
; Show the data in memory on the display
; Parameters: X-reg points to datablock in zero page
;             ZP-address+0: first (left-most) digit
;             ZP-address+1: second digit
;             ZP-address+2: third digit
;             ZP-address+3: fourth digit (right-most)
; The digits must have a value between 0 and $0F otherwise the display result is undefined.
SHOW:
	LDA $00,X
	STA DATA
	LDA $01,X
	STA DATA+1
	LDA $02,X
	STA DATA+2
	LDA $03,X
	STA DATA+3
SHOW0:
	JSR SEND_START_BIT
	LDA #ADDR_AUTO
	JSR WRITE_BYTE
	JSR SEND_STOP_BIT
	JSR SEND_START_BIT
	LDA #START_ADDR
	JSR WRITE_BYTE
	LDX #0
SHOW1:
	LDA DATA,X
	JSR CONVERT
	JSR WRITE_BYTE
	INX
	CPX #4
	BNE SHOW1
	JSR SEND_STOP_BIT
	JSR SEND_START_BIT
	LDA BRIGHTNESS
	CLC
	ADC #$88
	JSR WRITE_BYTE
	JSR SEND_STOP_BIT
	RTS
	
; Send a start bit to the TM1637 controller
SEND_START_BIT:
	JSR SET_CLOCK_HIGH
	JSR SET_DATA_HIGH
	JSR SET_DATA_LOW
	JSR SET_CLOCK_LOW
	RTS
	
; Send a stop bit to the TM1637 controller
SEND_STOP_BIT:
	JSR SET_CLOCK_LOW
	JSR SET_DATA_LOW
	JSR SET_CLOCK_HIGH
	JSR SET_DATA_HIGH
	RTS
	
; Make output pin A-0 high
SET_CLOCK_HIGH:
	LDA PORTA
	ORA #$01
	STA PORTA
	RTS
	
; Make output pin A-1 high
SET_DATA_HIGH:
	LDA PORTA
	ORA #$02
	STA PORTA
	RTS
	
; Make output pin A-0 low
SET_CLOCK_LOW:
	LDA PORTA
	AND #$FE
	STA PORTA
	RTS
	
; Make output pin A-1 high
SET_DATA_LOW:
	LDA PORTA
	AND #$FD
	STA PORTA
	RTS
	
; Write a byte (control data or digit) to the TM1637 controller
WRITE_BYTE:
	LDY #8
WRITE1:
	PHA
	JSR SET_CLOCK_LOW
	PLA
	LSR A
	PHA
	BCC WRITE_LOW
WRITE_HIGH:
	JSR SET_DATA_HIGH
	JMP WRITE2
WRITE_LOW:
	JSR SET_DATA_LOW
WRITE2:
	JSR SET_CLOCK_HIGH
	PLA
	DEY
	BNE WRITE1
WAIT_FOR_ACK:
	JSR SET_CLOCK_LOW
	JSR SET_DATA_HIGH
	JSR SET_CLOCK_HIGH
	JSR SET_DATA_PIN_IN
WAIT_ACK:
	LDA PORTA
	AND #$02
	BEQ WAIT_ACK_END
	JSR WAIT
	JMP WAIT_ACK
WAIT_ACK_END:
	JSR SET_DATA_PIN_OUT
	RTS
	
; Clear (turn off) the display
CLEAR:
	LDA BRIGHTNESS
	PHA
	LDA POINT_DATA
	PHA
	LDA #0
	STA BRIGHTNESS
	LDA #$7F
	STA $5A
	STA $5B
	STA $5C
	STA $5D
	LDX #$5A
	JSR SHOW
	PLA
	STA POINT_DATA
	PLA
	STA BRIGHTNESS
	RTS
	
; Convert a decimal value to the led value ($7F turns off the leds)
CONVERT:
	CMP #$7F
	BNE CONVERT1
	LDA #$00
	RTS
CONVERT1:
	TAY
	LDA HEX_DIGITS,Y
	ORA POINT_DATA
	RTS
	
; Set the brightness of the leds
; Parameter: A holds the new brightness value in range 0-7
SET_BRIGHTNESS:
	AND #$07
	STA BRIGHTNESS
	JMP SHOW0
	

; Set the double point on or off
; Parameter: A = 0   -> double point off
;            A = $80 -> double point on
SET_DOUBLE_POINT:
	AND #$80
	STA POINT_DATA
	RTS
	
EndAddr:
