import sys
import os
import shutil

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FIFO_RTL = os.path.join(ROOT_DIR, "rtl", "fifo.sv")
APB_RTL  = os.path.join(ROOT_DIR, "rtl", "apb_peripheral.sv")

BACKUP_FIFO = FIFO_RTL + ".orig"
BACKUP_APB  = APB_RTL  + ".orig"

def ensure_backups():
    if not os.path.exists(BACKUP_FIFO):
        shutil.copyfile(FIFO_RTL, BACKUP_FIFO)
    if not os.path.exists(BACKUP_APB):
        shutil.copyfile(APB_RTL, BACKUP_APB)

def restore_clean():
    ensure_backups()
    shutil.copyfile(BACKUP_FIFO, FIFO_RTL)
    shutil.copyfile(BACKUP_APB, APB_RTL)
    print("[INJECTOR] Restored RTL to clean reference state.")

def inject_bug(bug_id):
    restore_clean()
    if bug_id == 1:
        with open(FIFO_RTL, "r") as f:
            content = f.read()
        content = content.replace("output logic [$clog2(FIFO_DEPTH):0] level,",
                                  "output logic [$clog2(FIFO_DEPTH)-1:0] level,")
        with open(FIFO_RTL, "w") as f:
            f.write(content)
        print("[INJECTOR] INJECTED BUG01: FIFO level counter truncated to 4 bits.")

    elif bug_id == 2:
        with open(FIFO_RTL, "r") as f:
            content = f.read()
        content = content.replace("assign full  = (level == FIFO_DEPTH);",
                                  "assign full  = (level == FIFO_DEPTH - 1);")
        with open(FIFO_RTL, "w") as f:
            f.write(content)
        print("[INJECTOR] INJECTED BUG02: Premature full flag asserted at 15 words.")

    elif bug_id == 3:
        with open(APB_RTL, "r") as f:
            content = f.read()
        content = content.replace("reg_config       <= 5'd8;",
                                  "reg_config       <= 5'd0;")
        with open(APB_RTL, "w") as f:
            f.write(content)
        print("[INJECTOR] INJECTED BUG03: CONFIG register reset value corrupted to 0.")

    elif bug_id == 4:
        with open(APB_RTL, "r") as f:
            content = f.read()
        content = content.replace("ADDR_IRQ_STATUS:   reg_irq_status   <= reg_irq_status & ~pwdata[3:0];",
                                  "ADDR_IRQ_STATUS:   reg_irq_status   <= reg_irq_status | pwdata[3:0];")
        with open(APB_RTL, "w") as f:
            f.write(content)
        print("[INJECTOR] INJECTED BUG04: W1C logic replaced with W1S (cannot clear IRQ).")

    elif bug_id == 5:
        with open(APB_RTL, "r") as f:
            content = f.read()
        content = content.replace("assign addr_valid = (addr_align == 2'b00) && (reg_addr <= ADDR_ERROR_STATUS);",
                                  "assign addr_valid = (reg_addr <= ADDR_ERROR_STATUS);")
        with open(APB_RTL, "w") as f:
            f.write(content)
        print("[INJECTOR] INJECTED BUG05: Address alignment check disabled.")

    else:
        print(f"[INJECTOR ERROR] Unknown bug ID: {bug_id}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/inject_bug.py [1|2|3|4|5|clean]")
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "clean":
        restore_clean()
    else:
        try:
            bid = int(cmd)
            inject_bug(bid)
        except ValueError:
            print("Invalid argument. Use 1-5 or 'clean'")
