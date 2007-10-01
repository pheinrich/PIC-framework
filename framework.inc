;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright © 2006,7  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL:$
;;  $Revision:$
;;
;; ---------------------------------------------------------------------------
;;  $Author:$
;;  $Date:$
;; ---------------------------------------------------------------------------



; Since this value may (will) be used to define other constants, we can't put
; off its own definition.  This isn't desirable at the framework level, of
; course, but we can't sacrifice the space/time savings of assembly-time
; definition for the run-time alternative.
kFrequency              equ   24000000

; Enumerate some BRG (Baud Rate Generator) values for common baud rates when
; the USART is in high-speed mode (BRGH = true).  At the default frequency of
; 24 MHz, these values all result in a fixed error of -0.16% (quite good).
USART.kBaud_9600        equ   (kFrequency / (  9600 << 4)) - 1    ; 155 (0x9b) @ 24 MHz
USART.kBaud_14400       equ   (kFrequency / ( 14400 << 4)) - 1    ; 103 (0x67) @ 24 MHz
USART.kBaud_19200       equ   (kFrequency / ( 19200 << 4)) - 1    ;  77 (0x4d) @ 24 MHz
USART.kBaud_28800       equ   (kFrequency / ( 28800 << 4)) - 1    ;  51 (0x33) @ 24 MHz
USART.kBaud_38400       equ   (kFrequency / ( 38400 << 4)) - 1    ;  38 (0x26) @ 24 MHz
USART.kBaud_57600       equ   (kFrequency / ( 57600 << 4)) - 1    ;  25 (0x19) @ 24 MHz
USART.kBaud_115200      equ   (kFrequency / (115200 << 4)) - 1    ;  12 (0x0c) @ 24 MHz

; Enumerate common error-checking methods.
USART.kParity_Even      equ   0
USART.kParity_Odd       equ   1
USART.kParity_None      equ   2
USART.kParity_Mark      equ   3
USART.kParity_Space     equ   4
