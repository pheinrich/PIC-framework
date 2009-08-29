LIB=framework.lib
DEVICE=18F242
OBJS=clock.o console.o eeprom.o m25p.o math.o max6957.o random.o spi.o usart.o util.o vtable.o
INCS=framework.inc macros.inc private.inc

AS=gpasm
ASFLAGS=-c -p p$(DEVICE)
AR=gplib
ARFLAGS=-c

$(LIB): $(OBJS)
	$(AR) $(ARFLAGS) $(LIB) $?

$(OBJS): $(INCS)

%.o : %.asm
	$(AS) $(ASFLAGS) $<

clean:
	$(RM) *.o *.lst *.lib
