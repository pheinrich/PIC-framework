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
