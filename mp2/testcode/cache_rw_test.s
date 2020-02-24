cache_rw_test.s:
.align 4
.section .text
.globl _start

_start:

      lw x1, zero
      lw x1, one
      lw x1, two
      lw x1, three
      lw x1, four
      lw x1, five

      xor x1, x1, x1

      la x2, zero
      sw x1, 0(x2)
      la x2, one
      sw x1, 0(x2)
      la x2, two
      sw x1, 0(x2)
      la x2, three
      sw x1, 0(x2)
      la x2, four
      sw x1, 0(x2)
      la x2, five
      sw x1, 0(x2)

      lw x1, zero
      lw x1, one
      lw x1, two
      lw x1, three
      lw x1, four
      lw x1, five

      xor x1, x1, x1

      la x2, zero
      sw x1, 0(x2)
      la x2, one
      addi x1, x1, 1
      sw x1, 0(x2)
      la x2, two
      addi x1, x1, 1
      sw x1, 0(x2)
      la x2, three
      addi x1, x1, 1
      sw x1, 0(x2)
      la x2, four
      addi x1, x1, 1
      sw x1, 0(x2)
      la x2, five
      addi x1, x1, 1
      sw x1, 0(x2)

      lw x1, zero
      lw x1, one
      lw x1, two
      lw x1, three
      lw x1, four
      lw x1, five


done:
      beq x0, x0, done


zero:       .word 0x00000000
one:        .word 0x00000001
two:        .word 0x00000002
three:      .word 0x00000003
four:       .word 0x00000004
five:       .word 0x00000005
six:        .word 0x00000006
seven:      .word 0x00000007
eight:      .word 0x00000008
nine:       .word 0x00000009
ten:        .word 0x00000010
eleven:     .word 0x00000011
twelve:     .word 0x00000012
thirteen:   .word 0x00000013
fourteen:   .word 0x00000014
fifteen:    .word 0x00000015
sixteen:    .word 0x00000016
seventeen:  .word 0x00000017
eighteen:   .word 0x00000018
nineteen:   .word 0x00000019
twenty:     .word 0x00000020
