
OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  rom (rx)  : ORIGIN = 0x00010000, LENGTH = 0x1000
  ram (rwx) : ORIGIN = 0x00018000, LENGTH = 0x1000
}

FORTH_DATA_STACK_SIZE = 1*1024;
FORTH_STRING_BUFFER_SIZE = 2*1024;

SECTIONS
{
    .init : {
        *(.init)
    } > rom

    .text : {
        *(.text)
    } > rom

    .rodata : {
        . = ALIGN(4);
        *(.rodata)
    } > rom

    .data : {
        *(.data)
        . = ALIGN(4);
        *(.bss)
        . = . + FORTH_DATA_STACK_SIZE;
        . = ALIGN(4);
        _forth_data_stack = .;
        . = ORIGIN(ram) + LENGTH(ram) - FORTH_STRING_BUFFER_SIZE - 16;
        _forth_return_stack = .;
        . = . + 16;
        . = ALIGN(4);
        _forth_string_buffer = .;
        . = ORIGIN(ram) + LENGTH(ram);
    } > ram

    _end_of_ram = .;
}
