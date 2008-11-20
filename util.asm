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
;;  Provides utility registers and a pseudo-stackframe, as well as functions
;;  to perform handy conversions.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   include "private.inc"

   ; Variables
   global   Util.Frame
   global   Util.Save
   global   Util.Scratch
   global   Util.Volatile
   
   ; Methods
   global   Util.char2hex
   global   Util.hex2char



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

Util.Frame              res   4     ; Pseudo stack frame for parameters/results
Util.Save               res   1     ; Temporary storage for (usually) W
Util.Scratch            res   1     ; Temporary storage for intermediate results
Util.Volatile           res   1     ; Temporary storage during interrupts



;; ---------------------------------------------------------------------------
.util                   code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  WREG Util.char2Hex( WREG ascii )
;;
;;  Converts the specified ASCII character code into the integer value corre-
;;  sponding to the hexadecimal digit it represents.  '0'-'9' become 0-9;
;;  'A'-'F' and 'a'-'f' become 10-15.
;;
Util.char2hex:
   ; Shift the character.
   addlw    0x9f
   bnn      adjust                  ; if positive, character was 'a' to 'f'
   addlw    0x20                    ; otherwise, shift to next range of digits
   bnn      adjust                  ; if now positive, character was 'A' to 'F'
   addlw    0x7                     ; otherwise, character must have been '0' to '9'

adjust:
   addlw    0xa                     ; shift the result to account for the alpha offset
   andlw    0xf                     ; clamp the value to one nybble
   return



;; ----------------------------------------------
;;  WREG Util.hex2char( WREG nybble )
;;
;;  Converts a hexadecimal nybble into the corresponding ASCII character.
;;  0-9 become '0'-'9' and 10-15 become 'A'-'F'. 
;;
Util.hex2char:
   andlw    0xf                     ; clamp the value to one nybble
   addlw    0xf6                    ; shift a "letter" nybble down to 0
   btfss    STATUS, N               ; was result negative?
     addlw  0x7                     ; no, convert to character, less common constant
   addlw    0x3a                    ; yes, add constant to adjust
   return



   end
