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
;;  Provides a general-purpose wallclock with millisecond resolution.
;; ---------------------------------------------------------------------------



   #include "private.inc"

   ; Variables
   global   Clock.Alarm
   global   Clock.Ticks

   ; Methods
   global   Clock.init
   global   Clock.isAwake
   global   Clock.isr
   global   Clock.setWakeTime
   global   Clock.sleep
   


kMIPS                   equ   kFrequency >> 2
kTickPrescalarLog2      equ   0
kInstructionsPerMS      equ   (kMIPS >> kTickPrescalarLog2) / 1000
kTickDelay              equ   0xffff - kInstructionsPerMS



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

Clock.Alarm             res   4
Clock.Ticks             res   4



;; ---------------------------------------------------------------------------
.clock                  code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  void Clock.init()
;;
;;  Initializes TIMER0 to be a general-purpose wallclock with millisecond
;;  resolution.
;;
Clock.init:
   bcf      PORTC, RC1
   lfsr     FSR0, Clock.Alarm
   movlw    0x08

   ; Clear the block.
   clrf     POSTINC0
   decfsz   WREG, F
     bra    $-4

   ; Install the isr at the correct frequency.
   bra      restart



;; ----------------------------------------------
;;  STATUS<C> Clock.isAwake()
;;
;;  Compares the current tick count to the wake time stored in Clock.Alarm.
;;  This method returns with the STATUS<C> set if the wake time is in the past,
;;  otherwise it will be clear.
;;
Clock.isAwake:
   ; Compare the 32-bit alarm value to the 32-bit tick count.
   movf     Clock.Alarm, W
   subwf    Clock.Ticks, W          ; first byte (LSB)

   movf     Clock.Alarm + 1, W
   subwfb   Clock.Ticks + 1, W      ; second byte

   movf     Clock.Alarm + 2, W
   subwfb   Clock.Ticks + 2, W      ; third byte

   movf     Clock.Alarm + 3, W
   subwfb   Clock.Ticks + 3, W      ; fourth byte (MSB)

   ; If the current tick count has passed the wake time, the subtraction above
   ; will set the carry flag.
   return



;; ----------------------------------------------
;;  void Clock.isr()
;;
;;  Updates the millisecond counter whenever Timer0 rolls over.  We reset the
;;  timer at the end of every update to ensure this method is called by the
;;  interrupt service routine every millisecond.
;;
Clock.isr:
   ; Determine if it's time for us to update the counter.
   btfss    INTCON, TMR0IE          ; is the TMR0 interrupt enabled?
     return                         ; no, we can exit
   btfss    INTCON, TMR0IF          ; yes, did TMR0 roll over?
     return                         ; no, we can exit

   ; Increment the millisecond tick counter, a 32-bit value.
   subwf    WREG, F                 ; W = 0, STATUS<C> = 1
   addwfc   Clock.Ticks + 0, F
   addwfc   Clock.Ticks + 1, F
   addwfc   Clock.Ticks + 2, F
   addwfc   Clock.Ticks + 3, F

   ; Toggle "heartbeat" I/O pin at ~1 Hz.
   btfss    Clock.Ticks + 1, 1
     bcf    PORTC, RC1
   btfsc    Clock.Ticks + 1, 1
     bsf    PORTC, RC1
   bra      restart



;; ----------------------------------------------
;;  void Clock.setWakeTime()
;;
;;  Adds the current time to the 32-bit value in Clock.Alarm, computing a
;;  tick count (probably) in the future.  We'll compare that value to the
;;  actual tick count to effect simple delays with millisecond precision.
;;
Clock.setWakeTime:
   ; Add the alarm value to the current tick count, creating a "target" tick count
   ; to match.  Once the actual tick count reaches the target value, the delay is
   ; complete.
   movf     Clock.Ticks, W
   addwf    Clock.Alarm, F          ; first byte (LSB)

   movf     Clock.Ticks + 1, W
   addwfc   Clock.Alarm + 1, F      ; second byte

   movf     Clock.Ticks + 2, W
   addwfc   Clock.Alarm + 2, F      ; third byte

   movf     Clock.Ticks + 3, W
   addwfc   Clock.Alarm + 3, F      ; fourth byte (MSB)
   return



;; ----------------------------------------------
;;  void Clock.sleep()
;;
;;  Enters a busy loop (suspends normal execution) until the tick count equals
;;  a specified alarm value, settable by updating Clock.Alarm directly via
;;  Clock.setWakeTime() or by using the SetAlarmMS macro.  On entry, this
;;  routine expects the alarm registers to hold the target wake time.
;;
;;  Note that interrupts must not be disabled when this routine runs, since it
;;  depends on Clock.Ticks being volatile and updated asynchronously by the
;;  interrupt service routine.
;;
Clock.sleep:
   ; Compare the current time to the wake time.
   rcall    Clock.isAwake        ; has the wake time passed?
   bnc      Clock.sleep          ; no, keep checking
   return                        ; yes, we can exit



;; ----------------------------------------------
;;  void restart()
;;
;;  Reset the countdown period for the millisecond timer.
;;
restart:
   ; Set up the basic timer operation.
   movlw    b'00001000'
            ; 0------- TMR0ON       ; turn off timer
            ; -0------ T08BIT       ; use 16-bit counter
            ; --0----- T0CS         ; use internal instruction clock
            ; ---X---- TOSE         ; [not used with internal instruction clock]
            ; ----1--- PSA          ; do not prescale timer output
            ; -----XXX T0PSx        ; [not used when prescaler inactive]
   movwf    T0CON

   ; Establish the countdown based on calculated MIPS.
   movlw    kTickDelay >> 8
   movwf    TMR0H
   movlw    kTickDelay & 0xff
   movwf    TMR0L

   ; Clear the timer interrupt flag.
   bcf      INTCON, TMR0IF
   btfsc    INTCON, TMR0IF          ; is the flag clear now?
     bra    $-2                     ; no, wait for it to change

   ; Unmask the timer interrupt and turn on the countdown timer.
   bsf      INTCON, TMR0IE
   bsf      T0CON, TMR0ON
   return



   end
