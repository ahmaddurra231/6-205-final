import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import random
import os
import sys
from pathlib import Path
from cocotb_test.simulator import run  # Use run instead of get_runner

@cocotb.test()
async def test_adsr(dut):
    """ Test the ADSR module behavior. """
    # Generate a 100 MHz clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Initialize reset and start inputs
    dut.rst_in.value = 1
    dut.start.value = 0

    # Wait a few cycles to ensure reset is applied
    for _ in range(5):
        await RisingEdge(dut.clk_in)

    # Deassert reset
    dut.rst_in.value = 0
    await RisingEdge(dut.clk_in)
    await RisingEdge(dut.clk_in)

    # Check that ADSR is idle
    assert dut.adsr_idle.value == 1, "ADSR should be idle after reset"

    # Start the ADSR envelope by pulsing start
    dut.start.value = 1
    await RisingEdge(dut.clk_in)
    dut.start.value = 0

    #hold the value:
    dut.hold.value = 1
    await RisingEdge(dut.clk_in)
    # dut.start.value = 0

    # Check envelope increase after some time
    initial_envelope = dut.envelope.value.integer
    await Timer(1000, units="ns")
    mid_envelope = dut.envelope.value.integer

    if mid_envelope <= initial_envelope:
        raise cocotb.result.TestFailure(
            f"Envelope did not increase during attack phase. Initial: {initial_envelope}, Mid: {mid_envelope}"
        )

    # Wait more time to see if envelope eventually decreases (entering decay)
    await Timer(5_000_000, units="ns")
    dec_envelope = dut.envelope.value.integer

    if dec_envelope >= mid_envelope:
        cocotb.log.warning("Envelope has not decreased; consider lowering envelope times for quicker test.")
    else:
        cocotb.log.info("Envelope has begun to decrease, likely in decay phase.")

    cocotb.log.info("ADSR test completed. Check waveform and logs for expected envelope behavior.")


def adsr_con_runner():
    proj_path = Path(__file__).resolve().parent.parent
    sources = [
        proj_path / "hdl" / "adsr.sv"
    ]

    # Shorter ADSR times for quicker simulation
    iverilog_params = [
        "-Padsr.T_ATTACK_MS=1",
        "-Padsr.T_DECAY_MS=1",
        "-Padsr.T_SUSTAIN_MS=10",
        "-Padsr.T_RELEASE_MS=1"
    ]

    run(
        verilog_sources=[str(src) for src in sources],
        toplevel="adsr",
        module="test_adsr",
        timescale="1ns/1ps",
        waves=True,
        sim="icarus",
        work_dir=str(proj_path / "sim"),
        iverilog_extra_args=["-Wall"] + iverilog_params,
        clean=True  # This forces the build directory to be cleaned before recompile
    )


if __name__ == "__main__":
    adsr_con_runner()
