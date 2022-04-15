// ***************************************************************************
// ***************************************************************************
// Copyright 2022 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************
`timescale 1ns/1ps

module axi_tdd_ng_channel #(
  parameter  DEFAULT_POLARITY = 0,
  parameter  REGISTER_WIDTH = 32) (

  input  logic                      clk,
  input  logic                      resetn,

  input  logic [REGISTER_WIDTH-1:0] tdd_counter,
  input  axi_tdd_ng_pkg::state_t    tdd_cstate,
  input  logic                      tdd_enable,
  input  logic                      tdd_endof_frame,

  input  logic                      ch_en,
  input  logic                      ch_pol,
  input  logic [REGISTER_WIDTH-1:0] t_high,
  input  logic [REGISTER_WIDTH-1:0] t_low,

  output logic                      out);

  // package import
  import axi_tdd_ng_pkg::*;

  // internal registers
  logic ch_en_q;
  logic ch_set;
  logic ch_rst;

  //initial values
  initial begin
    ch_en_q = 1'b0;
    ch_set  = 1'b0;
    ch_rst  = 1'b0;
    out     = 1'b0;
  end

  (* direct_enable = "yes" *) logic enable;
  assign enable = tdd_enable;

  always @(posedge clk) begin
    if (resetn == 1'b0) begin
      ch_en_q <= 1'b0;
    end else begin
      if (enable == 1'b0) begin
        ch_en_q <= 1'b0;
      end else begin
        if ((tdd_cstate == ARMED) || (tdd_endof_frame == 1'b1)) begin
          ch_en_q <= ch_en;
        end else begin
          ch_en_q <= ch_en_q;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (resetn == 1'b0) begin
      ch_set <= 1'b0;
    end else begin
      if (enable == 1'b0) begin
        ch_set <= 1'b0;
      end else begin
        if ((tdd_cstate == RUNNING) && (tdd_counter == t_high)) begin
          ch_set <= 1'b1;
        end else begin
          ch_set <= 1'b0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (resetn == 1'b0) begin
      ch_rst <= 1'b0;
    end else begin
      if (enable == 1'b0) begin
        ch_rst <= 1'b0;
      end else begin
        if (((tdd_cstate == RUNNING) && (tdd_counter == t_low)) || (tdd_endof_frame == 1'b1)) begin
          ch_rst <= 1'b1;
        end else begin
          ch_rst <= 1'b0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (resetn == 1'b0) begin
      out <= 1'b0;
    end else begin
      if (enable == 1'b0) begin
        out <= DEFAULT_POLARITY;
      end else begin
        if ((ch_en_q == 1'b0) || (ch_rst == 1'b1)) begin
          out <= ch_pol;
        end else begin
          if (ch_set == 1'b1) begin
            out <= ~ch_pol;
          end else begin
            out <= out;
          end
        end
      end
    end
  end

endmodule

