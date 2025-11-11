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

.macro PRINT buf, len
 mov x0, #1
 ldr x1, =\buf
 mov x2, \len
 mov x8, #SYS_write
 svc #0
.endm

.macro SLEEP_MS ms
 ldr x0, =tspec
 mov x1, #0
 str x1, [x0]
 mov x1, \ms
 ldr x2, =1000000
 mul x1, x1, x2
 str x1, [x0, #8]
 mov x1, #0
 mov x8, #SYS_nanosleep
 svc #0
.endm

_start:
 mov x20, #1000
 mov x21, #15
 mov x22, #200
 mov x23, #0
 mov x24, #0

loop:
 PRINT msg_on, len_on
 mov x0, x20
 lsr x0, x0, #1
 SLEEP_MS x0
 add x24, x24, x0
 PRINT msg_off, len_off
 mov x0, x20
 lsr x0, x0, #1
 SLEEP_MS x0
 add x24, x24, x0
 cmp x24, x22
 blt loop
 sub x24, x24, x22
 cmp x23, #0
 bne up
 subs x20, x20, x21
 cmp x20, #250
 bhi loop
 mov x20, #250
 mov x23, #1
 b loop
up:
 adds x20, x20, x21
 cmp x20, #1000
 blt loop
 mov x20, #1000
 mov x23, #0
 b loop
