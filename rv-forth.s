/*
 * RISC-V Forth re-written from an ancient Z80 disassembler listing
 */

        .text
        .global _start
_start:
        j _cold_start

_exit:
        mv a1, zero
        mv a2, zero
        mv a3, zero
        mv a4, zero
        mv a5, zero
        li a7, 93
        ecall

_cold_start:
        li a0, 0
        tail _exit
