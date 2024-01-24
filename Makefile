TARGET := rv-forth

LDSCRIPT := $(TARGET).ld

RISCV ?= /opt/xpack/riscv-none-elf-gcc
ARCH  ?= rv32i
ABI   ?= ilp32

ARCH_FLAGS := -march=$(ARCH) -mabi=$(ABI) -mno-relax
CFLAGS  := $(ARCH_FLAGS) -Wall
ASFLAGS := $(ARCH_FLAGS) --warn --fatal-warnings

CROSS_COMPILE ?= riscv-none-elf-

export PATH := $(RISCV)/bin:$(PATH)

CC      := $(CROSS_COMPILE)gcc
AS      := $(CROSS_COMPILE)as
SIZE    := $(CROSS_COMPILE)size
OBJDUMP := $(CROSS_COMPILE)objdump

SPIKE := /usr/bin/xspike
PK    := /opt/riscv-none-elf/bin/pk

HFILES := $(wildcard *.h)
OFILES := $(TARGET).o syscall.o

.PHONY: all run clean distclean size dump

ifdef S
all: size
else
all: $(TARGET)
endif

run: $(TARGET) $(if $(S),size)
	$(SPIKE) --isa=rv32iac $(if $(D),-d) $(PK) $(if $(S),-s) $(TARGET)

size: $(TARGET)
	$(SIZE) -A $(TARGET)

dump: $(TARGET)
	$(OBJDUMP) -d $(TARGET) > $(TARGET).dump

clean:
	$(RM) $(TARGET)
	$(RM) *.dump
	$(RM) *.o

distclean: clean
	$(RM) *~

.S.s:
	$(CC) $(CFLAGS) -E -o $@ $<

.s.o:
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET): $(OFILES) $(LDSCRIPT) Makefile
	$(CC) $(CFLAGS) \
	-nostartfiles -nostdlib \
	$(if $(LDSCRIPT), -T $(LDSCRIPT)) -o $@ $(OFILES)
