;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;  Copyright (c) 2006,2008  Peter Heinrich
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
;;  Provides SPI initialization and wrapper routines for reading and writing
;;  bytes and words on the SPI bus.
;; ---------------------------------------------------------------------------



   include "private.inc"


   ; Global Variables
#ifdef SPIDEBUG
   global   SPI.Debug
#endif
   global   SPI.Queue

   ; Public Methods
   global   SPI.init
   global   SPI.io
   global   SPI.ioByte
   global   SPI.ioWord



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

#ifdef SPIDEBUG
SPI.Debug               res   1
#endif
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
   bcf      TRISA, RA2              ; make RA3/AN3/VREF+ an output, if not already
   bcf      TRISC, RC3              ; make RC3/SCK/SCL an output, if not already
   bsf      TRISC, RC4              ; make RC4/SDI/SDA an input, if not already
   bcf      TRISC, RC5              ; make RC5/SDO an output, if not already

   ; Choose when data is sampled and on which clock edge.
   bcf      SSPSTAT, SMP            ; input data sampled at middle of data output time
   bsf      SSPSTAT, CKE            ; data transmitted on rising edge of SCK
   bcf      PORTA, RA3              ; RA3/AN3/VREF+ will act as CS/ (but active-H)

   ; Turn on SPI handling and set some functional parameters.
   movlw    b'00100000'
            ; X-------              ; [used only during transmission]
            ; -X------              ; [not used in Master mode]
            ; --1----- SSPEN        ; enable serial port
            ; ---0---- CKP          ; idle clock polarity is low
            ; ----0000 SSPMx        ; SPI Master mode, clock = Fosc / 4
   movwf    SSPCON1

#ifdef SPIDEBUG
   ; Reset the debug flag to false.
   clrf     SPI.Debug
#endif

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
#ifdef SPIDEBUG
   ; If debuging, listen in on every byte we send.  Add it to the buffer pointed
   ; to by FSR0.
   tstfsz   SPI.Debug
     movwf  POSTINC0
#endif

   ; Transmit the byte over the SPI bus.
   movwf    SSPBUF                  ; shift 8 bits out
#ifndef SPIEMULATED
   btfss    SSPSTAT, BF             ; is the shift complete?
     bra    $-2                     ; no, wait until it is
#endif

   ; Shifting out means we shifted in, too.
   movf     SSPBUF, W               ; retrieve bits we received
   return



;; ----------------------------------------------
;;  WREG SPI.ioByte( WREG value )
;;
;;  Assumes the CS/ (Chip Select) line is addressable as RA3 active-H and
;;  asserts it, then writes a single byte onto the SPI bus.  Eight bits are
;;  shifted off the bus simultaneously and returned in W.
;;
SPI.ioByte:
   bsf      PORTA, RA3              ; assert CS/ line
   rcall    SPI.io                  ; write/read 8 bits
   bcf      PORTA, RA3              ; turn off chip select

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
   bsf      PORTA, RA3

   ; Shift 16 bits out and in, saving the result.
   movf     SPI.Queue, W            ; fetch MSB of word to be transmitted
   rcall    SPI.io                  ; write/read 8 bits
   movwf    SPI.Queue               ; store bits shifted in

   movf     SPI.Queue + 1, W        ; fetch LSB of word to be transmitted
   rcall    SPI.io                  ; write/read 8 bits
   movwf    SPI.Queue + 1           ; store bits shifted in

   ; Turn off chip select and return.
   bcf      PORTA, RA3
   return



   end
