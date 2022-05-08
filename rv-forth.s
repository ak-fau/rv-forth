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
/*
1:      call _getchar
        li t0, 'q'
        beq a0, t0, 1f
        call _putchar
        j 1b
1:
        li a0, 0
        tail _exit
        */

        la s0, _forth_data_stack
        la s1, START
        j NEXT

        /****************************************************************
        * Interpreter registers:
        *   x2  (sp) -- return stack pointer
        *   x8  (s0) -- data stack pointer
        *   x9  (s1) -- threaded code pointer
        *   x10 (a0) -- copy of data stack top element
        */

        .option push
        /* .option norvc /* */
        /* .option rvc /* */

        .macro _next
        lw a1, 0(s1)
        addi s1, s1, 4
        jr a1
        .endm

CALL:   addi sp, sp, -4
        sw s1, 0(sp)
        mv s1, ra
NEXT:   _next

EXIT:   lw s1, 0(sp)
        addi sp, sp, 4

        /* duplicate NEXT, comment out j NEXT to measure speed-up */
        .if 0
        j NEXT
        .else
NEXT1:  _next
        .endif

        .option pop
        /****************************************************************/

        /* (KEY) */
_KEY:   call _getchar
        addi s0, s0, -4
        sw a0, 0(s0)
        j NEXT

        /* (EMIT) */
_EMIT:  addi s0, s0, 4
        call _putchar
        j NEXT

_STOP:
        mv a0, zero
        tail _exit

        /* BRANCH */
BRANCH: lw s1, 0(s1)
        j NEXT

QBRANCH: /* ?BRANCH */
        mv t0, a0
        lw a0, 4(s0)
        lw a1, 0(s1)
        addi s1, s1, 4
        addi s0, s0, 4
        beqz t0, NEXT
        mv s1, a1
        j NEXT

_EQ:    /* == */
        lw a1, 4(s0)
        addi s0, s0, 4
        beq a0, a1, 1f
        mv a0, zero
        sw a0, 0(s0)
        j NEXT
1:      li a0, -1
        sw a0, 0(s0)
        j NEXT

LIT:    lw a0, 0(s1)
        addi s0, s0, -4
        addi s1, s1, 4
        sw a0, 0(s0)
        j NEXT

DUP:    sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

        /****************************************************************/

        .align 4
START:
        .word TEST
        .word _STOP

        .align 4
TEST: /* CFA */
        call CALL
TEST_DFA:
        .word _KEY
        .word DUP
        .word LIT, 'q'
        .word _EQ
        .word QBRANCH, TEST_END
        .word _EMIT
        .word  BRANCH, TEST_DFA
TEST_END:
        .word EXIT
