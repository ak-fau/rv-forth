
ENTRY(_start)

MEMORY
{
  rom : ORIGIN = 0x00010000, LENGTH = 0x8000
  ram : ORIGIN = 0x00018000, LENGTH = 0x8000
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
    } > ram

    .bss : {
        *(.bss)
    } > ram
}
