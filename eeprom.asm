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
;;  Wraps basic read/write access to on-chip EEPROM.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   include "private.inc"

   ; Public Methods
   global   EEPROM.read
   global   EEPROM.write

   ; Dependencies
   extern   Util.Frame



;; ---------------------------------------------------------------------------
.eeprom                 code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  WREG EEPROM.read( WREG address )
;;
;;  Reads the EEPROM memory location at the specified address, which must fit
;;  in eight bits.  Since most chips have fewer than 256 locations anyway, this
;;  isn't much of an issue.
;;
EEPROM.read:
   ; Set up to read EEPROM memory.
   movwf    EEADR                   ; latch the read target address
   bcf      EECON1, EEPGD           ; EEPROM instead of Flash
   bcf      EECON1, CFGS            ; data memory instead of config/calibration registers

   ; Read the EEPROM location into W.
   bsf      EECON1, RD              ; initiate the EEPROM read
   movf     EEDATA, W               ; copy our value from the latch register
   return



;; ----------------------------------------------
;;  void EEPROM.write( frame[0] value, frame[1] address )
;;
;;  Writes a single value to the EEPROM address specified.  As above, the
;;  the address is limited to the range [0, 255].
;;
EEPROM.write:
   ; Set up to write EEPROM memory.
   movf     Util.Frame, W
   movwf    EEDATA                  ; latch the value we want to write
   movff    Util.Frame + 1, EEADR   ; latch the write target address
   bcf      EECON1, EEPGD           ; EEPROM instead of Flash
   bcf      EECON1, CFGS            ; data memory instead of config/calibration registers

   ; Enable EEPROM writes and disable interrupts.
   bsf      EECON1, WREN
   bcf      INTCON, GIE

   ; Write the security sequence (ensures against spurious writes).
   movlw    0x55
   movwf    EECON2
   movlw    0xaa
   movwf    EECON2

   ; Write the data into the EEPROM location.
   bsf      EECON1, WR              ; initiate the EEPROM write
   btfsc    EECON1, WR              ; is the write complete?
     bra    $-2                     ; no, keep polling until it is

   ; Cleanup after writing the value.
   bcf      PIR2, EEIF              ; clear the EEPROM interrupt flag
   bsf      INTCON, GIE             ; re-enable interrupts
   bcf      EECON1, WREN            ; disable EEPROM writes.
   return



   end
