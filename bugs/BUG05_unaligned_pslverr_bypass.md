# DEFECT REPORT: BUG05 - Unaligned Address Error Detection Bypass
- **Severity:** High
- **Target File:** `rtl/apb_peripheral.sv`

## 1. Description
Address decoder omitted `addr_align == 2'b00`, allowing unaligned addresses (0x01, 0x02, 0x07) to complete without error.

## 2. Detection
- **Failing Test:** `test_unaligned_access`
- **Symptom:** Unaligned writes completed with `PSLVERR = 0`.
- **Checker Failure:** Expected PSLVERR=1, Got 0.

## 3. Remediation
Enforced alignment check: `assign addr_valid = (addr_align == 2'b00) && (reg_addr <= ADDR_ERROR_STATUS);`.
