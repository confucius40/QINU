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

GRUB_MKRESCUE ?= grub-mkrescue
ISO_DIR       = build/isodir
ISO            = build/qinu.iso

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

# run: $(KERNEL)
# 	$(QEMU) -kernel $(KERNEL)

run: iso
	$(QEMU) -cdrom $(ISO)

clean:
	rm -rf $(BUILD)

iso: $(KERNEL)
	@mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL) $(ISO_DIR)/boot/qinu.elf
	cp boot/grub.cfg $(ISO_DIR)/boot/grub/grub.cfg
	$(GRUB_MKRESCUE) -o $(ISO) $(ISO_DIR)
