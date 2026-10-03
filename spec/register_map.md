# APB4 Peripheral Register Map Specification

**Base Address:** `0x0000_0000`  
**Bus Protocol:** AMBA APB4 (32-bit data, word-aligned 32-bit address)  
**Access Rule:** Unaligned addresses (`PADDR[1:0] != 2'b00`) assert `PSLVERR`.

| Offset | Name | Access | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| **`0x00`** | `CTRL` | RW | `32'h0000_0000` | Bit [0]: Peripheral Enable<br>Bit [1]: FIFO Clear (self-clearing strobe)<br>Bit [2]: IRQ Global Enable |
| **`0x04`** | `STATUS` | RO | `32'h0000_0001` | Bit [0]: FIFO Empty<br>Bit [1]: FIFO Full<br>Bit [2]: Watermark Hit<br>Bit [3]: Error Active Flag |
| **`0x08`** | `FIFO_DATA` | WO / RO | `32'h0000_0000` | Write: Push 32-bit word into FIFO.<br>Read: Pop 32-bit word from FIFO. |
| **`0x0C`** | `FIFO_LEVEL` | RO | `32'h0000_0000` | Bits [4:0]: Current FIFO occupancy count (0 to 16). |
| **`0x10`** | `IRQ_ENABLE` | RW | `32'h0000_0000` | Interrupt Mask Register.<br>Bit [0]: Full IRQ En<br>Bit [1]: Empty IRQ En<br>Bit [2]: Watermark IRQ En<br>Bit [3]: Error IRQ En |
| **`0x14`** | `IRQ_STATUS` | W1C | `32'h0000_0000` | Write-1-to-Clear event flags.<br>Bit [0]: Full Fired<br>Bit [1]: Empty Fired<br>Bit [2]: Watermark Hit<br>Bit [3]: Error Fired |
| **`0x18`** | `CONFIG` | RW | `32'h0000_0008` | Bits [4:0]: Programmable FIFO watermark threshold (default = 8). |
| **`0x1C`** | `ERROR_STATUS` | W1C | `32'h0000_0000` | Bit [0]: Write to Full FIFO (Overflow)<br>Bit [1]: Read from Empty FIFO (Underflow)<br>Bit [2]: Unaligned/Unmapped Address Access |
