/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_sienahlee (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Internal signal declarations
  wire valid, inside_circle;

  // Route outputs: valid -> uo_out[0], inside_circle -> uo_out[1], rest unused
  assign uo_out  = {6'b0, inside_circle, valid};

  // Bidir pins unused — all set to input mode, outputs driven to 0
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // Tie off unused inputs to prevent warnings
  wire _unused = &{ena, rst_n, uio_in, 1'b0};

  tiny_nn dut (
    .clk          (clk),
    .in           (ui_in[3:0]),   // lower 4 bits of ui_in
    .btn          (ui_in[7:4]),   // upper 4 bits of ui_in (per your pinout)
    .valid        (valid),
    .inside_circle(inside_circle)
  );

endmodule