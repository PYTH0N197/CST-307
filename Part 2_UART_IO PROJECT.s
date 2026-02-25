@ ============================================================
@ Part 2 - UART Communication via Emulator
@ ARM Cortex-A9 | DE1-SoC | CPUlator
@
@ Reads two characters from JTAG-UART input buffer,
@ compares them numerically, and outputs GREATER, EQUAL, or LESS
@ ============================================================

.equ UART_BASE,   0xFF201000   @ JTAG-UART base address
.equ RVALID_MASK, 0x8000       @ bit 15 = read valid flag

.text
.global _start

_start:
    LDR    R10, =UART_BASE      @ R10 ← UART base address

@ ── Read first character ─────────────────────────────────────
read_char1:
    LDR    R1, [R10]            @ read UART data register
    TST    R1, #RVALID_MASK     @ check bit 15 (RVALID)
    BEQ    read_char1           @ no data yet - keep polling
    AND    R4, R1, #0xFF        @ R4 ← first character
    BL     wait_write_space     @ wait for TX space
    STR    R4, [R10]            @ echo char 1 back to terminal

@ ── Read second character ────────────────────────────────────
read_char2:
    LDR    R1, [R10]            @ read UART data register
    TST    R1, #RVALID_MASK     @ check bit 15 (RVALID)
    BEQ    read_char2           @ no data yet - keep polling
    AND    R5, R1, #0xFF        @ R5 ← second character
    BL     wait_write_space     @ wait for TX space
    STR    R5, [R10]            @ echo char 2 back to terminal

@ ── Print newline ────────────────────────────────────────────
    PUSH   {R4, R5}             @ save R4 and R5 before newline
    MOV    R4, #0x0A            @ newline character
    BL     print_char
    POP    {R4, R5}             @ restore R4 and R5 after newline

@ ── Compare (R4 and R5 are safe here) ───────────────────────
    CMP    R4, R5
    BGT    print_greater
    BEQ    print_equal
    B      print_less

@ ── Print "GREATER" ──────────────────────────────────────────
print_greater:
    ADR    R6, msg_greater
    BL     print_string
    B      done

@ ── Print "EQUAL" ────────────────────────────────────────────
print_equal:
    ADR    R6, msg_equal
    BL     print_string
    B      done

@ ── Print "LESS" ─────────────────────────────────────────────
print_less:
    ADR    R6, msg_less
    BL     print_string
    B      done

@ ── Halt ─────────────────────────────────────────────────────
done:
    B      done

@ =============================================================
@ SUBROUTINE: wait_write_space
@ Polls UART control register until TX buffer has space
@ =============================================================
wait_write_space:
    LDR    R1, [R10, #4]        @ read UART control register
    MOVW   R2, #0x0000          @ \
    MOVT   R2, #0xFFFF          @  R2 ← 0xFFFF0000 (write space mask)
    AND    R1, R1, R2           @ isolate bits 31-16
    CMP    R1, #0               @ any write space?
    BEQ    wait_write_space     @ no - keep polling
    BX     LR                   @ yes - return

@ =============================================================
@ SUBROUTINE: print_char
@ Input: R4 = character to send
@ =============================================================
print_char:
    PUSH   {LR}
    BL     wait_write_space
    STR    R4, [R10]            @ write character to UART
    POP    {PC}

@ =============================================================
@ SUBROUTINE: print_string
@ Input: R6 = pointer to null-terminated string
@ =============================================================
print_string:
    PUSH   {LR}
print_loop:
    LDRB   R4, [R6], #1        @ load byte, advance pointer
    CMP    R4, #0              @ null terminator?
    BEQ    print_done          @ yes - stop
    BL     print_char          @ no - send character
    B      print_loop
print_done:
    POP    {PC}

@ =============================================================
@ Strings inside .text so linker can find them
@ =============================================================
msg_greater:  .asciz "GREATER\n"
msg_equal:    .asciz "EQUAL\n"
msg_less:     .asciz "LESS\n"