#!/usr/bin/env python3
"""MAX7219 surucu — AXI GPIO MMIO (FPGA bit-bang)."""

import mmap
import os
import struct
import time

GPIO_DATA = 0x0
DEFAULT_BASE = 0x41200000
MAP_SIZE = 0x1000

DIN = 0x1
CLK = 0x2
CS = 0x4

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

HEART = (0x00, 0x66, 0xFF, 0xFF, 0xFF, 0x7E, 0x3C, 0x18)
SMILE = (0x00, 0x66, 0x3C, 0x00, 0x42, 0x81, 0x81, 0x42)


class Max7219:
    def __init__(self, base=DEFAULT_BASE, intensity=4):
        self._fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
        self._mm = mmap.mmap(
            self._fd, MAP_SIZE, mmap.MAP_SHARED,
            mmap.PROT_READ | mmap.PROT_WRITE, offset=base,
        )
        self._shadow = CS | CLK | DIN
        self._write_gpio()
        self._init_chip(intensity)

    def _write_gpio(self):
        self._mm.seek(GPIO_DATA)
        self._mm.write(struct.pack("<I", self._shadow))

    def _set(self, mask, val):
        if val:
            self._shadow |= mask
        else:
            self._shadow &= ~mask
        self._write_gpio()

    def _pulse_clk(self):
        self._set(CLK, 1)
        self._set(CLK, 0)

    def _shift16(self, word):
        for bit in range(15, -1, -1):
            self._set(DIN, bool(word & (1 << bit)))
            self._pulse_clk()

    def _write_reg(self, reg, data):
        self._set(CS, 0)
        self._shift16((reg << 8) | data)
        self._set(CS, 1)

    def _init_chip(self, intensity):
        for reg, data in (
            (0x0F, 0x00), (0x0C, 0x01), (0x0B, 0x00),
            (0x09, 0x00), (0x0A, intensity), (0x0F, 0x01),
        ):
            self._write_reg(reg, data)

    def show_rows(self, rows):
        for i, row in enumerate(rows[:8]):
            self._write_reg(0x01 + i, row)

    def show_digit(self, n):
        self.show_rows(DIGITS[max(0, min(9, int(n)))])

    def clear(self):
        self.show_rows((0,) * 8)

    def close(self):
        self._mm.close()
        os.close(self._fd)
