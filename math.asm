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
