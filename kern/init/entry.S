#include <mmu.h>
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop //把bootstacktop的地址放进sp，进入kern_init()之前设置好内核栈

    tail kern_init //跳到kern_init()，kern_init()为进入C语言后的真正的内核初始化入口

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack: //该栈空间的低地址
    .space KSTACKSIZE //定义一块KSTACKSIZE大小的空间（栈空间）
    .global bootstacktop
bootstacktop: //该栈空间的高地址