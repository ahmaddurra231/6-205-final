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
async def phase_accumulator_period_test(dut):
    """Test the phase_accumulator module by measuring the period for each note when one gate is active."""

    # Create a clock with a period of 10 ns (100 MHz)
    clock = Clock(dut.clk_in, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the DUT
    dut.rst_in.value = 1
    dut.gate_in.value = 0
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0
    await RisingEdge(dut.clk_in)

    # Define phase increments as per the module
    phase_increments = [
        112404,  # C4
        126156,  # D4
        141526,  # E4
        149664,  # F4
        167772,  # G4
        188743,  # A4
        211688,  # B4
        224003,  # C5
    ]

    # Clock frequency in Hz
    f_clk = 100e6  # 100 MHz

    # For each gate, activate it and measure the period
    for i in range(8):
        # Reset the DUT
        dut.rst_in.value = 1
        dut.gate_in.value = 0
        await ClockCycles(dut.clk_in, 5)
        dut.rst_in.value = 0
        await RisingEdge(dut.clk_in)

        # Activate gate i
        dut.gate_in.value = 1 << i

        cocotb.log.info(f"Testing gate_in[{i}] with phase_increment = {phase_increments[i]}")

        # Wait until phase_value[i] starts increasing
        while int(dut.phase_value[i].value) == 0:
            await RisingEdge(dut.clk_in)

        # Record the time when phase_value[i] crosses zero (overflows)
        initial_phase = int(dut.phase_value[i].value)
        wrap_around_detected = False

        # Wait for the first overflow
        while not wrap_around_detected:
            prev_phase = int(dut.phase_value[i].value)
            await RisingEdge(dut.clk_in)
            current_phase = int(dut.phase_value[i].value)

            # Detect overflow
            if current_phase < prev_phase:
                wrap_around_detected = True
                start_time = cocotb.utils.get_sim_time(units='ns')
                cocotb.log.info(f"First overflow detected for gate_in[{i}] at time {start_time} ns")

        # Wait for the second overflow to measure the period
        wrap_around_detected = False
        while not wrap_around_detected:
            prev_phase = int(dut.phase_value[i].value)
            await RisingEdge(dut.clk_in)
            current_phase = int(dut.phase_value[i].value)

            # Detect overflow
            if current_phase < prev_phase:
                wrap_around_detected = True
                end_time = cocotb.utils.get_sim_time(units='ns')
                cocotb.log.info(f"Second overflow detected for gate_in[{i}] at time {end_time} ns")

        # Calculate measured period
        measured_period_ns = end_time - start_time
        measured_period_s = measured_period_ns * 1e-9  # Convert ns to seconds

        # Calculate expected period
        expected_period_s = (2**32) / (phase_increments[i] * f_clk)

        cocotb.log.info(f"Measured period for gate_in[{i}]: {measured_period_s} s")
        cocotb.log.info(f"Expected period for gate_in[{i}]: {expected_period_s} s")

        # Allow a small tolerance due to simulation timing
        tolerance = expected_period_s * 0.01  # 1% tolerance

        if abs(measured_period_s - expected_period_s) > tolerance:
            cocotb.log.error(
                f"Period mismatch for gate_in[{i}]: Measured = {measured_period_s} s, Expected = {expected_period_s} s"
            )
            raise cocotb.result.TestFailure(
                f"Period mismatch for gate_in[{i}]: Measured = {measured_period_s} s, Expected = {expected_period_s} s"
            )
        else:
            cocotb.log.info(
                f"Period match for gate_in[{i}]: Measured = {measured_period_s} s, Expected = {expected_period_s} s"
            )

        # Deactivate gate i
        dut.gate_in.value = 0
        await ClockCycles(dut.clk_in, 5)



def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "phase_accumulator.sv"]
    
    build_test_args = ["-Wall"]
    
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="phase_accumulator",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="phase_accumulator",
        test_module="test_phase_accumulator",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()
