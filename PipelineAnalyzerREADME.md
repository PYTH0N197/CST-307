# CST-307 | Pipeline Analyzer — Part 2
### ARM Assembly | CPUlator DE1-SoC (ARMv7)

---

## How to Run

1. Go to **https://cpulator.01xz.net/?sys=arm-de1soc**

2. Click **Editor** (bottom-left tab), select all existing code and delete it.

3. Paste the contents of `pipeline_analyzer.s` into the editor.

4. Click **Compile and Load** — confirm no errors appear in the Messages panel.

5. Click **Continue** once to step past the initial breakpoint (this is normal CPUlator behavior).

6. Watch the **JTAG UART** panel on the right for text output and **Seven-segment displays** for the hex counter.

---

## Expected Output

**JTAG UART:** `HELLO ALL. I AM HERE,` printed 20 times  
**HEX0 display:** Cycles `0 → 1 → 2 → ... → 9 → A → b`, wrapping back to `0`, updating once per character sent  
**On completion:** HEX0 clears and the program halts

---

## Files

| File | Description |
|---|---|
| `pipeline_analyzer.s` | ARM assembly source code |
| `README.md` | This file |
