#
# Copyright (C) 2019
# Authors: Wen Wang <wen.wang.ww349@yale.edu> 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import sys

import argparse

parser = argparse.ArgumentParser(description='Generate toplevel main module.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)
 
parser.add_argument('-k', dest='key_len', type=int, required= False, default=256,
          help='key_len')
 
args = parser.parse_args()
  
KEY_LEN = args.key_len

print '''

`timescale 1ns / 1ps

module gen_leaf_tb;
  
  // inputs
  reg clk = 1'b0;
  reg start = 1'b0;
  reg reset = 1'b0;
  reg [{KEY_LEN}-1:0] sec_seed = 0;
  reg [{KEY_LEN}-1:0] pub_seed = 0;
  reg [255:0] hash_addr = 0;
  
  // outputs
  wire [{KEY_LEN}-1:0] leaf_out;
  wire done;
  
  main DUT (
    .clk(clk),
    .start(start),
    .reset(reset),
    .sec_seed(sec_seed),
    .pub_seed(pub_seed),
    .hash_addr(hash_addr),
    .leaf_out(leaf_out),
    .done(done) 
  );
   
  initial
    begin
      $dumpfile("gen_leaf_tb.vcd");
      $dumpvars(0, gen_leaf_tb);
    end
  
  
  initial
    begin
	  sec_seed  <= 256'h1c349f208e70b458958c754e2adc32f1828f5c7379e39b8239f972a0d05eeb5f;
	  pub_seed  <= 256'h2072a1a266f236c93b46dfa9ce868e792981d0d0a047817446cb7c58698fd233;
	  hash_addr <= 256'h0000000000000000000000000000000000000001000000000000000000000000;
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
      $display("\\nruntime: %0d cycles\\n", (end_time-start_time)/10);
      
      // write output data
      f = $fopen("test.out", "w");
       
      $fwrite(f, "%x\\n", leaf_out);
       
      # 1000;
      
      $fclose(f);
      
      // start over!
      
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
      $display("\\nruntime: %0d cycles\\n", (end_time-start_time)/10);
      
      // write output data
      f = $fopen("test_2.out", "w");
       
      $fwrite(f, "%x\\n", leaf_out);
       
      # 1000;
      
      $fclose(f);
       
      $finish;
      
    end
  
  always
    #5 clk = !clk;
  
endmodule
'''.format(KEY_LEN=KEY_LEN)
 
