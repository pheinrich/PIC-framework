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
;;  Provides utility registers and a pseudo-stackframe, as well as functions
;;  to perform handy conversions.
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
