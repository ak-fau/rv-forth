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
        la sp, _end_of_ram - 16

1:      call _getchar
        li t0, 'q'
        beq a0, t0, 1f
        call _putchar
        j 1b
1:
        li a0, 0
        tail _exit

        /*
        * Interpreter registers:
        *   x2  (sp) -- return stack pointer
        *   x8  (s0) -- data stack pointer
        *   x9  (s1) -- threaded code pointer
        *   x10 (a0) -- copy of data stack top element
        */
        .option push
        .option rvc

CALL:   addi sp, sp, -4
        sw s1, 0(sp)
        mv s1, ra
NEXT:   lw a1, 0(s1)
        addi s1, s1, 4
        jr a1

EXIT:   lw s1, 0(sp)
        addi sp, sp, 4
        j NEXT
        /* duplicate NEXT, comment out j NEXT above to measure speed-up */
NEXT1:  lw a1, 0(s1)
        addi s1, s1, 4
        jr a1

        .option pop
