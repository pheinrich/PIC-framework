;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright © 2006,7  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL$
;;  $Revision$
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
   
   ; Methods
   global   Util.char2hex
   global   Util.hex2char



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

Util.Frame              res   4  ; Pseudo stack frame for parameters/results
Util.Save               res   1  ; Temporary storage for (usually) W
Util.Scratch            res   1  ; Temporary storage for intermediate results
Util.Volatile           res   1  ; Temporary storage during interrupts



;; ---------------------------------------------------------------------------
.util                   code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  byte Util.char2Hex( char ascii )
;;
;;  Converts the specified ASCII character code into the integer value corre-
;;  sponding to the hexadecimal digit it represents.  '0'-'9' become 0-9;
;;  'A'-'F' and 'a'-'f' become 10-15.
;;
Util.char2hex:
   ; Shift the character.
   addlw    0x9f
   bnn      adjust               ; if positive, character was 'a' to 'f'
   addlw    0x20                 ; otherwise, shift to next range of digits
   bnn      adjust               ; if now positive, character was 'A' to 'F'
   addlw    0x7                  ; otherwise, character must have been '0' to '9'

adjust:
   addlw    0xa                  ; shift the result to account for the alpha offset
   andlw    0xf                  ; clamp the value to one nybble
   return



;; ----------------------------------------------
;;  char Util.hex2char( byte nybble )
;;
;;  Converts a hexadecimal nybble into the corresponding ASCII character.
;;  0-9 become '0'-'9' and 10-15 become 'A'-'F'. 
;;
Util.hex2char:
   andlw    0xf                  ; clamp the value to one nybble
   addlw    0xf6                 ; shift a "letter" nybble down to 0
   btfss    STATUS, N            ; was result negative?
     addlw  0x7                  ; no, convert to character, less common constant
   addlw    0x3a                 ; yes, add constant to adjust
   return



   end
