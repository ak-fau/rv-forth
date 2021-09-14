/*
 * System calls (to proxy kernel/spike)
 */

        .equ SYSCALL_exit,  93

        .section .init
        .global _init
_init:
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
