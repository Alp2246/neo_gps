#!/usr/bin/env python3
"""
MAX7219 8x8 LED matris — Linux sysfs GPIO bit-bang.

Varsayilan PYNQ-Z2 RPi header (GPS/I2C pinleri haric):
  DIN -> Pin 11 (BCM 17)
  CLK -> Pin 13 (BCM 27)
  CS  -> Pin 15 (BCM 22)
  VCC -> 3.3V Pin 1, GND Pin 6

Modul 5V etiketli olsa da cogu 3.3V logic ile calisir.
"""

import time
from pathlib import Path

# 8x8 rakam fontu (0-9), her satir 1 byte
DIGITS = {
    0: (0x3C, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3C),
    1: (0x08, 0x18, 0x08, 0x08, 0x08, 0x08, 0x08, 0x1C),
    2: (0x3C, 0x42, 0x02, 0x04, 0x08, 0x10, 0x20, 0x7E),
    3: (0x3C, 0x42, 0x02, 0x1C, 0x02, 0x02, 0x42, 0x3C),
    4: (0x04, 0x0C, 0x14, 0x24, 0x7E, 0x04, 0x04, 0x04),
    5: (0x7E, 0x40, 0x40, 0x7C, 0x02, 0x02, 0x42, 0x3C),
    6: (0x1C, 0x20, 0x40, 0x7C, 0x42, 0x42, 0x42, 0x3C),
    7: (0x7E, 0x02, 0x04, 0x08, 0x10, 0x10, 0x10, 0x10),
    8: (0x3C, 0x42, 0x42, 0x3C, 0x42, 0x42, 0x42, 0x3C),
    9: (0x3C, 0x42, 0x42, 0x42, 0x3E, 0x02, 0x04, 0x38),
}

NO_FIX = (0x18, 0x24, 0x24, 0x18, 0x00, 0x3C, 0x42, 0x42)  # kucuk X + F benzeri


class SysfsPin:
    def __init__(self, bcm: int):
        self.bcm = bcm
        self.path = Path(f"/sys/class/gpio/gpio{bcm}")
        if not self.path.exists():
            Path("/sys/class/gpio/export").write_text(str(bcm))
            time.sleep(0.05)
        (self.path / "direction").write_text("out")

    def set(self, val: bool):
        (self.path / "value").write_text("1" if val else "0")


class MAX7219:
    def __init__(self, din=17, clk=27, cs=22, intensity=3):
        self.din = SysfsPin(din)
        self.clk = SysfsPin(clk)
        self.cs = SysfsPin(cs)
        self._init_hw(intensity)

    def _pulse_clk(self):
        self.clk.set(True)
        self.clk.set(False)

    def _shift16(self, val):
        for bit in range(15, -1, -1):
            self.din.set(bool(val & (1 << bit)))
            self._pulse_clk()

    def _write(self, reg, data):
        self.cs.set(False)
        self._shift16((reg << 8) | data)
        self.cs.set(True)

    def _init_hw(self, intensity):
        for reg, data in (
            (0x0F, 0x00),
            (0x0C, 0x01),
            (0x0B, 0x00),
            (0x09, 0x00),
            (0x0A, intensity),
            (0x0F, 0x01),
        ):
            self._write(reg, data)

    def show_rows(self, rows):
        for i, row in enumerate(rows[:8]):
            self._write(0x01 + i, row)

    def show_digit(self, n):
        n = max(0, min(9, int(n)))
        self.show_rows(DIGITS[n])

    def show_sats(self, count, fix: bool):
        if not fix:
            self.show_rows(NO_FIX)
        elif count > 9:
            self.show_digit(9)
        else:
            self.show_digit(count)

    def clear(self):
        self.show_rows((0,) * 8)
