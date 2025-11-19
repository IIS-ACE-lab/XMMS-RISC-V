/*
 * Function: bridge module
 *
 * Copyright (C) 2019
 * Authors: Wen Wang <wen.wang.ww349@yale.edu> 
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
*/

module sha256xmss_wrapper (
  input  wire          io_mainClk,
  input  wire          io_systemReset,

  input  wire [2:0]    cmd_reg,
  input  wire [1023:0] input_data_reg,

  input  wire          sha256XMSS_second_block_data_available,
  input  wire          sha256XMSS_start_reg,
  input  wire          sha256XMSS_store_intermediate,
  input  wire          sha256XMSS_continue_intermediate,
  input  wire          sha256XMSS_init_iv,
  input  wire          sha256XMSS_message_length,
  output wire          sha256XMSS_done,

  input  wire          sha256_sha256_start_reg,
  input  wire          sha256_sha256_init_message,
  input  wire          sha256_sha256_init_iv, 
  
  output wire [255:0]  output_data,
  output wire          module_busy
	);
 
  wire [1023:0] sha256XMSS_data_in; 
  wire sha256XMSS_start; 
  wire [255:0] sha256XMSS_data_out; 
  wire sha256XMSS_busy;
  wire sha256XMSS_data_out_valid;

  // in sha256XMSS: output interface to sha256 module
  wire sha256XMSS_sha256_start;
  wire sha256XMSS_sha256_init_message;
  wire [511:0] sha256XMSS_sha256_data_in;
  wire sha256XMSS_sha256_init_iv;
 
  wire [511:0] sha256_sha256_data_in; 
  wire sha256_sha256_start;
  wire [511:0] sha256_data_in;
  wire sha256_start;
  wire sha256_init_message;
  wire sha256_init_iv;
  
  wire [255:0] sha256_data_out;
  wire sha256_data_out_valid;
  wire sha256_done;
  wire sha256_busy;


  assign module_busy = (cmd_reg == 3'b010) ? sha256XMSS_busy : sha256_busy;
                       
  assign output_data = (cmd_reg == 3'b010) ? sha256XMSS_data_out : sha256_data_out;
   
  assign sha256XMSS_data_in = input_data_reg;
  assign sha256XMSS_start = sha256XMSS_start_reg & (cmd_reg == 3'b010); 
  
  assign sha256_sha256_data_in = input_data_reg[1023:512];
  assign sha256_sha256_start = sha256_sha256_start_reg & (cmd_reg == 3'b001); 

  assign sha256_data_in = (cmd_reg == 3'b010) ? sha256XMSS_sha256_data_in : sha256_sha256_data_in;
  assign sha256_start = sha256XMSS_sha256_start | sha256_sha256_start;
  assign sha256_init_message = sha256XMSS_sha256_init_message | sha256_sha256_init_message;
  assign sha256_init_iv = sha256XMSS_sha256_init_iv | sha256_sha256_init_iv;
 
sha256XMSS sha256XMSS_inst
  (
    .clk(io_mainClk),
    .reset(io_systemReset),
    .start(sha256XMSS_start),  
    .second_block_data_available(sha256XMSS_second_block_data_available),
    .data_in(sha256XMSS_data_in), 
    .init_iv(sha256XMSS_init_iv),
    .message_length(sha256XMSS_message_length),  
    .store_intermediate(sha256XMSS_store_intermediate), 
    .continue_intermediate(sha256XMSS_continue_intermediate),  
    .data_out(sha256XMSS_data_out), 
    .data_out_valid(sha256XMSS_data_out_valid),  
    .done(sha256XMSS_done),  
    .busy(sha256XMSS_busy),
    // interface to sha256 
    .sha256_start(sha256XMSS_sha256_start),
    .sha256_init_message(sha256XMSS_sha256_init_message),
    .sha256_data_in(sha256XMSS_sha256_data_in),
    .sha256_init_iv(sha256XMSS_sha256_init_iv),
    .sha256_data_out(sha256_data_out),
    .sha256_data_out_valid(sha256_data_out_valid),
    .sha256_done(sha256_done),
    .sha256_busy(sha256_busy)
  );

  sha256 sha256_inst
  (
    .clk(io_mainClk),
    .reset(io_systemReset),
    .start(sha256_start),  
    .init_message(sha256_init_message), 
    .data_in(sha256_data_in), 
    .init_iv(sha256_init_iv), 
    .data_out(sha256_data_out),  
    .data_out_valid(sha256_data_out_valid),  
    .done(sha256_done),  
    .busy(sha256_busy)  
  );

endmodule