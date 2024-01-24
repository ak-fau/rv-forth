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
        la sp, _forth_return_stack
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

        .macro _next
            lw a1, 0(s1)
            addi s1, s1, 4
            jr a1
        .endm

        .macro _call
            jal ra, CALL
        .endm

CALL:   addi sp, sp, -4
        sw s1, 0(sp)
        mv s1, ra
NEXT:   _next

RETURN: lw s1, 0(sp)
        addi sp, sp, 4

        /* duplicate NEXT, comment out j NEXT to measure speed-up */
        .if 0
            j NEXT
        .else
            _next
        .endif

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

        /****************************************************************/

        /* @ */
_AT:    lw a0, 0(a0)
        sw a0, 0(s0)
        j NEXT

        /* ! */
_STORE: lw a1, 4(s0)
        addi s0, s0, 8
        sw a1, 0(a0)
        lw a0, 0(s0)
        j NEXT

        /* C@ */
C_AT:   lbu a0, 0(a0)
        sw a0, 0(s0)
        j NEXT

        /* C! */
C_STORE: lw a1, 4(s0)
        addi s0, s0, 8
        sb a1, 0(a0)
        lw a0, 0(s0)
        j NEXT
/***
H_AT:   lhu a0, 0(a0)
        sw a0, 0(s0)
        j NEXT

H_STORE: lw a1, 4(s0)
        addi s0, s0, 8
        sh a1, 0(a0)
        lw a0, 0(s0)
        j NEXT
***/
        /* BRANCH */
BRANCH: lw s1, 0(s1)
        j NEXT

NQBRANCH: /* N?BRANCH */
        bnez a0, 1f
        li a0, -1
        j QBRANCH
1:      mv a0, zero
QBRANCH: /* ?BRANCH */
        mv t0, a0
        lw a0, 4(s0)
        lw a1, 0(s1)
        addi s1, s1, 4
        addi s0, s0, 4
        bnez t0, NEXT
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

VAR:    mv a0, s1
        addi s0, s0, -4
        addi s1, s1, 4
        sw a0, 0(s0)
        j NEXT

ONE:    li a0, 1
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

TWO:    li a0, 2
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

DUP:    sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

SWAP:   lw a1, 4(s0)
        sw a0, 4(s0)
        sw a1, 0(s0)
        mv a0, a1
        j NEXT

OVER:   lw a0, 4(s0)
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

        /****************************************************************/

PLUS:   lw a1, 4(s0)
        addi s0, s0, 4
        add a0, a0, a1
        sw a0, 0(s0)
        j NEXT

ONE_PLUS:
        addi a0, a0, 1
        sw a0, 0(s0)
        j NEXT

        /****************************************************************/

        .align 2

CR:     _call
        .word LIT, 0x0d, _EMIT
        .word LIT, 0x0a, _EMIT
        .word RETURN

TYPE:   _call
        .word RETURN

COUNT:  _call
        .word DUP, _AT
        .word SWAP, LIT, 4, PLUS, SWAP
        .word RETURN

BYE:    _call
        .word LIT
        .word MSG
        .word COUNT
        .word TYPE
        .word CR
        .word RETURN

        .section .rodata
        .align 2
MSG:
        .word 7
        .ascii "Goodbye"

        .align 2

        /****************************************************************/

        .text
        .align 2
START:
        .word TEST
        ; .word BYE
        .word _STOP

        .align 2
TEST: /* CFA -- no RVC!! */
        _call
TEST_PFA:
        .word _KEY
        .word DUP
        .word LIT, 'q'
        .word _EQ
        .word QBRANCH, 1f
        .word RETURN
1:
        .word _EMIT
        .word  BRANCH, TEST_PFA

R0:
        _call
        .word LIT, _forth_return_stack, RETURN

S0:
        jal ra, CALL
        .word LIT, _forth_data_stack, RETURN
