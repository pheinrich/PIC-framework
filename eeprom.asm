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

   ; Methods
   global   EEPROM.read
   global   EEPROM.write



;; ---------------------------------------------------------------------------
.eeprom                 code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  byte EEPROM.read( byte address )
;;
;;  Reads the EEPROM memory location at the specified address.
;;
EEPROM.read:
   ; Set up to read EEPROM memory.
   movwf    EEADR                ; latch the read target address
   bcf      EECON1, EEPGD        ; EEPROM instead of Flash
   bcf      EECON1, CFGS         ; data memory instead of config/calibration registers

   ; Read the EEPROM location into W.
   bsf      EECON1, RD           ; initiate the EEPROM read
   movf     EEDATA, W            ; copy our value from the latch register
   return



;; ----------------------------------------------
;;  void EEPROM.write( byte value )
;;
;;  Writes a value to the EEPROM address specified via Util.Frame.
;;
EEPROM.write:
   extern   Util.Frame

   ; Set up to write EEPROM memory.
   movwf    EEDATA               ; latch the value we want to write
   movff    Util.Frame, EEADR    ; latch the write target address
   bcf      EECON1, EEPGD        ; EEPROM instead of Flash
   bcf      EECON1, CFGS         ; data memory instead of config/calibration registers

   ; Enable EEPROM writes and disable interrupts.
   bsf      EECON1, WREN
   bcf      INTCON, GIE

   ; Write the security sequence (ensures against spurious writes).
   movlw    0x55
   movwf    EECON2
   movlw    0xaa
   movwf    EECON2

   ; Write the data into the EEPROM location.
   bsf      EECON1, WR           ; initiate the EEPROM write
   btfsc    EECON1, WR           ; is the write complete?
     bra    $-2                  ; no, keep polling until it is

   ; Cleanup after writing the value.
   bcf      PIR2, EEIF           ; clear the EEPROM interrupt flag
   bsf      INTCON, GIE          ; re-enable interrupts
   bcf      EECON1, WREN         ; disable EEPROM writes.
   return



   end
