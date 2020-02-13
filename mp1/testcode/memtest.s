memtest.s:
.align 4
.section .text
.globl _start

_start:

      lb x1, byte
      lbu x1, byte
      lh x1, half
      lhu x1, half
      lw x1, word

      lb x1, byte
      lb x1, bytetwo
      lb x1, bytethree

      lh x1, half
      lh x1, halftwo
      lhu x1, halftwo

      la x2, byte
      addi x1, x0, 127
      sb x1, 0(x2)
      lb x1, byte

      la x2, half
      addi x1, x0, 15
      sh x1, 0(x2)
      lh x1, half

      la x2, word
      addi x1, x0, 14
      sw x1, 0(x2)
      lw x1, word

done:
      beq x0, x0, done

misalign:   .byte 0x77
byte:       .byte 0x8A
bytetwo:    .byte 0x97
bytethree:  .byte 0x31
half:       .half 0x800B
halftwo:    .half 0xB00B
word:       .word 0x800000CD
