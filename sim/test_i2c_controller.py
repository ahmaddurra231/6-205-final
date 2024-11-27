import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from cocotb.result import TestFailure
from cocotb.binary import BinaryValue
from cocotb.handle import Force, Release


# Constants
I2C_FREQ = 100_000  # 100 kHz I2C frequency
CLK_FREQ = 100_000_000  # 100 MHz clock frequency

# Calculate clock periods
CLK_PERIOD = 1e9 / CLK_FREQ  # in nanoseconds

# I2C Slave Model
class I2CSlave:
    def __init__(self, address, dut):
        self.sda = dut.sda
        self.scl = dut.scl_out
        self.address = address  # 7-bit slave address
        self.dut = dut
        self.sda_tri = None

    async def run(self):
        while True:
            # Wait for START condition (SDA falling while SCL is high)
            await FallingEdge(self.sda)
            if self.scl.value == 1:
                # START condition detected
                await self.receive_address()

    async def receive_address(self):
        # Receive 7 bits of address and 1 bit of R/W
        address = 0
        for _ in range(8):
            await RisingEdge(self.scl)
            await ReadOnly()
            # address = (address << 1) | self.sda.value.integer
            await FallingEdge(self.scl)
        rw = address & 0x1
        address >>= 1  # Get the 7-bit address

        
        # Acknowledge the address
        await self.send_ack()
        await self.receive_data()
        await self.receive_data()
        # if rw == 0:
        #     # Master wants to write data
        #     await self.receive_data()
        # else:
        #     # Master wants to read data
        #     await self.send_data()

    async def receive_data(self):
        # Receive data byte
        data = 0
        for _ in range(8):
            await RisingEdge(self.scl)
            await ReadOnly()
            # data = (data << 1) | self.sda.value.integer
            await FallingEdge(self.scl)
        # Acknowledge the data byte
        await self.send_ack()

        # Store or process the received data as needed

    async def send_data(self):
        # Send data byte to master (e.g., 0x55)
        data = 0xAB  # Example data to send
        for i in range(8):
            bit = (data >> (7 - i)) & 0x1
            await FallingEdge(self.scl)
            self.sda <= bit
            await ReadOnly()
            await RisingEdge(self.scl)
            await ReadOnly()
        # Wait for NACK/ACK from master
        await FallingEdge(self.scl)
        self.sda.release()
        await ReadOnly()
        await RisingEdge(self.scl)
        await ReadOnly()
        ack = self.sda.value.integer
        if ack == 0:
            # Master acknowledged, might send more data
            pass
        else:
            # Master sent NACK, will generate STOP condition
            pass

    async def send_ack(self):
        self.dut.drive_low <= 1
        await ReadOnly()
        await RisingEdge(self.scl)
        await ReadOnly()
        await FallingEdge(self.scl)
        self.dut.drive_low <= 0
        await ReadOnly()

@cocotb.test()
async def test_i2c_controller(dut):
    """Test the I2C Controller module with a simulated I2C Slave device."""
    # Create a clock
    clock = Clock(dut.clk_in, CLK_PERIOD, units='ns')
    cocotb.fork(clock.start())

    # Initialize inputs
    dut.rst_in <= 1
    dut.start <= 0
    dut.drive_low <= 0
    dut.peripheral_addr_in <= 0x5A  # Example slave address
    dut.rw <= 0  # Start with a write operation
    dut.command_byte_in <= 0x0F  # Command byte to write
    dut.data_byte_in <= 0xAA  # Data byte to write

    # Wait for a few clock cycles
    for _ in range(5):
        await RisingEdge(dut.clk_in)

    # Deassert reset
    dut.rst_in <= 0

    # Start the I2C slave model
    slave = I2CSlave(0x5A, dut)
    cocotb.fork(slave.run())

    # Wait for a few clock cycles
    for _ in range(5):
        await RisingEdge(dut.clk_in)

    # Start the I2C transaction
    dut.start <= 1
    await RisingEdge(dut.clk_in)
    dut.start <= 0

    # Wait for the transaction to complete
    # You may need to wait for a specific signal or a timeout
    timeout_cycles = 100000
    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk_in)
        if int(dut.current_state) == 0:  # IDLE corresponds to 0
            break
    else:
        raise TestFailure("Timeout: I2C transaction did not complete")

    # Check for ACK
    if dut.ack_out.value.integer != 0:
        raise TestFailure("ACK was not received by the controller")

    # Read data byte from the slave
    # Prepare for read operation
    dut.rw <= 1  # Set to read
    dut.start <= 1
    await RisingEdge(dut.clk_in)
    dut.start <= 0

    # Wait for the read transaction to complete
    for _ in range(timeout_cycles):
        await RisingEdge(dut.clk_in)
        if int(dut.current_state) == 0:  # IDLE corresponds to 0
            break
    else:
        raise TestFailure("Timeout: I2C read transaction did not complete")

    # Check the received data
    expected_data = 0xAB  # Data sent by the slave model
    received_data = dut.data_byte_out.value.integer
    if received_data != expected_data:
        raise TestFailure(f"Data mismatch: expected 0x{expected_data:02X}, got 0x{received_data:02X}")
    else:
        dut._log.info(f"Received data: 0x{received_data:02X}")

    # Test passed
    dut._log.info("I2C Controller test passed.")



def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "i2c_controller.sv"]
    build_test_args = ["-Wall"]
    
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="i2c_controller",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="i2c_controller",
        test_module="test_i2c_controller",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()
