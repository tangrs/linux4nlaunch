HOST_CC		:= gcc
HOST_CFLAGS	:= -Wall
CROSS_CC	:= arm-none-eabi-gcc
CROSS_OBJCOPY	:= arm-none-eabi-objcopy

all: makebin template.bin

makebin: makebin.c
	$(HOST_CC) $(HOST_CFLAGS) $< -o $@

template.bin: template.o
	$(CROSS_OBJCOPY) -O binary $< $@

template.o: template.S
	$(CROSS_CC) -c $< -o $@

clean:
	rm -Rf template.bin template.o
	rm -Rf makebin
