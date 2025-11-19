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

// L_tree for computing leaf of XMSS tree, hash the leaves of an unbalanced binary tree to get a root value
// note: only works 
// compute hashes one by one, non-optimized version
// potential optimizations: use multiple thash_h cores to compute hashes in parallel

module l_tree
  #(
    parameter WOTS_LEN = 40,
    parameter XMSS_HASH_PADDING_H = 1,
    parameter XMSS_HASH_PADDING_PRF = 3,
    parameter KEY_LEN = 256  
  )
  (
    input wire clk,
    input wire start,
    input wire reset,
    input wire [KEY_LEN-1:0] input_key, // pub_seed
    input wire [255:0] hash_addr,
    
    // interface with pk array, stored in a dual-port memory
    output wire pk_wr_en_0,
    output wire [`CLOG2(WOTS_LEN)-1:0] pk_addr_0,
    input wire [KEY_LEN-1:0] pk_dout_0,
    output wire [KEY_LEN-1:0] pk_wr_din_0,
    
    output wire pk_wr_en_1,
    output wire [`CLOG2(WOTS_LEN)-1:0] pk_addr_1,
    input wire [KEY_LEN-1:0] pk_dout_1,
    output wire [KEY_LEN-1:0] pk_wr_din_1,
    
    output wire [255:0] hash_addr_updated,
    output wire done,
    output wire [KEY_LEN-1:0] leaf_out,
    
     // interface with the sha256 module
   
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    output wire hash_start,
    output wire [1023:0] hash_data_in,
    output wire message_length 
  );
   
  // idea: lift the odd number node upwards until it becomes a right child
   
  // port 0 is for reading and updating the hash results
  reg pk_wr_en_0_buf;
  reg [`CLOG2(WOTS_LEN)-1:0] pk_rd_addr_0_buf;
  reg [`CLOG2(WOTS_LEN)-1:0] pk_wr_addr_0_buf;
  reg [KEY_LEN-1:0] pk_wr_din_0_buf;
  
  // port 1 is for reading and moving the odd nodes' hash values
  reg pk_wr_en_1_buf;
  reg [`CLOG2(WOTS_LEN)-1:0] pk_rd_addr_1_buf;
  reg [`CLOG2(WOTS_LEN)-1:0] pk_wr_addr_1_buf;
  //reg [KEY_LEN-1:0] pk_wr_din_1_buf;
  assign pk_wr_din_1 = pk_dout_1;
  
  reg [`CLOG2(WOTS_LEN)-1:0] pk_len;
  reg [31:0] round; // round number = tree height
  reg round_done;
  reg round_done_buf;
  reg [31:0] step; // number of hashes within one tree level computation
  wire [31:0] hardcodeone;
  assign hardcodeone = 32'd1;
  
  reg thash_h_start;
  wire thash_h_done;
  reg thash_h_done_reg;
  wire [KEY_LEN-1:0] thash_h_dout;  
  reg [255:0] hash_addr_set;
  reg done_buf;
  
  assign pk_wr_en_0 = pk_wr_en_0_buf;
  assign pk_addr_0 = pk_wr_en_0 ? pk_wr_addr_0_buf : pk_rd_addr_0_buf;
  assign pk_wr_din_0 = pk_wr_din_0_buf;
  
  assign pk_wr_en_1 = pk_wr_en_1_buf;
  assign pk_addr_1 = pk_wr_en_1 ? pk_wr_addr_1_buf : 
                      round_done ? pk_len -1 :
                      pk_rd_addr_1_buf;
    
  assign done = done_buf;
  reg [KEY_LEN-1:0] leaf_out_buf;
  assign leaf_out = leaf_out_buf;
  
  reg [2*KEY_LEN-1:0] thash_h_data_in;
  
  reg start_buf;
  
  always @(posedge clk)
    begin
      if (reset)
        begin
          done_buf <= 1'b0;
          pk_wr_en_0_buf <= 1'b0;
          pk_rd_addr_0_buf <= 0; // needed
          pk_wr_addr_0_buf <= 0;
          pk_wr_din_0_buf <= 0;
          
          pk_wr_en_1_buf <= 1'b0;
          pk_rd_addr_1_buf <= 1; // needed
          pk_wr_addr_1_buf <= 0; 
          
          pk_len <= 0;
          round <= 32'b0;
          round_done <= 1'b0;
          round_done_buf <= 1'b0;
          step <= 0;
          
          thash_h_start <= 1'b0;
          hash_addr_set <= 256'd0;
          
          start_buf <= 1'b0;
          
          thash_h_data_in <= 0;
          thash_h_done_reg <= 1'b0;
          leaf_out_buf <= 0;
        end
      else
        begin
          round_done_buf <= round_done;
          
          leaf_out_buf <= start ? 0 :
                          round_done & (pk_len == 2) ? thash_h_dout :
                          leaf_out_buf;
          
          start_buf <= start;
          
          thash_h_done_reg <= thash_h_done;
          
          done_buf <= round_done & (pk_len == 2);
          
          pk_len <= start ? WOTS_LEN :
                    (round_done & pk_len[0]) ? (pk_len >> 1) + 1 : // one dangling node left
                    (round_done & (!pk_len[0])) ? pk_len >> 1 : // no dangling node left
                    pk_len;
          
          round_done <= thash_h_done & (step == ((pk_len >> 1)- 1));  
          
          round <= start ? 32'b0 :
                  round_done ? round + 1 :
                  round;
          
          step <= (start | round_done) ? 32'b0 :
                  thash_h_done ? step + 1 :
                  step;
          
          pk_wr_en_0_buf <= thash_h_done;
          
          pk_rd_addr_0_buf <= (thash_h_done_reg & (pk_rd_addr_0_buf == ((pk_len >> 1) << 1) - 2 )) ? 0 :  
                              (start | thash_h_done_reg) ? pk_rd_addr_0_buf + 2 :
                              pk_rd_addr_0_buf;
          
          pk_wr_addr_0_buf <= (start_buf | round_done) ? 32'b0 :
                              thash_h_start ? pk_wr_addr_0_buf + 1 :
                              pk_wr_addr_0_buf;
          
          pk_wr_din_0_buf <= thash_h_dout;
          
          pk_wr_en_1_buf <= (pk_len[0] & round_done);
          
          pk_rd_addr_1_buf <= (thash_h_done_reg & (pk_rd_addr_1_buf == ((pk_len >> 1) << 1) - 1 )) ? 1 :  
                              ((pk_len == 3) && round_done_buf) ? 2 :
                              (start | thash_h_done_reg) ? pk_rd_addr_1_buf + 2 :
                              pk_rd_addr_1_buf;
          
          pk_wr_addr_1_buf <= (pk_len >> 1);
          
          hash_addr_set <= start ? {hash_addr[255:96], 64'd0, hash_addr[31:0]} :
                            thash_h_done & (step == ((pk_len >> 1)- 1)) ? {hash_addr_updated[255:96], round + hardcodeone, 32'd0, hash_addr_updated[31:0]} :  
                            thash_h_done ? {hash_addr_updated[255:64], step + hardcodeone, hash_addr_updated[31:0]} :
                            hash_addr_set;
          
          thash_h_start <= start | (thash_h_done & (pk_len > 2));  
          
          thash_h_data_in <= (thash_h_done & (((pk_len >> 1) << 1) == 4) & (step == 1)) ? {pk_dout_0, thash_h_dout} :
                              (thash_h_done & (pk_len == 3)) ? {thash_h_dout, pk_dout_1} :
                              (start | thash_h_done) ? {pk_dout_0, pk_dout_1} :
                              thash_h_data_in;
       
        end
    end
  
  
  thash_h #(.XMSS_HASH_PADDING_H(XMSS_HASH_PADDING_H), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) thash_h_inst (
    .clk(clk),
    .start(thash_h_start),
    .reset(reset),
    .input_key(input_key),
    .input_data(thash_h_data_in),
    .hash_addr(hash_addr_set),
    .data_out(thash_h_dout), 
    .done(thash_h_done), 
    .hash_addr_updated(hash_addr_updated), 
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(hash_start),
    .hash_data_in(hash_data_in),
	  .message_length(message_length) 
  );
  
endmodule











  