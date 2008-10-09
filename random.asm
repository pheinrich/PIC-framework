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
;;  These implementations of the Galois LFSR (Linear Feedback Shift Register)
;;  come directly from Mark Jeronimus, as posted to the PICList.  See
;;  http://www.piclist.com/techref/microchip/rand8bit.htm.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   #include "private.inc"

   ; Global Variables
   global   Random.Value

   ; Public Methods
   global   Random.byte
   global   Random.word



;; ---------------------------------------------------------------------------
                        idata_acs
;; ---------------------------------------------------------------------------

Random.Value            dw    0



;; ---------------------------------------------------------------------------
.random                 code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  WREG Random.byte()
;;
;;  Advances the low byte of Random.Value according to the prime polynomial
;;  value 0xb4, then returns that byte in the working register.
;;
Random.byte:
   bcf      STATUS, C
   rrcf     Random.Value, W
   btfsc    STATUS, C
     xorlw  0xb4
   movwf    Random.Value
   return



;; ----------------------------------------------
;;  void Random.word()
;;
;;  Generates the next random 16-bit value, using 0xa1a1 as the prime poly-
;;  mial.  The value is returned in Random.Value.
;;
Random.word:
   bcf      STATUS, C
   rrcf     Random.Value + 1, F
   rrcf     Random.Value, F
   btfss    STATUS, C
     return

   movlw    0xa1
   xorwf    Random.Value + 1
   xorwf    Random.Value
   return



   end
