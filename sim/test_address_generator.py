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
async def test_address_generator(dut):
    """Test address_generator behavior when one of the last 8 gates is active."""

    # Parameters (must match what is in the DUT)
    NUM_NOTES = 24
    NUM_VOICES = 8
    ADDR_WIDTH = 8
    
    # Start a clock on clk_in
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Initialize inputs
    dut.rst_in.value = 1
    for i in range(NUM_NOTES):
        dut.phase_in[i].value = 0
    dut.gate_in.value = 0

    # Wait a few cycles with reset active
    for _ in range(5):
        await RisingEdge(dut.clk_in)

    # Release reset
    dut.rst_in.value = 0

    # Provide some arbitrary phase_in values
    # Just assign incrementing values for simplicity
    for i in range(NUM_NOTES):
        dut.phase_in[i].value = (i+1)*100  # arbitrary scaling

    # Activate one of the last 8 gates, for example gate_in[20]
    # This falls in the range [16..23], which is the last waveform block.
    gate_vec = 0
    gate_note = 20
    gate_vec |= (1 << gate_note)
    dut.gate_in.value = gate_vec

    # Run for several cycles to let waveform_idx cycle through 3 and back
    # We need at least 4 cycles to get final results to commit.
    for _ in range(20):
        await RisingEdge(dut.clk_in)

    # Now check outputs
    # By now, waveform_idx should have cycled at least once, and
    # the final results should be stable.

    num_voices = int(dut.num_voices.value)
    active_voices = int(dut.active_voices.value)
    active_voices_idx = [int(dut.active_voices_idx[i].value) for i in range(NUM_VOICES)]

    # We expect at least one voice active since we set gate_in[20]
    # That means num_voices > 0 and active_voices[20] = 1
    assert num_voices > 0, f"Expected at least one voice to be active, got num_voices={num_voices}"
    assert (active_voices & (1 << gate_note)) != 0, f"Expected note {gate_note} to be active in active_voices={bin(active_voices)}"

    # Check that one of the active_voices_idx is exactly '20'
    assert gate_note in active_voices_idx, f"Expected note {gate_note} in active_voices_idx, got {active_voices_idx}"

    dut._log.info("Test passed: one of the last 8 gates active and reflected in outputs.")




    


def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "address_generator.sv"]
    
    build_test_args = ["-Wall"]
    
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="address_generator",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="address_generator",
        test_module="test_address_generator",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()

