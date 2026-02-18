/* ============================================================
 * larger_of_two.s
 * ARMv7 Assembly – CPUlator (DE1-SoC)
 *
 * Reads two signed integers from the JTAG UART,
 * compares them, and prints the larger value.
 *
 * JTAG UART registers:
 *   Data:    0xFF201000  (R/W char, bit 15 = RVALID on read)
 *   Control: 0xFF201004  (bits [31:16] = WSPACE)
 *
 * Cache: 1 cycle address access + 3 cycles data transfer
 * ============================================================ */

            .text
            .global _start

            .equ    JTAG_UART_DATA, 0xFF201000
            .equ    JTAG_UART_CTRL, 0xFF201004
            .equ    NEWLINE,        0x0A
            .equ    CARRIAGE_RET,   0x0D
            .equ    MINUS_SIGN,     0x2D

/* ── Entry Point ─────────────────────────────────────────── */
_start:
            LDR     R0, =prompt1
            BL      uart_print_string

            BL      uart_read_integer
            MOV     R4, R0                  @ R4 = first number (preserved across calls)

            LDR     R0, =prompt2
            BL      uart_print_string

            BL      uart_read_integer
            MOV     R5, R0                  @ R5 = second number

            /* CMP sets CPSR flags (N,Z,C,V) by computing R4-R5
               without storing the result. Branches read these flags:
               BEQ checks Z=1, BGT checks Z=0 and N=V */
            CMP     R4, R5
            BEQ     numbers_equal
            BGT     first_is_larger

            MOV     R6, R5                  @ fall-through: second is larger
            B       print_result

first_is_larger:
            MOV     R6, R4
            B       print_result

numbers_equal:
            LDR     R0, =equal_msg
            BL      uart_print_string
            MOV     R6, R4
            B       print_value

print_result:
            LDR     R0, =result_msg
            BL      uart_print_string

print_value:
            MOV     R0, R6
            BL      uart_print_integer

            LDR     R0, =newline_str
            BL      uart_print_string

end:        B       end                     @ No HALT in ARM; infinite loop stops execution

            .ltorg                          @ Emit literal pool (constants for LDR =label)


/* ── uart_putc: send R0[7:0] to UART ──────────────────────── */
/* Polls WSPACE in control register until FIFO has room */
uart_putc:
            PUSH    {R1, R2, LR}
            LDR     R1, =JTAG_UART_CTRL
_putc_wait: LDR     R2, [R1]
            LSR     R2, R2, #16             @ WSPACE is in upper 16 bits
            CMP     R2, #0
            BEQ     _putc_wait
            LDR     R1, =JTAG_UART_DATA
            STR     R0, [R1]
            POP     {R1, R2, LR}
            BX      LR                      @ BX LR = return to caller

            .ltorg


/* ── uart_getc: poll UART, return char in R0[7:0] ─────────── */
/* Polls RVALID (bit 15) until a character is available */
uart_getc:
            PUSH    {R1, LR}
            LDR     R1, =JTAG_UART_DATA
_getc_wait: LDR     R0, [R1]
            TST     R0, #0x8000             @ TST = AND without storing; tests RVALID
            BEQ     _getc_wait
            AND     R0, R0, #0xFF           @ Isolate the character byte
            POP     {R1, LR}
            BX      LR

            .ltorg


/* ── uart_print_string: print null-terminated string at R0 ── */
uart_print_string:
            PUSH    {R0, R1, LR}
            MOV     R1, R0
_ps_loop:   LDRB    R0, [R1], #1            @ Load byte + post-increment pointer
            CMP     R0, #0
            BEQ     _ps_done
            BL      uart_putc
            B       _ps_loop
_ps_done:   POP     {R0, R1, LR}
            BX      LR


/* ── uart_read_integer: read signed decimal, return in R0 ─── */
/* Builds number digit-by-digit: value = value*10 + (char-'0')
   Supports optional leading '-'. Echoes typed chars back.     */
uart_read_integer:
            PUSH    {R1-R5, LR}
            MOV     R1, #0                  @ R1 = accumulated value
            MOV     R2, #0                  @ R2 = negative flag
            MOV     R3, #0                  @ R3 = got-digit flag

_ri_loop:   BL      uart_getc

            CMP     R0, #CARRIAGE_RET       @ Enter key ends input
            BEQ     _ri_done
            CMP     R0, #NEWLINE
            BEQ     _ri_done

            CMP     R0, #MINUS_SIGN         @ Accept '-' only before first digit
            BNE     _ri_not_minus
            CMP     R3, #0
            BNE     _ri_loop
            MOV     R2, #1
            BL      uart_putc
            B       _ri_loop

_ri_not_minus:
            CMP     R0, #0x30              @ Ignore anything outside '0'-'9'
            BLT     _ri_loop
            CMP     R0, #0x39
            BGT     _ri_loop

            BL      uart_putc               @ Echo digit

            SUB     R0, R0, #0x30          @ ASCII to integer
            MOV     R4, #10
            MUL     R5, R1, R4              @ value * 10
            ADD     R1, R5, R0              @ + new digit
            MOV     R3, #1
            B       _ri_loop

_ri_done:   CMP     R2, #1
            BNE     _ri_pos
            RSB     R1, R1, #0             @ RSB = Reverse Subtract: R1 = 0 - R1 (negate)
_ri_pos:    MOV     R0, R1

            PUSH    {R0}
            MOV     R0, #NEWLINE
            BL      uart_putc
            POP     {R0}

            POP     {R1-R5, LR}
            BX      LR


/* ── divide_by_10: R0=quotient, R1=remainder ──────────────── */
/* UDIV not supported on this CPU, so we multiply by the
   reciprocal: quotient = hi32(n * 0xCCCCCCCD) >> 3
   Uses UMULL for full 64-bit unsigned multiply.              */
divide_by_10:
            PUSH    {R2, R3, LR}
            LDR     R2, =0xCCCCCCCD        @ Magic constant ~ 2^35 / 10
            UMULL   R3, R2, R0, R2          @ 64-bit multiply; we only need high word (R2)
            LSR     R2, R2, #3              @ Quotient
            MOV     R3, #10
            MUL     R3, R2, R3
            SUB     R1, R0, R3              @ Remainder = dividend - quotient*10
            MOV     R0, R2
            POP     {R2, R3, LR}
            BX      LR

            .ltorg


/* ── uart_print_integer: print signed int in R0 as ASCII ──── */
/* Extracts digits via divide_by_10, pushes onto stack,
   then pops in reverse order (LIFO) to print MSB first.      */
uart_print_integer:
            PUSH    {R0-R5, LR}
            MOV     R4, R0
            MOV     R5, SP                  @ Save SP for safe cleanup

            CMP     R4, #0
            BGE     _pi_positive
            PUSH    {R4}
            MOV     R0, #MINUS_SIGN
            BL      uart_putc
            POP     {R4}
            RSB     R4, R4, #0              @ Absolute value

_pi_positive:
            CMP     R4, #0
            BNE     _pi_push
            MOV     R0, #0x30
            BL      uart_putc
            B       _pi_exit

_pi_push:   MOV     R2, #0                  @ Digit count
_pi_div:    CMP     R4, #0
            BEQ     _pi_pop

            MOV     R0, R4
            BL      divide_by_10
            ADD     R1, R1, #0x30           @ Remainder to ASCII
            PUSH    {R1}                    @ Push digit (least-significant first)
            ADD     R2, R2, #1
            MOV     R4, R0
            B       _pi_div

_pi_pop:    CMP     R2, #0                  @ Pop prints most-significant first
            BEQ     _pi_exit
            POP     {R0}
            BL      uart_putc
            SUB     R2, R2, #1
            B       _pi_pop

_pi_exit:   MOV     SP, R5
            POP     {R0-R5, LR}
            BX      LR


/* ── Strings in .text (CPUlator can't resolve .data refs) ─── */
prompt1:    .asciz  "Enter first number: "
            .align
prompt2:    .asciz  "\nEnter second number: "
            .align
result_msg: .asciz  "\nThe larger number is: "
            .align
equal_msg:  .asciz  "\nBoth numbers are equal: "
            .align
newline_str:.asciz  "\n"
            .align

            .end