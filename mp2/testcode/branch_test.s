individual_tests.s:
.align 4
.section .text
.globl _start

_start:

      lw x1, one
      lw x2, one
      beq x1, x2, skip1
      beq x1, x1, error
skip1:
      addi x2, x2, 1
      bne x1, x2, skip2
      beq x1, x1, error
skip2:
      lw x2, negtwo
      lw x1, negone
      blt x2, x1, skip3
      beq x1, x2, error
skip3:
      bge x1, x2, skip4
      beq x1, x1, error
skip4:
      lw x1, signweird
      lw x2, one
      bltu x2, x1, skip5
      beq x1, x1, error
skip5:
      bgeu x1, x2, success
      beq x1, x1, error

success:
      lw x1, sample
      beq x1, x1, success

error:
      lw x1, bad
      beq x1, x1, error

one:        .word 0x00000001
two:        .word 0x00000002
bad:        .word 0xdeadbeef
empty:      .word 0x00000000
sample:     .word 0xB00BB00B
negone:     .word 0xFFFFFFFF
negtwo:     .word 0xFFFFFFFE
signweird:  .word 0xF000000D
