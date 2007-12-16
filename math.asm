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



   #include "private.inc"

   ; Public Methods
   global   Math.compare16

   ; Dependencies
   extern   Util.Frame
   extern   Util.Save



;; ---------------------------------------------------------------------------
.math                   code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  STATUS<C,Z> Math.compare16( frame[0..1] value, frame[2..3] comparand )
;;
;;  Compares two 16-bit (unsigned) numbers passed on the pseudo-stack, setting
;;  the status flags as appropriate:
;;
;;    C    Z    comparison
;;    0    X    value  > comparand
;;    1    X    value <= comparand
;;    X    0    value != comparand
;;    X    1    value == comparand
;;    0    0    value >= comparand
;;    1    0    value  < comparand
;;    1    1    value >= comparand    
;;
Math.compare16
   ; Save the working register.
   movff    WREG, Util.Save

   ; Compare the high words.
   movf     Util.Frame + 1, W
   subwf    Util.Frame + 3, W
   bnz      cmp16Done

   ; Compare the low words.
   movf     Util.Frame + 0, W
   subwf    Util.Frame + 2, W

cmp16Done:
   ; Restore the working register, but preserve status flags.
   movff    Util.Save, WREG
   return



   end
