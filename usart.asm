;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright � 2006,7  Peter Heinrich
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

   ; Variables
   global   USART.HookRX
   global   USART.HookTX
   global   USART.Parity
   global   USART.Read
   global   USART.Status
   global   USART.Write

   ; Methods
   global   USART.init
   global   USART.isrReceive
   global   USART.isrTransmit
   global   USART.send



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

USART.Parity            res   1  ; USART.kParity_XXX from framework.inc
USART.HookRX            res   2  ; Pointer to reception callback function
USART.HookTX            res   2  ; Pointer to transmission callback function

USART.Read              res   1  ; Holds last byte received
USART.Write             res   1  ; Holds the next byte to be transmitted
USART.Status            res   1  ; Tracks errors
                        ; XXXX----           ; reserved
                        ; ----1--- PERR      ; parity error
                        ; -----1-- FERR      ; framing error
                        ; ------1- OERR      ; overflow error
                        ; -------X RX9D      ; last parity bit received



;; ---------------------------------------------------------------------------
.usart                  code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  byte USART.calcParity( byte value )
;;
;;  Calculates the even parity of the byte specified in W.  The even parity is
;;  the 1-bit sum of all bits in the byte (also equivalent to XOR-ing them all
;;  together); the odd parity is the complement of that.  The result is re-
;;  turned in W.
;;
USART.calcParity:
   extern   Util.Scratch

   ; Copy W into a temporary variable.
   movwf    Util.Scratch         ; Scratch = |a|b|c|d|e|f|g|h|

   ; XOR the nybbles of W together.
   swapf    WREG                 ; W = |e|f|g|h|a|b|c|d|
   xorwf    Util.Scratch         ; Scratch = |e^a|f^b|g^c|h^d|a^e|b^f|c^g|d^h|

   ; Now shift the value by 1 in order to XOR adjacent bits together.
   rrcf     Util.Scratch, W      ; W = |?|e^a|f^b|g^c|h^d|a^e|b^f|c^g|
   xorwf    Util.Scratch         ; Scratch = |?^e^a|e^a^f^b|f^b^g^c|g^c^h^d|h^d^a^e|a^e^b^f|b^f^c^g|c^g^d^h|

   ; Note that |bit 2| = a^e^b^f, which is the parity of half the bits in the
   ; byte.  |bit 0| = c^g^d^h, the parity of the other half, so |bit 2| ^ |bit 0|
   ; is the parity for the whole byte.  If |bit 2| = 0, just take the value of
   ; |bit 0|, since parity = 0 ^ |bit 0| = |bit 0|.  For |bit 2| = 1, the value is
   ; complemented, since parity = 1 ^ |bit 0| = !|bit 0|.
   btfsc    Util.Scratch, 2      ; is a^e^b^f = 0?
     btg    Util.Scratch, 0      ; no, toggle bit 0
   movf     Util.Scratch, W      ; yes, we're done
   andlw    0x01                 ; mask off all but the LSb.

   return



;; ----------------------------------------------
;;  void USART.getParity()
;;
;;  Based on the current parity checking preference, determines whether the
;;  received byte appears correct.  There are five possible parity checks that
;;  may be performed.
;;
;;     USART.kParity_None   --  the parity bit is ignored
;;     USART.kParity_Even   --  the byte's set-bit count must be even
;;     USART.kParity_Odd    --  the byte's set-bit count must be odd
;;     USART.kParity_Mark   --  the parity bit must always be set
;;     USART.kParity_Space  --  the parity bit must always be clear
;;
;;  This method takes no parameters.  Instead, it refers to USART.Read for the
;;  most recent byte.  Depending on the operation mode of the USART, eight or
;;  nine bits may have been received.  To support parity checking in 8-bit
;;  mode, one bit must be reserved in the byte itself, resulting in seven sig-
;;  nificant bits for each character.  The MSb is set aside for this purpose.
;;  In 9-bit mode (or if no parity checking is performed), a full eight bits
;;  will comprise the data.
;;
;;  If parity checking is enabled but the received parity doesn't match the
;;  expected parity, PERR will be set in USART.Status to indicate a parity
;;  error.
;;
USART.getParity:
   ; Assume no parity error.
   bcf      USART.Status, PERR

   ; If not operating in 9-bit mode, the parity bit will come from the high bit
   ; of the byte itself.
   btfsc    RCSTA, RX9           ; USART in 9-bit mode?
     bra    getCheckSpace        ; yes, skip the special handling

   ; The USART is receiving in 8-bit mode, so copy the parity bit from the MSb
   ; of the byte read (then clear it}.
   bcf      USART.Status, RX9D   ; assume the high bit is clear
   btfsc    USART.Read, 7        ; is it actually set?
     bsf    USART.Status, RX9D   ; yes, set the parity status bit
   bcf      USART.Read, 7        ; regardless, strip parity bit from byte

getCheckSpace:
   ; Figure out what kind of parity checking we should do.
   movlw    USART.kParity_Space
   cpfseq   USART.Parity         ; is parity type Space?
     bra    getCheckMark         ; no, check Mark

   ; Check Space parity (bit must always be clear).
   btfsc    USART.Status, RX9D   ; is parity bit clear?
     bsf    USART.Status, PERR   ; no, parity error
   return                        ; yes, yay!

getCheckMark:
   movlw    USART.kParity_Mark
   cpfseq   USART.Parity         ; is parity type Mark?
     bra    getCompute           ; no, compute the expected parity

   ; Check Mark parity (bit must always be set).
   btfss    USART.Status, RX9D   ; is parity bit set?
     bsf    USART.Status, PERR   ; no, parity error
   return                        ; yes, yay!

getCompute:
   ; Compute the expected parity for the byte received.
   movf     USART.Read, W        ; W = received byte
   rcall    USART.calcParity     ; W = expected parity
   xorwf    USART.Status         ; combine with the parity received

   ; Check Odd parity (sum of set bits mod 2 must be 1).
   movlw    USART.kParity_Odd
   cpfslt   USART.Parity         ; is parity type Odd?
     btg    USART.Status, RX9D   ; yes, complement result

   ; If the final result is not 0, the parity check fails.
   btfsc    USART.Status, RX9D   ; is computed parity 0?
     bsf    USART.Status, PERR   ; no, parity error 
   return                        ; yes, yay! 



;; ----------------------------------------------
;;  void USART.init( bool ascii, enum baud, enum parity )
;;
;;  Initializes the serial port hardware to support asynchronous reception and
;;  transmission.  The baud rate, byte length (8 or 9 bits), and parity check
;;  type are specified on the pseudo-stackframe.  Parity is handled in soft-
;;  ware since hardware parity isn't supported.
;;
USART.init:
   extern   Util.Frame

   ; Set the I/O direction for the RX and TX pins.
   bcf      TRISC, RC6           ; RC6/TX/CK will be an output
   bsf      TRISC, RC7           ; RC7/RX/DT will be an input

   ; Stash some initialization parameters.
   movff    Util.Frame + 1, SPBRG ; specify baud rate
   movff    Util.Frame + 2, USART.Parity ; indicate software parity type

   ; Specify how data is transmitted.
   movlw    b'01100100'
            ; X-------           ; [not used in asynchronous mode]
            ; -1------ TX9       ; assume 8-bit characters (+1 parity)
            ; --1----- TXEN      ; enable the transmitter
            ; ---0---- SYNC      ; be asynchronous
            ; ----X---           ; [unimplemented]
            ; -----1-- BRGH      ; use high-speed baud rate
            ; ------X-           ; [read-only shift register status]
            ; -------X           ; [used only during actual transmission]
   movwf    TXSTA

   ; Specify how data is received.
   movlw    b'11010000'
            ; 1------- SPEN      ; enable the serial port
            ; -1------ RX9       ; assume 8-bit characters (+1 parity)
            ; --X-----           ; [not used in asynchronous mode]
            ; ---1---- CREN      ; enable receiver
            ; ----0--- ADDEN     ; don't perform special address detection
            ; -----XXX           ; [read-only status/data bits]
   movwf    RCSTA

   ; Flush the buffer.
   clrf     RCREG
   clrf     RCREG
   clrf     RCREG

   ; Test our 9-bit character assumption.
   movf     Util.Frame
   bz       initInts             ; if correct, we're done

   bcf      TXSTA, TX9           ; otherwise, use 7-bit characters
   bcf      RCSTA, RX9

initInts:
   ; Enable interrupts and we're all done.
   bsf      PIE1, RCIE           ; character received
   return



;; ----------------------------------------------
;;  void USART.send( byte )
;;
;;  Attempts to send a byte at the request of the application.  This method
;;  calculates the correct parity, if necessary, and initializes the correct
;;  bit to reflect it (TX9D or the MSb of the byte itself).  Generally called
;;  as part of a callback sequence.
;;
USART.send:
   movwf    USART.Write
   rcall    USART.setParity
   movff    USART.Write, TXREG
   return



;; ----------------------------------------------
;;  void USART.setParity()
;;
;;  Calculates the parity of the byte in USART.Write, taking into account the
;;  parity check setting (see USART.getParity for more information).  The re-
;;  sult is copied to the TX9D or the MSb of the byte itself, depending on the
;;  operating mode of the USART.  If parity checking is disabled, no parity is
;;  calculated and file registers are left unchanged.
;;
USART.setParity:
   ; If configured for no parity, we're done.
   movlw    USART.kParity_None
   cpfsgt   USART.Parity         ; is parity checking enabled?
     return                      ; no, we're finished

   ; Parity checking is turned on, so determine what kind we should use.
   bcf      TXSTA, TX9D          ; assume no parity
   movlw    USART.kParity_Space
   cpfseq   USART.Parity         ; is parity type Space?
      bra   setCheckMark         ; no, check Mark
   bra      setCopy              ; yes, leave bit clear

setCheckMark:
   movlw    USART.kParity_Mark
   cpfseq   USART.Parity         ; is parity type Mark?
     bra    setCompute           ; no, compute parity
   bra      setToggle            ; yes, set the bit

setCompute:
   ; If the operating mode is 7-bit, the MSb is garbage data.
   movf     USART.Write, W
   btfss    TXSTA, TX9           ; USART in 7-bit mode?
     andlw  0x7f                 ; yes, mask off the MSb
   movwf    USART.Write          ; resave 7-bit character

   ; Calculate the parity of the 8-bit byte or 7-bit character, depending on the
   ; USART operating mode.
   rcall    USART.calcParity
   bz       setCheckOdd
   bsf      TXSTA, TX9D
   
setCheckOdd:
   ; Check Odd parity (sum of set bits mod 2 must be 1).
   movlw    USART.kParity_Odd
   cpfslt   USART.Parity         ; is parity type Odd?
setToggle:
     btg    TXSTA, TX9D          ; yes, complement result

setCopy:
   ; Copy the value to the byte itself, if necessary.
   btfsc    TXSTA, TX9           ; USART in 8-bit mode?
     return                      ; no, we're done
   bcf      USART.Write, 7       ; yes, assume no parity

   btfsc    TXSTA, TX9D          ; is parity bit set?
     bsf    USART.Write, 7       ; yes, copy bit to MSb
   return                        ; no, we're done



;; ---------------------------------------------------------------------------
.isr                    code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void USART.isrReceive()
;;
;;  Handles reception of a single byte via the USART.  Framing errors and input
;;  buffer overflows are detected, as well as parity checking (if appropriate).
;;
USART.isrReceive:
   ; Read the current state of the hardware.
   movf     RCSTA, W
   andlw    (1 << FERR) | (1 << OERR) | (1 << RX9D)
   movwf    USART.Status

   ; Read the byte and check parity if necessary.
   movff    RCREG, USART.Read    ; this will also clear the interrupt
   tstfsz   USART.Parity         ; is parity checking desired?
     call   USART.getParity      ; yes, verify the value

   ; If there was a reception error, we need to clear it in software.
   bcf      RCSTA, CREN          ; swizzle the bit to clear error, if any
   bsf      RCSTA, CREN          ; (if not, this should be harmless)

   ; If the reception hook is set, dispatch to it at last.
   movf     USART.HookRX, W
   iorwf    USART.HookRX + 1, W  ; is the vector null?
   bz       rxDone               ; yes, exit

   ; The hook vector is non-null, so push the current PC, replace the pushed
   ; address with the vectored address, then RETURN to jump through the function
   ; pointer. 
   push
   movf     USART.HookRX, W      ; can't movff to TOSL
   movwf    TOSL
   movf     USART.HookRX + 1, W  ; can't movff to TOSH, either
   movwf    TOSH

rxDone:
   return
   

;; ----------------------------------------------
;;  void USART.isrTransmit()
;;
;;  Handles reloading the USART transmission buffer with the next byte to be
;;  sent.  This method is called as a result of an interrupt generated after
;;  the last transmission (TXIF).
;;
USART.isrTransmit:
   ; We defer the handling of this interrupt, since the behavior is so appli-
   ; cation-specific.  Transfer control to the transmission hook, if set.
   movf     USART.HookTX, W
   iorwf    USART.HookTX + 1, W  ; is the vector null?
   bz       txDone               ; yes, exit

   ; The hook vector is non-null, so push the current PC, replace the pushed
   ; address with the vectored address, then RETURN to jump through the function
   ; pointer. 
   push
   movf     USART.HookTX, W      ; can't movff to TOSL
   movwf    TOSL
   movf     USART.HookTX + 1, W  ; can't movff to TOSH, either
   movwf    TOSH

txDone:
   return



   end
