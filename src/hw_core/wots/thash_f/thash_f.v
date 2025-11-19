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
// F function used in chaining function
// thash_f calls submodules: PRF + core_hash
// PRF can restore from intermediate states
// core_hash cannot restore from intermediate states

module thash_f 
  #(
    parameter XMSS_HASH_PADDING_F = 256'd0,
    parameter XMSS_HASH_PADDING_PRF = 256'd3,
    parameter KEY_LEN = 256 
  )
  (
    input wire clk,
    input wire start, // start signal, one clock high
    input wire reset,
    input wire [KEY_LEN-1:0] input_key, // pub_seed
    input wire [KEY_LEN-1:0] input_data, 
    input wire [255:0] hash_addr, // hash address = addr0 + addr1 + ... + addr7
    
    output wire [KEY_LEN-1:0] data_out, 
    output wire done,
    output wire busy,
    output wire [255:0] hash_addr_updated,
	  
	   // interface with the sha256 module
   
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    output reg hash_start,
    output wire [1023:0] hash_data_in,
    output wire message_length,
    output reg continue_intermediate 
    
  );
  
// reuse core hash for: first prf, second prf and the last core hash operations.
  
  wire [255:0] PRF_padding; // consts
  wire [255:0] F_padding; // consts

  assign PRF_padding = XMSS_HASH_PADDING_PRF;
  assign F_padding = XMSS_HASH_PADDING_F;
  
  reg hash_done_buf; 
  reg [767:0] core_hash_data_in;
  
  reg [1:0] hash_count;
  reg [KEY_LEN-1:0] core_hash_key;
   
  reg busy_buf; 
	reg running;
   
  assign data_out = hash_data_out;
  assign done = (running && hash_done && (hash_count == 2));
  assign hash_addr_updated = {hash_addr[255:32], 32'd1};
  assign busy = busy_buf;
  
  assign hash_data_in = {core_hash_data_in, 256'd0};
  assign message_length = 1'b0;
  
  always @(posedge clk)
    begin
      if (reset)
        begin
          hash_done_buf <= 1'b0; 
          core_hash_data_in <= 767'b0; 
          hash_count <= 2'b0;
          core_hash_key <= {KEY_LEN{1'b0}}; 
          hash_start <= 1'b0;
          continue_intermediate <= 1'b0;  
          busy_buf <= 1'b0; 
          running <= 1'b0;
        end
      else
        begin
          running <= start ? 1'b1 :
                     done ? 1'b0 :
                     running;
          
          hash_done_buf <= hash_done;
           
          hash_start <= start | (running && hash_done && (hash_count < 2));  
          
          hash_count <= (start | done) ? 2'b0 :
                        (hash_done & running) ? hash_count + 1 :
                        hash_count;  
          
          core_hash_key <= (hash_done && (hash_count == 0)) ? hash_data_out : core_hash_key; 
          
          continue_intermediate <= (running && (hash_done && (hash_count == 0))) | start;
          
          core_hash_data_in <= start ? {PRF_padding, input_key, hash_addr[255:32], 32'd0} :
                              (hash_done && (hash_count == 0)) ? {PRF_padding, input_key, hash_addr[255:32], 32'd1} :
                              (hash_done && (hash_count == 1)) ? {F_padding, core_hash_key, (input_data ^ hash_data_out)} :
                              core_hash_data_in; 
          
          busy_buf <= start ? 1'b1 :
                      (hash_done && (hash_count == 2)) ? 1'b0: 
                      busy_buf; 
        end
    end
  
   
endmodule
