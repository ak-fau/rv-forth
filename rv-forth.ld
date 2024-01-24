
OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  rom (rx)  : ORIGIN = 0x00010000, LENGTH = 0x0800
  ram (rwx) : ORIGIN = 0x00018000, LENGTH = 0x1000
}

FORTH_DATA_STACK_SIZE = 1*1024;

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
        . = . + FORTH_DATA_STACK_SIZE;
        . = ALIGN(4);
        _forth_data_stack = .;
        . = ORIGIN(ram) + LENGTH(ram) - 16;
        _forth_return_stack = .;
        . = ORIGIN(ram) + LENGTH(ram);
    } > ram

    _end_of_ram = .;
}
