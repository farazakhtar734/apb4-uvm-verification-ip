# DEFECT REPORT: BUG04 - Defective Write-1-to-Clear Interrupt Logic
- **Severity:** Critical
- **Target File:** `rtl/apb_peripheral.sv`

## 1. Description
`IRQ_STATUS` applied bitwise OR (`| pwdata`) instead of bitwise AND with inverted data (`& ~pwdata`), making it impossible for software to clear interrupts.

## 2. Detection
- **Failing Test:** `test_irq`
- **Symptom:** Interrupt pin `irq` remained permanently high after W1C write.

## 3. Remediation
Restored W1C masking: `reg_irq_status <= reg_irq_status & ~pwdata[3:0];`.
