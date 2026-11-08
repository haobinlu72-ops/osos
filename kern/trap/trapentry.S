#include <riscv.h>

    .macro SAVE_ALL

    csrw sscratch, sp

    addi sp, sp, -36 * REGBYTES
    # save x registers
    STORE x0, 0*REGBYTES(sp) #zero
    STORE x1, 1*REGBYTES(sp) #ra
    STORE x3, 3*REGBYTES(sp) #gp
    STORE x4, 4*REGBYTES(sp) #tp
    STORE x5, 5*REGBYTES(sp) #t0
    STORE x6, 6*REGBYTES(sp) #t1
    STORE x7, 7*REGBYTES(sp) #t2
    STORE x8, 8*REGBYTES(sp) #s0/fp
    STORE x9, 9*REGBYTES(sp) #s1
    STORE x10, 10*REGBYTES(sp) #a0
    STORE x11, 11*REGBYTES(sp) #a1
    STORE x12, 12*REGBYTES(sp) #a2
    STORE x13, 13*REGBYTES(sp) #a3
    STORE x14, 14*REGBYTES(sp) #a4
    STORE x15, 15*REGBYTES(sp) #a5
    STORE x16, 16*REGBYTES(sp) #a6
    STORE x17, 17*REGBYTES(sp) #a7
    STORE x18, 18*REGBYTES(sp) #s2
    STORE x19, 19*REGBYTES(sp) #s3
    STORE x20, 20*REGBYTES(sp) #s4
    STORE x21, 21*REGBYTES(sp) #s5
    STORE x22, 22*REGBYTES(sp) #s6
    STORE x23, 23*REGBYTES(sp) #s7
    STORE x24, 24*REGBYTES(sp) #s8
    STORE x25, 25*REGBYTES(sp) #s9
    STORE x26, 26*REGBYTES(sp) #s10
    STORE x27, 27*REGBYTES(sp) #s11
    STORE x28, 28*REGBYTES(sp) #t3
    STORE x29, 29*REGBYTES(sp) #t4
    STORE x30, 30*REGBYTES(sp) #t5
    STORE x31, 31*REGBYTES(sp) #t6

    # get sr, epc, badvaddr, cause
    # Set sscratch register to 0, so that if a recursive exception
    # occurs, the exception vector knows it came from the kernel
    csrrw s0, sscratch, x0
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, sbadaddr
    csrr s4, scause

    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm

    .macro RESTORE_ALL

    #lab3 function1 YOUR CODE
    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)
    csrw sstatus, s1
    csrw sepc, s2

    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    LOAD x4, 4*REGBYTES(sp)
    LOAD x5, 5*REGBYTES(sp)
    LOAD x6, 6*REGBYTES(sp)
    LOAD x7, 7*REGBYTES(sp)
    LOAD x8, 8*REGBYTES(sp)
    LOAD x9, 9*REGBYTES(sp)
    LOAD x10, 10*REGBYTES(sp)
    LOAD x11, 11*REGBYTES(sp)
    LOAD x12, 12*REGBYTES(sp)
    LOAD x13, 13*REGBYTES(sp)
    LOAD x14, 14*REGBYTES(sp)
    LOAD x15, 15*REGBYTES(sp)
    LOAD x16, 16*REGBYTES(sp)
    LOAD x17, 17*REGBYTES(sp)
    LOAD x18, 18*REGBYTES(sp)
    LOAD x19, 19*REGBYTES(sp)
    LOAD x20, 20*REGBYTES(sp)
    LOAD x21, 21*REGBYTES(sp)
    LOAD x22, 22*REGBYTES(sp)
    LOAD x23, 23*REGBYTES(sp)
    LOAD x24, 24*REGBYTES(sp)
    LOAD x25, 25*REGBYTES(sp)
    LOAD x26, 26*REGBYTES(sp)
    LOAD x27, 27*REGBYTES(sp)
    LOAD x28, 28*REGBYTES(sp)
    LOAD x29, 29*REGBYTES(sp)
    LOAD x30, 30*REGBYTES(sp)
    LOAD x31, 31*REGBYTES(sp)
    # Restore the original sp only after all frame accesses are complete.
    LOAD x2, 2*REGBYTES(sp)

    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL

    #lab3 function1 YOUR CODE
    mv a0, sp
    jal trap
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
