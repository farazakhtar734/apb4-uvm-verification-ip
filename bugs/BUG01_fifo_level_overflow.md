# DEFECT REPORT: BUG01 - FIFO Level Counter Bit-Width Truncation
- **Severity:** High
- **Target File:** `rtl/fifo.sv`

## 1. Description
The level counter was declared as 4 bits `[$clog2(FIFO_DEPTH)-1:0]` instead of 5 bits. When 16 items are stored, binary `10000` is truncated to `0000`, causing a full FIFO to falsely show as empty.

## 2. Detection
- **Failing Test:** `test_fifo_full`
- **Symptom:** Read of `FIFO_LEVEL` (0x0C) returned 0 instead of 16 after 16 writes.
- **Checker Failure:** `assert (fifo_level == 16)` failed.

## 3. Remediation
Adjusted width to 5 bits: `output logic [$clog2(FIFO_DEPTH):0] level`.
