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



; Since this value may (will) be used to define other constants, we can't put
; off its own definition.  This isn't desirable at the framework level, of
; course, but we can't sacrifice the space/time savings of assembly-time
; definition for the run-time alternative.
kFrequency              equ   24000000

; Enumerate some BRG (Baud Rate Generator) values for common baud rates when
; the USART is in high-speed mode (BRGH = true).  At the default frequency of
; 24 MHz, these values all result in a fixed error of -0.16% (quite good).
USART.kBaud_9600        equ   (kFrequency / (  9600 << 4)) - 1    ; 155 (0x9b) @ 24 MHz
USART.kBaud_14400       equ   (kFrequency / ( 14400 << 4)) - 1    ; 103 (0x67) @ 24 MHz
USART.kBaud_19200       equ   (kFrequency / ( 19200 << 4)) - 1    ;  77 (0x4d) @ 24 MHz
USART.kBaud_28800       equ   (kFrequency / ( 28800 << 4)) - 1    ;  51 (0x33) @ 24 MHz
USART.kBaud_38400       equ   (kFrequency / ( 38400 << 4)) - 1    ;  38 (0x26) @ 24 MHz
USART.kBaud_57600       equ   (kFrequency / ( 57600 << 4)) - 1    ;  25 (0x19) @ 24 MHz
USART.kBaud_115200      equ   (kFrequency / (115200 << 4)) - 1    ;  12 (0x0c) @ 24 MHz

; The USART operates in one of two modes.  If no parity is used, an extra stop
; bit will be sent instead, maintaining the total bit-length for each mode.
USART.kMode_Byte        equ   0  ; 8-bit character + start/stop/parity = 11 bits total
USART.kMode_Char        equ   1  ; 7-bit character + start/stop/parity = 10 bits total

; Enumerate common error-checking methods.
USART.kParity_None      equ   0
USART.kParity_Even      equ   1
USART.kParity_Odd       equ   2
USART.kParity_Mark      equ   3
USART.kParity_Space     equ   4

; This bit in USART.Status indicates a parity error occured.
PERR                    equ   3
