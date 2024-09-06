/* This is a simple CIC filter
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (C) 2024 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : tt_um_micro_cic.v
 * Create   : Sep 6, 2024
 * Revise   : Sep 6, 2024
 * Revision : 1.0
 *
 * -----------------------------------------------------------------------------
 */

`default_nettype none

module tt_um_micro_gfg_development_cic (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  parameter STAGES        = 2;
  parameter DOWNSAMPLING  = 4;
  parameter WIDTH_CTR     = 2;

  parameter WIDTH_REGS    = 1 + STAGES * WIDTH_CTR;

  reg [WIDTH_CTR - 2 : 0]   ctr;
  reg                       downsample_clock;

  wire [WIDTH_REGS - 1 : 0] integrator_stage_out    [0 : STAGES - 1];
  wire [WIDTH_REGS - 1 : 0] integrator_stage_in     [0 : STAGES - 1];
  reg  [WIDTH_REGS - 1 : 0] integrator_stage_buffer [0 : STAGES - 1];

  assign integrator_stage_in[0]          = {{(WIDTH_REGS - 1){1'b0}}, ui_in[0]};

  genvar i;
  generate
    for (i = 0; i < STAGES; i = i + 1) begin
      assign integrator_stage_out[i]     = integrator_stage_in[i] + integrator_stage_buffer[i];
    
      if (i != 0) begin
        assign integrator_stage_in[i]    = integrator_stage_out[i - 1];
      end 
    end
  endgenerate;

  always @(posedge clk or negedge rst_n) begin
    integer ii;
    for (ii = 0; ii < STAGES; ii = ii + 1) begin
      if (rst_n == 1'b0) begin
        integrator_stage_buffer[ii]       <= 0;
      end else begin
        integrator_stage_buffer[ii]       <= integrator_stage_out[ii];
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
      ctr                 <= 0;
    end else begin      
      if (ctr == DOWNSAMPLING / 2 - 1) begin
        ctr               <= 0;
        downsample_clock  <= ~downsample_clock;
      end else begin
        ctr <= ctr + 1;
      end
    end
  end

  wire [WIDTH_REGS - 1 : 0] comb_stage_out    [0 : STAGES - 1];
  wire [WIDTH_REGS - 1 : 0] comb_stage_in     [0 : STAGES - 1];
  reg  [WIDTH_REGS - 1 : 0] comb_stage_buffer [0 : STAGES - 1];

  assign comb_stage_in[0]          = integrator_stage_out[STAGES - 1];

  genvar j;
  generate
    for (j = 0; j < STAGES; j = j + 1) begin
      assign comb_stage_out[j]     = comb_stage_in[j] - comb_stage_buffer[j];
    
      if (j != 0) begin
        assign comb_stage_in[j]    = comb_stage_out[j - 1];
      end 
    end
  endgenerate;

  always @(posedge downsample_clock or negedge rst_n) begin
    integer jj;
    for (jj = 0; jj < STAGES; jj = jj + 1) begin
      if (rst_n == 1'b0) begin
        integrator_stage_buffer[ii]       <= 0;
      end else begin
        comb_stage_buffer[jj]             <= comb_stage_in[jj];
      end
    end
  end

  assign uo_out[0]                    = downsample_clock;
  assign uo_out[1]                    = 1'b0;
  assign uo_out[7 : 7 - WIDTH_REGS]   = comb_stage_out[STAGES - 1][WIDTH_REGS - 1 : 0];

endmodule  // tt_um_factory_test
