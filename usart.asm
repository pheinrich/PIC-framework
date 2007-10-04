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



   include "private.inc"

   ; Variables
   global   USART.Baud
   global   USART.HookRX
   global   USART.HookTX
   global   USART.Parity
   global   USART.Read
   global   USART.Status
   global   USART.Write

   ; Methods
   global   USART.init
   global   USART.isrReceive
   global   USART.isrTransmit



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

USART.Baud              res   1  ; USART.kBaud_XXX from framework.inc
USART.Parity            res   1  ; USART.kParity_XXX from framework.inc

USART.HookRX            res   2	 ; Pointer to reception callback function
USART.HookTX            res   2  ; Pointer to transmission callback function

USART.Read              res   1  ; Holds last byte received
USART.Write             res   1  ; Holds the next byte to be transmitted
USART.Status            res   1	 ; Tracks errors, callbacks, and current parity



;; ---------------------------------------------------------------------------
.usart                  code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void USART.init()
;;

;; ----------------------------------------------
;;  void USART.isrReceive()
;;
;;  Handles reception of a single byte via the USART.  Framing errors and input
;;  buffer overflows are detected, as well as parity checking (if appropriate).
;;
USART.isrReceive:
   ; Read the current state of the hardware.
   movf     RCSTA, W
   andlw    (1 << FERR) | (1 << OERR) | (1 << RX9D)
   movwf    USART.Status

   ; If there was an error, we need to clear it in software.
   bcf      RCSTA, CREN          ; swizzle the bit to clear error, if any
   bsf      RCSTA, CREN          ; (if not, this should be harmless)

   ; Read the byte and check parity if necessary.
   movff    RCREG, UART.Read     ; this will also clear the interrupt
   tstfsz   USART.Parity         ; is parity checking desired?
     rcall  checkParity          ; yes, verify the value

   ; If the reception hook is set, dispatch to it at last.
   movf     USART.HookRX, W
   iorwf    USART.HookRX + 1     ; is the vector null?
   bz       rxDone               ; yes, exit

   ; The hook vector is non-null, so jump through it.
   push                          ; push the current PC
   clrf     TOSU                 ; always 0 for low-memory devices
   CopyAddress USART.HookRX, TOSL; return through vector

rxDone:
   return
   

;; ----------------------------------------------
;;  void USART.isrTransmit()
;;
;;  Handles reloading the USART transmission buffer with the next byte to be
;;  sent.  This method is called as a result of an interrupt generated after
;;  the last transmission (TXIF).
;;
USART.isrTransmit:
   ; We defer the handling of this interrupt, since the behavior is so appli-
   ; cation-specific.  Transfer control to the transmission hook, if set.
   movf     USART.HookTX, W
   iorwf    USART.HookTX + 1     ; is the vector null?
   bz       txDone               ; yes, exit

   ; The hook vector is non-null, so jump through it.
   push                          ; push the current PC
   clrf     TOSU                 ; always 0 for low-memory devices
   CopyAddress USART.HookTX, TOSL; return through vector

txDone:
   return



;; ----------------------------------------------
;;  void USART.checkParity()
;;
USART.checkParity:
   ; Assume no parity error.
   bcf      USART.Status, PERR

   ; If not operating in 9-bit mode, the parity bit will come from the high bit
   ; of the byte itself.
   btfsc    RCSTA, RX9           ; USART in 9-bit mode?
     bra    checkSpace           ; yes, no special set-up necessary

   ; The USART is receiving in 8-bit mode, so copy the parity bit from the MSb
   ; of the byte read.  Clear that bit when done.
   btfsc    USART.Read, 7        ; is high bit set?
     bsf    USART.Status, RX9D   ; yes, set the parity status bit
   bcf      USART.Status, RX9D   ; no, clear the parity status bit
   bcf      USART.Read, 7        ; regardless, we're dealing with 7-bit chars

checkSpace:
   ; Figure out what kind of parity checking we should do.
   movlw    USART.kParity_Space
   cpfslt   USART.Parity         ; is parity type Space?
     bra    checkMark            ; no, check Mark

   ; Check Space parity (bit must always be clear).
   btfss    USART.Status, RX9D   ; is parity bit clear?
     bsf    USART.Status, PERR   ; no, parity error
   return                        ; yes, yay!

checkMark:
   movlw    USART.kParity_Mark
   cpfslt   USART.Parity         ; is parity type Mark?
     bra    compute              ; no, compute expected

   ; Check Mark parity (bit must always be set).
   btfsc    USART.Status, RX9D   ; is parity bit set?
     bsf    USART.Status, PERR   ; no, parity error
   return                        ; yes, yay!

compute:
   ; Compute the expected parity for the byte received.
   movf     USART.Read, W
   rcall    USART.calcParity     ; W = expected parity
   btfsc    WREG, 0              ; is parity bit set?
     xorwf  USART.Status         ; yes, combine with status

   ; If configured for Odd parity checking, we complement the result.
   movlw    USART.kParity_Even
   cpfsgt   USART.Parity         ; is parity type Even?
     btg    USART.Status, RX9D   ; no, complement result

   ; If the final result is not 0, the parity doesn't match.
   btfsc    USART.Status, RX9D
     bsf    USART.Status, PERR
   return



;; ----------------------------------------------
;;  byte USART.calcParity( byte value )
;;
;;  Calculates the even parity of the byte specified in W.  The even parity is
;;  the 1-bit sum of all bits in the byte (also equivalent to XOR-ing them all
;;  together); the odd parity is the complement of that.  The result is re-
;;  turned in W.
;;
USART.calcParity:
   extern   Util.Scratch

   ; Copy W into a temporary variable.
   movwf    Util.Scratch         ; Scratch = |a|b|c|d|e|f|g|h|

   ; XOR the nybbles of W together.
   swapf    WREG                 ; W = |e|f|g|h|a|b|c|d|
   xorwf    Util.Scratch         ; Scratch = |e^a|f^b|g^c|h^d|a^e|b^f|c^g|d^h|

   ; Now shift the value by 1 in order to XOR adjacent bits together.
   rrcf     Util.Scratch, W      ; W = |?|e^a|f^b|g^c|h^d|a^e|b^f|c^g|
   xorwf    Util.Scratch         ; Scratch = |?^e^a|e^a^f^b|f^b^g^c|g^c^h^d|h^d^a^e|a^e^b^f|b^f^c^g|c^g^d^h|

   ; Note that bit 2 = a^e^b^f, which is the parity of half the bits in the byte.
   ; Bit 0 = c^g^d^h, the parity of the other half, so (bit 2) ^ (bit 0) is the
   ; parity for the whole byte.  If bit 2 = 0, just take the value of bit 0, since
   ; parity = 0 ^ (bit 0) = bit 0.  For bit 2 = 1, the value is complemented,
   ; since parity = 1 ^ (bit 0) = !bit 0.
   btfsc    Util.Scratch, 2      ; is a^e^b^f = 0?
     btg    Util.Scratch, 0      ; no, toggle bit 0
   movf     Util.Scratch, W      ; yes, we're done
   xorlw    0x01                 ; mask off all but the LSb.

   return



   end
