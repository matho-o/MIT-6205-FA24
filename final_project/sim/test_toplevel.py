import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_a(dut):
    """cocotb test?"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    await ClockCycles(dut.clk_in, 3)
    dut._log.info("Holding reset...")
    dut.btn.value = 15
    await ClockCycles(dut.clk_in, 3)
    dut.btn.value = 0

    await ClockCycles(dut.clk_in, 100000000)

def evt_counter_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "top_level.sv", proj_path / "hdl" / "control_rod.sv", proj_path / "hdl" / "hdmi_clk_wiz.v", proj_path / "hdl" / "seven_segment_controller.sv", proj_path / "hdl" / "video_sig_gen.sv", proj_path / "hdl" / "test_pattern_generator.sv", proj_path / "hdl" / "pong.sv", proj_path / "hdl" / "block_sprite.sv", proj_path / "hdl" / "sim_time_control.sv", proj_path / "hdl" / "point_kinetics_model.sv", proj_path / "hdl" / "precursor_tracker_grp1.sv", proj_path / "hdl" / "precursor_tracker_grp2.sv", proj_path / "hdl" / "precursor_tracker_grp3.sv", proj_path / "hdl" / "precursor_tracker_grp4.sv", proj_path / "hdl" / "precursor_tracker_grp5.sv", proj_path / "hdl" / "precursor_tracker_grp6.sv", proj_path / "hdl" / "tm_choice.sv", proj_path / "hdl" / "tmds_encoder.sv", proj_path / "hdl" / "tmds_serializer.sv", proj_path / "hdl" / "video_sig_gen.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {} #!!! nice figured it out.
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="top_level",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="top_level",
        test_module="test_a",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    evt_counter_runner()