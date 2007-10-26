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
;;  Provides a basic wrapper to the SPI functions used to control the MAX6957.
;;
;; ---------------------------------------------------------------------------
;;  $Author$
;;  $Date$
;; ---------------------------------------------------------------------------



   #include "private.inc"

   ; Public Methods
   global   MAX6957.getConfig
   global   MAX6957.getDetectTransitions
   global   MAX6957.getGlobalCurrent
   global   MAX6957.getPortConfig
   global   MAX6957.getPortsConfig
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
   extern   Util.Frame



;; ---------------------------------------------------------------------------
                        udata_acs
;; ---------------------------------------------------------------------------

Scratch                 res   2



;; ---------------------------------------------------------------------------
.max6957                code
;; ---------------------------------------------------------------------------

;; ----------------------------------------------
;;  byte MAX6957.getConfig()
;;
;;  Returns the configuration word for this device.  See MAX6957.setConfig()
;;  for more information.
;;
MAX6957.getConfig:
   movlw    0x84
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  boolean MAX6957.getDetectTransitions()
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
;;  byte MAX6957.getGlobalCurrent()
;;
;;  Returns the global current setting.  See MAX6957.setGlobalCurrent() for
;;  more information.
;;
MAX6957.getGlobalCurrent:
   movlw    0x82
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  byte MAX6957.getPortConfig( byte port )
;;
;;  Returns the 2-bit value describing the I/O configuration (input, output,
;;  or constant current sink) of the specified port.  For more information,
;;  see MAX6957.setPortConfig().
;;
MAX6957.getPortConfig:
   ; Retrieve the configuration for all ports that share our block.
   movwf    Util.Frame           ; preserve a copy of the port number
   rcall    MAX6957.getPortsConfig

   ; Extract the correct two bits, based on our position in the block.
   btfsc    Util.Frame, 1        ; is the port in the lower half of the block?
     swapf  WREG, W              ; no, we want the upper nybble
   btfss    Util.Frame, 0        ; is the port even?
     bra    getPrtCfgMask        ; yes, the lower 2 bits are what we want

   rrncf    WREG, W              ; no, shift down
   rrncf    WREG, W

getPrtCfgMask:
   ; We want only the bottom 2 bits.
   andlw    0x03
   return



;; ----------------------------------------------
;;  byte MAX6957.getPortCurrent( byte port )
;;
;;  Returns the current setting for the specified port.  For more information,
;;  see MAX6957.setPortCurrent().
;;
MAX6957.getPortCurrent:
   ; Retrieve the currents for all ports that share our block.
   movwf    Util.Frame           ; preserve a copy of the port number
   rcall    MAX6957.getPortsCurrent

   ; Extract the correct four bits, based on our block position.
   btfsc    Util.Frame, 0        ; is the port even?
     swapf  WREG, W              ; no, we want the upper nybble

   ; Make sure the value fits in a nybble.
   andlw    0x0f
   return



;; ----------------------------------------------
;;  byte MAX6957.getPortsConfig( byte port )
;;
;;  Returns the configuration bits for all ports sharing the same block with
;;  the port specified.  For more information, see MAX6957.setPortsConfig().
;;
MAX6957.getPortsConfig:
   andlw    0x1c
   rrncf    WREG, W
   rrncf    WREG, W
   addlw    0x88
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  byte MAX6957.getPortsCurrent( byte port )
;;
;;  Returns the currents for all ports sharing the same block as the port
;;  specified.  For more information, see MAX6957.setPortsCurrent().
;;
MAX6957.getPortsCurrent:
   andlw    0x1e
   rrncf    WREG, W
   addlw    0x90
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  boolean MAX6957.getShutdown()
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
;;  boolean MAX6957.getTestDisplay()
;;
;;  Returns true (0xff) if this device is currently in test display mode,
;;  otherwise false (0x00).  See MAX6957.setTestDisplay() for more info.
;;
MAX6957.getTestDisplay:
   movlw    0x87
   movwf    Util.Frame
   call     SPI.ioWord
   btfsc    WREG, 0
     setf   WREG
   return



;; ----------------------------------------------
;;  boolean MAX6957.getUseGlobalCurrent()
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
;;  boolean MAX6957.readPort( byte port )
;;
;;  Returns true (0xff) if the specified port pin is currently high, otherwise
;;  false (0x00).  See MAX6957.writePort() for more information.
;;
MAX6957.readPort:
   addlw    0xa0
   movwf    Util.Frame
   call     SPI.ioWord
   btfsc    WREG, 0
     setf   WREG
   return

   

;; ----------------------------------------------
;;  byte MAX6957.readPorts( byte port )
;;
;;  Returns a 8-bit bitfield reflecting the current status of the specified
;;  port pin and the seven pins following it.  See MAX6957.writePorts() for
;;  more information.
;;
MAX6957.readPorts:
   addlw    0xc0
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setConfig( byte config )
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
   movwf    Util.Frame + 1
   movlw    0x04
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setDetectTransitions( boolean onOff )
;;
;;  Configures this device to detect transitions on I/O pins supporting this
;;  feature (and masked to do so).  This involves setting the M bit in the
;;  configuration register.  See MAX6957.setConfig().
;;
MAX6957.setDetectTransitions:
   movwf    Scratch
   rcall    MAX6957.getConfig
   bcf      WREG, 7
   tstfsz   Scratch
     bsf    WREG, 7
   bra      MAX6957.setConfig



;; ----------------------------------------------
;;  void MAX6957.setGlobalCurrent( byte level )
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
   movwf    Util.Frame + 1
   movlw    0x02
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setPortConfig( byte port, byte config )
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
   ; Save same values and prepare to calculate a mask.
   movff    Util.Frame + 1, Scratch ; preserve the desired config value
   movlw    0x03
   movwf    Scratch + 1          ; create an initial mask of b'00000011'
   andwf    Util.Frame, W
   incf     WREG, W              ; compute the shift count

setPrtCfgShift:
   ; Shift the new config value and mask according to the block position of the
   ; specified pin.
   dcfsnz   WREG, W              ; have we shifted enough?
     bra    setPrtCfgMerge       ; yes, we're ready to update the register

   rlncf    Scratch, F           ; no, shift the value up two bits
   rlncf    Scratch, F
   rlncf    Scratch + 1, F       ; shift the mask up, too
   rlncf    Scratch + 1, F
   bra      setPrtCfgShift
   
setPrtCfgMerge:
   ; Retrieve the current config values for all ports sharing our block, then
   ; combine with our new value.
   rcall    MAX6957.getPortsConfig
   andwf    Scratch + 1, W       ; mask off the old value
   iorwf    Scratch, W           ; insert the new value
   bra      MAX6957.setPortsConfig



;; ----------------------------------------------
;;  void MAX6957.setPortCurrent( byte port, byte level )
;;
;;  Sets the current level for the port pin specified, whichis significant
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
   ; Save some values and prepare to calculate a mask.
   movff    Util.Frame + 1, Scratch ; preserve the desired config value
   movlw    0x0f
   movwf    Scratch + 1          ; create an initial mask of b'00001111'

   btfss    Util.Frame, 0        ; is the port number even?
     bra    setPrtCrtMerge       ; yes, we're ready to update the register

   swapf    Scratch, F           ; no, the value will go in the upper nybble
   swapf    Scratch + 1, F       ; shift the mask to match

setPrtCrtMerge:
   ; Retrieve the current values for both pins associated with our current control
   ; register, then combine with our new value. 
   rcall    MAX6957.getPortsCurrent
   andwf    Scratch + 1, W       ; mask off the old value
   iorwf    Scratch, W           ; insert the new value
   bra      MAX6957.setPortsCurrent



;; ----------------------------------------------
;;  void MAX6957.setPortsConfig( byte port, byte configs )
;;
;;  Simultaneously sets the 2-bit configuration for all ports sharing a block
;;  with the port specified.  Ports are grouped together in fours for config-
;;  uration purposes, so the parameter is a bitfield of four 2-bit values.
;;
MAX6957.setPortsConfig:
   movf     Util.Frame, W
   andlw    0x1c
   rrncf    WREG, W
   rrncf    WREG, W
   addlw    0x08
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setPortsCurrent( byte firstPort, byte currents )
;;
;;  Simultaneously sets the 4-bit current for both ports associated with a
;;  particular current control register.  Ports are paired for current setting
;;  purposes, so the parameter is a bitfield of two four-bit values.
;;
MAX6957.setPortsCurrent:
   movf     Util.Frame, W
   andlw    0x1e
   rrncf    WREG, W
   addlw    0x10
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setShutdown( boolean onOff )
;;
;;  Sets the current sleep mode, where true (0xff) means the device is in low-
;;  power sleep mode, and false (0x00) indicates normal operation.  This in-
;;  volves setting the S bit in the configuration register.  For more info,
;;  see MAX6957.setConfig().
;;
MAX6957.setShutdown:
   movwf    Scratch
   rcall    MAX6957.getConfig
   bsf      WREG, 0
   tstfsz   Scratch
     bcf    WREG, 0
   bra      MAX6957.setConfig



;; ----------------------------------------------
;;  void MAX6957.setTestDisplay( boolean onOff )
;;
;;  Sets the current display test mode, where true (0xff) means the device is
;;  testing, and false (0x00) indicates normal operation.  When test mode is
;;  active, all I/O pins configured as LED segment drivers are turned on and
;;  sink 1/2 the maximum current.
;;
MAX6957.setTestDisplay:
   movwf    Util.Frame + 1
   movlw    0x07
   movwf    Util.Frame
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.setUseGlobalCurrent( boolean onOff )
;;
;;  Sets the global current preference, where true (0xff) means a global set-
;;  ting applies to all LED segment drivers, and false (0x00) indicates each
;;  pin so configured is individually controlled.
;;
MAX6957.setUseGlobalCurrent:
   movwf    Scratch
   rcall    MAX6957.getConfig
   bsf      WREG, 6
   tstfsz   Scratch
     bcf    WREG, 6
   bra      MAX6957.setConfig



;; ----------------------------------------------
;;  void MAX6957.writePort( byte port, boolean onOff )
;;
;;  Sets the current status of the port specified.  If the parameter is false
;;  (0x00), the pin will be driven low.
;;
MAX6957.writePort:
   tstfsz   Util.Frame + 1
     setf   Util.Frame + 1
   movlw    0x20
   addwf    Util.Frame, F
   goto     SPI.ioWord



;; ----------------------------------------------
;;  void MAX6957.writePorts( byte firstPort, byte bitfield )
;;
;;  Simultaneously writes the statuses of eight consecutive port pins, start-
;;  ing with the one specified.
;;
MAX6957.writePorts:
   movlw    0x40
   addwf    Util.Frame, F
   goto     SPI.ioWord



   end
