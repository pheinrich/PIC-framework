;; ---------------------------------------------------------------------------
;;
;;  PIC Framework
;;  Copyright © 2006,2008  Peter Heinrich
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
;;  Provides a basic wrapper to the SPI functions used to control the MAX6957.
;; ---------------------------------------------------------------------------



   #include "private.inc"

   ; Public Methods
   global   MAX6957.getConfig
   global   MAX6957.getDetectTransitions
   global   MAX6957.getGlobalCurrent
   global   MAX6957.getPortConfig
   global   MAX6957.getPortCurrent
   global   MAX6957.getPortsConfig
   global   MAX6957.getPortsCurrent
   global   MAX6957.getShutdown
   global   MAX6957.getTestDisplay
   global   MAX6957.getUseGlobalCurrent
   global   MAX6957.readPort
   global   MAX6957.readPorts
   global   MAX6957.setConfig
   global   MAX6957.setDetectTransitions
   global   MAX6957.setGlobalCurrent
   global   MAX6957.setPortConfig
   global   MAX6957.setPortCurrent
   global   MAX6957.setPortsConfig
   global   MAX6957.setPortsCurrent
   global   MAX6957.setShutdown
   global   MAX6957.setTestDisplay
   global   MAX6957.setUseGlobalCurrent
   global   MAX6957.writePort
   global   MAX6957.writePorts

   ; Dependencies
   extern   SPI.ioWord
   extern   SPI.Queue
   extern   Util.Frame
   extern   Util.Save
   extern   Util.Scratch



;; ---------------------------------------------------------------------------
.max6957                code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  WREG MAX6957.getConfig()
;;
;;  Returns the configuration word for this device.  See MAX6957.setConfig()
;;  for more information.
;;
MAX6957.getConfig:
   movlw    0x04
   bra      read



;; ----------------------------------------------
;;  WREG MAX6957.getDetectTransitions()
;;
;;  Returns true (0xff) if this device is configured to detect transitions on
;;  I/O pins that support this, false (0x00) otherwise.  For more information,
;;  see MAX6957.setDetectTransitions().
;;
MAX6957.getDetectTransitions:
   rcall    MAX6957.getConfig
   btfsc    WREG, 7
     setf   WREG
   btfss    WREG, 7
     clrf   WREG
   return



;; ----------------------------------------------
;;  WREG MAX6957.getGlobalCurrent()
;;
;;  Returns the global current setting.  See MAX6957.setGlobalCurrent() for
;;  more information.
;;
MAX6957.getGlobalCurrent:
   movlw    0x02
   bra      read



;; ----------------------------------------------
;;  WREG MAX6957.getPortConfig( WREG port )
;;
;;  Returns the 2-bit value describing the I/O configuration (input, output,
;;  or constant current sink) of the specified port.  For more information,
;;  see MAX6957.setPortConfig().
;;
MAX6957.getPortConfig:
   ; Retrieve the configuration for all ports that share our block.
   movwf    Util.Save               ; preserve a copy of the port number
   rcall    MAX6957.getPortsConfig

   ; Extract the correct two bits, based on our position in the block.
   btfsc    Util.Save, 1            ; is the port in the lower half of the block?
     swapf  WREG, W                 ; no, we want the upper nybble
   btfss    Util.Save, 0            ; is the port even?
     bra    getPrtCfgMask           ; yes, the lower 2 bits are what we want

   rrncf    WREG, W                 ; no, shift down
   rrncf    WREG, W

getPrtCfgMask:
   ; We want only the bottom 2 bits.
   andlw    b'00000011'
   return



;; ----------------------------------------------
;;  WREG MAX6957.getPortCurrent( WREG port )
;;
;;  Returns the current setting for the specified port.  For more information,
;;  see MAX6957.setPortCurrent().
;;
MAX6957.getPortCurrent:
   ; Retrieve the currents for all ports that share our block.
   movwf    Util.Save               ; preserve a copy of the port number
   rcall    MAX6957.getPortsCurrent

   ; Extract the correct four bits, based on our block position.
   btfsc    Util.Save, 0            ; is the port even?
     swapf  WREG, W                 ; no, we want the upper nybble

   ; Make sure the value fits in a nybble.
   andlw    b'00001111'
   return



;; ----------------------------------------------
;;  WREG MAX6957.getPortsConfig( WREG port )
;;
;;  Returns the configuration bits for all ports sharing the same block with
;;  the port specified.  For more information, see MAX6957.setPortsConfig().
;;
MAX6957.getPortsConfig:
   rrncf    WREG, W
   rrncf    WREG, W
   andlw    b'00000111'
   addlw    0x08
   bra      read



;; ----------------------------------------------
;;  WREG MAX6957.getPortsCurrent( WREG port )
;;
;;  Returns the currents for all ports sharing the same block as the port
;;  specified.  For more information, see MAX6957.setPortsCurrent().
;;
MAX6957.getPortsCurrent:
   rrncf    WREG, W
   andlw    b'00001111'
   addlw    0x10
   bra      read



;; ----------------------------------------------
;;  WREG MAX6957.getShutdown()
;;
;;  Returns true (0xff) if this device is in low-power (sleep) mode, otherwise
;;  false (0x00).
;;
MAX6957.getShutdown:
   rcall    MAX6957.getConfig
   btg      WREG, 0
   btfsc    WREG, 0
     setf   WREG
   btfss    WREG, 0
     clrf   WREG
   return



;; ----------------------------------------------
;;  WREG MAX6957.getTestDisplay()
;;
;;  Returns true (0xff) if this device is currently in test display mode,
;;  otherwise false (0x00).  See MAX6957.setTestDisplay() for more info.
;;
MAX6957.getTestDisplay:
   movlw    0x07
   rcall    read
   btfsc    WREG, 0
     setf   WREG
   return



;; ----------------------------------------------
;;  WREG MAX6957.getUseGlobalCurrent()
;;
;;  Returns true (0xff) if this device is configured to use a global current
;;  value for all ports configured as constant current sinks, otherwise false
;;  (0x00).  See MAX6957.setUseGlobalCurrent() for more information.
;;
MAX6957.getUseGlobalCurrent:
   rcall    MAX6957.getConfig
   btg      WREG, 6
   btfsc    WREG, 6
     setf   WREG
   btfss    WREG, 6
     clrf   WREG
   return



;; ----------------------------------------------
;;  WREG MAX6957.readPort( WREG port )
;;
;;  Returns true (0xff) if the specified port pin is currently high, otherwise
;;  false (0x00).  See MAX6957.writePort() for more information.
;;
MAX6957.readPort:
   addlw    0x20
   rcall    read
   btfsc    WREG, 0
     setf   WREG
   return

   

;; ----------------------------------------------
;;  WREG MAX6957.readPorts( WREG firstPort )
;;
;;  Returns an 8-bit bitfield reflecting the current status of the specified
;;  port pin and the seven pins following it.  See MAX6957.writePorts() for
;;  more information.
;;
MAX6957.readPorts:
   addlw    0x40
   bra      read



;; ----------------------------------------------
;;  WREG MAX6957.setConfig( WREG config )
;;
;;  Sets the configuration byte for this device, which controls sleep mode,
;;  transition detection, and whether port currents may be set individually or
;;  follow a global setting.
;;
;;    1------- M     ; Transition Detection Control (0 = disabled, 1 = enabled)
;;    -1------ I     ; Global Current Control (0 = global, 1 = individual)
;;    --XXXXX-       ; [unimplemented]
;;    -------1 S     ; Shutdown Control (0 = shutdown, 1 = normal operation)
;;
MAX6957.setConfig:
   movwf    SPI.Queue + 1
   movlw    0x04
   movwf    SPI.Queue
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setDetectTransitions( WREG onOff )
;;
;;  Configures this device to detect transitions on I/O pins supporting this
;;  feature (and masked to do so).  This involves setting the M bit in the
;;  configuration register.  See MAX6957.setConfig().
;;
MAX6957.setDetectTransitions:
   movwf    Util.Scratch
   rcall    MAX6957.getConfig
   bcf      WREG, 7
   tstfsz   Util.Scratch
     bsf    WREG, 7
   bra      MAX6957.setConfig



;; ----------------------------------------------
;;  void MAX6957.setGlobalCurrent( WREG level )
;;
;;  Sets the current level to be used globally by all pins configured as con-
;;  stant current sinks.  The value is four bits (0-15) and describes the
;;  fractional current in increments of 1/16.  For example, a value of 0 in-
;;  dicates 1/16 of the maximum current should be sunk, while a value of 13
;;  specifies 14/16.  To sink 0/16, turn the pin off (segment drivers must be
;;  driven high in order to sink current).
;;
;;  Note that this level is only significant when the device is configured to
;;  use a global current setting.  See MAX6957.setUseGlobalCurrent().
;;
MAX6957.setGlobalCurrent:
   movwf    SPI.Queue + 1
   movlw    0x02
   movwf    SPI.Queue
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setPortConfig( frame[0] port, frame[1] config )
;;
;;  Sets the configuration bits for the port specified.  The parameter is a
;;  2-bit value that indicates the nature of the port pin:
;;
;;     00 = LED segment driver
;;     01 = GPIO output
;;     10 = GPIO input (without pullup)
;;     11 = GPIO input (with pullup)
;;
MAX6957.setPortConfig:
   ; Create a 2-bit mask, then shift it (and the config value) into the correct
   ; position based on the bit number.
   movlw    0xfc
   movwf    Util.Scratch

   btfss    Util.Frame, 1           ; is the bit in the lower half of the block?
     bra    noSwap                  ; yes, no need to shift dramatically

   swapf    Util.Scratch, F         ; no, shift the mask at least 4 bits
   swapf    Util.Frame + 1, F       ; (keep config lined up with mask)

noSwap:
   btfss    Util.Frame, 0           ; is the bit even?
     bra    noShift                 ; yes, we're done shifting

   rlncf    Util.Scratch, F         ; no, shift two more bits
   rlncf    Util.Scratch, F
   rlncf    Util.Frame + 1, F       ; (keep config lined up with mask)
   rlncf    Util.Frame + 1, F

noShift:
   ; Read the current configuration for the block of ports.
   movf     Util.Frame, W
   rcall    MAX6957.getPortsConfig

   andwf    Util.Scratch, W         ; mask out our port's bits
   iorwf    Util.Frame + 1, F       ; add in the desired configuration
   bra      MAX6957.setPortsConfig  ; save the value back to the device



;; ----------------------------------------------
;;  void MAX6957.setPortCurrent( frame[0] port, frame[1] level )
;;
;;  Sets the current level for the port pin specified, which is significant
;;  only when it has been configured as a constant current sink (LED segment
;;  driver).  The value is four bits (0-15) and describes the current as a
;;  fraction of the maximum, in 1/16 increments.  For example, a value of 3
;;  indicates 4/16 of the maximum current will flow, while a value of 9 would
;;  correspond to 10/16.  To sink 0/16, turn the pin off (segment drivers must
;;  be driven high to sink current).
;;
;;  Note that this level is only significant when the device is configured to
;;  use individual current settings for each segment.  For more information,
;;  See MAX6957.setUseGlobalCurrent().
;;
MAX6957.setPortCurrent:
   ; Create a 4-bit mask, then shift it (and the current level) into the correct
   ; position based on the bit number.
   movlw    0xf0
   movwf    Util.Scratch

   movf     Util.Frame, W
   btfss    Util.Frame, 0           ; is the bit number odd?
     bra    evenBit                 ; no, we're done shifting

   swapf    Util.Scratch, F         ; no, shift the mask at least 4 bits
   swapf    Util.Frame + 1, F       ; (keep level lined up with mask)

evenBit:
   ; Retrieve the current values for both pins associated with our current control
   ; register, then combine with our new value. 
   rcall    MAX6957.getPortsCurrent
   andwf    Util.Scratch, W         ; mask off the old value
   iorwf    Util.Frame + 1, F       ; insert the new value
   bra      MAX6957.setPortsCurrent



;; ----------------------------------------------
;;  void MAX6957.setPortsConfig( frame[0] firstPort, frame[1] configs )
;;
;;  Simultaneously sets the 2-bit configuration for all ports sharing a block
;;  with the port specified.  Ports are grouped together in fours for config-
;;  uration purposes, so the parameter is a bitfield of four 2-bit values.
;;
MAX6957.setPortsConfig:
   movf     Util.Frame, W
   rrncf    WREG, W
   rrncf    WREG, W
   andlw    b'00000111'
   addlw    0x08
   movwf    SPI.Queue
   movff    Util.Frame + 1, SPI.Queue + 1
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setPortsCurrent( frame[0] firstPort, frame[1] currents )
;;
;;  Simultaneously sets the 4-bit current for both ports associated with a
;;  particular current control register.  Ports are paired for current setting
;;  purposes, so the parameter is a bitfield of two four-bit values.
;;
MAX6957.setPortsCurrent:
   movf     Util.Frame, W
   rrncf    WREG, W
   andlw    b'00001111'
   addlw    0x10
   movwf    SPI.Queue
   movff    Util.Frame + 1, SPI.Queue + 1
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setShutdown( WREG onOff )
;;
;;  Sets the current sleep mode, where true (0xff) means the device is in low-
;;  power sleep mode, and false (0x00) indicates normal operation.  This in-
;;  volves setting the S bit in the configuration register.  For more info,
;;  see MAX6957.setConfig().
;;
MAX6957.setShutdown:
   movwf    Util.Scratch
   rcall    MAX6957.getConfig
   bsf      WREG, 0
   tstfsz   Util.Scratch
     bcf    WREG, 0
   bra      MAX6957.setConfig



;; ----------------------------------------------
;;  void MAX6957.setTestDisplay( WREG onOff )
;;
;;  Sets the current display test mode, where true (0xff) means the device is
;;  testing, and false (0x00) indicates normal operation.  When test mode is
;;  active, all I/O pins configured as LED segment drivers are turned on and
;;  sink 1/2 the maximum current.
;;
MAX6957.setTestDisplay:
   movwf    SPI.Queue + 1
   movlw    0x07
   movwf    SPI.Queue
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setUseGlobalCurrent( WREG onOff )
;;
;;  Sets the global current preference, where true (0xff) means a global set-
;;  ting applies to all LED segment drivers, and false (0x00) indicates each
;;  pin so configured is individually controlled.
;;
MAX6957.setUseGlobalCurrent:
   movwf    Util.Scratch
   rcall    MAX6957.getConfig
   bsf      WREG, 6
   tstfsz   Util.Scratch
     bcf    WREG, 6
   bra      MAX6957.setConfig



;; ----------------------------------------------
;;  void MAX6957.writePort( frame[0] port, frame[1] onOff )
;;
;;  Sets the current status of the port specified.  If the parameter is false
;;  (0x00), the pin will be driven low.
;;
MAX6957.writePort:
   movff    Util.Frame, SPI.Queue
   movlw    0x20
   addwf    SPI.Queue, F
   clrf     SPI.Queue + 1
   tstfsz   Util.Frame + 1
     setf   SPI.Queue + 1
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.writePorts( frame[0] firstPort, frame[1] bitfield )
;;
;;  Simultaneously writes the statuses of eight consecutive port pins, start-
;;  ing with the one specified.
;;
MAX6957.writePorts:
   movlw    0x40
   addwf    Util.Frame, W
   movwf    SPI.Queue
   movff    Util.Frame + 1, SPI.Queue + 1
   goto     SPI.ioWord




;; ----------------------------------------------
;;  WREG read( WREG register )
;;
;;  Reads the register specified.  This requires setting the high bit and
;;  clocking out two full bytes (the second byte is ignored as dummy data, so
;;  it can be anything), then clocking out two more to retrieve the value,
;;  which will be returned in the last byte read.
;;
read:
   ; Send the command word.
   iorlw    0x80                    ; reads are indicated by a set high bit
   movwf    SPI.Queue
   call     SPI.ioWord              ; low byte is ignored

   ; Send a dummy word to retrieve value.
   clrf     SPI.Queue               ; use the no-op command
   goto     SPI.ioWord              ; low byte is ignored



   end
