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
   global   SPI.init
   global   SPI.ioByte
   global   SPI.ioWord



;; ---------------------------------------------------------------------------
.spi                    code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void SPI.init()
;;
;;  Initializes the device to turn on SPI handling (with standard options) and
;;  set the I/O directions on the appropriate pins.
;;
SPI.init:
   ; Set the I/O direction for each of the lines used by SPI.
   movlw    b'11000011'
            ; XX----XX           ; RC<7:6> and RC<1:0> remain unchanged
            ; --0000--           ; RC<5:2> start as outputs
   andwf    TRISC
   bsf      TRISC, RC4           ; RC4/SDI/SDA will be an input

   ; Choose when data is sampled and on which clock edge.
   bcf      SSPSTAT, SMP         ; input data sampled at middle of data output time
   bsf      SSPSTAT, CKE         ; data transmitted on rising edge of SCK
   bsf      PORTC, RC2           ; RC2/CCP1 will act as CS/ and starts high

   ; Turn on SPI handling and set some functional parameters.
   movlw    b'00100000'
            ; X-------           ; [used only during transmission]
            ; -X------           ; [not used in Master mode]
            ; --1----- SSPEN     ; enable serial port
            ; ---0---- CKP       ; idle clock polarity is low
            ; ----0000 SSPMx     ; SPI Master mode, clock = Fosc / 4
   movwf    SSPCON1
   return



;; ----------------------------------------------
;;  byte SPI.ioByte( byte value )
;;
;;  Assumes the CS/ (Chip Select) line is addressable as RC2 and asserts it
;;  low, then writes a single byte onto the SPI bus.  Eight bits are shifted
;;  off the bus simultaneously and returned in W.
;;
SPI.ioByte:
   bcf      PORTC, RC2           ; assert CS/ line
   SPIPut                        ; write/read 8 bits
   bsf      PORTC, RC2           ; turn off chip select

   return



;; ----------------------------------------------
;;  void SPI.ioWord()
;;
;;  Like SPI.ioByte(), except that two bytes are transferred instead of one.
;;  Since W is only 8 bits wide, the word to be transmitted is passed via
;;  Util.Frame, which also receives the result.
;;
SPI.ioWord:
   extern   Util.Frame

   ; Assert chip select, as above.
   bcf      PORTC, RC2

   ; Shift 16 bits out and in, saving the result.
   movf     Util.Frame, W        ; fetch LSB of word to be transmitted
   SPIPut                        ; write/read 8 bits
   movwf    Util.Frame           ; store bits shifted in

   movf     Util.Frame + 1, W    ; fetch MSB of word to be transmitted
   SPIPut                        ; write/read 8 bits
   movwf    Util.Frame + 1       ; store bits shifted in

   ; Turn off chip select and return.
   bsf      PORTC, RC2
   return



   end
