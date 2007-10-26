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
;;  Provides a basic wrapper to the SPI functions used to control the M25P10.
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
                        udata_acs
;; ---------------------------------------------------------------------------



;; ---------------------------------------------------------------------------
.m25p10                	code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void M25P10.bulkErase()
;;
M25P10.bulkErase:
   movlw    0xc7
   rcall    beginCommand
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.powerDown()
;;
M25P10.powerDown:
   movlw    0xb9
   rcall    beginCommand
   bra      endCommand



;; ----------------------------------------------
;;  void M25P10.powerUp()
;;
M25P10.powerUp:
   movlw    0xab
   rcall    beginCommand
   bra      endCommand



;; ----------------------------------------------
;;  byte M25P10.readByte( byte[0..2] address )
;;
M25P10.readByte:
   movlw    0x03
   rcall    beginCommandAddress
   call     SPI.io
   bra      endCommand



;; ----------------------------------------------
;;  void M25P10.readBytes( byte[0..2] address, byte[3] count, byte* buffer )
;;
M25P10.readBytes:
   movlw    0x03
   rcall    beginCommandAddress

rdBytes:
   call     SPI.io
   movwf    POSTINC0
   decfsz   Util.Frame + 3, F
     bra    rdBytes

   bra      endCommand



;; ----------------------------------------------
;;  byte[3] M25P10.readId()
;;
M25P10.readId:
   movlw    0x9f
   rcall    beginCommand

   call     SPI.io
   movwf    Util.Frame
   call     SPI.io
   movwf    Util.Frame + 1
   call     SPI.io
   movwf    Util.Frame + 2

   bra      endCommand



;; ----------------------------------------------
;;  byte M25P10.readStatus()
;;
M25P10.readStatus:
   movlw    0x05
   goto     SPI.ioByte



;; ----------------------------------------------
;;  void M25P10.sectorErase( byte[0..2] address )
;;
M25P10.sectorErase:
   movlw    0xd8
   rcall    beginCommandAddress
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.writeByte( byte value, byte[0..2] address )
;;
M25P10.writeByte:
   movwf    Util.Frame + 3
   movlw    0x02
   rcall    beginCommandAddress

   movf     Util.Frame + 3, W
   call     SPI.io
   bra      endCommandConfirmWrite



;; ----------------------------------------------
;;  void M25P10.writeBytes( byte[0..2] address, byte* buffer )
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
;;  void M25P10.writeStatus( byte )
;;
M25P10.writeStatus:
   movwf    Util.Frame + 1
   movlw    0x01
   movwf    Util.Frame
   call     SPI.ioWord
   bra      waitForWriteComplete



;; ----------------------------------------------
;;  void beginCommand( byte command )
;;
beginCommand:
   bcf      PORTC, RC2
   goto     SPI.io



;; ----------------------------------------------
;;  void beginCommandAddress( byte command, byte[0..2] address )
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
