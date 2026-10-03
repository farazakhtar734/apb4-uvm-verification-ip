# DEFECT REPORT: BUG03 - Configuration Register Reset Value Corruption
- **Severity:** Low
- **Target File:** `rtl/apb_peripheral.sv`

## 1. Description
The specification requires `CONFIG` (0x18) to reset to default watermark `5'd8`. The RTL reset block initialized it to `5'd0`.

## 2. Detection
- **Failing Test:** `test_reset`
- **Symptom:** Read of 0x18 after reset yielded `0x0` instead of `0x8`.

## 3. Remediation
Restored reset constant: `reg_config <= 5'd8;`.
