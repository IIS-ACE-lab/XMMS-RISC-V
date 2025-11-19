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
  input wire second_block_data_available,// the second block of input data (256 or 512 bits) is received, and current computation is NOT busy, set as HIGH all the time when used in Chain/Leaf modules 
  input wire init_iv, // compatible interface with store variant,
  input wire [1023:0] data_in, // input data
  input wire message_length, // 0 -> 768 bit, 1 -> 1024 bit.
  input wire store_intermediate, // one clock high, synchronous with start
                                  // if high, the hash module will store an intermediate state after processing the first 512-bits
  input wire continue_intermediate, // one clock high, synchronous with start
                                    // if high, will resume from the stored intermediate state

  output wire [255:0] data_out, // output data, buffered and do not changed unless updated as the next result
  output wire data_out_valid, // stay high as long as the output is valid
  output reg done = 1'b0, // one clock high, done signal
  output reg busy = 1'b0, // showing if hash function is busy or not

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
 
reg second_block_ready; // the first compression operation is done and the second block of data is received 
reg [1:0] processed_blocks;
reg [1:0] total_blocks; 
wire first_compression_start;
wire first_compression_done;
reg first_compression_done_stay;
wire second_compression_ready;
reg second_compression_ready_buf;
wire second_compression_start;
wire third_compression_start;

reg [255:0] sha256_internal_state;
reg store_intermediate_state_reg; 

reg sha256_init_iv_buf;

// need to buffer the lower half of the input for second compression operation
reg [511:0] data_in_low_buf;
wire [511:0] data_in_valid;
reg used_as_building_block; 

reg start_buf;

// when do we need only one compression:
 // when message_length = 0 and store_intermediate = 1
 // when message length = 0 and continue_intermediate = 1 
// when do we need two compressions:
 // when message length = 0 and no other special conditions
// when do we need three compressions:
 // when message length = 1

// first compression always happens
assign first_compression_start = (start & (!continue_intermediate)) | start_buf;
// only generate the done signal if there are more than one block to process
assign first_compression_done = (processed_blocks == 2'd0) & sha256_done & (total_blocks > 2'd0);
// second compression starts only after the first compression and when the input data of the second block is available
assign second_compression_ready = (first_compression_done_stay | first_compression_done) & second_block_data_available;
// one clock high signal
assign second_compression_start = (second_compression_ready) & (!second_compression_ready_buf);
// only happens when input msg = 1024 bits
assign third_compression_start = (processed_blocks == 2'd1) & sha256_done & message_length; 

// if sha256 is used as building block in chain/leaf, data_in is given synchronously with start signal,
// otherwise, data_in is greshly sent by bus
assign data_in_valid = used_as_building_block ? data_in_low_buf : data_in[511:0];

assign sha256_start = first_compression_start | second_compression_start | third_compression_start;

assign sha256_init_iv = start & continue_intermediate;
 
assign sha256_data_in = // msg_len = 1024, second compression
                              (second_compression_start & message_length) ? data_in_valid[511:0] : 
                              // msg_len = 768 and store request OR 
                              // msg_len = 768, no special requests, first compression OR
                              // msg_len = 1024, first compression
                              (start & (store_intermediate | ((store_intermediate | continue_intermediate) == 1'b0))) ? data_in[1023:512] : 
                              // msg_len = 1024, third compression
                              sha256_init_iv ? {sha256_internal_state, 256'd0} :
                              third_compression_start ? {1'b1, 31'd0, 448'd0, 32'h400} :
                              {data_in_valid[511:256], 32'h80000000, 192'd0, 32'h300};

assign sha256_init_message = start & (continue_intermediate == 1'b0);

assign data_out = sha256_data_out; 

assign data_out_valid = sha256_data_out_valid;
 

always @(posedge clk) begin
  if (reset) begin 
    processed_blocks <= 2'd0;
    total_blocks <= 2'd0;
    first_compression_done_stay <= 1'b0;  
    used_as_building_block <= 1'b0;
    data_in_low_buf <= 512'd0;  
    busy <= 1'b0;
    done <= 1'b0; 
    store_intermediate_state_reg <= 1'b0;  
    sha256_internal_state <= 256'd0;
    sha256_init_iv_buf <= 1'b0;
    start_buf <= 1'b0;
  end
  else begin

    start_buf <= start & continue_intermediate;

    sha256_init_iv_buf <= sha256_init_iv;

    store_intermediate_state_reg <= (start & store_intermediate) ? 1'b1 :
                                    sha256_done ? 1'b0 :
                                    store_intermediate_state_reg;
    
    sha256_internal_state <= (store_intermediate_state_reg & sha256_done) ? sha256_data_out : 
                             sha256_internal_state; 

    total_blocks <= (start & message_length) ? 2'd2 :
                    start & ((store_intermediate & second_block_data_available) | ((store_intermediate | continue_intermediate) == 1'b0)) ? 2'd1 :
                    (start | done) ? 2'd0 :
                    total_blocks; 

    processed_blocks <= (start | done) ? 2'd0 :
                        sha256_done ? processed_blocks + 2'd1 :
                        processed_blocks;
    
    first_compression_done_stay <= (start | done) ? 1'b0 :
                                    first_compression_done ? 1'b1 :
                                    first_compression_done_stay;
    
    second_compression_ready_buf <= second_compression_ready;

    used_as_building_block <= done ? 1'b0 :
                              (start & second_block_data_available) ? 1'b1 :
                              used_as_building_block;

    data_in_low_buf <= start ? data_in[511:0] : data_in_low_buf;

     
    busy <= start ? 1'b1 :
            done ? 1'b0 :
            busy; 

    done <= (processed_blocks == total_blocks) & sha256_done;

  end
end
 
endmodule