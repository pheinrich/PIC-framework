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
;;  Provides a basic wrapper to control the M25P10-A serial flash memory chip.
;;  This is a low-voltage 1 Mbit memory that supports SPI up to 50 MHz.
;;
;;  Due to the nature of flash memory, writes can only change bits from 1 to
;;  0, not 0 to 1.  This means a cell holding 0xff may be reprogrammed to any
;;  value, but one holding 0xa2 (for example) may never change to, say, 0xf6.
;;  Standard operating procedure with flash memory, therefore, is to "erase"
;;  cells to 0xff before storing values in them.  Unfortunately, this isn't
;;  possible on individual locations, but must be done at the sector level,
;;  or for the whole chip at once.  In addition, this procedure is usually
;;  very slow (~1s/sector or ~3s/chip for the M25P10-A), although reads are
;;  very fast and write speed is acceptable.
;;
;;  Like other NOR-based EEPROMs, the M25P10-A supports about ~100k erase/
;;  program cycles per sector.  This makes it a good candidate for static
;;  data or code, but repeatedly changing data risks data loss due to chip
;;  degradation and failure.  This may be mitigated with "wear leveling," but
;;  that is beyond the scope of this simple wrapper.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   #include "private.inc"

   ; Public Methods
   global   M25P10.bulkErase
   global   M25P10.powerDown
   global   M25P10.powerUp
   global   M25P10.readByte
   global   M25P10.readBytes
   global   M25P10.readId
   global   M25P10.readStatus
   global   M25P10.sectorErase
   global   M25P10.writeByte
   global   M25P10.writeBytes
   global   M25P10.writeDisable
   global   M25P10.writeEnable
   global   M25P10.writeStatus

   ; Dependencies
   extern   SPI.io
   extern   SPI.ioByte
   extern   SPI.ioWord
   extern   Util.Frame



;; ---------------------------------------------------------------------------
.m25p10                	code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void M25P10.bulkErase()
;;
;;  Resets all memory locations to 0xff, unless one or both Block Protect bits
;;  (BP1, BP0) are set.  In that case, this method does nothing.
;;
;;  This procedure is inherently slow, and may take up to 6 seconds(!) to
;;  complete.  This methods blocks until the Write In Progress (WIP) bit is
;;  reset to 0.
;;
M25P10.bulkErase:
   movlw    0xc7
   rcall    beginCommand
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.powerDown()
;;
;;  Enters the extreme low-power consumption mode of the chip, typically
;;  about 5µA.  When in this mode, the device will not respond to any other
;;  commands besides M25P10.powerUp().
;;
M25P10.powerDown:
   movlw    0xb9
   rcall    beginCommand
   bra      endCommand



;; ----------------------------------------------
;;  WREG M25P10.powerUp()
;;
;;  Restores the chip to regular standby mode, drawing about 50µA.  If the
;;  device is in deep power-down mode, this method must be executed before
;;  other commands will be accepted.
;;
;;  This method returns the 1-byte electronic signature of the chip, which
;;  is 0x10 for the M25P10-A.  The device need not be in low-power mode to
;;  call this method, so the signature may be retrieved at any time.
;;
M25P10.powerUp:
   movlw    0xab
   rcall    beginCommand
   call     SPI.io
   bra      endCommand



;; ----------------------------------------------
;;  WREG M25P10.readByte( frame[0..2] address )
;;
;;  Returns the 8-bit value stored at the memory address specified.
;;
M25P10.readByte:
   movlw    0x03
   rcall    beginCommandAddress
   call     SPI.io
   bra      endCommand



;; ----------------------------------------------
;;  void M25P10.readBytes( frame[0..2] address, frame[3] count, FSR0 buffer )
;;
;;  Reads up to a page of memory (256 bytes) and copies the data sequentially
;;  to the memory block whose base address is stored in FSR0.  The first
;;  address to be read doesn't actually have to be at a page boundary.  If the
;;  range extends past the end of physical memory, retrieval will resume at
;;  location 0x00000000.
;;
;;  A count parameter of 0 indicates a full 256 bytes should be read.
;;
M25P10.readBytes:
   movlw    0x03
   rcall    beginCommandAddress

rdBytes:
   ; Loop over the flash memory range requested.
   call     SPI.io               ; shift out the next value
   movwf    POSTINC0             ; store the byte and advance pointer
   decfsz   Util.Frame + 3, F    ; count satisfied?
     bra    rdBytes              ; no, go back for another byte

   bra      endCommand



;; ----------------------------------------------
;;  frame[0], frame[1..2] M25P10.readId()
;;
;;  Returns the 1-byte JEDEC manufacturer id (0x20 for STMicroelectronics) and
;;  the 2-byte device identification, which includes the memory type in the
;;  first byte and memory capacity in the second byte (0x20 and 0x11, respect-
;;  ively, for the M25P10-A).
;;
;;  Note that this method returns 0 for both values unless the device has the
;;  "X" process technology code.  See M25P10.powerUp() for an alternative
;;  identification technique.
;;
M25P10.readId:
   movlw    0x9f
   rcall    beginCommand

   ; Shift out the identification info.
   call     SPI.io
   movwf    Util.Frame           ; JEDEC manufacturer id
   call     SPI.io
   movwf    Util.Frame + 1       ; memory type
   call     SPI.io
   movwf    Util.Frame + 2       ; memory capacity

   bra      endCommand



;; ----------------------------------------------
;;  WREG M25P10.readStatus()
;;
M25P10.readStatus:
   movlw    0x05
   goto     SPI.ioByte



;; ----------------------------------------------
;;  void M25P10.sectorErase( frame[0..2] address )
;;
M25P10.sectorErase:
   movlw    0xd8
   rcall    beginCommandAddress
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.writeByte( WREG value, frame[0..2] address )
;;
M25P10.writeByte:
   movwf    Util.Frame + 3
   movlw    0x02
   rcall    beginCommandAddress

   movf     Util.Frame + 3, W
   call     SPI.io
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.writeBytes( frame[0..2] address, FSR buffer )
;;
M25P10.writeBytes:
   movlw    0x02
   rcall    beginCommandAddress

wrBytes:
   movf     POSTINC0, W
   call     SPI.io
   decfsz   Util.Frame + 3, W
     bra    wrBytes

   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.writeDisable()
;;
M25P10.writeDisable:
   movlw    0x04
   goto     SPI.ioByte



;; ----------------------------------------------
;;  void M25P10.writeEnable()
;;
M25P10.writeEnable:
   movlw    0x06
   goto     SPI.ioByte



;; ----------------------------------------------
;;  void M25P10.writeStatus( WREG status )
;;
M25P10.writeStatus:
   movwf    Util.Frame + 1
   movlw    0x01
   movwf    Util.Frame
   call     SPI.ioWord
   bra      waitForWriteComplete



;; ----------------------------------------------
;;  void beginCommand( WREG command )
;;
beginCommand:
   bcf      PORTC, RC2
   goto     SPI.io



;; ----------------------------------------------
;;  void beginCommandAddress( WREG command, frame[0..2] address )
;;
beginCommandAddress:
   bcf      PORTC, RC2
   call     SPI.io

   movf     Util.Frame, W
   call     SPI.io
   movf     Util.Frame + 1, W
   call     SPI.io
   movf     Util.Frame + 2, W
   call     SPI.io

   return



;; ----------------------------------------------
;;  void endCommand()
;;
endCommand:
   bsf      PORTC, RC2
   return



;; ----------------------------------------------
;;  void endCommandConfirmWrite()
;;
endCommandConfirmWrite:
   bsf      PORTC, RC2
   nop
   ; Fall through to next routine.



;; ----------------------------------------------
;;  void waitForWriteComplete()
;;
waitForWriteComplete:
   bcf      PORTC, RC2
   movlw    0x05

waitChk:
   call     SPI.io
   btfsc    WREG, 0
     bra    waitChk

   bsf      PORTC, RC2
   return



   end
