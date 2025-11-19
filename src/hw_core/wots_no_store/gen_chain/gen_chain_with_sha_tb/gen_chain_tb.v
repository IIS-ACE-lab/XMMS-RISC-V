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

module gen_chain_tb;
  
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
  
  gen_chain_with_sha #(.WOTS_W(`WOTS_W), .XMSS_HASH_PADDING_F(`XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(`XMSS_HASH_PADDING_PRF), .KEY_LEN(`KEY_LEN)) DUT (
    .clk(clk),
    .start(start),
    .reset(reset),
    .input_key(input_key),
    .input_data(input_data),
    .hash_addr(hash_addr),
    .start_step(0),
    .end_step(14),
    .data_out(data_out),
    .busy(busy),
    .done(done), 
	  .hash_addr_updated(hash_addr_updated) 
  );
   
   
  
  integer STDERR = 32'h8000_0002;
  integer STDIN  = 32'h8000_0000;
  
  initial
    begin
      $dumpfile("gen_chain_tb.vcd");
      $dumpvars(0, gen_chain_tb);
    end
  
  integer scan_file;
  
  initial
    begin
      input_key = 256'h2072a1a266f236c93b46dfa9ce868e792981d0d0a047817446cb7c58698fd233;
      input_data = 256'h66d0132b7513d81c2b76d87d21eb57b661bd28d0887cebac2072342ff461d6af;
      hash_addr = 256'd0;
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

      # 100;
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
       
      # 1000;
      $fclose(f);
        
      $finish;
      
    end
  
  always
    #5 clk = !clk;
  
endmodule

 