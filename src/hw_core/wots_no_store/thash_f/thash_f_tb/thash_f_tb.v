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

module thash_f_tb;
  
  // inputs
  reg clk = 1'b0;
  reg start = 1'b0;
  reg reset = 1'b0;
  reg [`KEY_LEN-1:0] input_key = 0;
  reg [`KEY_LEN-1:0] input_data = 0;
  reg [255:0] hash_addr = 0;
  
  
  // outputs
  wire [255:0] hash_addr_updated;
  wire [`KEY_LEN-1:0] data_out; 
  wire busy;
  wire done;
  
	wire hash_done;
  wire [`KEY_LEN-1:0] hash_data_out; 
	wire hash_start;
  wire [1023:0] hash_data_in;
  wire message_length;
  wire hash_second_start;
  wire continue_intermediate;
  wire store_intermediate;
   
  wire sha256_plain_start;
  wire sha256_plain_init_message;
  wire [511:0] sha256_plain_data_in;
  wire sha256_plain_init_iv;
    // outputs
  wire [255:0] sha256_plain_data_out;
  wire sha256_plain_data_out_valid;
  wire sha256_plain_done;
  wire sha256_plain_busy;
  
  thash_f #(.XMSS_HASH_PADDING_F(`XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(`XMSS_HASH_PADDING_PRF), .KEY_LEN(`KEY_LEN)) DUT (
    .clk(clk),
    .start(start),
    .reset(reset),
    .input_key(input_key),
    .input_data(input_data),
    .hash_addr(hash_addr),
    .data_out(data_out),
    .busy(busy),
    .done(done),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(hash_start),
    .hash_data_in(hash_data_in),
    .message_length(message_length) 
  );
  
  sha256XMSS sha256_inst (
    .clk(clk),
    .reset(reset),
    .start(hash_start),
    .data_in(hash_data_in),
    .message_length(message_length),
    .init_iv(1'b0),
    .second_block_data_available(1'b1),  
    .data_out(hash_data_out),
    .store_intermediate(1'b0),
    .continue_intermediate(1'b0),
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
      $dumpfile("thash_f_tb.vcd");
      $dumpvars(0, thash_f_tb);
    end
  
  integer scan_file;
  
  initial
    begin
      scan_file = $fscanf(STDIN, "%b\n", input_key);
      scan_file = $fscanf(STDIN, "%b\n", input_data);
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
      // write output data
      f = $fopen("test.out", "w");
      $fwrite(f, "%x\n", data_out);
      $fdisplay(STDERR, "\nruntime: %0d cycles\n", (end_time-start_time)/10);
       
      # 2000;
      $fclose(f);
       
      $finish;
      
    end
  
  always
    #5 clk = !clk;
  
endmodule

 