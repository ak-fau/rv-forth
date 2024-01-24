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
        lw a0, 0(s0)
        j NEXT

_STOP:
        mv a0, zero
        tail _exit

        /****************************************************************/

        /* @ */
AT:     lw a0, 0(a0)
        sw a0, 0(s0)
        j NEXT

        /* ! */
STORE:  lw a1, 4(s0)
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

        /****************************************************************/

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

_DO:                             /* end-value, start-value --> */
                                 /* leave-addres -R->          */
        _call
        .word FROM_R, DUP, AT, TO_R
        .word ROT, TO_R
        .word SWAP, TO_R
        .word LIT, 4, PLUS, TO_R /* -R->  leave-address', end-value, start/current-value, loop-body-start */
        .word RETURN             /* -R->  leave-address', end-value, current-value */

_LOOP:
        _call
        .word FROM_R, FROM_R, R_AT /* --> return-address, current-value, end-value */
        .word OVER, LT
        .word QBRANCH, 1f
        /* leave */
        .word DROP, FROM_R, FROM_R, DROP, DROP
        .word LIT, 4, PLUS
        .word BRANCH, 2f
1:
        /* continue */
        .word ONE, PLUS, TO_R, AT
2:
        .word TO_R
        .word RETURN

        /****************************************************************/

EQ:     /* == */
        lw a1, 4(s0)
        addi s0, s0, 4
        beq a0, a1, 1f
        mv a0, zero
        sw a0, 0(s0)
        j NEXT
1:      li a0, -1
        sw a0, 0(s0)
        j NEXT


LT:     /* <  less than:   A, B --> Flag */
        lw a1, 4(s0)
        addi s0, s0, 4
        bltu a1, a0, 1f
        sw zero, 0(s0)
        mv a0, zero
        j NEXT
1:
        li a0, -1
        sw a0, 0(s0)
        j NEXT

GT:     /* >  more than:   A, B --> Flag */
        lw a1, 4(s0)
        addi s0, s0, 4
        bgtu a1, a0, 1f
        sw zero, 0(s0)
        mv a0, zero
        j NEXT
1:
        li a0, -1
        sw a0, 0(s0)
        j NEXT

        /****************************************************************/

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

ZERO:   mv a0, zero
        sw zero, -4(s0)
        addi s0, s0, -4
        j NEXT

ONE:    li a0, 1
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

TWO:    li a0, 2
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

DROP:   addi s0, s0, 4
        lw a0, 0(s0)
        j NEXT

QDUP:   bnez a0, DUP
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

ROT:    lw a1, 4(s0)
        lw a2, 8(s0)
        sw a0, 4(s0)
        sw a1, 8(s0)
        sw a2, 0(s0)
        mv a0, a2
        j NEXT

TO_R:   addi s0, s0, 4
        sw a0, -4(sp)
        addi sp, sp, -4
        lw a0, 0(s0)
        j NEXT

FROM_R: lw a0, 0(sp)
        addi sp, sp, 4
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

R_AT:   lw a0, 0(sp)
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

        /****************************************************************/

PLUS:   lw a1, 4(s0)
        addi s0, s0, 4
        add a0, a0, a1
        sw a0, 0(s0)
        j NEXT

MINUS:  lw a1, 4(s0)
        addi s0, s0, 4
        sub a0, a1, a0
        sw a0, 0(s0)
        j NEXT

AND:    lw a1, 4(s0)
        addi s0, s0, 4
        and a0, a1, a0
        sw a0, 0(s0)
        j NEXT

ONE_PLUS:
        addi a0, a0, 1
        sw a0, 0(s0)
        j NEXT

TWO_DIV:
        srai a0, a0, 1
        sw a0, 0(s0)
        j NEXT

RSHIFT:
        lw a1, 4(s0)
        addi s0, s0, 4
        srl a0, a1, a0
        sw a0, 0(s0)
        j NEXT

        /****************************************************************/

        .align 2

CR:     _call
        .word LIT, 0x0d, _EMIT
        .word LIT, 0x0a, _EMIT
        .word RETURN

BL:     li a0, ' '
        sw a0, -4(s0)
        addi s0, s0, -4
        j NEXT

SPACE:  _call
        .word BL, _EMIT, RETURN

SPACES: _call
        .word QDUP, QBRANCH, 2f
        .word ZERO, _DO, 2f
1:
        .word SPACE
        .word _LOOP, 1b
2:
        .word RETURN

TYPE:   _call
TYPE_PFA:
        .word QDUP              /* A, N --> A, N, N | A, 0 */
        .word QBRANCH, 1f
        .word ONE, MINUS        /* -- A, N-1 */
        .word SWAP, DUP, C_AT, _EMIT
        .word ONE, PLUS, SWAP
        .word BRANCH, TYPE_PFA
1:
        .word DROP, RETURN

COUNT:  _call
        .word DUP, AT
        .word SWAP, LIT, 4, PLUS, SWAP
        .word RETURN

HEX_DIGIT:
        _call
        .word LIT, 15, AND
        .word DUP, LIT, 10, LT
        .word NQBRANCH, 1f
        .word LIT, 'A'-10, PLUS
        .word RETURN
1:
        .word LIT, '0', PLUS
        .word RETURN

HEX_DOT_C:
        _call
        .word DUP, LIT, 4, RSHIFT
        .word HEX_DIGIT, _EMIT
        .word HEX_DIGIT, _EMIT
        .word RETURN

HEX_DOT:
        _call
        .word DUP, LIT, 24, RSHIFT, HEX_DOT_C
        .word DUP, LIT, 16, RSHIFT, HEX_DOT_C
        .word DUP, LIT,  8, RSHIFT, HEX_DOT_C
        .word HEX_DOT_C
        .word RETURN

_OK:    _call
        .word LIT
        .word MSG_OK
        .word COUNT
        .word TYPE
        .word CR
        .word RETURN

        .section .rodata
        .align 2
MSG_OK:
        .word 2
        .ascii "ok"

        /****************************************************************/

        .text
        .align 2
START:
        .word TEST
        .word _STOP

        .align 2
TEST: /* CFA -- no RVC!! */
        _call
        .word LIT,  0, HEX_DOT_C, CR
        .word LIT,  1, HEX_DOT_C, CR
        .word LIT,  2, HEX_DOT_C, CR
        .word LIT,  3, HEX_DOT_C, CR
        .word LIT,  4, HEX_DOT_C, CR
        .word LIT,  5, HEX_DOT_C, CR
        .word LIT,  6, HEX_DOT_C, CR
        .word LIT,  7, HEX_DOT_C, CR
        .word LIT,  8, HEX_DOT_C, CR
        .word LIT,  9, HEX_DOT_C, CR
        .word LIT, 10, HEX_DOT_C, CR
        .word LIT, 11, HEX_DOT_C, CR
        .word LIT, 12, HEX_DOT_C, CR
        .word LIT, 13, HEX_DOT_C, CR
        .word LIT, 14, HEX_DOT_C, CR
        .word LIT, 15, HEX_DOT_C, CR
        .word LIT, 0x10, HEX_DOT_C, CR
        .word LIT, 0x20, HEX_DOT_C, CR
        .word LIT, 0x30, HEX_DOT_C, CR
        .word LIT, 0x40, HEX_DOT_C, CR
        .word LIT, 0x50, HEX_DOT_C, CR
        .word LIT, 0x60, HEX_DOT_C, CR
        .word LIT, 0x70, HEX_DOT_C, CR
        .word LIT, 0x80, HEX_DOT_C, CR
        .word LIT, 0x90, HEX_DOT_C, CR
        .word LIT, 0xA0, HEX_DOT_C, CR
        .word LIT, 0xB0, HEX_DOT_C, CR
        .word LIT, 0xC0, HEX_DOT_C, CR
        .word LIT, 0xD0, HEX_DOT_C, CR
        .word LIT, 0xE0, HEX_DOT_C, CR
        .word LIT, 0xF0, HEX_DOT_C, CR
        .word LIT, 0xFF, HEX_DOT_C, CR
        .word LIT, 0x1234abcd, HEX_DOT, CR
        /* .word RETURN */

        .word _OK
        .word LIT, '*', _EMIT
        .word LIT, 3, SPACES
        .word LIT, '*', _EMIT
        .word CR
1:
        .word _KEY
        .word DUP
        .word LIT, 'q'
        .word EQ
        .word QBRANCH, 2f
        .word RETURN
2:
        .word _EMIT
        .word  BRANCH, 1b

R0:
        _call
        .word LIT, _forth_return_stack, RETURN

S0:
        _call
        .word LIT, _forth_data_stack, RETURN
