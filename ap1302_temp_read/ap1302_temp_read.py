#!/usr/bin/python3
import subprocess
import time


DMA_SRC = 0x60a0
DMA_DST = 0x60a4
DMA_SIZE = 0x60a8
DMA_CTRL = 0x60ac


def raw_read_dump(addr, len):
    """Read ap1302 registers

    The sysfs interface of the ap1302 driver has a 'dump' function but it writes the hexa dump
    into the kernel log via printk() calls. So we first execute the dump and then try to find
    the response in the 'dmesg' output.

    Args:
        addr (int): address to start dump at
        len (int): no. of bytes to dump
    """
    with open("/sys/devices/platform/soc/40013000.i2c/i2c-1/1-003d/dump",
              "w") as f:
        f.write("0x%04x %i" % (addr, len))

    resp = None
    output = subprocess.run(["dmesg"], capture_output=True, text=True).stdout.splitlines()
    for line in output:
        line_start = line.find(" **** %04x:  " % (addr,))
        if line_start >= 0:
            resp = line[line_start+13:]
            # print(resp)
    return resp


def raw_read_uint16(addr):
    """Read 16-bit ap1302 register value at given address
    """
    resp = raw_read_dump(addr, 2)
    reg = None
    if resp:
        reg = 0
        for nums in resp.split():
            reg = (reg << 8) + int(nums, 16)
        # print("reg: 0x%04x" % reg)
    return reg


def raw_read_uint32(addr):
    """Read 32-bit ap1302 register value at given address
    """
    resp = raw_read_dump(addr, 4)
    reg = None
    if resp:
        reg = 0
        for nums in resp.split():
            reg = (reg << 8) + int(nums, 16)
        # print("reg: 0x%08x" % reg)
    return reg


def raw_read_int16(addr):
    reg = raw_read_uint16(addr)
    if reg > 32767:
        reg -= 65536
    return reg


def raw_write_reg16(addr, val):
    """Write 16-bit ap1302 register through the sysfs interface

    Args:
        addr (int): address of register
        val (int): register value
    """
    with open("/sys/devices/platform/soc/40013000.i2c/i2c-1/1-003d/write_reg16",
              "w") as f:
        f.write("0x%04x 0x%04x" % (addr, val))


def raw_write_reg32(addr, val):
    """Write 32-bit ap1302 register through the sysfs interface

    Args:
        addr (int): address of register
        val (int): register value
    """
    with open("/sys/devices/platform/soc/40013000.i2c/i2c-1/1-003d/write_reg32",
              "w") as f:
        f.write("0x%04x 0x%08x" % (addr, val))


def dma_wait_ready():
    """Wait for ap1302 DMA to be ready
    """
    while True:
        if not (raw_read_uint16(DMA_CTRL) & 0x07):
            break


def sensor_read_uint16(addr):
    """Read sensor register using ap1302 DMA

    Args:
        addr (int): address of sensor register
    """
    dma_wait_ready()
    i2c_addr = raw_read_uint16(0x00d2)

    raw_write_reg32(DMA_SRC, (i2c_addr << 16) + addr)
    raw_write_reg32(DMA_DST, DMA_DST)
    raw_write_reg32(DMA_SIZE, 2)

    # start the write
    raw_write_reg16(DMA_CTRL, 0x032)
    dma_wait_ready()

    return raw_read_uint16(DMA_DST)


def sensor_write_uint16(addr, val):
    """Write sensor register using ap1302 DMA

    Args:
        addr (int): address of sensor register
        val (int): 16-bit value to be written
    """
    dma_wait_ready()
    i2c_addr = raw_read_uint16(0x00d2)

    raw_write_reg32(DMA_SRC, val)
    raw_write_reg32(DMA_DST, (i2c_addr << 16) + addr)
    raw_write_reg32(DMA_SIZE, 2)

    # start the write
    raw_write_reg16(DMA_CTRL, 0x0301)
    dma_wait_ready()


if __name__ == '__main__':
    chip_id = sensor_read_uint16(0x3000)
    print(f'Sensor_ID: {hex(chip_id)}')

    # power on tempsens
    sensor_write_uint16(0x3126, 0x1)

    # clear tempsens_data
    sensor_write_uint16(0x3126, 0x21)

    # start temperature conversion and read tempsens_data
    sensor_write_uint16(0x3126, 0x11)
    time.sleep(0.5)
    tempsens_data = sensor_read_uint16(0x3124)

    # power down temperature sensor
    sensor_write_uint16(0x3126, 0)

    ref60 = sensor_read_uint16(0x3128)
    unit = 1.443137
    offset = ref60 - unit * 60
    temperature = (tempsens_data - offset)/unit

    print(f'temperature: {temperature}')
