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



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

Util.Frame              res   4  ; Pseudo stack frame for parameters/results
Util.Save               res   1  ; Temporary storage for (usually) W
Util.Scratch            res   1  ; Temporary storage for intermediate results



   end
