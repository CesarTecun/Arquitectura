.set SR, 8000
.set CH, 1
.set BITS, 8
.set DUR_MS, 3000

.set F_DO, 523
.set F_MI, 659
.set F_SOL, 784

.set SYS_openat, 56
.set SYS_close, 57
.set SYS_write, 64
.set SYS_exit, 93

.set AT_FDCWD, -100
.set O_WRONLY, 1
.set O_CREAT, 64
.set O_TRUNC, 512

.section .data
fname: .asciz "scale.wav"
hdr: .space 44
buf: .space 4096

.section .text
.global _start

write_tone:
 mov x3, #SR
 mul x3, x3, x2
 ldr x4, =1000
 udiv x3, x3, x4
 mov x4, #SR
 mov x5, #2
 mul x5, x5, x1
 udiv x6, x4, x5

gen_loop:
 cbz x3, gen_end
 ldr x9, =4096
 cmp x3, x9
 csel x9, x3, x9, lo
 ldr x10, =buf
 mov x11, #0
 mov x12, #0
fill:
 cbz x9, filled
 cbz x12, zval
 mov w13, #0xFF
 b store
zval:
 mov w13, #0x00
store:
 strb w13, [x10], #1
 add x11, x11, #1
 cmp x11, x6
 blt keep
 eor x12, x12, #1
 mov x11, #0
keep:
 subs x9, x9, #1
 b fill
filled:
 mov x0, x19
 ldr x1, =buf
 ldr x2, =4096
 cmp x3, x2
 csel x2, x3, x2, lo
 mov x8, #SYS_write
 svc #0
 ldr x2, =4096
 cmp x3, x2
 csel x2, x3, x2, lo
 sub x3, x3, x2
 b gen_loop
gen_end:
 ret

build_wav_header:
 mov x2, x0
 ldr w3, =0x46464952
 str w3, [x2], #4
 mov w3, #36
 add w3, w3, w1
 str w3, [x2], #4
 ldr w3, =0x45564157
 str w3, [x2], #4
 ldr w3, =0x20746D66
 str w3, [x2], #4
 mov w3, #16
 str w3, [x2], #4
 mov w3, #1
 strh w3, [x2], #2
 mov w3, #CH
 strh w3, [x2], #2
 mov w3, #SR
 str w3, [x2], #4
 mov w3, #8000
 str w3, [x2], #4
 mov w3, #1
 strh w3, [x2], #2
 mov w3, #BITS
 strh w3, [x2], #2
 ldr w3, =0x61746164
 str w3, [x2], #4
 str w1, [x2], #4
 ret

_start:
 ldr x0, =AT_FDCWD
 ldr x1, =fname
 mov x2, #577
 mov x3, #420
 mov x8, #SYS_openat
 svc #0
 mov x19, x0
 mov x4, #SR
 mov x5, #DUR_MS
 mul x4, x4, x5
 ldr x6, =1000
 udiv x4, x4, x6
 add x22, x4, x4
 add x22, x22, x4
 mov x1, x22
 ldr x0, =hdr
 bl build_wav_header
 mov x0, x19
 ldr x1, =hdr
 mov x2, #44
 mov x8, #SYS_write
 svc #0
 mov x0, x19
 mov x1, #F_DO
 mov x2, #DUR_MS
 bl write_tone
 mov x0, x19
 mov x1, #F_MI
 mov x2, #DUR_MS
 bl write_tone
 mov x0, x19
 mov x1, #F_SOL
 mov x2, #DUR_MS
 bl write_tone
 mov x0, x19
 mov x8, #SYS_close
 svc #0
 mov x0, #0
 mov x8, #SYS_exit
 svc #0
