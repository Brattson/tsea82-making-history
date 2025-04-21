
.equ T, 0			; Tone frequency constant
.equ N, 20			; Morse Delay constant (frequency we send characters at)
	
STR: .db "DATORTEKNIK", 0

; BTAB – Morse binärkod för A–Z (0x41–0x5A)
; Index = ASCII - 0x41
BTAB:
	.db 0x60; A
	.db 0x88; B
	.db 0xA8; C
	.db 0x90; D
	.db 0x40; E
	.db 0x28; F
	.db 0xD0; G
	.db 0x10; H
	.db 0x20; I
	.db 0x78; J
	.db 0xB0; K
	.db 0x48; L
	.db 0xE0; M
	.db 0xA0; N
	.db 0xF0; O
	.db 0x68; P
	.db 0xD8; Q
	.db 0x50; R
	.db 0x10; S
	.db 0xC0; T
	.db 0x30; U
	.db 0x18; V
	.db 0x70; W
	.db 0x98; X
	.db 0xB8; Y
	.db 0xC8; Z


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;		START OF LOGIC	;;;
;;;		PROPERTY OF		;;;
;;;		BIG BIRGER		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Initialize hardware
HW_INIT:
	sbi DDRB, 7   ; Sätt bit 7 i DDRB till 1 och därmed gör PB7 till utgång
	ret

; Huvudloop som sänder en hel sträng
MORSE:
	;TODO pusha alla register vi använder till stacken (inklusive Z etc)
	; De måste enl instruktionerna vara opåverkade (höhö som jag ;) LOL BB busted by Slimy, 1000ug senare)
	; efter vi kört programmet	
	push r16
	push r30
	push r31

	ldi r30, low(STR << 1)	; Ladda ZL-pekare (för strängen)
	ldi r30, high(STR << 1)	; Ladda ZH-pekare
	
	call GET_CHAR			; Get first character in string
	call BEEP_CHARS

	;;TODO pop all regs
	pop r31
	pop r30
	pop r16

	rjmp MORSE				; Loop again

; Logic for sending one character
; Call 'GET_CHAR' first
BEEP_CHARS:
	; We have ASCII-character in r16
	call LOOKUP			; Convert character to morse representation
	; Binary Morse-representation will now be in r16

	call SEND
	call NOBEEP			; Silence over 2N
	call NOBEEP

	CALL GET_CHAR		; Get next character in string
	cpi r16, 0			; Loop until no more chars (r16 == 0)
	brne BEEP_CHARS
	ret					; Return to MORSE routine

; Get next ASCII-character from string
; Next character byte is saved to r16
GET_CHAR:
	lpm r16, Z+			; Read character byte from Z-pointer, then increment pointer
	ret

; Translates ASCII-character to binary
; Character in r16
; Output morse representation in r16
LOOKUP:
	push r30			; Store Z-pointer on stack
	push r31
	
	; Subtrahera ASCII-kod för första bokstaven 'A' ($41)
	subi r16, 'A'		; r16 = index i BTAB

	; Ladda addressen till BTAB i Z-pointer
	ldi r30, low(BTAB << 1)
	ldi r31, high(BTAB << 1)

	; Add r16 offset to Z-pointer
	add r30, r16
	adc r31, __zero_reg__	; Handle pointer carry overflow

	; Read Morse representation from BTAB
	lpm r16, Z
	
	pop r31
	pop r30 
	ret
	
; Sends a character
SEND:
	call GET_BIT
	;TODO while loop till there are no more bits for character
	;if bit == 0
	call BEEP			; 1N Beep, Morse '.'
	;else
	call BEEP3			; 1N Beep, Morse '-'

	call NOBEEP			; 1N Silence, space between next character
	call GET_BIT		; Get next bit to send

; Get the next bit to send
GET_BIT:
	; TODO we bitshift the character byte
	; Next bit is found in the carry flag

	;When whole byte is 0 and carry flag is 1,
	; we know character is done
	ret

; Sends all bits for a character
SEND_BITS
	ret

; Sends a "-" or "." and then waits
BIT:
	ret

BEEP:
	ldi r18, 20; vi ska loopa 20 gånger, (20 millisekunder)
	;TODO göra så att r18 inte förändrar värde egentligen. Spara i stacken
BeepLoop:
	;Genom att växla mellan 1 och 0 med en frekvens på ungefär 500 hz generar vi en hörbar ton
	sbi PORTB, 7  ;Sätter pin 7 på utgång B hög. 
	call DELAY ; Väntar ungefär 1 millisekund, därav frekvensen 500hz
	cbi PORTB, 7; sätter pin 7 på utgång B låg
	dec r18;    en runda har gått på loopen
	brne BEEPLoop; om r18 inte blev noll så fortsätter vi loopa
	ret

BEEP3:
	call BEEP
	call BEEP
	call BEEP
	ret

NOBEEP:
	ldi r18, 20; vi ska loopa 20 gånger, (20 millisekunder)
	cbi PORTB, 7; sätter utgången till 0, vi vill inte ha något ljud
	;TODO göra så att r18 inte förändrar värde egentligen. Spara i stacken
NoBeepLoop:
	call DELAY ; Väntar ungefär 1 millisekund, därav frekvensen 500hz
	dec r18;    en runda har gått på loopen
	brne NoBEEPLoop; om r18 inte blev noll så fortsätter vi loopa
	ret

NOBEEP3:
	call NOBEEP
	call NOBEEP
	call NOBEEP
	ret

; Rutinen DELAY är en vänteloop som samtidigt
; avger en skvallersignal på PB7.
; PB7 är hög (jag med) när rutinen körs
;
; Med angivet värde i r16 väntar rutinen
; ungefär en millisekund @ 1 MHz
;
; PORTB måste konfigureras separat.
DELAY:
	ldi		r16,10		; Decimal bas
delayYttreLoop:
	ldi		r17,$1F
delayInreLoop:
	dec		r17
	brne	delayInreLoop
	dec		r16
	brne	delayYttreLoop
	ret
