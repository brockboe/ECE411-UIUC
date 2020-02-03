factorial.s:
.align 4
.section .text
.globl _start

_start:
      lw x1, input
      la x4, multiplier
      sw x1, 0(x4)

      add x1, x1, -1
      la x4, multiplicand
      sw x1, 0(x4)
      add x1, x1, -1
      la x4, input
      sw x1, 0(x4)

      beq x1, x1, mult_start

fact_loop:
      lw x1, product
      lw x2, result
      la x4, result
      sw x1, 0(x4)

      lw x1, input
      xor x4, x4, x4
      add x4, x4, 1
      beq x1, x4, done

      lw x1, input
      lw x2, result
      la x3, multiplier
      sw x1, 0(x3)
      la x3, multiplicand
      sw x2, 0(x3)

      add x1, x1, -1
      la x3, input
      sw x1, 0(x3)
      beq x1, x1, mult_start


mult_start:
      lw x1, multiplicand
      lw x2, multiplier
      xor x3, x3, x3
mult_loop:
      add x3, x1, x3
      addi x2, x2, -1
      xor x4, x4, x4
      bne x2, x4, mult_loop
mult_done:
      la x4, product
      sw x3, 0(x4)
      beq x3, x3, fact_loop


done:
      lw x1, result
done_loop:
      beq x1, x1, done_loop

.section .rodata

input:            .word 0x00000005
multiplier:       .word 0x00000000
multiplicand:     .word 0x00000000
product:          .word 0x00000000
result:           .word 0x00000000
