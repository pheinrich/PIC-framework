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
;;  Wraps basic read/write access to on-chip EEPROM.
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
