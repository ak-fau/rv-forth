/*
 * System calls (to proxy kernel/spike)
 */

        .equ SYSCALL_exit,  93
        .equ SYSCALL_read,  63
        .equ SYSCALL_write, 64

        .section .init
        .global _init
_init:  wfi
        j _init

        .global _exit
_exit:
	mv a1, zero
	mv a2, zero
	mv a3, zero
	mv a4, zero
	mv a5, zero
	li a7, SYSCALL_exit
	ecall
1:
        wfi
        j 1b

        .global _putchar
_putchar:
        addi sp, sp, -4
        sb a0, 0(sp)
        mv a1, sp
        mv a6, a0
        li a0, 1
        li a2, 1
        li a7, SYSCALL_write
        ecall
        addi sp, sp, 4
        blez a0, 1f
        mv a0, a6
        ret
1:      li a0, -1
        ret

        .global _getchar
_getchar:
        addi sp, sp, -4
        mv a1, sp
        li a0, 0
        li a2, 1
        li a7, SYSCALL_read
        ecall
        addi t0, a0, -1
        lbu a0, 0(sp)
        beqz t0, 1f
        li a0, -1
1:      addi sp, sp, 4
        ret
