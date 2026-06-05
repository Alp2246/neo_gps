"""FPGA bitstream yukleme — sensor panel (gps_i2c combo overlay)."""

import shutil
import time
from pathlib import Path

FPGA_MANAGER_FW = Path("/sys/class/fpga_manager/fpga0/firmware")
FPGA_MANAGER_STATE = Path("/sys/class/fpga_manager/fpga0/state")
FIRMWARE_DIR = Path("/lib/firmware")


def load_overlay(bin_path: Path, fw_name: str = "gps_i2c.bin", force: bool = True) -> None:
    if not bin_path.is_file():
        raise FileNotFoundError(f"Bitstream yok: {bin_path}")

    state = FPGA_MANAGER_STATE.read_text().strip() if FPGA_MANAGER_STATE.exists() else ""
    if state == "operating" and not force:
        print("[INFO] FPGA zaten operating.")
        return

    FIRMWARE_DIR.mkdir(parents=True, exist_ok=True)
    target = FIRMWARE_DIR / fw_name
    shutil.copy2(bin_path, target)
    print(f"[INFO] Bitstream: {bin_path.name} -> {target}")
    FPGA_MANAGER_FW.write_text(fw_name)

    deadline = time.time() + 30.0
    last = ""
    while time.time() < deadline:
        state = FPGA_MANAGER_STATE.read_text().strip()
        if state != last:
            print(f"[INFO] fpga_manager: {state}")
            last = state
        if state == "operating":
            time.sleep(1.0)
            return
        time.sleep(0.2)
    raise RuntimeError(f"FPGA yuklenemedi (state={last!r})")
