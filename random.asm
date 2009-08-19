;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright (c) 2006-8  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL$
;;  $Revision$
;;
;;  Redistribution and use in source and binary forms, with or without
;;  modification, are permitted provided that the following conditions are met:
;;      * Redistributions of source code must retain the above copyright
;;        notice, this list of conditions and the following disclaimer.
;;      * Redistributions in binary form must reproduce the above copyright
;;        notice, this list of conditions and the following disclaimer in the
;;        documentation and/or other materials provided with the distribution.
;;      * Neither the name of the PIC Modbus project nor the names of its
;;        contributors may be used to endorse or promote products derived from
;;        this software without specific prior written permission.
;;
;;  THIS SOFTWARE IS PROVIDED BY PETER HEINRICH ''AS IS'' AND ANY EXPRESS OR
;;  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
;;  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
;;  NO EVENT SHALL PETER HEINRICH BE LIABLE FOR ANY DIRECT, INDIRECT,
;;  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;;  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES LOSS OF USE,
;;  DATA, OR PROFITS OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
;;  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; ---------------------------------------------------------------------------
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
                        udata_acs
;; ---------------------------------------------------------------------------

;;  Note that this should be initialized prior to first use if desired.
Random.Value            res   2



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
   xorwf    Random.Value + 1, F
   xorwf    Random.Value, F
   return



   end
