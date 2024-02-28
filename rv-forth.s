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
        la gp, _forth_string_buffer
        la s1, START
        j NEXT

        /****************************************************************
        * Interpreter registers:
        *   x2  (sp) -- return stack pointer
        *   x3  (gp) -- [long] strings area
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

        .macro save_t012
            sw t0, -4(s0)
            sw t1, -8(s0)
            sw t2, -12(s0)
            addi s0, s0, -12
        .endm

        .macro restore_t012
            lw t2, 0(s0)
            lw t1, 4(s0)
            lw t0, 8(s0)
            addi s0, s0, 12
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

ASMCALL: /* a0 a1 a2 a3 a4 a5 addr -- a0 a1 */
        sw ra, -4(sp)
        addi sp, sp, -4
        mv ra, a0

        lw a5, 4(s0)
        lw a4, 8(s0)
        lw a3, 12(s0)
        lw a2, 16(s0)
        lw a1, 20(s0)
        lw a0, 24(s0)

        jalr ra, ra

        lw ra, 0(sp)
        addi sp, sp, 4
        addi s0, s0, 20
        sw a0, 4(s0)
        sw a1, 0(s0)
        mv a0, a1

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

NOT:
        _call
        .word ZERO, EQ
        .word RETURN

GE:
        _call
        .word LT, NOT, RETURN

LE:
        _call
        .word GT, NOT, RETURN

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

TWO_DUP:
        _call
        .word OVER, OVER
        .word RETURN

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

BS:     /* backspace */
        _call
        .word LIT, 0x08 /* ASCII BS */
        .word BL, OVER
        .word _EMIT, _EMIT, _EMIT
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

OK:    _call
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

        .text
        .align 2

QPRINT:
        _call
        .word DUP, LIT, ' '
        .word GE, QBRANCH, 1f
        .word LIT, '~'
        .word LE, QBRANCH, 2f
        .word LIT, -1
        .word RETURN
1:      .word DROP
2:      .word ZERO
        .word RETURN

        /****************************************************************/

        /* Parameters:
        /* [gp -- long strings area -- global      */
        /* a0 -- string len                        */
        /* a1 -- string pointer                    */
        /* a2 -- pointer to name list (vocabulary) */
        /*                                         */
        /* Returns:                                */
        /* a0 == 0 -- not found                    */
        /* a0 -- NFA (pointer to the list entry)   */

_find:
        andi a0, a0, 0x1f
        li t0, 3
        bgt a0, t0, 4f /* len > 3 */
        /* fall through, len <= 3 */
        lw a1, 0(a1)
        li t0, 1
        slli a0, a0, 3
        sll t0, t0, a0
        addi t0, t0, -1
        slli a0, a0, (24 - 3)
        and a1, a1, t0
        or a1, a1, a0 /* len & char(s) */
        li t0, 0x1fffffff
1:
        bnez a2, 2f
        mv a0, zero
        ret
2:
        lw a0, 0(a2)
        and a0, a0, t0
        beq a0, a1, 3f
        lw a2, 4(a2)
        j 1b
3:
        mv a0, a2
        ret

4:      /* len > 3 */
        li a0, 0
        ret

        /****************************************************************/

_strncmp:
        mv t0, a0
        mv a0, zero
        bnez a2, 2f
1:
        jr ra
2:
        lbu t1, 0(t0)
        lbu t2, 0(a1)
        sub a0, t1, t2
        beqz a0, 3f
        jr ra
3:
        addi a2, a2, -1
        bnez a2, 4f
        jr ra
4:
        addi t0, t0, 1
        addi a1, a1, 1
        j 2b

_EXPECT: /* buf_addr max_count --> buf_addr count */
        lw t0, 4(s0)
        mv t1, zero
        mv t2, a0
1:
        save_t012
        call _getchar
        restore_t012

        li a1, 0x20
        blt a0, a1, 3f
        li a1, 0x7f
        bge a0, a1, 3f

        sb a0, 0(t0)
        addi t0, t0, 1
        addi t1, t1, 1
        save_t012
        call _putchar
        restore_t012
        bne t1, t2, 1b
2:
        mv a0, t1
        sw a0, 0(s0)
        j NEXT

3:      /* control character */
        li a1, 0x0A
        beq a0, a1, 2b

        li a1, 0x7f
        bne a0, a1, 1b

        /* backspace */
        beqz t1, 1b
        addi t1, t1, -1
        addi t0, t0, -1

        li a0, 0x08
        call _putchar
        li a0, ' '
        call _putchar
        li a0, 0x08
        call _putchar

        j 1b


        .data
        .align 2
        .set TIB_SIZE, 80
TIB:    .space  TIB_SIZE

        /****************************************************************/

        .text
        .align 2
START:
        .word TEST
        .word _STOP

        .align 2
TEST_FIND:
        lui a2, %hi(_dict)
        addi a2, a2, %lo(_dict)
        lw a1, 4(s0)
        addi s0, s0, 4
        call _find
        sw a0, 0(s0)
        j NEXT

        .align 2
TEST:
        _call
        .word CR, LIT, '>', _EMIT, SPACE

        .word LIT, TIB, LIT, 4
        .word _EXPECT, CR

        .word TWO_DUP, SWAP, HEX_DOT, SPACE, HEX_DOT
        .word CR
        .word TWO_DUP, TYPE, CR

        .word TEST_FIND
        .word HEX_DOT, CR

        .word _KEY, DROP
        .word RETURN

R0:
        _call
        .word LIT, _forth_return_stack, RETURN

S0:
        _call
        .word LIT, _forth_data_stack, RETURN
