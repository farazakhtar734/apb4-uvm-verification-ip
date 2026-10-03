# Production-Style SystemVerilog/UVM Verification of a Parameterized APB4 Peripheral

[![Regression Status](https://img.shields.io/badge/Regression-10%2F10%20Passed%20(100%25)-brightgreen.svg)](#regression-results)
[![Methodology](https://img.shields.io/badge/Methodology-UVM%201.2%20%7C%20SVA-blue.svg)](#verification-architecture)
[![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Python-orange.svg)](#tools--environment)

An end-to-end digital design verification environment built from scratch for a synthesizable AMBA APB4 slave peripheral with an internal register bank, synchronous FIFO, interrupt logic, and error detection.

---

## 1. Architectural Overview

The Design Under Test (DUT) is a parameterized APB4 slave IP providing:
* **Protocol Interface:** 32-bit AMBA APB4 slave (PADDR, PWDATA, PRDATA, PSEL, PENABLE, PWRITE, PREADY, PSLVERR).
* **Register Bank:** 8 memory-mapped registers (CTRL, STATUS, FIFO_DATA, FIFO_LEVEL, IRQ_ENABLE, IRQ_STATUS, CONFIG, ERROR_STATUS).
* **Internal Storage:** Parameterized synchronous FIFO (16 entries x 32 bits) with first-word fall-through combinational reads and level tracking.
* **Interrupt Engine:** Level-sensitive interrupt generation (irq) triggered by FIFO threshold, full/empty transitions, and error events.
* **Fault Handling:** Immediate PSLVERR assertion on unaligned transfers, invalid address spaces, FIFO overflow, and FIFO underflow.

---

## 2. Verification Architecture

The verification suite incorporates both an industrial IEEE 1800.2 UVM 1.2 architecture and an automated Python Regression Framework:
* **Driver (apb_driver.sv):** Translates UVM sequence items into cycle-accurate APB4 Setup and Access phases.
* **Monitor (apb_monitor.sv):** Passively samples bus cycles and broadcasts transactions via uvm_analysis_port.
* **Scoreboard (apb_scoreboard.sv):** Implements an independent golden reference model utilizing dynamic queues and associative arrays to verify data ordering and response flags.
* **Assertions (apb_assertions.sv):** Concurrent SystemVerilog Assertions (SVA) verifying PENABLE rise timing, signal stability during wait states, and FIFO depth invariants.

---

## 3. Regression Results

All 10 directed tests execute through the Python automation framework:

* TOTAL TESTS RUN: 10
* PASSED: 10
* FAILED: 0
* PASS RATE: 100.0%

---

## 4. Defect Injection & Root Cause Analysis

To validate checker sensitivity, 5 realistic defects were injected into the RTL and verified:
* **BUG01:** FIFO level counter 4-bit truncation causing rollover at depth 16 (Caught by test_fifo_full).
* **BUG02:** Premature full flag assertion at 15 items (Caught by test_fifo_full / Scoreboard).
* **BUG03:** Corrupted CONFIG register reset constant (Caught by test_reset).
* **BUG04:** Write-1-to-Set bug on IRQ_STATUS preventing interrupt deassertion (Caught by test_irq).
* **BUG05:** Omission of address alignment check PADDR[1:0] == 2'b00 (Caught by test_unaligned_access).

---

## 5. Quick Start (Reproduce Locally)

```bash
# 1. Run Complete 10-Test Regression (100% Pass)
python3 scripts/run_regression.py

# 2. Live Bug Injection Demo (Inject Bug 2)
python3 scripts/inject_bug.py 2
python3 scripts/run_regression.py  # Observe test_fifo_full FAIL

# 3. Restore Clean Reference State
python3 scripts/inject_bug.py clean
python3 scripts/run_regression.py  # Observe 100% PASS
```
