/*
 * ARM Assembly Program: Sum of Squares
 * 
 * This program reads two single-digit numbers from the user via JTAG UART,
 * calculates the sum of their squares, and prints the result.
 *
 * Register Usage:
 * R0 - First number (user input)
 * R1 - Second number (user input)
 * R3 - Square of first number (R0 * R0)
 * R4 - Square of second number (R1 * R1)
 * R5 - Sum of squares (R3 + R4)
 */

        .text
        .global _start

.equ JTAG_UART, 0xFF201000

_start:
        LDR     R7, =JTAG_UART        @ R7 = UART base address

MAIN_LOOP:

/* -------- Print "Enter First Number:" -------- */

        LDR     R6, =msg1
PRINT_MSG1:
        LDRB    R8, [R6], #1
        CMP     R8, #0
        BEQ     READ_FIRST

WAIT_WRITE1:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_WRITE1
        STR     R8, [R7]
        B       PRINT_MSG1

/* -------- Read First Number -------- */

READ_FIRST:
        LDR     R8, [R7]
        TST     R8, #0x8000
        BEQ     READ_FIRST
        AND     R0, R8, #0xFF
        SUB     R0, R0, #'0'          @ Convert ASCII to digit

/* -------- Print "Enter Second Number:" -------- */

        LDR     R6, =msg2
PRINT_MSG2:
        LDRB    R8, [R6], #1
        CMP     R8, #0
        BEQ     READ_SECOND

WAIT_WRITE2:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_WRITE2
        STR     R8, [R7]
        B       PRINT_MSG2

/* -------- Read Second Number -------- */

READ_SECOND:
        LDR     R8, [R7]
        TST     R8, #0x8000
        BEQ     READ_SECOND
        AND     R1, R8, #0xFF
        SUB     R1, R1, #'0'          @ Convert ASCII to digit

/* -------- Calculate Sum of Squares -------- */

        MUL     R3, R0, R0            @ R3 = R0 * R0 (first number squared)
        MUL     R4, R1, R1            @ R4 = R1 * R1 (second number squared)
        ADD     R5, R3, R4            @ R5 = R3 + R4 (sum of squares)

/* -------- Print Result Message -------- */

        LDR     R6, =msg3
PRINT_MSG3:
        LDRB    R8, [R6], #1
        CMP     R8, #0
        BEQ     PRINT_RESULT

WAIT_WRITE3:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_WRITE3
        STR     R8, [R7]
        B       PRINT_MSG3

/* -------- Print Result (R5) -------- */

PRINT_RESULT:
        MOV     R2, R5                @ Copy result to R2 for printing
        BL      PRINT_NUMBER          @ Call subroutine to print number

/* -------- Print Newline -------- */

        LDR     R6, =newline
PRINT_NL:
        LDRB    R8, [R6], #1
        CMP     R8, #0
        BEQ     END_PROGRAM

WAIT_WRITE4:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_WRITE4
        STR     R8, [R7]
        B       PRINT_NL

END_PROGRAM:
        B       END_PROGRAM           @ Infinite loop

/* -------- Subroutine: Print Number in R2 -------- */
/* This converts the number to decimal digits and prints them */

PRINT_NUMBER:
        PUSH    {R2, R6, R8, R9, R10, R11, LR}
        
        @ Handle numbers 0-9 (single digit)
        CMP     R2, #10
        BLT     SINGLE_DIGIT
        
        @ Handle numbers 10-99 (two digits)
        CMP     R2, #100
        BLT     TWO_DIGITS
        
        @ Handle numbers >= 100 (three or more digits)
        @ Extract hundreds digit
        MOV     R10, R2
        MOV     R11, #100
FIND_HUNDREDS:
        CMP     R10, R11
        BLT     PRINT_HUNDREDS_DONE
        SUB     R10, R10, R11
        B       FIND_HUNDREDS
PRINT_HUNDREDS_DONE:
        SUB     R6, R2, R10           @ R6 = hundreds digit value
        MOV     R11, #100
DIV_HUNDREDS:
        CMP     R6, R11
        BLT     HUNDREDS_FOUND
        SUB     R6, R6, R11
        B       DIV_HUNDREDS
HUNDREDS_FOUND:
        MOV     R11, #100
COUNT_HUNDREDS:
        CMP     R6, #0
        BEQ     HUNDREDS_COUNTED
        ADD     R6, R6, R11
        B       COUNT_HUNDREDS
HUNDREDS_COUNTED:
        @ Actually, let's use a simpler approach with division by subtraction
        MOV     R10, #0               @ Hundreds counter
SUBTRACT_100:
        CMP     R2, #100
        BLT     DONE_100
        SUB     R2, R2, #100
        ADD     R10, R10, #1
        B       SUBTRACT_100
DONE_100:
        CMP     R10, #0
        BEQ     TWO_DIGITS            @ Skip if no hundreds digit
        ADD     R8, R10, #'0'
WAIT_H:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_H
        STR     R8, [R7]
        
TWO_DIGITS:
        MOV     R10, #0               @ Tens counter
SUBTRACT_10:
        CMP     R2, #10
        BLT     DONE_10
        SUB     R2, R2, #10
        ADD     R10, R10, #1
        B       SUBTRACT_10
DONE_10:
        ADD     R8, R10, #'0'
WAIT_T:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_T
        STR     R8, [R7]
        
SINGLE_DIGIT:
        ADD     R8, R2, #'0'
WAIT_U:
        LDR     R9, [R7, #4]
        LSR     R9, R9, #16
        CMP     R9, #0
        BEQ     WAIT_U
        STR     R8, [R7]
        
        POP     {R2, R6, R8, R9, R10, R11, PC}

/* -------- Data Section -------- */

        .data

msg1:   .asciz "\nEnter First Number (0-9): "
msg2:   .asciz "\nEnter Second Number (0-9): "
msg3:   .asciz "\nSum of Squares: "
newline: .asciz "\n"

        .end