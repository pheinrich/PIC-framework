;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright � 2006-8  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL$
;;  $Revision$
;;
;;  Provides SPI initialization and wrapper routines for reading and writing
;;  bytes and words on the SPI bus.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   include "private.inc"

   ; Global Variables
ifdef SPIDEBUG
   global   SPI.Debug
endif
   global   SPI.Queue

   ; Public Methods
   global   SPI.init
   global   SPI.io
   global   SPI.ioByte
   global   SPI.ioWord



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

ifdef SPIDEBUG
SPI.Debug               res   1
endif
SPI.Queue               res   4



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
            ; XX----XX              ; RC<7:6> and RC<1:0> remain unchanged
            ; --0000--              ; RC<5:2> start as outputs
   andwf    TRISC, F
   bsf      TRISC, RC4              ; RC4/SDI/SDA will be an input

   ; Choose when data is sampled and on which clock edge.
   bcf      SSPSTAT, SMP            ; input data sampled at middle of data output time
   bsf      SSPSTAT, CKE            ; data transmitted on rising edge of SCK
   bsf      PORTC, RC2              ; RC2/CCP1 will act as CS/ and starts high

   ; Turn on SPI handling and set some functional parameters.
   movlw    b'00100000'
            ; X-------              ; [used only during transmission]
            ; -X------              ; [not used in Master mode]
            ; --1----- SSPEN        ; enable serial port
            ; ---0---- CKP          ; idle clock polarity is low
            ; ----0000 SSPMx        ; SPI Master mode, clock = Fosc / 4
   movwf    SSPCON1

 ifdef SPIDEBUG
   ; Reset the debug flag to false.
   clrf     SPI.Debug
 endif

   return



;; ----------------------------------------------
;;  WREG SPI.io( WREG value )
;;
;;  Shifts the byte in W onto the SPI bus, simultaneously shifting eight bits
;;  out, overwriting W's previous value.  Additional bytes may be similarly
;;  processed during the same operation, which is handy for sending 16-bit
;;  words (or greater), or for devices that support CS/ sharing.  In both
;;  cases, only the last byte will be returned in W, of course.
;;
;;  It's up to the caller to ensure the CS/ line is actually low for SOMEONE,
;;  otherwise no one's listening and no data will be returned, either.
;;
SPI.io:
 ifdef SPIDEBUG
   ; If debuging, listen in on every byte we send.  Add it to the buffer pointed
   ; to by FSR0.
   tstfsz   SPI.Debug
     movwf  POSTINC0
 endif

   ; Transmit the byte over the SPI bus.
   movwf    SSPBUF                  ; shift 8 bits out
 ifndef SPIEMULATED
   btfss    SSPSTAT, BF             ; is the shift complete?
     bra    $-2                     ; no, wait until it is
 endif

   ; Shifting out means we shifted in, too.
   movf     SSPBUF, W               ; retrieve bits we received
   return



;; ----------------------------------------------
;;  WREG SPI.ioByte( WREG value )
;;
;;  Assumes the CS/ (Chip Select) line is addressable as RC2 and asserts it
;;  low, then writes a single byte onto the SPI bus.  Eight bits are shifted
;;  off the bus simultaneously and returned in W.
;;
SPI.ioByte:
   bcf      PORTC, RC2              ; assert CS/ line
   rcall    SPI.io                  ; write/read 8 bits
   bsf      PORTC, RC2              ; turn off chip select

   return



;; ----------------------------------------------
;;  void SPI.ioWord( queue[0..1] value )
;;
;;  Like SPI.ioByte(), except that two bytes are transferred instead of one.
;;  Since W is only 8 bits wide, the word to be transmitted is passed via
;;  SPI.Queue, which also receives the result.
;;
SPI.ioWord:
   ; Assert chip select, as above.
   bcf      PORTC, RC2

   ; Shift 16 bits out and in, saving the result.
   movf     SPI.Queue, W            ; fetch MSB of word to be transmitted
   rcall    SPI.io                  ; write/read 8 bits
   movwf    SPI.Queue               ; store bits shifted in

   movf     SPI.Queue + 1, W        ; fetch LSB of word to be transmitted
   rcall    SPI.io                  ; write/read 8 bits
   movwf    SPI.Queue + 1           ; store bits shifted in

   ; Turn off chip select and return.
   bsf      PORTC, RC2
   return



   end
