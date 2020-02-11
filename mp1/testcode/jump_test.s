jump_test:
.align 4
.section .text
.globl _start

_start:
      jal x1, ld_reg
      jal done

ld_reg:
      lw x5, testval
      jalr x2, 3(x1)

done:
      beq x0, x0, done

testval:    .word 0x0000B00B
