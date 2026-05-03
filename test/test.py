# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge

@cocotb.test()
async def test_centre_point(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset: btn3=0 holds reset, btn3=1 releases
    dut.ui_in.value = 0x00  # btn3 low = in reset
    await ClockCycles(dut.clk, 4)
    dut.ui_in.value = 0x80  # btn3 high = release reset
    await ClockCycles(dut.clk, 2)

    # Load x=0.5 (fx=0x1) via btn1 — on falling edges
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0xA1  # btn3=1 (keep out of reset), btn1=1, data=0x1
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0x81  # btn3=1, btn1=0, data=0x1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0x80  # btn3=1, data=0x0

    # Load y=-0.25 (fy=0x0) via btn0 — on falling edges
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0x90  # btn3=1, btn0=1, data=0x0
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0x80  # btn3=1, btn0=0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)

    # Trigger inference (btn2 pulse)
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0xC0  # btn3=1, btn2=1
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0x80  # btn3=1, btn2=0
    await RisingEdge(dut.clk)

    # Wait for valid (uo_out[0])
    while not (int(dut.uo_out.value) & 0x1):
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)  # let inside_circle settle

    # Check result — uo_out[1] is inside_circle
    inside_circle = (int(dut.uo_out.value) >> 1) & 0x1
    assert inside_circle == 1, f"Expected inside=1, got {inside_circle}"