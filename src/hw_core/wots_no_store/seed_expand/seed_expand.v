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

// seed expanding
// the expanded seed array is stored in a memory

module seed_expand
  #(
    parameter SEED_NUM = 40, // number of seeds needed after expansion
    parameter XMSS_HASH_PADDING_PRF = 256'd3, // SHA2-256
    parameter KEY_LEN = 256 // SHA2-256 
  )
  (
    input wire clk,
    input wire start,
    input wire reset,
    input wire [KEY_LEN-1:0] input_key,
     
    output wire busy,
    output wire done,
	  
    // interface with the sha256 module
   
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    output reg hash_start,
    output wire [1023:0] hash_data_in,
    output wire message_length, 
    
    // interface with mem_dual module
    output wire [KEY_LEN-1:0] seed_wr_data,
    output wire [`CLOG2(SEED_NUM)-1:0] seed_mem_wr_addr,
    output wire seed_mem_wr_en
  );
  
  reg [`CLOG2(SEED_NUM)-1:0] seed_num_counter; 
  wire [KEY_LEN-1:0] prf_data_out;
  wire prf_data_out_valid; 
  wire prf_busy;
  
  reg running;
  reg done_buf; 
  
  assign seed_wr_data = hash_data_out;
  assign seed_mem_wr_addr = seed_num_counter;
  assign seed_mem_wr_en = hash_done & running;
  
  wire [255:0] PRF_padding; // consts 
  assign PRF_padding = XMSS_HASH_PADDING_PRF;
  
  assign hash_data_in = {PRF_padding, input_key, {(256-`CLOG2(SEED_NUM)){1'b0}}, seed_num_counter, 256'd0};
  assign message_length = 1'b0; 
	
  always @(posedge clk)
    begin
      if (reset)
        begin
          seed_num_counter <= {`CLOG2(SEED_NUM){1'b0}};
          hash_start <= 0; 
          running <= 1'b0;
          done_buf <= 1'b0; 
        end
      else
        begin 
          running <= start ? 1'b1 : 
                     done ? 1'b0 :
                     running;

          seed_num_counter <= start ? 0 : 
                              running & hash_done & (seed_num_counter < (SEED_NUM-1)) ? seed_num_counter + 1 :
                              seed_num_counter;

			    hash_start <= start | (running & hash_done & (seed_num_counter < (SEED_NUM-1)));
 
		      done_buf <= hash_done && (seed_num_counter == (SEED_NUM-1)) & running;
        end
         
    end
  
  assign busy = start | running;
  assign done = done_buf; 
   
endmodule
