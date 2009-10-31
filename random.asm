;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;  Copyright (c) 2006,2008  Peter Heinrich
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
;;  These implementations of the Galois LFSR (Linear Feedback Shift Register)
;;  come directly from Mark Jeronimus, as posted to the PICList.  See
;;  http://www.piclist.com/techref/microchip/rand8bit.htm.
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
