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

// Function: leaf generation
// Take in one secret seed, one public seed, one hash address, then:
// expand the secret seed into WOTS_LEN number of secret keys,
// use each secret key to WOTS_LEN number of public keys, 
// then use l_tree to hash these public keys into one single leaf

// ******NOTE MAPPINGS TO SW IMPLEMENTATIONS******
// sec_seed = sk[0] || sk[1] || ... || sk[31] (bytes)
// pub_seed = pk[0] || pk[1] || ... || pk[31] (bytes)
// hash_addr = hash_addr[0] || ... || hash_addr[7] (words)
// ***********************************************

module gen_leaf
  #(
    parameter WOTS_W = 16,
    parameter WOTS_LEN = 67,
    parameter XMSS_HASH_PADDING_F = 0,
    parameter XMSS_HASH_PADDING_H = 1,
    parameter XMSS_HASH_PADDING_PRF = 3,
    parameter KEY_LEN = 256, 
    parameter WOTS_LOG_W = `CLOG2(WOTS_W)
  )
  (
    input wire clk, // clock
    input wire start, // start signal, one clock high signal
    input wire reset, // reset signal, comes before start signal
    input wire [KEY_LEN-1:0] sec_seed, // secret initial seed for seed expansion
    input wire [KEY_LEN-1:0] pub_seed, // public seed, stay unchanged
    input wire [255:0] hash_addr, // initial hash address
    
    output wire done, // one clock high signal
    output wire [KEY_LEN-1:0] leaf_out, // hashing root value
    output wire [255:0] hash_addr_out, // updated hash address
    output reg busy,
    
    // interface to sha
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    output wire hash_start,
    output wire [1023:0] hash_data_in,
    output wire message_length,
    output wire store_intermediate,
    output wire continue_intermediate,

    // interface to Chain
    output wire gen_chain_start,
    output wire [KEY_LEN-1:0] gen_chain_input_key,
    output wire [KEY_LEN-1:0] gen_chain_input_data,
    output wire [WOTS_LOG_W-1:0] gen_chain_start_step,
    output wire [WOTS_LOG_W-1:0] gen_chain_end_step,
    output wire [255:0] gen_chain_hash_addr,

    input  wire [KEY_LEN-1:0] gen_chain_data_out,
    input  wire gen_chain_done,
    input  wire gen_chain_busy,
    input  wire [255:0] gen_chain_hash_addr_updated,

    input wire gen_chain_hash_start,
    input wire [1023:0] gen_chain_hash_data_in,
    input wire gen_chain_message_length,
    input wire gen_chain_continue_intermediate,
    input wire gen_chain_store_intermediate

    
  );

  assign store_intermediate = 1'b0;
  assign continue_intermediate = 1'b0;
   
  wire [`CLOG2(WOTS_LEN)-1:0] pk_addr_0;
  wire [KEY_LEN-1:0] pk_wr_din_0;
  wire [KEY_LEN-1:0] pk_dout_0;

  wire pk_wr_en_1;
  wire [`CLOG2(WOTS_LEN)-1:0] pk_addr_1;
  wire [KEY_LEN-1:0] pk_wr_din_1;
  wire [KEY_LEN-1:0] pk_dout_1;
  
  wire gen_pk_busy;
  wire gen_pk_done;
  wire [255:0] gen_pk_hash_addr_out;
  
  reg l_tree_start;
  reg [255:0] l_tree_hash_addr;
   
  wire gen_pk_hash_start;
  wire [1023:0] gen_pk_hash_data_in;
  wire gen_pk_message_length; 
  wire gen_pk_seed_mem_rd_en;
  wire [`CLOG2(WOTS_LEN)-1:0] gen_pk_seed_mem_rd_addr; 
  wire [255:0] gen_pk_wr_data_0;
  wire [`CLOG2(WOTS_LEN)-1:0] gen_pk_wr_addr_0;
  wire gen_pk_wr_en_0;

  wire l_tree_pk_wr_en_0;
  wire [`CLOG2(WOTS_LEN)-1:0] l_tree_pk_addr_0;
  wire [255:0] mem_dout_0;
  wire [255:0] l_tree_pk_wr_din_0;
  wire l_tree_pk_wr_en_1;
  wire [`CLOG2(WOTS_LEN)-1:0] l_tree_pk_addr_1;
  wire [255:0] mem_dout_1;
  wire [255:0] l_tree_pk_wr_din_1;
  wire l_tree_hash_start;
  wire [1023:0] l_tree_hash_data_in;
  wire l_tree_message_length; 

  assign hash_start = gen_pk_hash_start | l_tree_hash_start;
  assign hash_data_in = gen_pk_hash_start ? gen_pk_hash_data_in : l_tree_hash_data_in;
  assign message_length = gen_pk_hash_start ? gen_pk_message_length : l_tree_message_length;

  always @(posedge clk)
    begin
      if (reset)
        begin
          l_tree_start <= 1'b0;
          l_tree_hash_addr <= 256'd0;
          busy <= 1'b0;
        end
      else
        begin
          l_tree_start <= gen_pk_done;
			    l_tree_hash_addr <= gen_pk_done ? {gen_pk_hash_addr_out[255:160], 32'd1, gen_pk_hash_addr_out[127:0]} : l_tree_hash_addr;
          busy <= start ? 1'b1 :
                  done ? 1'b0 :
                  busy;
        end
    end
  
  gen_pk #(.WOTS_W(WOTS_W), .WOTS_LEN(WOTS_LEN), .XMSS_HASH_PADDING_F(XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) gen_pk_inst (
    .clk(clk),
    .start(start),
    .reset(reset),
    .sec_seed(sec_seed),
    .pub_seed(pub_seed),
	  .hash_addr(hash_addr), 
    .busy(gen_pk_busy),
    .done(gen_pk_done),
    .hash_addr_out(gen_pk_hash_addr_out),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .gen_pk_hash_start(gen_pk_hash_start),
    .gen_pk_hash_data_in(gen_pk_hash_data_in),
    .gen_pk_message_length(gen_pk_message_length), 
    .seed_mem_rd_en(gen_pk_seed_mem_rd_en),
    .seed_mem_rd_addr(gen_pk_seed_mem_rd_addr),
    .seed_mem_dout(mem_dout_1),
    .gen_pk_wr_data_0(gen_pk_wr_data_0),
    .gen_pk_wr_addr_0(gen_pk_wr_addr_0),
    .gen_pk_wr_en_0(gen_pk_wr_en_0),
    .gen_chain_start(gen_chain_start),
    .gen_chain_input_key(gen_chain_input_key),
    .gen_chain_input_data(gen_chain_input_data),
    .gen_chain_start_step(gen_chain_start_step),
    .gen_chain_end_step(gen_chain_end_step),
    .gen_chain_hash_addr(gen_chain_hash_addr),
    .gen_chain_data_out(gen_chain_data_out),
    .gen_chain_done(gen_chain_done),
    .gen_chain_busy(gen_chain_busy),
    .gen_chain_hash_addr_updated(gen_chain_hash_addr_updated),
    .gen_chain_hash_start(gen_chain_hash_start),
    .gen_chain_hash_data_in(gen_chain_hash_data_in),
    .gen_chain_message_length(gen_chain_message_length)
  );

  l_tree #(.WOTS_LEN(WOTS_LEN), .XMSS_HASH_PADDING_H(XMSS_HASH_PADDING_H), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) l_tree_inst (
    .clk(clk),
    .start(l_tree_start),
    .reset(reset),
    .input_key(pub_seed),
    .hash_addr(l_tree_hash_addr),
    .pk_wr_en_0(l_tree_pk_wr_en_0),
    .pk_addr_0(l_tree_pk_addr_0),
    .pk_dout_0(mem_dout_0),
    .pk_wr_din_0(l_tree_pk_wr_din_0),
    .pk_wr_en_1(l_tree_pk_wr_en_1),
    .pk_addr_1(l_tree_pk_addr_1),
    .pk_dout_1(mem_dout_1),
    .pk_wr_din_1(l_tree_pk_wr_din_1),
    .leaf_out(leaf_out),     
    .done(done),     
    .hash_addr_updated(hash_addr_out),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(l_tree_hash_start),
    .hash_data_in(l_tree_hash_data_in),
    .message_length(l_tree_message_length) 
  );
  
  mem_dual #(.WIDTH(KEY_LEN), .DEPTH(WOTS_LEN)) mem_dual_inst (
    .clock(clk),
    .data_0(gen_pk_wr_en_0 ? gen_pk_wr_data_0 : l_tree_pk_wr_din_0),
    .data_1(l_tree_pk_wr_din_1),
    .address_0(gen_pk_wr_en_0 ? gen_pk_wr_addr_0 : l_tree_pk_addr_0),
    .address_1(gen_pk_seed_mem_rd_en ? gen_pk_seed_mem_rd_addr : l_tree_pk_addr_1),
    .wren_0(gen_pk_wr_en_0 | l_tree_pk_wr_en_0),
    .wren_1(l_tree_pk_wr_en_1),
    .q_0(mem_dout_0),
    .q_1(mem_dout_1)
  );
   
  
endmodule
