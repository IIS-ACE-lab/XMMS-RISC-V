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


// public key generation, generate WOTS_LEN number of pks for one root of the tree

module gen_pk 
  #(
    parameter WOTS_W = 16,
    parameter WOTS_LEN = 40,
    parameter XMSS_HASH_PADDING_F = 256'd0,
    parameter XMSS_HASH_PADDING_PRF = 256'd3,
    parameter KEY_LEN = 256, 
    parameter WOTS_LOG_W = `CLOG2(WOTS_W)
    
  )
  (
    input wire clk,
    input wire start,
    input wire reset,
    input wire [KEY_LEN-1:0] sec_seed, // secret initial seed for seed expansion
    input wire [KEY_LEN-1:0] pub_seed, // public seed, stay unchanged
    input wire [255:0] hash_addr, // initial hash address
    
    output wire busy,
    output wire done,
    output wire [255:0] hash_addr_out, 
    
    // interface with sha256
    input wire hash_done,
    input wire [KEY_LEN-1:0] hash_data_out,  
    
      // seed_expand
    output wire gen_pk_hash_start,
    output wire [1023:0] gen_pk_hash_data_in,
    output wire gen_pk_message_length,
    
      // seed_expand interface with mem_dual module
        // read interface
    output reg seed_mem_rd_en,
    output reg [`CLOG2(WOTS_LEN)-1:0] seed_mem_rd_addr,
    input wire [KEY_LEN-1:0] seed_mem_dout,
        
        // write interface 
    output wire [KEY_LEN-1:0] gen_pk_wr_data_0,
    output wire [`CLOG2(WOTS_LEN)-1:0] gen_pk_wr_addr_0,
    output wire gen_pk_wr_en_0,

    // interface to gen_chain module
    output reg  gen_chain_start,
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
    input wire gen_chain_store_intermediate,
    input wire gen_chain_continue_intermediate
    
  );
   
  wire seed_expand_busy;
  wire seed_expand_done;
  reg seed_expand_done_buf; 
      
  reg [255:0] hash_addr_set; 
  
  assign hash_addr_out = gen_chain_hash_addr_updated;
  assign gen_chain_input_key = pub_seed;
  assign gen_chain_input_data = seed_mem_dout;
  assign gen_chain_start_step = 0;
  assign gen_chain_end_step = WOTS_W-2;
  assign gen_chain_hash_addr = hash_addr_set;

  
  reg busy_buf;
  reg done_buf;
  assign busy = busy_buf;
  assign done = done_buf;

  wire gen_chain_done_valid;
  assign gen_chain_done_valid = gen_chain_done & busy;
  
  // seed_expand
  wire seed_expand_hash_start;
  wire [1023:0] seed_expand_hash_data_in;
  wire seed_expand_message_length; 
 
  assign gen_pk_hash_start = seed_expand_hash_start | gen_chain_hash_start;
  assign gen_pk_hash_data_in = seed_expand_hash_start ? seed_expand_hash_data_in : gen_chain_hash_data_in;
  assign gen_pk_message_length = seed_expand_hash_start ? seed_expand_message_length : gen_chain_message_length;
  
  wire [KEY_LEN-1:0] seed_wr_data;
  wire [`CLOG2(WOTS_LEN)-1:0] seed_mem_wr_addr;
  wire seed_mem_wr_en;
   
  assign gen_pk_wr_data_0 = gen_chain_done_valid ? gen_chain_data_out : seed_wr_data;
  assign gen_pk_wr_addr_0 = gen_chain_done_valid ? seed_mem_rd_addr : seed_mem_wr_addr;
  assign gen_pk_wr_en_0 = seed_mem_wr_en | gen_chain_done_valid;
  
  
  always @(posedge clk)
    begin
      if (reset)
        begin
          gen_chain_start <= 1'b0;
          seed_mem_rd_addr <= 0;
          hash_addr_set <= 256'b0;
          seed_mem_rd_en <= 1'b0;
          busy_buf <= 1'b0;
          done_buf <= 1'b0;
          seed_expand_done_buf <= 1'b0; 
           
        end
      else
        begin
          
          seed_expand_done_buf <= seed_expand_done;
          
          seed_mem_rd_en <= (seed_expand_done | (gen_chain_done_valid && (seed_mem_rd_addr < (WOTS_LEN-1)))); //FIXME here
           
          seed_mem_rd_addr <= (start | done) ? 0 :
                              gen_chain_done_valid ? seed_mem_rd_addr + 1 :
                              seed_mem_rd_addr;
          
          gen_chain_start <= seed_mem_rd_en; // gen_chain start syncs with valid seed_out
           
          hash_addr_set <= start ? hash_addr :
                            seed_expand_done ? {hash_addr_set[255:96], 32'b0, hash_addr_set[63:0]} :
                            (gen_chain_done_valid && (seed_mem_rd_addr < (WOTS_LEN - 1))) ? {gen_chain_hash_addr_updated[255:96], gen_chain_hash_addr_updated[95:64] + 32'b1, gen_chain_hash_addr_updated[63:0]} :
                            hash_addr_set;
          
          busy_buf <= start ? 1'b1 :
                      done ? 1'b0 :
                      busy_buf;
          
          done_buf <= (gen_chain_done_valid && (seed_mem_rd_addr == (WOTS_LEN - 1)));
                       
        end
    end
  
  seed_expand #(.SEED_NUM(WOTS_LEN), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) seed_expand_inst (
    .clk(clk),
    .start(start),
    .reset(reset),
    .input_key(sec_seed),  
    .busy(seed_expand_busy),
    .done(seed_expand_done),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(seed_expand_hash_start),
    .hash_data_in(seed_expand_hash_data_in),
	  .message_length(seed_expand_message_length), 
    .seed_wr_data(seed_wr_data),
    .seed_mem_wr_addr(seed_mem_wr_addr),
    .seed_mem_wr_en(seed_mem_wr_en)
  );
 
endmodule

  
