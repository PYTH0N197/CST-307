@ ============================================================
@ CST-307: Recursive Fibonacci Sequence in ARM Assembly
@ Platform: CPUlator DE1-SoC (ARMv7)
@ ============================================================
@ Purpose:
@   This program computes and stores the Fibonacci sequence
@   F(0) through F(9) using a recursive procedure. Each value
@   is placed into consecutive memory locations beginning at
@   the label "results".
@
@ Fibonacci Definition:
@   F(n) = 1           if n < 2
@   F(n) = F(n-1) + F(n-2)  otherwise
@
@ Register Usage (Main):
@   r0  - argument to fib / return value from fib
@   r4  - loop counter i (callee-saved)
@   r5  - upper bound n (callee-saved)
@   r6  - pointer into results array (callee-saved)
@   sp  - stack pointer
@   lr  - link register (return address)
@
@ Register Usage (fib procedure):
@   r0  - argument n / return value
@   r4  - saved copy of n  (callee-saved, preserved on stack)
@   r5  - result of fib(n-1) (callee-saved, preserved on stack)
@   lr  - return address (preserved on stack via push/pop to pc)
@
@ Approach: Saved registers (r4, r5) are used instead of
@ temporary registers (r1, r2) because the recursive calls
@ would overwrite temporaries. Saved registers are preserved
@ across calls via the stack, guaranteeing correctness.
@ ============================================================

.text
.global _start

@ ------------------------------------------------------------
@ Main Program
@ ------------------------------------------------------------
_start:
    @ Initialize stack pointer to top of a safe region in SDRAM.
    @ CPUlator DE1-SoC maps SDRAM at 0x00000000 – 0x03FFFFFF.
    @ We place the stack well above our code/data to avoid
    @ "unallocated stack space" warnings from CPUlator.
    ldr     sp, =0x04000000      @ SP = top of 64 MB SDRAM

    mov     r4, #0               @ i = 0 (loop counter)
    mov     r5, #9               @ n = 9 (compute F(0)..F(9))
    ldr     r6, =results         @ r6 = base address of results array

loop:
    cmp     r4, r5               @ Compare i with n
    bgt     done                 @ If i > n, exit loop

    mov     r0, r4               @ r0 = i (argument for fib)
    bl      fib                  @ Call fib(i); result in r0

    str     r0, [r6]             @ Store result at results[i]
    add     r6, r6, #4           @ Advance pointer to next word
    add     r4, r4, #1           @ i = i + 1
    b       loop                 @ Repeat

done:
    b       done                 @ Halt (infinite loop)

@ ------------------------------------------------------------
@ Recursive Fibonacci Procedure
@ ------------------------------------------------------------
@ Input:  r0 = n
@ Output: r0 = F(n)
@ Modifies: r4, r5 (saved/restored via stack)
@ ------------------------------------------------------------
fib:
    @ --- Base case optimization ---
    @ About half of all recursive calls receive n = 0 or n = 1.
    @ For these base cases we skip the full stack frame
    @ (push/pop of r4, r5, lr) and return immediately.
    @ This saves 2 memory writes + 2 memory reads per base call,
    @ significantly reducing stack traffic.
    cmp     r0, #2               @ Is n < 2?
    blt     fib_base             @ Yes -> return 1 immediately

    @ --- Recursive case: need full stack frame ---
    push    {r4, r5, lr}         @ Save r4, r5 (callee-saved) and lr

    mov     r4, r0               @ r4 = n (preserve n across calls)

    sub     r0, r4, #1           @ r0 = n - 1
    bl      fib                  @ r0 = fib(n-1)
    mov     r5, r0               @ r5 = fib(n-1) (save result)

    sub     r0, r4, #2           @ r0 = n - 2
    bl      fib                  @ r0 = fib(n-2)

    add     r0, r5, r0           @ r0 = fib(n-1) + fib(n-2)

    pop     {r4, r5, pc}         @ Restore r4, r5; pop lr into pc (return)

fib_base:
    mov     r0, #1               @ F(0) = 1, F(1) = 1
    bx      lr                   @ Return to caller (no stack frame used)

@ ------------------------------------------------------------
@ Data Section
@ ------------------------------------------------------------
.data
results:
    .space  40                   @ 10 words (F(0)..F(9)), each 4 bytes