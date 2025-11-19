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

// H function used in L_tree
// thash_f calls submodules: 3*PRF + core_hash
// PRF can restore from intermediate states
// core_hash cannot restore from intermediate states

module thash_h 
  #(
    parameter XMSS_HASH_PADDING_H = 1,
    parameter XMSS_HASH_PADDING_PRF = 3, 
    parameter KEY_LEN = 256 
    
  )
  (
    input wire clk,
    input wire start, // start signal, one clock high
    input wire reset,
    input wire [KEY_LEN-1:0] input_key, // pub_seed
    input wire [2*KEY_LEN-1:0] input_data, // {pk[2*i+1] || pk[2*i]}
    input wire [255:0] hash_addr, // hash address
    
	  output wire [KEY_LEN-1:0] data_out, 
    output wire done,
    output wire busy,
    output wire [255:0] hash_addr_updated,
	  
	   // interface with the sha256 module
   
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    output reg hash_start,
    output reg [1023:0] hash_data_in,
    output reg message_length 
	  
  );
   
  // use one sha256 functions to do (three prf + core_hash) computations in sequence, can use stored intermediate states
   
  reg [2:0] hash_count;
  
  wire [255:0] H_padding;
  assign H_padding = XMSS_HASH_PADDING_H;
  
  wire [255:0] PRF_padding;
  assign PRF_padding = XMSS_HASH_PADDING_PRF;
  
  reg [KEY_LEN-1:0] hash_key;
  reg [KEY_LEN-1:0] hash_mask_part_1;
  
  assign hash_addr_updated = {hash_addr[255:32], 32'd2};
  assign data_out = hash_data_out;
   
  reg done_buf;
  reg busy_buf;
  
  assign done = done_buf;
  assign busy = busy_buf;
   
  reg running;
  
  always @(posedge clk)
    begin
      if (reset)
        begin
          hash_start <= 1'b0;
          message_length <= 1'b0;
          hash_data_in <= 1024'b0;  
          hash_count <= 3'b0;
          hash_key <= 0;
          hash_mask_part_1 <= 0; 
          done_buf <= 1'b0;
          busy_buf <= 1'b0;
          running <= 1'b0;
        end
      else
        begin
          
          running <= start ? 1'b1 :
                     done ? 1'b0 :
                     running; 
          
          done_buf <= start ? 1'b0 : (running && hash_done && (hash_count == 3));
          
          busy_buf <= start ? 1'b1 :
                      done ? 1'b0 :
                      busy_buf;
                      
          hash_start <= start | (running & hash_done & (hash_count < 3));
          
          hash_count <= (start | done) ? 2'b0 :
                        (hash_done & running) ? hash_count + 1 :
                        hash_count;
          
          message_length <= start ? 1'b0 : // prf input = 3*256 bits
			                (running & hash_done & (hash_count == 2)) ? 1'b1 :
                            message_length;
             
          hash_data_in <= start ? {PRF_padding, input_key, hash_addr[255:32], 32'b0, 256'd0} : // prf 1st
                          (hash_done && (hash_count == 0)) ? {PRF_padding, input_key, hash_addr[255:32], 32'd1, 256'd0} : // prf 2nd
                          (hash_done && (hash_count == 1)) ? {PRF_padding, input_key, hash_addr[255:32], 32'd2, 256'd0} : // prf 3rd
                          (hash_done && (hash_count == 2)) ? {H_padding, hash_key, (hash_mask_part_1 ^ input_data[2*KEY_LEN-1:KEY_LEN]), (hash_data_out ^ input_data[KEY_LEN-1:0])} : // core_hash
                          hash_data_in;
          
          hash_key <= start ? 0 :
                      (hash_done && (hash_count == 0)) ? hash_data_out :
                      hash_key;
          
          hash_mask_part_1 <= start ? 0 :
                              (hash_done && (hash_count == 1)) ? hash_data_out :
                              hash_mask_part_1;
           
        end
    end
  
endmodule
