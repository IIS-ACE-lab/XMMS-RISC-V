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

`timescale 1ns / 1ps

module gen_pk_tb;
  parameter WOTS_LOG_W = `CLOG2(`WOTS_W);
  // inputs
  reg clk = 1'b0;
  reg start = 1'b0;
  reg reset = 1'b0;
  reg [`KEY_LEN-1:0] sec_seed = 0;
  reg [`KEY_LEN-1:0] pub_seed = 0;
  reg [255:0] hash_addr = 0;
   
  // outputs
  wire [255:0] hash_addr_out;
  wire busy;
  wire done;
  
  wire [`KEY_LEN-1:0] hash_data_out;
  wire hash_done;
	
  wire gen_pk_hash_start;
  wire [1023:0] gen_pk_hash_data_in;
  wire gen_pk_message_length; 
 
    // seed_expand read interface with mem_dual module
  wire seed_mem_rd_en;
  wire [`CLOG2(`WOTS_LEN)-1:0] seed_mem_rd_addr;
  wire  [`KEY_LEN-1:0] seed_mem_dout;
  
    // gen_pk interface with mem_dual module
      // write result back to port 0
  wire [`KEY_LEN-1:0] gen_pk_wr_data_0;
  wire [`CLOG2(`WOTS_LEN)-1:0] gen_pk_wr_addr_0;
  wire gen_pk_wr_en_0; 
  
  reg [`CLOG2(`WOTS_LEN)-1:0] pk_mem_addr_0;
  wire [`KEY_LEN-1:0] pk_mem_dout_0;

  wire sha256_plain_start;
  wire sha256_plain_init_message;
  wire [511:0] sha256_plain_data_in;
  wire sha256_plain_init_iv;
    // outputs
  wire [255:0] sha256_plain_data_out;
  wire sha256_plain_data_out_valid;
  wire sha256_plain_done;
  wire sha256_plain_busy;

  wire gen_chain_start;
  wire [`KEY_LEN-1:0] gen_chain_input_key;
  wire [`KEY_LEN-1:0] gen_chain_input_data;
  wire [WOTS_LOG_W-1:0] gen_chain_start_step;
  wire [WOTS_LOG_W-1:0] gen_chain_end_step;
  wire [255:0] gen_chain_hash_addr;

  wire [`KEY_LEN-1:0] gen_chain_data_out;
  wire gen_chain_done;
  wire gen_chain_busy;
  wire [255:0] gen_chain_hash_addr_updated;

  wire gen_chain_hash_start;
  wire [1023:0] gen_chain_hash_data_in;
  wire gen_chain_message_length;
  wire gen_chain_continue_intermediate;
  wire gen_chain_store_intermediate;
  
  gen_pk #(.WOTS_W(`WOTS_W), .WOTS_LEN(`WOTS_LEN), .XMSS_HASH_PADDING_F(`XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(`XMSS_HASH_PADDING_PRF), .KEY_LEN(`KEY_LEN)) DUT (
    .clk(clk),
    .start(start),
    .reset(reset),
    .sec_seed(sec_seed),
    .pub_seed(pub_seed),
    .hash_addr(hash_addr), 
    .busy(busy),
    .done(done),
    .hash_addr_out(hash_addr_out),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .gen_pk_hash_start(gen_pk_hash_start),
    .gen_pk_hash_data_in(gen_pk_hash_data_in),
    .gen_pk_message_length(gen_pk_message_length), 
    .seed_mem_rd_en(seed_mem_rd_en),
    .seed_mem_rd_addr(seed_mem_rd_addr),
    .seed_mem_dout(seed_mem_dout),
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
    .gen_chain_message_length(gen_chain_message_length),
    .gen_chain_continue_intermediate(gen_chain_continue_intermediate),
    .gen_chain_store_intermediate(gen_chain_store_intermediate)
  );

  gen_chain #(.WOTS_W(`WOTS_W), .XMSS_HASH_PADDING_F(`XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(`XMSS_HASH_PADDING_PRF), .KEY_LEN(`KEY_LEN)) gen_chain_inst (
    .clk(clk),
    .start(gen_chain_start),
    .reset(reset),
    .input_key(gen_chain_input_key),
    .input_data(gen_chain_input_data),
    .start_step(gen_chain_start_step),
    .end_step(gen_chain_end_step),
    .hash_addr(gen_chain_hash_addr),
    .data_out(gen_chain_data_out),
    .busy(gen_chain_busy),
    .done(gen_chain_done), 
    .hash_addr_updated(gen_chain_hash_addr_updated),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(gen_chain_hash_start),
    .hash_data_in(gen_chain_hash_data_in),
    .message_length(gen_chain_message_length),
    .continue_intermediate(gen_chain_continue_intermediate),
    .store_intermediate(gen_chain_store_intermediate)
  );
  
  mem_dual #(.WIDTH(`KEY_LEN), .DEPTH(`WOTS_LEN)) mem_dual_inst (
    .clock(clk),
    .data_0(gen_pk_wr_data_0),
    .data_1(),
    .address_0(gen_pk_wr_en_0 ? gen_pk_wr_addr_0 : pk_mem_addr_0),
    .address_1(seed_mem_rd_addr),
    .wren_0(gen_pk_wr_en_0),
    .wren_1(1'b0),
    .q_0(pk_mem_dout_0),
    .q_1(seed_mem_dout)
  );
  
  sha256XMSS sha256_inst (
    .clk(clk),
    .reset(reset),
    .start(gen_pk_hash_start),
    .data_in(gen_pk_hash_data_in),
    .message_length(gen_pk_message_length), 
    .second_block_data_available(1'b1),
    .store_intermediate(1'b0),
    .continue_intermediate(1'b0),
    .init_iv(1'b0),
    .data_out(hash_data_out),
    .data_out_valid(),
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
  
  integer STDERR = 32'h8000_0002;
  integer STDIN  = 32'h8000_0000;
  
  initial
    begin
      $dumpfile("gen_pk_tb.vcd");
      $dumpvars(0, gen_pk_tb);
    end
  
  integer scan_file;
  
  initial
    begin
      scan_file = $fscanf(STDIN, "%b\n", sec_seed);
      scan_file = $fscanf(STDIN, "%b\n", pub_seed);
      scan_file = $fscanf(STDIN, "%b\n", hash_addr);
    end
  
  integer start_time;
  integer end_time;
  integer i;
  integer f;
  
  initial
    begin
      # 10;
      reset <= 1'b1;
      # 10;
      reset <= 1'b0;
      # 25;
      start <= 1'b1;   
      start_time <= $time;
      # 10;
      start <= 1'b0;
       
      @(posedge done);
      end_time = $time;
      $fdisplay(STDERR, "\nruntime: %0d cycles\n", (end_time-start_time)/10);
      
      // write data
      f = $fopen("test.out", "w");
      // write data
      @(posedge clk);
      
      for (i = 0; i < `WOTS_LEN; i = i + 1)
        begin
          pk_mem_addr_0 = i;
          # 10;
          $fwrite(f, "%x\n", pk_mem_dout_0);
        end
       
      pk_mem_addr_0 = 0;
      
      # 1000;
      $fclose(f);
      
      // start over.
      
      # 10;
      // reset <= 1'b1;
      # 10;
      reset <= 1'b0;
      # 25;
      start <= 1'b1;   
      start_time <= $time;
      # 10;
      start <= 1'b0;
       
      @(posedge done);
      end_time = $time;
      $fdisplay(STDERR, "\nruntime: %0d cycles\n", (end_time-start_time)/10);
      
      // write data
      f = $fopen("test.out", "w");
      // write data
      @(posedge clk);
       
      for (i = 0; i < `WOTS_LEN; i = i + 1)
        begin
          pk_mem_addr_0 = i;
          # 10;
          $fwrite(f, "%x\n", pk_mem_dout_0);
        end
      
      
      # 1000;
      $fclose(f);
      
      $finish;
      
    end
  
  always
    #5 clk = !clk;
  
endmodule

 