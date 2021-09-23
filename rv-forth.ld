
OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  rom (rx)  : ORIGIN = 0x00010000, LENGTH = 0x8000
  ram (rwx) : ORIGIN = 0x00018000, LENGTH = 0x8000
}

SECTIONS
{
    .init : {
        *(.init)
    } > rom

    .text : {
        *(.text)
    } > rom

    .rodata : {
        *(.rodata)
    } > rom

    .data : {
        *(.data)
        . = ALIGN(4);
        *(.bss)
        . = ORIGIN(ram) + LENGTH(ram);
    } > ram

    _end_of_ram = .;
}
