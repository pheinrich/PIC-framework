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



;; ----------------------------------------------
;;  Macro CopyWord( from, to )
;;
;;  Copies a 16-bit word from one file register pair to another.  This macro
;;  is often used to initialize the FSRx registers, since data addresses are
;;  never more than 16 bits wide.
;;
;;  Two versions are defined here, one for normal byte ordering and one for big
;;  endian (network order).
;;
CopyWord                macro from, to
   movff    from + 0, to + 0
   movff    from + 1, to + 1
   endm

CopyWordBE              macro from, to
   movff    from + 1, to + 0
   movff    from + 0, to + 1
   endm



;; ----------------------------------------------
;;  Macro DecrementWord( register, bigEndian )
;;
;;  Decrements the 16-bit word with LSB in register and MSB in register + 1.
;;  We assume the correct bank has already been selected, or that the registers
;;  are in the access bank.
;;
;;  Two versions are defined here, one for normal byte ordering and one for big
;;  endian (network order).
;;
DecrementWord           macro register
   decf     register + 0, F
   btfss    STATUS, C
     decf   register + 1, F
   endm

DecrementWordBE         macro register
   decf     register + 1, F
   btfss    STATUS, C
     decf   register + 0, F
   endm



;; ----------------------------------------------
;;  Macro IncrementWord( register )
;;
;;  Increments the 16-bit word with LSB in register and MSB in register + 1.
;;  We assume the correct bank has already been selected, or that the registers
;;  are in the access bank.
;;
;;  Two versions are defined here, one for normal byte ordering and one for big
;;  endian (network order).
;;
IncrementWord           macro register
   infsnz   register + 0, F
     incf   register + 1, F
   endm

IncrementWordBE         macro register
   infsnz   register + 1, F
     incf   register + 0, F
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
   extern   Clock.Ticks
   local i

   bcf      INTCON,TMR0IE

   movff    Clock.Ticks, Clock.Alarm
   if 0 != (millis & 0xff)
    movlw   millis & 0xff
    addwf   Clock.Alarm, F
   else
    bcf     STATUS, C
   endif

i = 1
   while 4 > i
    movff   Clock.Ticks + i, Clock.Alarm + i
    movlw   (millis >> (i << 3)) & 0xff
    addwfc  Clock.Alarm + i, F
i += 1
   endw

   bsf      INTCON, TMR0IE
   endm



;; ----------------------------------------------
;;  Macro SetBank( label )
;;
;;  Selects the bank appropriate for the label specified.  This is basically
;;  just the upper byte of the corresponding address. 
;;
SetBank                 macro label
   movlb    HIGH label
   endm



;; ----------------------------------------------
;;  Macro SetTableBase( label )
;;
;;  Initializes the TBLPTRx file registers from the ROM address specified.
;;
SetTableBase            macro label
   ; The upper address byte will always be 0 for chips with less than 64K ROM.
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
   movlw    LOW (literal)
   movwf    register
   movlw    HIGH (literal)
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
