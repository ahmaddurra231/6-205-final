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

@cocotb.test()
async def test_pdm(dut):
    """Test the PDM module."""

    # Create a 10 ns clock (100 MHz)
    clock = Clock(dut.clk_in, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the DUT
    dut.rst_in.value = 1
    dut.dc_in.value = 0
    dut.gate_in.value = 0
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    await RisingEdge(dut.clk_in)

    # Test with gate inactive (all zeros)
    cocotb.log.info("Testing with gate_in = 0")
    dut.gate_in.value = 0
    dut.dc_in.value = random.randint(0, 255)  # Random DC input
    await ClockCycles(dut.clk_in, 50)
    assert dut.sig_out.value == 0, "sig_out should be 0 when gate_in is 0"

    # Test with gate active and varying dc_in
    for dc in [0, 64, 128, 192, 255]:
        cocotb.log.info(f"Testing with dc_in = {dc}")
        dut.dc_in.value = dc
        dut.gate_in.value = 0xFF  # All gates active

        sig_out_high_count = 0
        sig_out_low_count = 0

        # Run for multiple clock cycles to check PDM behavior
        for _ in range(1000):
            await RisingEdge(dut.clk_in)
            if dut.sig_out.value == 1:
                sig_out_high_count += 1
            else:
                sig_out_low_count += 1

        # Calculate the duty cycle
        total_cycles = sig_out_high_count + sig_out_low_count
        expected_duty_cycle = dc / 255.0
        measured_duty_cycle = sig_out_high_count / total_cycles

        cocotb.log.info(f"Expected duty cycle: {expected_duty_cycle:.4f}")
        cocotb.log.info(f"Measured duty cycle: {measured_duty_cycle:.4f}")

        # Allow a small tolerance for rounding errors
        tolerance = 0.02
        assert abs(expected_duty_cycle - measured_duty_cycle) <= tolerance, (
            f"Duty cycle mismatch: Expected {expected_duty_cycle:.4f}, "
            f"measured {measured_duty_cycle:.4f}"
        )

    # Test reset functionality
    cocotb.log.info("Testing reset behavior")
    dut.rst_in.value = 1
    await RisingEdge(dut.clk_in)
    dut.rst_in.value = 0
    await RisingEdge(dut.clk_in)

    assert dut.sig_out.value == 0, "sig_out should be 0 after reset"
    assert int(dut.accumulator.value) == 0, "Accumulator should be reset to 0"
def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "pdm.sv"]
    
    build_test_args = ["-Wall"]
    
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="pdm",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="pdm",
        test_module="test_pdm",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()
