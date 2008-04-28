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
;;  Provides a basic wrapper to control the M25P-type serial flash memories.
;;  This is a low-voltage 1-Mbit memory that supports SPI up to 50 MHz.
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
   global   M25P.disableWrites
   global   M25P.enableWrites
   global   M25P.eraseAll
   global   M25P.eraseSector
   global   M25P.getId
   global   M25P.getStatus
   global   M25P.powerDown
   global   M25P.powerUp
   global   M25P.readByte
   global   M25P.readBytes
   global   M25P.setStatus
   global   M25P.writeByte
   global   M25P.writeBytes

   ; Dependencies
   extern   SPI.io
   extern   Util.Frame



;; ---------------------------------------------------------------------------
.m25p                	code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void M25P.disableWrites()
;;
;;  Clears the Write Enable Latch bit of the status register, prohibiting
;;  subsequent operations that write to the device.
;;
M25P.disableWrites:
   movlw    0x04
   rcall    beginCommand
   bra      endCommand



;; ----------------------------------------------
;;  void M25P.enableWrites()
;;
;;  Sets the Write Enable Latch bit of the status register, enabling write
;;  operations on the device.
;;
M25P.enableWrites:
   movlw    0x06
   rcall    beginCommand
   bra      endCommand



;; ----------------------------------------------
;;  void M25P.eraseAll()
;;
;;  Resets all memory locations to 0xff, unless one or both Block Protect bits
;;  (BP1, BP0) are set.  In that case, this method does nothing.
;;
;;  This procedure is inherently slow, and may take up to 6 seconds(!) to
;;  complete.  This methods blocks until the Write In Progress (WIP) bit is
;;  reset to 0.
;;
M25P.eraseAll:
   movlw    0xc7
   rcall    beginCommand
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P.eraseSector( frame[0..2] address )
;;
;;  Sets all bits in the specified sector to 1.  Any address in the sector may
;;  be used to indicate which one is to be cleared.  M25P.enableWrites() must
;;  be called prior to this method.
;;
;;  Note that this is a slow operation, taking up to 3 seconds.  This method
;;  blocks until the write completes.
;;
M25P.eraseSector:
   movlw    0xd8
   rcall    beginCommandAddress
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  frame[0], frame[1..2] M25P.getId()
;;
;;  Returns the 1-byte JEDEC manufacturer id (0x20 for STMicroelectronics) and
;;  the 2-byte device identification, which includes the memory type in the
;;  first byte and memory capacity in the second (0x20 and 0x11, respectively,
;;  for the M25P10-A).
;;
;;  Note that this method returns 0 for all values unless the device has the
;;  "X" process technology code.  See M25P.powerUp() for an alternative
;;  identification technique.
;;
M25P.getId:
   movlw    0x9f
   rcall    beginCommand

   ; Shift out the identification info.
   call     SPI.io
   movwf    Util.Frame              ; JEDEC manufacturer id
   call     SPI.io
   movwf    Util.Frame + 1          ; memory type
   call     SPI.io
   movwf    Util.Frame + 2          ; memory capacity

   bra      endCommand



;; ----------------------------------------------
;;  WREG M25P.getStatus()
;;
;;  Returns the current status byte, whose bits are organized as follows:
;;
;;    X------- SRWD     ; Status Register Write Protect
;;    -000----          ; [unused, always read zero]
;;    ----X--- BP1      ; Block Protect 1
;;    -----X-- BP0      ; Block Protect 0
;;    ------X- WEL      ; Write Enable Latch
;;    -------X WIP      ; Write in Progress
;;
M25P.getStatus:
   movlw    0x05
   rcall    beginCommand
   call     SPI.io
   bra      endCommand



;; ----------------------------------------------
;;  void M25P.powerDown()
;;
;;  Enters the extreme low-power consumption mode of the chip, typically
;;  about 5µA.  When in this mode, the device will not respond to any other
;;  commands besides M25P.powerUp().
;;
M25P.powerDown:
   movlw    0xb9
   rcall    beginCommand
   bra      endCommand



;; ----------------------------------------------
;;  WREG M25P.powerUp()
;;
;;  Restores the chip to regular standby mode, drawing about 50µA.  If the
;;  device is in deep power-down mode, this method must be executed before
;;  other commands will be accepted.
;;
;;  This method returns the 1-byte electronic signature of the chip, which
;;  is 0x10 for the M25P10-A.  The device need not be in low-power mode to
;;  call this method, so the signature may be retrieved at any time.
;;
M25P.powerUp:
   movlw    0xab
   rcall    beginCommandAddress
   call     SPI.io
   bra      endCommand



;; ----------------------------------------------
;;  WREG M25P.readByte( frame[0..2] address )
;;
;;  Returns the 8-bit value stored at the memory address specified.
;;
M25P.readByte:
   movlw    0x03
   rcall    beginCommandAddress
   call     SPI.io
   bra      endCommand



;; ----------------------------------------------
;;  void M25P.readBytes( frame[0..2] address, frame[3] count, FSR0 buffer )
;;
;;  Reads up to a page of memory (256 bytes) and copies the data sequentially
;;  to the memory block whose base address is stored in FSR0.  The first
;;  address to be read doesn't actually have to be at a page boundary.  If the
;;  range extends past the end of physical memory, retrieval will resume at
;;  location 0x00000000.  This differs from M25P.writeBytes(), which always
;;  works within the confines of a single page.
;;
;;  A count parameter of 0 indicates 256 bytes should be read.
;;
M25P.readBytes:
   movlw    0x03
   rcall    beginCommandAddress

rdBytes:
   ; Loop over the flash memory range requested.
   call     SPI.io                  ; shift out the next value
   movwf    POSTINC0                ; store the byte and advance pointer
   decfsz   Util.Frame + 3, F       ; count satisfied?
     bra    rdBytes                 ; no, go back for another byte

   bra      endCommand



;; ----------------------------------------------
;;  void M25P.setStatus( WREG status )
;;
M25P.setStatus:
   movwf    Util.Frame + 1
   movlw    0x01
   rcall    beginCommand

   movf     Util.Frame + 1, W
   call     SPI.io
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P.writeByte( WREG value, frame[0..2] address )
;;
;;  Performs a logical AND of the working register and the memory address
;;  specified.  A call to M25P.enableWrites() must preceed this operation.  A
;;  write attempt to a page protected by the Block Protect bits will be ig-
;;  nored.
;;
;;  This method blocks until the write is complete (typically 1.4 to 5 ms).
;;
M25P.writeByte:
   movwf    Util.Frame + 3
   movlw    0x02
   rcall    beginCommandAddress

   movf     Util.Frame + 3, W
   call     SPI.io
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P.writeBytes( frame[0..2] address, frame[3] count, FSR0 buffer )
;;
;;  Performs a logical AND of the data memory pointed to by FSR0 and the Flash
;;  memory starting at the address specified, up to the parameterized count (a
;;  count of 0 indicates 256 bytes should processed).  The Write Enable Latch
;;  must be set prior to this operation.
;;
;;  The write request may extend beyond the page boundary, but the write it-
;;  self never will.  Flash locations past the end of the page will be mapped
;;  to its beginning, resulting in a wrap-around write.  A write attempt to
;;  any page protected by the Block Protect bits will be ignored.
;;
;;  This method blocks until the write completes.
;;
M25P.writeBytes:
   movlw    0x02
   rcall    beginCommandAddress

wrBytes:
   ; Loop over the flash memory range requested.
   movf     POSTINC0, W             ; load the next value and advance pointer
   call     SPI.io                  ; shift in the next value
   decfsz   Util.Frame + 3, W       ; count satisfied?
     bra    wrBytes                 ; no, go back for another byte

   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void beginCommand( WREG command )
;;
;;  Transmits the command byte, usually in advance of numeric parameters.
;;
beginCommand:
   ; Assert chip select and send command.
   bcf      PORTC, RC2
   goto     SPI.io



;; ----------------------------------------------
;;  void beginCommandAddress( WREG command, frame[0..2] address )
;;
;;  Transmits the command byte and 24-bit address specified, usually in advance
;;  of other numeric parameters.  The address should be in little-endian format.
;;
beginCommandAddress:
   ; Send the command.
   bcf      PORTC, RC2
   call     SPI.io

   ; Send the memory address in network byte order (big-endian).
   movf     Util.Frame + 2, W       ; upper byte
   call     SPI.io
   movf     Util.Frame + 1, W       ; high byte
   call     SPI.io
   movf     Util.Frame + 0, W       ; low byte
   call     SPI.io

   return



;; ----------------------------------------------
;;  void endCommand()
;;
;;  Terminates the current command by de-asserting the chip select line.
;;
endCommand:
   ; De-assert chip select.
   bsf      PORTC, RC2
   return



;; ----------------------------------------------
;;  void endCommandConfirmWrite()
;;
;;  Terminates the current command and blocks until the Write In Progress (WIP)
;;  flag is clear.
;;
endCommandConfirmWrite:
   bsf      PORTC, RC2

   movlw    0xff
waitBusy:
   nop
   decfsz   WREG
     bra    waitBusy

   movlw    0x05
   rcall    beginCommand

waitChk:
   ; Check the WIP status bit.
   call     SPI.io                  ; request status register
   btfsc    WREG, 0                 ; is WIP clear?
     bra    waitChk                 ; no, keep waiting

   ; Write is complete, so de-assert the chip select line.
   bra      endCommand



   end
