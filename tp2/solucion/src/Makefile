CC = gcc
ASM = nasm
DBG = gdb
CFLAGS64 = -ggdb -Wall -std=c99 -pedantic -m64
ASMFLAGS64 = -felf64 -g -F dwarf
CFLAGS   = $(CFLAGS64) -O1
ASMFLAGS = $(ASMFLAGS64)


UBUNTU = $(shell lsb_release -sd)

OPENCV_LIB = `pkg-config --cflags --libs opencv`

BIN = tp2
BIN_DIR = ../bin



COBJS = tp2.o cli.o utils.o opencv_wrapper.o \
	tiles_c.o tiles.o \
	popart_c.o popart.o \
	ldr_c.o ldr.o \
	temperature_c.o temperature.o
	
ASMOBJS = tiles_asm.o \
	popart_asm.o \
	ldr_asm.o \
	temperature_asm.o

OBJS = $(COBJS) $(ASMOBJS)
# OBJS = $(COBJS) tmp.o

.PHONY: all clean

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $@ $(OPENCV_LIB) -lm
	cp $(BIN) $(BIN_DIR)/$(BIN)

opencv_wrapper.o: opencv_wrapper.c
	$(CC) $(CFLAGS) -c -o $@ $< $(OPENCV_LIB)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $< -lm

%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

all: $(BIN)

clean:
	rm -f $(OBJS)
	rm -f ./$(BIN)
	rm -f $(BIN_DIR)/$(BIN)


installopencv:
	sudo apt-get install libcv-dev libhighgui-dev libcvaux-dev libc6-dev
ifeq "Ubuntu 13.10" "${UBUNTU}"
	sudo cp opencv1310.pc /usr/lib/pkgconfig/opencv.pc
endif



