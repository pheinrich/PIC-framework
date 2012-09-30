;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;  Copyright © 2006,2008  Peter Heinrich
;;
;;  This program is free software; you can redistribute it and/or
;;  modify it under the terms of the GNU General Public License
;;  as published by the Free Software Foundation; either version 2
;;  of the License, or (at your option) any later version.
;;
;;  Linking this library statically or dynamically with other modules
;;  is making a combined work based on this library. Thus, the terms
;;  and conditions of the GNU General Public License cover the whole
;;  combination.
;;
;;  As a special exception, the copyright holders of this library give
;;  you permission to link this library with independent modules to
;;  produce an executable, regardless of the license terms of these
;;  independent modules, and to copy and distribute the resulting
;;  executable under terms of your choice, provided that you also meet,
;;  for each linked independent module, the terms and conditions of the
;;  license of that module. An independent module is a module which is
;;  not derived from or based on this library. If you modify this
;;  library, you may extend this exception to your version of the
;;  library, but you are not obligated to do so. If you do not wish to
;;  do so, delete this exception statement from your version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program; if not, write to the Free Software
;;  Foundation, Inc., 51 Franklin Street, Boston, MA  02110-1301, USA.
;;
;; ---------------------------------------------------------------------------
;;  Provides basic text/debugging output over a serial link.  All the methods
;;  in this module assume the serial communication channel has already been
;;  established and is working.  They don't arbitrate with callback functions
;;  that may hook USART events, however, so care should be taken when the
;;  USART is used in interrupt mode.
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
