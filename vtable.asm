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
   global   VTable.dispatch

   ; Dependencies
   extern   Math.compare16
   extern   Util.Frame



;; ---------------------------------------------------------------------------
.vtable                 code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void VTable.dispatch( frame[0..1] funcKey, TBLPTR vtable )
;;
;;  Iterates over a list of key-value entries stored in program memory,
;;  searching for a function pointer that matches the key specified.  Each
;;  entry in the key-value list starts with a 16-bit identifier, followed by
;;  the lower 16 bits of a program memory address in little-endian format (the
;;  upper 5 bits are always treated as 0).
;;
;;  This method searches linearly through the list until a matching id or -1
;;  is found.  The ids don't have to be in any particular numerical order, al-
;;  though sorting the most-used entries to the beginning of the list will
;;  improve performance.  If a match isn't found, the vector associated with
;;  the -1 identifier will be used to simulate a "missing_method" call, else
;;  program execution will be transferred to the matching address.
;;
;;  Here's an example of how a vtable might be declared.  Each numerical value
;;  indicates a function id, while the symbols following refer to program
;;  memory locations:
;;
;;     .mySection code
;;     myVTbl:
;;       data     1,  readCoils
;;       data     2,  readDiscretes
;;       data     4,  readInputs
;;       data     15, writeCoils
;;       data     16, writeRegisters
;;       data     20, readFileRecord
;;       data     -1, unsupported      ; required terminator/default handler
;;
VTable.dispatch:
   ; Back up the pointer two bytes to account for the first iteration.
   tblrd*-
   tblrd*-

lookup:
   ; Find the correct function pointer, based on the id specified.
   tblrd*+                          ; skip the function pointer from the last entry
   tblrd*+

   tblrd*+                          ; read the low byte of the id
   movff    TABLAT, Util.Frame + 2
   tblrd*+                          ; read the high byte of the id
   movff    TABLAT, Util.Frame + 3

   ; Compare the two-byte id to the first parameter.
   call     Math.compare16
   bnz      noMatch

vecJump:
   ; Dispatch to the correct method.
   clrf     PCLATU                  ; always 0 for chips with < 64k
   tblrd*+
   movf     TABLAT, W               ; stash low byte to be written last
   tblrd*+
   movff    TABLAT, PCLATH          ; write high byte of new PC
   movwf    PCL                     ; write low byte of new PC

noMatch:
   movf     Util.Frame + 2, W
   cpfseq   Util.Frame + 3          ; are both id bytes equal?
     bra    lookup                  ; no, so can't be -1 (0xffff)
   comf     WREG, F                 ; yes, complement one of them
   bz       vecJump                 ; 0 => id = -1, so we're done
   bra      lookup                  ; otherwise, keep looking



   end
