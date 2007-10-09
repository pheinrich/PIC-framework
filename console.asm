;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright � 2006,7  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL:$
;;  $Revision:$
;;
;; ---------------------------------------------------------------------------
;;  $Author:$
;;  $Date:$
;; ---------------------------------------------------------------------------



   include "private.inc"

   ; Methods
   global   Console.newline
   global   Console.printHex
   global   Console.printString
   global   Console.putByte



;; ---------------------------------------------------------------------------
.console                code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void Console.newline()
;;
;;  Transmits carriage-return/linefeed characters (0x0d 0x0a).
;;
Console.newline:
   movlw    '\r'
   rcall    Console.putByte
   movlw    '\n'
   bra      Console.putByte



;; ----------------------------------------------
;;  void Console.printHex( byte value )
;;
;;  Transmits two hex digits (ASCII characters in [0-9A-F] representing the
;;  specified byte.  W is unchanged.
;;
Console.printHex:
   extern   Util.Scratch
   movwf    Util.Scratch

	; Convert high nybble to ASCII character.
   swapf    WREG              	; work on lower 4 bits
   andlw    0xf               	; clamp the value to one nybble
   addlw    0xf6              	; shift a "letter" nybble down to 0
   btfss    STATUS, N         	; was result negative?
   addlw    0x7               	; no, convert to character, less common constant
   addlw    0x3a              	; yes, add constant to adjust

	; Transmit first character.
   rcall    Console.putByte

	; Convert low nybble to ASCII character.
   movf     Util.Scratch, W      ; retrieve saved lower bits
   andlw    0xf               	; clamp the value to one nybble
   addlw    0xf6              	; shift a "letter" nybble down to 0
   btfss    STATUS, N         	; was result negative?
   addlw    0x7               	; no, convert to character, less common constant
   addlw    0x3a              	; yes, add constant to adjust

	; Transmit second character, restore W, and exit.
   rcall    Console.putByte
   movf     Util.Scratch, W
   return



;; ----------------------------------------------
;;  void Console.printString( const char* string )
;;
;;  Transmits the C-string (NUL-terminated) whose ROM address has been pre-
;;  loaded into TBLPTRx.
;;
Console.printString:
   extern   USART.send

	; Read the next character.
	tblrd*+
	movf     TABLAT, W
   bnz      psOut                ; is character NUL ('\0')?
	return                        ; yes, we're done

psOut:
	; Output a character.
	btfss    TXSTA, TRMT          ; is UART busy?
	  bra    $-2                  ; yes, wait until finished
	call     USART.send           ; no, transmit character
	bra      Console.printString



;; ----------------------------------------------
;;  void Console.putByte( byte value )
;;
;;  Transmits a single byte using the UART.  This is a blocking call, because
;;  it will wait for the UART to complete its current operation, if busy.
;;
Console.putByte:
   extern   USART.send

   btfss    TXSTA, TRMT         ; is UART busy?
     bra    $-2                 ; yes, wait until finished
   goto		USART.send          ; no, transmit character



   end
