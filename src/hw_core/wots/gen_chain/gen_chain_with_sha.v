/*
 *  
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
// chaining function for wots module

module gen_chain_with_sha
  #(
    parameter WOTS_W = 16,
    parameter XMSS_HASH_PADDING_F = 256'd0,
    parameter XMSS_HASH_PADDING_PRF = 256'd3,
    parameter KEY_LEN = 256, 
    parameter WOTS_LOG_W = `CLOG2(WOTS_W)
    
  )
  (
    input wire clk,
    input wire start, 
    input wire reset,
    input wire [KEY_LEN-1:0] input_key,
    input wire [KEY_LEN-1:0] input_data,
    input wire [WOTS_LOG_W-1:0] start_step,
    input wire [WOTS_LOG_W-1:0] end_step,
    input wire [255:0] hash_addr,
    
    output wire [KEY_LEN-1:0] data_out, 
    output wire done,
    output wire busy,
    output wire [255:0] hash_addr_updated 
  );
  
  wire hash_start;
  wire hash_done;
  wire [KEY_LEN-1:0] hash_data_out;
  wire [1023:0] hash_data_in;
  wire message_length;
  wire continue_intermediate; 
  wire store_intermediate;

  wire sha256_plain_start;
  wire sha256_plain_init_message;
  wire [511:0] sha256_plain_data_in;
  wire sha256_plain_init_iv;
    // outputs
  wire [255:0] sha256_plain_data_out;
  wire sha256_plain_data_out_valid;
  wire sha256_plain_done;
  wire sha256_plain_busy;
  
  gen_chain #(.WOTS_W(WOTS_W), .XMSS_HASH_PADDING_F(XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) gen_chain_inst (
    .clk(clk),
    .start(start),
    .reset(reset),
    .input_key(input_key),
    .input_data(input_data),
    .hash_addr(hash_addr),
    .start_step(start_step),
    .end_step(end_step),
    .data_out(data_out),
    .busy(busy),
    .done(done), 
    .hash_addr_updated(hash_addr_updated),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(hash_start),
    .hash_data_in(hash_data_in),
    .message_length(message_length),
	  .continue_intermediate(continue_intermediate),
    .store_intermediate(store_intermediate)
  );
   
  sha256XMSS sha256_inst (
    .clk(clk),
    .reset(reset),
    .start(hash_start),
    .data_in(hash_data_in),
    .message_length(message_length),
    .store_intermediate(store_intermediate),
    .continue_intermediate(continue_intermediate), 
    .data_out(hash_data_out),
    .second_block_data_available(1'b1),
    .data_out_valid(),
    .init_iv(1'b0),
    .done(hash_done),
    .busy(),
    .sha256_start(sha256_plain_start),
    .sha256_init_message(sha256_plain_init_message),
    .sha256_data_in(sha256_plain_data_in),
    .sha256_init_iv(sha256_plain_init_iv),
    .sha256_data_out(sha256_plain_data_out),
    .sha256_data_out_valid(sha256_plain_data_out_valid),
    .sha256_done(sha256_plain_done),
    .sha256_busy(sha256_plain_busy)
  );

  sha256 sha256_plain_inst (
    .clk(clk),
    .reset(reset),
    .start(sha256_plain_start),
    .init_message(sha256_plain_init_message),
    .data_in(sha256_plain_data_in),
    .init_iv(sha256_plain_init_iv),
    .data_out(sha256_plain_data_out),
    .data_out_valid(sha256_plain_data_out_valid),
    .done(sha256_plain_done),
    .busy(sha256_plain_busy)
  );
   
endmodule

 
