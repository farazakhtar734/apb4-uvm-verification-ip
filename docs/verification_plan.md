# Verification Plan & Traceability Matrix

## 1. Scope & Objective
Verify standard AMBA APB4 protocol compliance, register accessibility, FIFO integrity under boundary conditions, interrupt assertions, and error handling.

## 2. Requirement Traceability Matrix

| Req ID | Target Feature | Stimulus Description | Expected Response | Checker / Assertion | Test Name | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **REQ_01** | Power-On Reset | Deassert `PRESETn` | Default registers restored; FIFO empty | Readback comparison | `test_reset` | PASS |
| **REQ_02** | Register RW | Write masks to `CTRL`, `CONFIG`, `IRQ_EN` | Exact readback matching written masks | Scoreboard shadow mirror | `test_register_write` | PASS |
| **REQ_03** | Read-Only Protection | Write `0xFF` to `STATUS` | Write ignored; status reflects real state | Read comparison | `test_register_read` | PASS |
| **REQ_04** | FIFO Data Ordering | Push single word then pop | Read data matches written word exactly | Direct compare | `test_fifo_basic` | PASS |
| **REQ_05** | FIFO Full Boundary | Write 16 words consecutively | `FIFO_LEVEL=16`, `STATUS[1]=1` (Full) | Level and status check | `test_fifo_full` | PASS |
| **REQ_06** | FIFO Empty Boundary | Drain all items | `FIFO_LEVEL=0`, `STATUS[0]=1` (Empty) | Level and status check | `test_fifo_empty` | PASS |
| **REQ_07** | FIFO Overflow Protection | 17th write into full FIFO | `PSLVERR=1`, `ERROR_STATUS[0]=1` | Error bit check | `test_fifo_overflow` | PASS |
| **REQ_08** | FIFO Underflow Protection | Pop from empty FIFO | `PSLVERR=1`, `ERROR_STATUS[1]=1` | Error bit check | `test_fifo_underflow` | PASS |
| **REQ_09** | Interrupt Generation | Reach watermark threshold | Hardware `irq` pin asserts high | Strobe check | `test_irq` | PASS |
| **REQ_10** | Interrupt W1C Clearing | Service FIFO, write `1` to `0x14` | Hardware `irq` pin deasserts to `0` | Active-low check | `test_irq` | PASS |
| **REQ_11** | Address Alignment Check | Access addresses ending in `1, 2, 3` | `PSLVERR=1`, transfer rejected | Protocol assertion | `test_unaligned_access` | PASS |
