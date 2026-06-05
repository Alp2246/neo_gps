"""FPGA bitstream yukleme — max7219_led overlay."""

import shutil
import time
from pathlib import Path

FW = Path("/sys/class/fpga_manager/fpga0/firmware")
STATE = Path("/sys/class/fpga_manager/fpga0/state")
LIB = Path("/lib/firmware")


def load(bin_path: Path, fw_name: str = "max7219_led.bin", force: bool = True) -> None:
    if not bin_path.is_file():
        raise FileNotFoundError(bin_path)
    if not force and STATE.read_text().strip() == "operating":
        return
    LIB.mkdir(parents=True, exist_ok=True)
    shutil.copy2(bin_path, LIB / fw_name)
    FW.write_text(fw_name)
    t0 = time.time()
    while time.time() - t0 < 30:
        if STATE.read_text().strip() == "operating":
            time.sleep(0.5)
            return
        time.sleep(0.2)
    raise RuntimeError(f"FPGA state={STATE.read_text().strip()!r}")
