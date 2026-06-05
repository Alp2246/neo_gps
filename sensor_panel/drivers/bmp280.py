#!/usr/bin/env python3
"""BMP280 basinc / sicaklik — AXI GPIO I2C uzerinden."""

import struct
import time

ADDR_LOW = 0x76
ADDR_HIGH = 0x77
REG_ID = 0xD0
REG_RESET = 0xE0
REG_CTRL_MEAS = 0xF4
REG_CONFIG = 0xF5
REG_PRESS = 0xF7
REG_TEMP = 0xFA
REG_CALIB = 0x88


class BMP280:
    def __init__(self, i2c, addr=None):
        self.i2c = i2c
        self.addr = addr or self._detect()
        if self.i2c.read_reg(self.addr, REG_ID, 1)[0] != 0x58:
            raise RuntimeError(f"BMP280 bulunamadi @ 0x{self.addr:02X}")
        self.i2c.write(self.addr, [REG_RESET, 0xB6])
        time.sleep(0.01)
        self.i2c.write(self.addr, [REG_CONFIG, 0x00])
        self.i2c.write(self.addr, [REG_CTRL_MEAS, 0x27])  # normal, x1
        time.sleep(0.01)
        cal = self.i2c.read_reg(self.addr, REG_CALIB, 24)
        (
            self.t1,
            self.t2,
            self.t3,
            self.p1,
            self.p2,
            self.p3,
            self.p4,
            self.p5,
            self.p6,
            self.p7,
            self.p8,
            self.p9,
        ) = struct.unpack("<HhHhhhhhhh", cal)

    def _detect(self):
        for a in (ADDR_LOW, ADDR_HIGH):
            try:
                if self.i2c.read_reg(a, REG_ID, 1)[0] == 0x58:
                    return a
            except OSError:
                pass
        raise RuntimeError("BMP280 I2C adresi bulunamadi (0x76/0x77)")

    def read(self):
        raw = self.i2c.read_reg(self.addr, REG_PRESS, 6)
        adc_p = (raw[0] << 12) | (raw[1] << 4) | (raw[2] >> 4)
        adc_t = (raw[3] << 12) | (raw[4] << 4) | (raw[5] >> 4)

        var1 = (adc_t / 16384.0 - self.t1 / 1024.0) * self.t2
        var2 = ((adc_t / 131072.0 - self.t1 / 8192.0) ** 2) * self.t3
        t_fine = var1 + var2
        temp_c = t_fine / 5120.0

        var1 = t_fine / 2.0 - 64000.0
        var2 = var1 * var1 * self.p6 / 32768.0
        var2 = var2 + var1 * self.p5 * 2.0
        var2 = var2 / 4.0 + self.p4 * 65536.0
        var1 = (self.p3 * var1 * var1 / 524288.0 + self.p2 * var1) / 524288.0
        var1 = (1.0 + var1 / 32768.0) * self.p1
        if var1 == 0:
            press_pa = 0.0
        else:
            press_pa = 1048576.0 - adc_p
            press_pa = (press_pa - var2 / 4096.0) * 6250.0 / var1
            var1 = self.p9 * press_pa * press_pa / 2147483648.0
            var2 = press_pa * self.p8 / 32768.0
            press_pa = press_pa + (var1 + var2 + self.p7) / 16.0

        press_hpa = press_pa / 100.0
        alt_m = 44330.0 * (1.0 - (press_hpa / 1013.25) ** 0.1903)
        return {
            "temp_c": round(temp_c, 1),
            "press_hpa": round(press_hpa, 1),
            "alt_baro_m": round(alt_m, 1),
        }
