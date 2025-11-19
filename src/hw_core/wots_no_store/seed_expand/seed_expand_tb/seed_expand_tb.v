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

module seed_expand_tb;
  
  // inputs
  reg clk = 1'b0;
  reg start = 1'b0;
  reg reset = 1'b0;
  reg [`KEY_LEN-1:0] input_key = 0;
  
  reg seed_mem_rd_en = 1'b0;
  reg [`CLOG2(`SEED_NUM)-1:0] seed_mem_rd_addr = 0;
  
  wire hash_done;
  wire [`KEY_LEN-1:0] hash_data_out; 
   
  // outputs 
  wire busy;
  wire done;
  wire hash_start;
  wire [1023:0] hash_data_in;
  wire message_length; 
  
  wire [`KEY_LEN-1:0] seed_wr_data;
  wire [`CLOG2(`SEED_NUM)-1:0] seed_mem_wr_addr;
  wire seed_mem_wr_en;
  
  wire [`KEY_LEN-1:0] seed_out;

  wire sha256_plain_start;
  wire sha256_plain_init_message;
  wire [511:0] sha256_plain_data_in;
  wire sha256_plain_init_iv;
    // outputs
  wire [255:0] sha256_plain_data_out;
  wire sha256_plain_data_out_valid;
  wire sha256_plain_done;
  wire sha256_plain_busy;
  
  seed_expand #(.SEED_NUM(`SEED_NUM), .XMSS_HASH_PADDING_PRF(`XMSS_HASH_PADDING_PRF), .KEY_LEN(`KEY_LEN)) DUT (
    .clk(clk),
    .start(start),
    .reset(reset),
    .input_key(input_key),  
    .busy(busy),
    .done(done),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(hash_start),
    .hash_data_in(hash_data_in),
    .message_length(message_length),
    .seed_wr_data(seed_wr_data),
    .seed_mem_wr_addr(seed_mem_wr_addr),
    .seed_mem_wr_en(seed_mem_wr_en)
  );
	
	mem_dual #(.WIDTH(`KEY_LEN), .DEPTH(`SEED_NUM)) mem_dual_inst (
    .clock(clk),
    .data_0(seed_wr_data),
    .data_1(),
    .address_0(seed_mem_wr_addr),
    .address_1(seed_mem_rd_en ? seed_mem_rd_addr : 0),
    .wren_0(seed_mem_wr_en),
    .wren_1(),
    .q_0(),
    .q_1(seed_out)
  );
  
  sha256XMSS sha256_inst (
    .clk(clk),
    .reset(reset),
    .start(hash_start),
    .init_iv(1'b0),
    .second_block_data_available(1'b1),
    .data_in(hash_data_in),
    .message_length(message_length), 
    .store_intermediate(1'b0),
    .continue_intermediate(1'b0),
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
      $dumpfile("seed_expand_tb.vcd");
      $dumpvars(0, seed_expand_tb);
    end
  
  integer scan_file;
  
  initial
    begin
      scan_file = $fscanf(STDIN, "%b\n", input_key);
    end
  
  integer start_time;
  integer end_time;
  integer i;
  integer f;
  
  initial
    begin
      # 10;
      reset <= 1'b1;
      seed_mem_rd_addr <= 0;
      # 10;
      reset <= 1'b0;
      # 25;
      start <= 1'b1;
      start_time <= $time;
      # 10;
      start <= 1'b0;
      
      @(posedge done);
      end_time = $time;
      $fdisplay(STDERR, "runtime: %0d cycles\n", (end_time-start_time)/10);
      
      //f = $fopen("test.out", "w");
      // write output data
      @(posedge clk);
      seed_mem_rd_en = 1'b1;
      for (i = 0; i < `SEED_NUM; i = i + 1)
        begin
          seed_mem_rd_addr = i;
          # 10;
          //$fwrite(f, "%x\n", seed_out);
        end
      //$fclose(f);
      seed_mem_rd_en = 1'b0;
      
      # 200;
      
      // start over.
      
      # 10;
      // reset <= 1'b1;
      seed_mem_rd_addr <= 0;
      # 10;
      reset <= 1'b0;
      # 25;
      start <= 1'b1;
      start_time <= $time;
      # 10;
      start <= 1'b0;
      
      @(posedge done);
      end_time = $time;
      $fdisplay(STDERR, "runtime: %0d cycles\n", (end_time-start_time)/10);
      
      f = $fopen("test.out", "w");
      // write output data
      @(posedge clk);
      seed_mem_rd_en = 1'b1;
      for (i = 0; i < `SEED_NUM; i = i + 1)
        begin
          seed_mem_rd_addr = i;
          # 10;
          $fwrite(f, "%x\n", seed_out);
        end
      $fclose(f);
      seed_mem_rd_en = 1'b0;
      $finish;
      
    end
  
  always
    #5 clk = !clk;
  
endmodule

 