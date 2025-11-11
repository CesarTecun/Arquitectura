.section .data
msg_on: .ascii "LED ON\n"
len_on = . - msg_on
msg_off: .ascii "LED OFF\n"
len_off = . - msg_off

.section .bss
.align 3
tspec: .quad 0,0

.section .text
.global _start

.set SYS_write, 64
.set SYS_nanosleep, 101
.set SYS_exit, 93

.macro PRINT buf, len
 mov x0, #1
 ldr x1, =\buf
 mov x2, \len
 mov x8, #SYS_write
 svc #0
.endm

.macro DELAY_MS ms
 mov x3, \ms
 mov x2, #50000
 mul x3, x3, x2
 mov x1, x3
1: subs x1, x1, #1
 b.ne 1b
.endm

_start:
 mov x20, #1000

loop:
 PRINT msg_on, len_on
 mov x0, x20
 lsr x0, x0, #1
 DELAY_MS x0
 PRINT msg_off, len_off
 mov x0, x20
 lsr x0, x0, #1
 DELAY_MS x0
 subs x20, x20, #50
 cmp x20, #250
 b.hs loop
 mov x20, #1000
 b loop
