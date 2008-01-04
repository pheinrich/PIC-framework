;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright © 2006-8  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL$
;;  $Revision$
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
