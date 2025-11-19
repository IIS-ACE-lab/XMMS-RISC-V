/*
 *  
 *
 * Copyright (C) 2019
 * Authors: Bernhard Jungk <bernhard@projectstarfire.de>
 *          Wen Wang <wen.wang.ww349@yale.edu>
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

module sha256XMSS
(
  input wire clk,
  input wire reset,
  input wire start, // start signal, one clock high
  input wire init_iv, // compatible interface with store variant,
  input wire second_block_data_available, // the second block of input data (256 or 512 bits) is received, and current computation is NOT busy, set as HIGH all the time when used in Chain/Leaf modules 
  input wire [1023:0] data_in, // input data, stay valid
  input wire message_length, // 0 -> 768 bit, 1 -> 1024 bit. stay valid 
  input wire store_intermediate, // compatible interface with store variant
  input wire continue_intermediate, // compatible interface with store variant
  output wire [255:0] data_out, // output data, buffered and do not changed unless updated as the next result
  output wire data_out_valid, // stay high as long as the output is valid
  output wire done, // one clock high, done signal
  output wire busy, // showing if hash function is busy or not

  // interface to sha256 module
  // inputs
  output wire sha256_start,
  output wire sha256_init_message,
  output wire sha256_init_iv,
  output wire [511:0] sha256_data_in, 
    // outputs
  input wire [255:0] sha256_data_out,
  input wire sha256_data_out_valid,
  input wire sha256_done,
  input wire sha256_busy 
);

sha256XMSS_core sha256XMSS_core_inst (
  .clk(clk),
  .reset(reset),
  .start(start),
  .init_iv(init_iv),
  .second_block_data_available(second_block_data_available),
  .data_in(data_in),
  .message_length(message_length),
  .store_intermediate(store_intermediate),
  .continue_intermediate(continue_intermediate),
  .data_out(data_out),
  .data_out_valid(data_out_valid),
  .done(done),
  .busy(busy),
  .sha256_start(sha256_start),
  .sha256_init_message(sha256_init_message),
  .sha256_init_iv(sha256_init_iv),
  .sha256_data_in(sha256_data_in),
  .sha256_data_out(sha256_data_out),
  .sha256_data_out_valid(sha256_data_out_valid),
  .sha256_done(sha256_done),
  .sha256_busy(sha256_busy)
  );

endmodule