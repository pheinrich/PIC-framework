;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright © 2006-8  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL$
;;  $Revision$
;;
;;  Provides basic text/debugging output over a serial link.  All the methods
;;  in this module assume the serial communication channel has already been
;;  established and is working.  They don't arbitrate with callback functions
;;  that may hook USART events, however, so care should be taken when the
;;  USART is used in interrupt mode.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   include "private.inc"

   ; Public Methods
   global   Console.newline
   global   Console.printHex
   global   Console.printString
   global   Console.putByte

   ; Dependencies
   extern   USART.send
   extern   Util.hex2char



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

Save					      res	1
   


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
;;  void Console.printHex( WREG value )
;;
;;  Transmits two hex digits (ASCII characters in [0-9A-F] representing the
;;  specified byte.  W is unchanged.
;;
Console.printHex:
   movwf    Save

   ; Convert high nybble to an ASCII character.
   swapf    WREG, W                 ; move 4 high bits down
   call     Util.hex2char

   ; Transmit first character.
   rcall    Console.putByte

   ; Convert low nybble to an ASCII character.
   movf     Save, W                 ; retrieve saved lower bits
   call     Util.hex2char

   ; Transmit second character, restore W, and exit.
   rcall    Console.putByte
   movf     Save, W
   return



;; ----------------------------------------------
;;  void Console.printString( TBLPTR string )
;;
;;  Transmits the C-string (NUL-terminated) whose ROM address has been pre-
;;  loaded into the TBLPTRx registers.
;;
Console.printString:
    ; Read the next character.
    tblrd*+
    movf    TABLAT, W
    bnz     psOut                   ; is character NUL ('\0')?
    return                          ; yes, we're done

psOut:
    ; Output a character.
    btfss    TXSTA, TRMT            ; is UART busy?
      bra    $-2                    ; yes, wait until finished
    call     USART.send             ; no, transmit character
    bra      Console.printString



;; ----------------------------------------------
;;  void Console.putByte( WREG value )
;;
;;  Transmits a single byte using the UART.  This is a blocking call, because
;;  it will wait for the UART to complete its current operation, if busy.
;;
Console.putByte:
   btfss    TXSTA, TRMT             ; is UART busy?
     bra    $-2                     ; yes, wait until finished
   goto     USART.send              ; no, transmit character



   end
