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

module gen_chain
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
	  output wire [255:0] hash_addr_updated,
	  
	   // interface with the sha256 module
   
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    output wire hash_start,
    output wire [1023:0] hash_data_in,
    output wire message_length,
    output wire continue_intermediate,
    output wire store_intermediate
  );

  assign continue_intermediate = 1'b0;
  assign store_intermediate = 1'b0;
  
  reg thash_f_start;
  reg [KEY_LEN-1:0] thash_f_din;
  reg [255:0] hash_addr_set;
  //reg [KEY_LEN-1:0] thash_f_input_key = 0;
  reg first_computation = 1'b0;
  
  wire thash_f_done;
  wire [KEY_LEN-1:0] thash_f_dout; 
  wire thash_f_busy;
  wire [255:0] thash_f_hash_addr_updated;
  
  wire [31:0] start_step_word;
  wire [31:0] end_step_word;

  reg [31:0] iteration_counter;
  wire [31:0] one_reg;
  assign one_reg = 32'd1;
   
  reg busy_buf;
   
  assign data_out = thash_f_dout;
  assign done = (thash_f_done && (iteration_counter == end_step_word));
  assign hash_addr_updated = thash_f_hash_addr_updated;
  assign busy = busy_buf;

  assign start_step_word ={{(32-WOTS_LOG_W){1'b0}}, start_step};
  assign end_step_word =  {{(32-WOTS_LOG_W){1'b0}}, end_step};

  always @(posedge clk)
    begin
      if (reset)
        begin
          thash_f_start <= 1'b0;
          thash_f_din <= 0;
          hash_addr_set <= 256'b0;
          iteration_counter <= 0; 
          busy_buf <= 1'b0;
        end
      else
        begin
          
          first_computation <= start;

          thash_f_start <= start | (thash_f_done && (iteration_counter < end_step_word));  

          thash_f_din <= start ? input_data :
                         thash_f_done ? thash_f_dout :
                         thash_f_din;

          iteration_counter <= start ? start_step_word :
                                thash_f_done && (iteration_counter < end_step_word) ? iteration_counter + 1 :
                                iteration_counter;  

          hash_addr_set <= start ? {hash_addr[255:64], start_step_word, hash_addr[31:0]} :
                            (thash_f_done && (iteration_counter < end_step_word)) ? {thash_f_hash_addr_updated[255:64],  iteration_counter + one_reg, thash_f_hash_addr_updated[31:0]} :
                            hash_addr_set;
 
          busy_buf <= start ? 1'b1 :
                      done ? 1'b0 :
                      busy;
        end
    end
  
   
  
  thash_f #(.XMSS_HASH_PADDING_F(XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) thash_f_inst (
    .clk(clk),
    .start(thash_f_start),  
    .reset(reset),
    .input_key(input_key),
    .input_data(thash_f_din),
    .hash_addr(hash_addr_set),
    .data_out(thash_f_dout), 
    .done(thash_f_done),
    .busy(thash_f_busy),
    .hash_addr_updated(thash_f_hash_addr_updated),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(hash_start),
    .hash_data_in(hash_data_in),
	  .message_length(message_length) 
  );
  
endmodule
