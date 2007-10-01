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



;; ----------------------------------------------
;;  Macro CopyAddress( from, to )
;;
;;  The CopyAddress macro transfers an address word between file registers.
;;  That is, it copies the copies two registers starting at 'from' to the two
;;  registers starting at 'to'.
;;
CopyAddress             macro from, to
   movff    from, to
   movff    from + 1, to + 1
   endm



;; ----------------------------------------------
;;  Macro IncrementWord( register )
;;
;;  This macro increments the register argument by 1, assuming it refers to a
;;  16-bit little-endian word composed of two file registers in the access
;;  bank.
;;
IncrementWord           macro register
   infsnz   register
     incf   register + 1
   endm



;; ----------------------------------------------
;;  Macro SetTableBase( label )
;;
;;  The SetTableBase macro initializes the TBLPTRx file registers from the ROM
;;  address specified.
;;
SetTableBase            macro label
   if 0 == UPPER label
    clrf     TBLPTRU
   else
    movlw     UPPER label
    movwf     TBLPTRU
   endif
   if 0 == HIGH label
    clrf	 TBLPTRH
   else
    movlw    HIGH label
    movwf    TBLPTRH
   endif
   if 0 == LOW low
    clrf	 TBLPTRL
   else   
    movlw    LOW label
    movwf    TBLPTRL
   endif
   endm



;; ----------------------------------------------
;;  Macro Puts( string )
;;
;;  The Puts macro transmits a ROM string using the USART, followed by a
;;  carriage-return-linefeed sequence ('\r', '\n').
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
;;  The WaitMS macro suspends execution for some specified number of milli-
;;  seconds, a 32-bit value.  It works by initializing Clock.Alarm and calling
;;  through to Clock.waitMS().  As a result, it must never be used inside code
;;  with interrupts disabled (except in the trivial case where millis = 0),
;;  for the same reason that restriction applies to Clock.waitMS().
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
