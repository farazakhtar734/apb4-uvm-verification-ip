import subprocess
import os
import sys
import random
import time

TEST_LIST = [
    "test_reset",
    "test_register_write",
    "test_register_read",
    "test_fifo_basic",
    "test_fifo_full",
    "test_fifo_empty",
    "test_fifo_overflow",
    "test_fifo_underflow",
    "test_irq",
    "test_unaligned_access"
]

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SIM_DIR = os.path.join(ROOT_DIR, "sim")
LOG_DIR = os.path.join(ROOT_DIR, "results", "logs")
SUMMARY_FILE = os.path.join(ROOT_DIR, "results", "regression_summary.txt")

os.makedirs(SIM_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

def compile_sim():
    cmd = [
        "iverilog", "-g2012",
        "-o", os.path.join(SIM_DIR, "tb_regression.vvp"),
        os.path.join(ROOT_DIR, "tb", "apb_if.sv"),
        os.path.join(ROOT_DIR, "rtl", "fifo.sv"),
        os.path.join(ROOT_DIR, "rtl", "apb_peripheral.sv"),
        os.path.join(ROOT_DIR, "tb", "tb_regression.sv")
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        print("[REGRESSION FATAL] Compilation Failed:")
        print(res.stderr)
        sys.exit(1)
    print("[REGRESSION] Compilation successful.")

def run_test(test_name, seed):
    log_file = os.path.join(LOG_DIR, f"{test_name}.log")
    cmd = [
        "vvp", os.path.join(SIM_DIR, "tb_regression.vvp"),
        f"+TESTNAME={test_name}",
        f"+SEED={seed}"
    ]
    with open(log_file, "w") as f:
        res = subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT, text=True)

    passed = False
    with open(log_file, "r") as f:
        content = f.read()
        if f"[REGRESSION STATUS] TESTNAME={test_name} : PASSED" in content:
            passed = True

    return passed, log_file

def main():
    start_time = time.time()
    compile_sim()

    master_seed = int(time.time()) & 0xFFFF
    random.seed(master_seed)

    results = []
    print("\n" + "="*50)
    print(f"STARTING VERIFICATION REGRESSION (BASE SEED: {master_seed})")
    print("="*50)

    for test in TEST_LIST:
        test_seed = random.randint(1000, 99999)
        passed, log_path = run_test(test, test_seed)
        status = "PASSED" if passed else "FAILED"
        results.append((test, status, test_seed, log_path))
        print(f"[{status:6s}] {test:<25} (Seed: {test_seed})")

    passed_count = sum(1 for _, status, _, _ in results if status == "PASSED")
    total_count = len(results)
    pass_rate = (passed_count / total_count) * 100.0
    elapsed = time.time() - start_time

    summary_content = []
    summary_content.append("="*50)
    summary_content.append("VERIFICATION REGRESSION SUMMARY REPORT")
    summary_content.append("="*50)
    summary_content.append(f"TOTAL TESTS RUN : {total_count}")
    summary_content.append(f"PASSED          : {passed_count}")
    summary_content.append(f"FAILED          : {total_count - passed_count}")
    summary_content.append(f"PASS RATE       : {pass_rate:.1f}%")
    summary_content.append(f"EXECUTION TIME  : {elapsed:.2f} seconds")
    summary_content.append(f"MASTER SEED     : {master_seed}")
    summary_content.append("="*50)
    summary_content.append(f"{'TEST NAME':<25} {'STATUS':<10} {'SEED':<10}")
    summary_content.append("-"*50)
    for test, status, test_seed, _ in results:
        summary_content.append(f"{test:<25} {status:<10} {test_seed:<10}")
    summary_content.append("="*50)

    report_str = "\n".join(summary_content)
    print("\n" + report_str)

    with open(SUMMARY_FILE, "w") as f:
        f.write(report_str + "\n")

    print(f"\n[REGRESSION] Summary written to: {SUMMARY_FILE}")

    if passed_count != total_count:
        sys.exit(1)

if __name__ == "__main__":
    main()
