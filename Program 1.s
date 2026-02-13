#-------------------------------------------------
# MIPS Example Program: Arithmetic Operations
#-------------------------------------------------
# Reads two integers from the user, performs:
# add, subtract, multiply, divide, and prints results
#-------------------------------------------------

        .data
prompt1:    .asciiz "Enter first number: "
prompt2:    .asciiz "Enter second number: "
resultAdd:  .asciiz "Addition result: "
resultSub:  .asciiz "Subtraction result: "
resultMul:  .asciiz "Multiplication result: "
resultDiv:  .asciiz "Division result (integer): "
newline:    .asciiz "\n"

        .text
        .globl main
main:
        # --- Read first number ---
        li $v0, 4          # print string
        la $a0, prompt1
        syscall

        li $v0, 5          # read integer
        syscall
        move $t0, $v0      # save first number in $t0

        # --- Read second number ---
        li $v0, 4
        la $a0, prompt2
        syscall

        li $v0, 5
        syscall
        move $t1, $v0      # save second number in $t1

        # --- Addition ---
        add $t2, $t0, $t1

        li $v0, 4          # print string
        la $a0, resultAdd
        syscall

        li $v0, 1          # print integer
        move $a0, $t2
        syscall

        li $v0, 4
        la $a0, newline
        syscall

        # --- Subtraction ---
        sub $t3, $t0, $t1

        li $v0, 4
        la $a0, resultSub
        syscall

        li $v0, 1
        move $a0, $t3
        syscall

        li $v0, 4
        la $a0, newline
        syscall

        # --- Multiplication ---
        mul $t4, $t0, $t1

        li $v0, 4
        la $a0, resultMul
        syscall

        li $v0, 1
        move $a0, $t4
        syscall

        li $v0, 4
        la $a0, newline
        syscall

        # --- Division ---
        div $t0, $t1       # $t0 / $t1
        mflo $t5           # quotient in $t5

        li $v0, 4
        la $a0, resultDiv
        syscall

        li $v0, 1
        move $a0, $t5
        syscall

        li $v0, 4
        la $a0, newline
        syscall

        # --- Exit ---
        li $v0, 10
        syscall