/*
 * RISC-V Forth re-written from an ancient Z80 disassembler listing
 */

        .section .init
        .global _start
_start:
        j _cold_start

        .text
        .global _cold_start
_cold_start:
        li a0, 0
        tail _exit
