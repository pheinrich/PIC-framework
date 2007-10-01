;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;
;;  Copyright © 2006,7  Peter Heinrich
;;  All Rights Reserved
;;
;;  $URL:$
;;  $Revision:$
;;
;; ---------------------------------------------------------------------------
;;  $Author:$
;;  $Date:$
;; ---------------------------------------------------------------------------



   #include "private.inc"

   ; Variables
   global   Clock.Alarm
   global   Clock.Ticks

   ; Methods
   global   Clock.init
   global   Clock.update
   global   Clock.waitMS
   


kMIPS                   equ   kFrequency >> 2
kTickPrescalarLog2      equ   8
kInstructionsPerMS      equ   (kMIPS >> kTickPrescalarLog2) / 1000
kTickDelay              equ   0xffff - kInstructionsPerMS



;; ---------------------------------------------------------------------------
            udata_acs
;; ---------------------------------------------------------------------------

Clock.Alarm       res   4
Clock.Ticks       res   4



;; ---------------------------------------------------------------------------
.clock      code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void Clock.init()
;;
;;  Initializes TIMER0 to be a general-purpose wallclock with millisecond
;;  resolution.
;;
Clock.init:
   clrf     Clock.Ticks
   clrf     Clock.Ticks + 1
   clrf     Clock.Ticks + 2
   clrf     Clock.Ticks + 3

   ; Fall through to the next method.



;; ----------------------------------------------
;;  void Clock.reset()
;;
;;  Reset the countdown period for the millisecond timer.
;;
Clock.reset:
   ; Set up the basic timer operation.
   movlw    b'00000111'
            ; 0------- TMR0ON    ; turn off timer
            ; -0------ T08BIT    ; use 16-bit counter
            ; --0----- T0CS      ; use internal instruction clock
            ; ---X---- TOSE      ; [not used with internal instruction clock]
            ; ----0--- PSA       ; prescale timer output
            ; -----111 T0PSx     ; TickPrescalarLog2
   movwf    T0CON

   ; Establish the countdown based on calculated MIPS.
   movlw    kTickDelay >> 8
   movwf    TMR0H
   movlw    kTickDelay & 0xff
   movwf    TMR0L

   ; Clear the timer interrupt flag.
   bcf      INTCON, TMR0IF
   btfsc    INTCON, TMR0IF    ; is the flag clear now?
     bra    $-2               ; no, wait for it to change

   ; Unmask the timer interrupt and turn on the countdown timer.
   bsf      INTCON, TMR0IE
   bsf      T0CON, TMR0ON
   return



;; ----------------------------------------------
;;  void Clock.update()
;;
;;  Updates the millisecond counter that constitutes our wallclock.  We reset
;;  the timer at the end of every update to ensure this method is called by the
;;  interrupt service routine every millisecond.
;;
Clock.update:
   ; Increment the millisecond tick counter, a 32-bit value.
   incfsz   Clock.Ticks       ; first byte (LSB)
     bra    Clock.reset

   ; Toggle "heartbeat" I/O pin at ~1 Hz.
   btfsc    Clock.Ticks + 1, 0
     btg    PORTC, RC1

   incfsz   Clock.Ticks + 1   ; second byte
     bra    Clock.reset

   incfsz   Clock.Ticks + 2   ; third byte
     bra    Clock.reset

   incf     Clock.Ticks + 3   ; fourth byte (MSB)
   bra      Clock.reset



;; ----------------------------------------------
;;  void Clock.waitMS()
;;
;;  Enters a busy loop (suspends normal execution) until the tick count equals
;;  a specified alarm value, settable by updating Clock.Alarm directly or by
;;  using the WaitMS macro.  On entry, this routine expects the alarm reg-
;;  isters to hold the desired delay, in milliseconds.
;;
;;  Note that interrupts must not be disabled when this routine runs, since it
;;  depends on Clock.Ticks being volatile and updated asynchronously by the
;;  interrupt service routine.
;;
Clock.waitMS:
   ; Add the alarm value to the current tick count, creating a "target" tick count
   ; to match.  Once the actual tick count reaches the target value, the delay is
   ; complete.
   movf     Clock.Ticks, W
   addwf    Clock.Alarm       ; first byte (LSB)

   movf     Clock.Ticks + 1, W
   addwfc   Clock.Alarm + 1   ; second byte

   movf     Clock.Ticks + 2, W
   addwfc   Clock.Alarm + 2   ; third byte

   movf     Clock.Ticks + 3, W
   addwfc   Clock.Alarm + 3   ; fourth byte (MSB)

spin:
   ; Compare the 32-bit alarm value to the 32-bit tick count.
   movf     Clock.Alarm, W
   subwf    Clock.Ticks, W    ; first byte (LSB)

   movf     Clock.Alarm + 1, W
   subwfb   Clock.Ticks + 1, W; second byte

   movf     Clock.Alarm + 2, W
   subwfb   Clock.Ticks + 2, W; third byte

   movf     Clock.Alarm + 3, W
   subwfb   Clock.Ticks + 3, W; fourth byte (MSB)

   ; If the current tick count hasn't passed the alarm time yet, spin in place.
   bnc      spin
   return



   end
