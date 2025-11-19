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

module sha256_wrapper (
  input  wire         io_mainClk,
  input  wire         io_systemReset,
  input  wire [511:0] input_data_reg,
  input  wire         sha256_start,
  input  wire         sha256_init_message,
  input  wire         sha256_init_iv,
  input  wire [2:0]   cmd_reg,
  output wire [255:0] output_data,
  output wire         module_busy
	);
 
  wire [511:0] sha256_data_in; 
  wire sha256_data_out_valid;
  wire sha256_busy;
  wire sha256_done;
  wire [255:0] sha256_data_out;  

  assign sha256_data_in = input_data_reg; 
  assign output_data = sha256_data_out;
  assign module_busy = sha256_busy; 

sha256 sha256_inst
  (
    .clk(io_mainClk),
    .reset(io_systemReset),
    .start(sha256_start & (cmd_reg == 3'b001)),  
    .init_message(sha256_init_message), 
    .data_in(sha256_data_in), 
    .init_iv(sha256_init_iv), 
    .data_out(sha256_data_out),  
    .data_out_valid(sha256_data_out_valid), 
    .done(sha256_done),  
    .busy(sha256_busy)  
  );

endmodule