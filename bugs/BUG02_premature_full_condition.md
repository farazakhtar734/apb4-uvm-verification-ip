# DEFECT REPORT: BUG02 - Premature FIFO Full Assertion
- **Severity:** Medium
- **Target File:** `rtl/fifo.sv`

## 1. Description
The comparator evaluated `full = (level == FIFO_DEPTH - 1);`, prematurely asserting full at 15 items instead of 16.

## 2. Detection
- **Failing Test:** `test_fifo_full`
- **Symptom:** 16th write rejected with unexpected `PSLVERR = 1`.
- **Scoreboard Failure:** Expected PSLVERR=0, Got PSLVERR=1.

## 3. Remediation
Fixed boundary condition: `assign full = (level == FIFO_DEPTH);`.
