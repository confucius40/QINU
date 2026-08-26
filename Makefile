CC      ?= cc
LD      = ld
AS      = nasm
QEMU    = qemu-system-x86_64

CFLAGS  = -m64 -ffreestanding -fno-pie -fno-stack-protector \
          -nostdinc -Wall -Wextra -Werror -std=c89

LDFLAGS = -m elf_x86_64 -nostdlib -T linker.ld

BUILD   = build

KERNEL  = $(BUILD)/qinu.elf

OBJS    = \
          $(BUILD)/entry.o \
          $(BUILD)/main.o

.PHONY: all clean run

all: $(KERNEL)

$(KERNEL): $(OBJS) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD)/entry.o: boot/entry.asm
	mkdir -p $(BUILD)
	$(AS) -f elf64 $< -o $@

$(BUILD)/main.o: kernel/main.c kernel/main.h
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -Ikernel -c $< -o $@

run: $(KERNEL)
	$(QEMU) -kernel $(KERNEL)

clean:
	rm -rf $(BUILD)
