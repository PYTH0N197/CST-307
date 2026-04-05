@ =============================================================================
@ CST-307 | Pipeline Analyzer Guide — Part 2
@ Program:  HELLO ALL. I AM HERE, + HEX display counter
@ Platform: CPUlator DE1-SoC (ARMv7)
@ Author:   [Your Name / CLC Members]
@ Date:     [Date]
@
@ Description:
@   Outputs "HELLO ALL. I AM HERE," to the JTAG-UART terminal while
@   counting 0x0 through 0xB on HEX0 concurrently.
@   Stops after 20 full message iterations, then halts.
@
@ Hardware Memory Map (DE1-SoC):
@   JTAG-UART base : 0xFF201000
@     +0x00  DATA register  bits[7:0] = char to TX
@     +0x04  CTRL register  bit[1]=WE, bit[0]=RE
@   HEX3-HEX0 base: 0xFF200020
@     Word store — one byte per digit packed into a 32-bit word:
@       bits [7:0]   = HEX0
@       bits [15:8]  = HEX1
@       bits [23:16] = HEX2
@       bits [31:24] = HEX3
@     IMPORTANT: GPIO on DE1-SoC requires WORD-sized (32-bit) stores.
@                Byte stores (STRB) trigger a device warning and may not work.
@
@ Fix history:
@   v1 - initial version
@   v2 - fixed WSPACE AND-immediate encoding (used LSR #16 instead)
@   v3 - added UART CTRL write-enable; moved data into .text section
@   v4 - replaced WSPACE polling with direct write + delay loop
@   v5 - replaced STRB with STR for HEX display (GPIO word-store requirement)
@ =============================================================================

.equ UART_BASE,    0xFF201000
.equ UART_DATA,    0x00
.equ UART_CTRL,    0x04
.equ HEX_BASE,     0xFF200020
.equ MAX_COUNT,    20
.equ HEX_DIGITS,   12          @ digits 0 through b (12 total)
.equ DELAY_COUNT,  5000        @ busy-wait cycles between characters

@ =============================================================================
.section .text
.global _start

_start:
    @ ---- load peripheral addresses ------------------------------------------
    LDR  R1, =UART_BASE
    LDR  R2, =HEX_BASE
    LDR  R3, =seg_table
    LDR  R8, =message

    @ ---- enable UART (RE=bit0, WE=bit1) -------------------------------------
    MOV  R0, #0x3
    STR  R0, [R1, #UART_CTRL]

    @ ---- initialise counters ------------------------------------------------
    MOV  R4, #0                 @ HEX digit index  (0-11, wraps)
    MOV  R5, #0                 @ iteration counter (0-19)

@ =============================================================================
@ MAIN LOOP
@ =============================================================================
main_loop:
    CMP  R5, #MAX_COUNT
    BGE  done

    MOV  R6, R8                 @ reset char pointer to message start

print_message:
    @ -- load next character --------------------------------------------------
    LDRB R0, [R6]
    CMP  R0, #0                 @ null terminator?
    BEQ  message_done

    @ -- write character to UART ----------------------------------------------
    STR  R0, [R1, #UART_DATA]

    @ -- busy-wait delay ------------------------------------------------------
    LDR  R7, =DELAY_COUNT
delay_loop:
    SUBS R7, R7, #1
    BNE  delay_loop

    @ -- update HEX0 ----------------------------------------------------------
    @ GPIO requires a full 32-bit word store.
    @ Load the segment byte, zero-extend it into R9, then STR (not STRB).
    @ The upper 3 bytes (HEX3-HEX1) are written as 0 (off).
    LDRB R9, [R3, R4]           @ R9 = seg_table[hex_index] (zero-extended)
    STR  R9, [R2]               @ word store to HEX3-HEX0 base; HEX0 = R9[7:0]

    @ -- advance string pointer -----------------------------------------------
    ADD  R6, R6, #1

    @ -- advance HEX index, wrap after b (index 11) ---------------------------
    ADD  R4, R4, #1
    CMP  R4, #HEX_DIGITS
    MOVGE R4, #0

    B    print_message

message_done:
    ADD  R5, R5, #1             @ count completed iteration
    B    main_loop

@ =============================================================================
done:
    MOV  R0, #0
    STR  R0, [R2]               @ clear HEX3-HEX0 (word store, all off)
halt:
    B    halt

@ =============================================================================
@ DATA — kept in .text for predictable addressing in CPUlator
@ =============================================================================

    @ seven-segment encoding (active HIGH): a=bit0 b=bit1 c=bit2 d=bit3
    @                                       e=bit4 f=bit5 g=bit6
seg_table:
    .byte 0x3F   @ 0  abcdef
    .byte 0x06   @ 1  bc
    .byte 0x5B   @ 2  abdeg
    .byte 0x4F   @ 3  abcdg
    .byte 0x66   @ 4  bcfg
    .byte 0x6D   @ 5  acdfg
    .byte 0x7D   @ 6  acdefg
    .byte 0x07   @ 7  abc
    .byte 0x7F   @ 8  abcdefg
    .byte 0x6F   @ 9  abcdfg
    .byte 0x77   @ a  abcefg
    .byte 0x7C   @ b  cdefg

message:
    .asciz "HELLO ALL. I AM HERE,"

@ End of file