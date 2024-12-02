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

@cocotb.test()
async def test_i2c_controller(dut):
    


def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "i2c_controller.sv"]
    sources += [proj_path / "hdl" / "mpr121_controller.sv"]
    build_test_args = ["-Wall"]
    
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="mpr121_controller",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="mpr121_controller",
        test_module="test_mpr121_controller",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()
