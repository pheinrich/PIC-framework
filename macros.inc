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



;; ----------------------------------------------
;;  Macro CopyWord( from, to )
;;
;;  Copies a 16-bit word from one file register pair to another.  This macro
;;  is often used to initialize the FSRx registers, since data addresses are
;;  never more than 16 bits wide.
;;
CopyWord                macro from, to
   movff    from, to
   movff    from + 1, to + 1
   endm



;; ----------------------------------------------
;;  Macro DecrementWord( register )
;;
;;  Decrements the 16-bit word with LSB in register and MSB in register + 1.
;;  We assume the correct bank has already been selected, or that the registers
;;  are in the access bank.
;;
DecrementWord           macro register
   decf     register, F
   btfss    STATUS, C
     decf   register + 1, F
   endm



;; ----------------------------------------------
;;  Macro IncrementWord( register )
;;
;;  Increments the 16-bit word with LSB in register and MSB in register + 1.
;;  We assume the correct bank has already been selected, or that the registers
;;  are in the access bank.
;;
IncrementWord           macro register
   infsnz   register, F
     incf   register + 1, F
   endm



;; ----------------------------------------------
;;  Macro Puts( label )
;;
;;  Transmits a ROM string using the USART, followed by a carriage-return-
;;  linefeed sequence ('\r', '\n').  This is a blocking call.
;;
Puts                    macro label
   extern   Console.newline
   extern   Console.printString

   SetTableBase label
   call     Console.printString
   call     Console.newline
   endm



;; ----------------------------------------------
;;  Macro SetAlarmMS( millis )
;;
;;  Initializes Clock.Alarm with the countdown value specified as a 32-bit
;;  millisecond delay, then calls Clock.setWakeTime() to add the delay to the
;;  current time.  Once initialized, callers may use Clock.sleep() to wait for
;;  the timeout period to expire, or poll the status with Clock.isAwake().
;;
SetAlarmMS              macro millis
   extern   Clock.Alarm
   extern   Clock.setWakeTime
   local i

i = 0
   while 4 > i
    if 0 != ((millis >> (i << 3)) & 0xff)
     movlw   (millis >> (i << 3)) & 0xff
     movwf   Clock.Alarm + i
    else
     clrf    Clock.Alarm + i
    endif
i += 1
   endw

   ; Calculate the wake time.
   call     Clock.setWakeTime
   endm



;; ----------------------------------------------
;;  Macro SetTableBase( label )
;;
;;  Initializes the TBLPTRx file registers from the ROM address specified.
;;
SetTableBase            macro label
   ; The upper address byte will always be 0 for chips with less than 16K ROM.
   clrf     TBLPTRU
   SetWord  label, TBLPTRL
   endm



;; ----------------------------------------------
;;  Macro SetWord( literal, register )
;;
;;  Sets the 16-bit word (with LSB in register and MSB in register + 1) to the
;;  literal value specified.  We assume the correct bank has already been
;;  selected, or that the registers are in the access bank.
;;
SetWord                 macro literal, register
   movlw    LOW literal
   movwf    register
   movlw    HIGH literal
   movwf    register + 1
   endm



;; ----------------------------------------------
;;  Macro TestSwitchSkipIfClosed( index )
;;
;;  Tests the position of a configuration switch, skipping the following in-
;;  struction if the switch is closed (low).  Otherwise, the next instruction
;;  is executed as normal.  The index parameter corresponds to a line from the
;;  B port, which is assumed to have weak pull-ups enabled.
;;
TestSwitchSkipIfClosed  macro index
   ; Read the hardware switch to check its position.
   btfsc    PORTB, RB#v(index)
   endm



;; ----------------------------------------------
;;  Macro TestSwitchSkipIfOpen( index )
;;
;;  Tests the position of a configuration switch, skipping the following in-
;;  struction if the switch is open (high).  Otherwise, the next instruction is
;;  executed as normal.  The index parameter corresponds to a line from the B
;;  port, which is assumed to have weak pull-ups enabled.
;;
TestSwitchSkipIfOpen    macro index
   ; Read the hardware switch to check its position.
   btfss    PORTB, RB#v(index)
   endm
