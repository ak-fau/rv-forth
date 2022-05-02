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
        *   x2 (sp) -- return stack pointer
        *   x3 (gp) -- data stack pointer
        *   x4 (tp) -- threaded code pointer
        *   x10 (a0) -- copy of data stack top element
        */
CALL:   addi sp, sp, -4
        sw tp, 0(sp)
        mv tp, ra
NEXT:   lw ra, 0(tp)
        addi tp, tp, 4
        jr ra

EXIT:   lw tp, 0(sp)
        addi sp, sp, 4
        j NEXT
