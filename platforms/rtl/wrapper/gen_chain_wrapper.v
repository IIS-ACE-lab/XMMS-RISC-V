/*
 * Function: bridge module
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

module gen_chain_wrapper 
  #(
    parameter WOTS_W = 16, 
    parameter WOTS_LOG_W = `CLOG2(WOTS_W)
  )
  (
  input  wire                   io_mainClk,
  input  wire                   io_systemReset,
  
  // signals collected from software
  input  wire [2:0]             cmd_reg,
  input  wire [1023:0]          input_data_reg,
    
    // for gen_chain input
  input  wire                   gen_chain_start_reg,
  input  wire [WOTS_LOG_W-1:0]  gen_chain_start_step,
  input  wire [WOTS_LOG_W-1:0]  gen_chain_end_step,

    // for sha256XMSS input
  input  wire                   sha256XMSS_sha256XMSS_second_block_data_available,
  input  wire                   sha256XMSS_sha256XMSS_start_reg,
  input  wire                   sha256XMSS_sha256XMSS_store_intermediate,
  input  wire                   sha256XMSS_sha256XMSS_continue_intermediate,
  input  wire                   sha256XMSS_sha256XMSS_init_iv,
  input  wire                   sha256XMSS_sha256XMSS_message_length,
  output wire                   sha256XMSS_done,
    
    // for sha256 input
  input  wire                   sha256_sha256_start_reg,
  input  wire                   sha256_sha256_init_message,
  input  wire                   sha256_sha256_init_iv, 
  
  // connect to Apb3 bridge modules
  output wire [255:0]           output_data,
  output wire                   module_busy
	);

  //  cmd           module
  // 3'b001           sha256
  // 3'b010       sha256XMSS
  // 3'b011        gen_chain

//----------------------------------------------------- 
  //***************************************************  
  // from software: interface to gen_chain 
  wire gen_chain_start;
  wire [255:0] gen_chain_input_key;
  wire [255:0] gen_chain_input_data;
  wire [255:0] gen_chain_hash_addr; 
  
  assign gen_chain_start = gen_chain_start_reg & (cmd_reg == 3'b011);
  assign gen_chain_input_key = input_data_reg[1023:768];
  assign gen_chain_input_data = input_data_reg[767:512];
  assign gen_chain_hash_addr = input_data_reg[511:256];

  wire [255:0] gen_chain_data_out;
  wire [255:0] gen_chain_hash_addr_updated;
  wire gen_chain_done;
  wire gen_chain_busy;

    // within gen_chain: interface to sha256XMSS
  wire gen_chain_sha256XMSS_start;
  wire [1023:0] gen_chain_sha256XMSS_data_in;
  wire gen_chain_sha256XMSS_message_length;
  wire gen_chain_sha256XMSS_continue_intermediate;
  wire gen_chain_sha256XMSS_store_intermediate;
 
//-----------------------------------------------------   
  // interface of sha256XMSS
  //***************************************************
    // from software: interface to sha256XMSS
  wire sha256XMSS_sha256XMSS_start;
  wire [1023:0] sha256XMSS_sha256XMSS_data_in; 
  
  assign sha256XMSS_sha256XMSS_start = sha256XMSS_sha256XMSS_start_reg & (cmd_reg == 3'b010);
  assign sha256XMSS_sha256XMSS_data_in = input_data_reg;

  wire sha256XMSS_start;
  wire [1023:0] sha256XMSS_data_in; 
  wire sha256XMSS_second_block_data_available; 
  wire sha256XMSS_store_intermediate;
  wire sha256XMSS_continue_intermediate;
  wire sha256XMSS_init_iv;
  wire sha256XMSS_message_length;
  
  //sha256XMSS is trigger by gen_chain or software requests
  assign sha256XMSS_start = sha256XMSS_sha256XMSS_start | gen_chain_sha256XMSS_start;
  assign sha256XMSS_data_in = gen_chain_busy ? gen_chain_sha256XMSS_data_in : sha256XMSS_sha256XMSS_data_in;
  assign sha256XMSS_second_block_data_available = gen_chain_busy | sha256XMSS_sha256XMSS_second_block_data_available; 
  assign sha256XMSS_store_intermediate = gen_chain_sha256XMSS_store_intermediate | sha256XMSS_sha256XMSS_store_intermediate;
  assign sha256XMSS_continue_intermediate = gen_chain_sha256XMSS_continue_intermediate | sha256XMSS_sha256XMSS_continue_intermediate;
  assign sha256XMSS_init_iv = sha256XMSS_sha256XMSS_init_iv;
  assign sha256XMSS_message_length = gen_chain_busy ? gen_chain_sha256XMSS_message_length : sha256XMSS_sha256XMSS_message_length;
  
   

  wire [255:0] sha256XMSS_data_out;  
  wire sha256XMSS_busy;
  wire sha256XMSS_data_out_valid;
 
  wire sha256XMSS_sha256_start;
  wire sha256XMSS_sha256_init_message;
  wire [511:0] sha256XMSS_sha256_data_in;
  wire sha256XMSS_sha256_init_iv;
  

//----------------------------------------------------- 
//***************************************************
    // from software: interface to sha256 
  wire [511:0] sha256_sha256_data_in; 
  wire sha256_sha256_start;

  assign sha256_sha256_data_in = input_data_reg[1023:512];
  assign sha256_sha256_start = sha256_sha256_start_reg & (cmd_reg == 3'b001);
  // interface of sha256
  wire [511:0] sha256_data_in;
  wire sha256_start;
  wire sha256_init_message;
  wire sha256_init_iv; 

  assign sha256_data_in = (gen_chain_busy | (cmd_reg == 3'b010))  ? sha256XMSS_sha256_data_in : sha256_sha256_data_in; 
  assign sha256_start = sha256XMSS_sha256_start | sha256_sha256_start;
  assign sha256_init_message = sha256XMSS_sha256_init_message | sha256_sha256_init_message;
  assign sha256_init_iv = sha256XMSS_sha256_init_iv | sha256_sha256_init_iv;
  
  wire [255:0] sha256_data_out;
  wire sha256_data_out_valid;
  wire sha256_done;
  wire sha256_busy;

  assign module_busy = (cmd_reg == 3'b011) ? gen_chain_busy :
                       (cmd_reg == 3'b010) ? sha256XMSS_busy : 
                       sha256_busy;
  
  assign output_data = (cmd_reg == 3'b011) ? gen_chain_data_out : 
                       (cmd_reg == 3'b010) ? sha256XMSS_data_out : 
                       sha256_data_out;
 
  gen_chain gen_chain_inst 
  (
    .clk(io_mainClk),
    .reset(io_systemReset),
    .start(gen_chain_start), 
    .input_key(gen_chain_input_key),
    .input_data(gen_chain_input_data),
    .start_step(gen_chain_start_step),
    .end_step(gen_chain_end_step),
    .hash_addr(gen_chain_hash_addr), 
    .data_out(gen_chain_data_out),
    .busy(gen_chain_busy),
    .done(gen_chain_done), 
    .hash_addr_updated(gen_chain_hash_addr_updated),
    .hash_done(sha256XMSS_done), //
    .hash_data_out(sha256XMSS_data_out), //
    // interface to sha256XMSS
    .hash_start(gen_chain_sha256XMSS_start),
    .hash_data_in(gen_chain_sha256XMSS_data_in),
    .message_length(gen_chain_sha256XMSS_message_length),
    .continue_intermediate(gen_chain_sha256XMSS_continue_intermediate),
    .store_intermediate(gen_chain_sha256XMSS_store_intermediate)
  );

  // shared by gen_chain and software
  sha256XMSS sha256XMSS_inst
  (
    .clk(io_mainClk),
    .reset(io_systemReset),
    .start(sha256XMSS_start),  
    .second_block_data_available(sha256XMSS_second_block_data_available),
    .data_in(sha256XMSS_data_in), 
    .init_iv(sha256XMSS_init_iv),
    .message_length(sha256XMSS_message_length),  
    .store_intermediate(sha256XMSS_store_intermediate), 
    .continue_intermediate(sha256XMSS_continue_intermediate),  
    .data_out(sha256XMSS_data_out), 
    .data_out_valid(sha256XMSS_data_out_valid),  
    .done(sha256XMSS_done),  
    .busy(sha256XMSS_busy),
    // interface to sha256 
    .sha256_start(sha256XMSS_sha256_start),
    .sha256_init_message(sha256XMSS_sha256_init_message),
    .sha256_data_in(sha256XMSS_sha256_data_in),
    .sha256_init_iv(sha256XMSS_sha256_init_iv),
    .sha256_data_out(sha256_data_out),//
    .sha256_data_out_valid(sha256_data_out_valid),//
    .sha256_done(sha256_done),//
    .sha256_busy(sha256_busy)//
  );
  
  // shared by sha256XMSS and software
  sha256 sha256_inst
  (
    .clk(io_mainClk),
    .reset(io_systemReset),
    .start(sha256_start),  
    .init_message(sha256_init_message), 
    .data_in(sha256_data_in), 
    .init_iv(sha256_init_iv), 
    .data_out(sha256_data_out),  
    .data_out_valid(sha256_data_out_valid),  
    .done(sha256_done),  
    .busy(sha256_busy)  
  );

endmodule