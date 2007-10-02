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
;;  Macro IncrementWord( register )
;;
;;  Increments the 16-bit word with LSB in register and MSB in register + 1.
;;  We assume the correct bank has already been selected, or that the registers
;;  are in the access bank.
;;
IncrementWord           macro register
   infsnz   register
     incf   register + 1
   endm



;; ----------------------------------------------
;;  Macro SetTableBase( label )
;;
;;  Initializes the TBLPTRx file registers from the ROM address specified.
;;
SetTableBase            macro label
   ; The upper address byte will always be 0 for chips with less than 16K ROM.
   if 0 == UPPER label
    clrf     TBLPTRU
   else
    movlw    UPPER label
    movwf    TBLPTRU
   endif

   if 0 == HIGH label
    clrf     TBLPTRH
   else
    movlw    HIGH label
    movwf    TBLPTRH
   endif

   if 0 == LOW low
    clrf     TBLPTRL
   else   
    movlw    LOW label
    movwf    TBLPTRL
   endif
   endm



;; ----------------------------------------------
;;  Macro Puts( string )
;;
;;  Transmits a ROM string using the USART, followed by a carriage-return-
;;  linefeed sequence ('\r', '\n').  This is a blocking call.
;;
Puts                    macro string
   extern   Console.newline
   extern   Console.printString

   SetTableBase string
   call     Console.printString
   call     Console.newline
   endm



;; ----------------------------------------------
;;  Macro WaitMS( millis )
;;
;;  Suspends execution with millisecond precision, the desired delay being
;;  specified as a 32-bit value.  It works by initializing Clock.Alarm and
;;  calling through to Clock.waitMS().  As a result, it must never be used in-
;;  side code with interrupts disabled (except in the trivial case where millis
;;  = 0), for the same reason that restriction applies to Clock.waitMS().
;;
WaitMS                  macro millis
   if 0 == millis
    exitm
   endif

   extern   Clock.Alarm
   extern   Clock.waitMS
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

   ; Delay until the alarm goes off.
   call     Clock.waitMS
   endm
