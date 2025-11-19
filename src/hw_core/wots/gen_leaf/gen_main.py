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
parser.add_argument('-w', '--wots_w', dest='wots_w', type=int, default=16, required=True,
          help='winternitz parameter')
parser.add_argument('-l', '--wots_len', dest='wots_len', type=int, default=40, required=True,
          help='wots length')
parser.add_argument('-k', dest='key_len', type=int, required= False, default=256,
          help='key_len')
 
args = parser.parse_args()

WOTS_W = args.wots_w

WOTS_LEN = args.wots_len

KEY_LEN = args.key_len

 
print """module main
#(
  parameter WOTS_W = {WOTS_W},
  parameter WOTS_LEN = {WOTS_LEN},
  parameter XMSS_HASH_PADDING_F = 0,
  parameter XMSS_HASH_PADDING_H = 1,
  parameter XMSS_HASH_PADDING_PRF = 3,
  parameter KEY_LEN = {KEY_LEN},
  parameter WOTS_LOG_W = `CLOG2(WOTS_W)
)
(
	  input wire clk, // clock
    input wire start, // start signal, one clock high signal
    input wire reset, // reset signal, comes before start signal
    input wire [KEY_LEN-1:0] sec_seed, // secret initial seed for seed expansion
    input wire [KEY_LEN-1:0] pub_seed, // public seed, stay unchanged
    input wire [255:0] hash_addr, // initial hash address
    
    output wire busy,
    output wire done, // one clock high signal
    output wire [KEY_LEN-1:0] leaf_out, // hashing root value
    output wire [255:0] hash_addr_out // updated hash address
);

  // interface to Chain
  wire gen_chain_start;
  wire [KEY_LEN-1:0] gen_chain_input_key;
  wire [KEY_LEN-1:0] gen_chain_input_data;
  wire [WOTS_LOG_W-1:0] gen_chain_start_step;
  wire [WOTS_LOG_W-1:0] gen_chain_end_step;
  wire [255:0] gen_chain_hash_addr;

  wire [KEY_LEN-1:0] gen_chain_data_out;
  wire gen_chain_done;
  wire gen_chain_busy;
  wire [255:0] gen_chain_hash_addr_updated;

  wire gen_chain_hash_start;
  wire [1023:0] gen_chain_hash_data_in;
  wire gen_chain_message_length;
  wire gen_chain_continue_intermediate;
  wire gen_chain_store_intermediate;

  // interface to sha
  wire hash_done;
  wire [KEY_LEN-1:0] hash_data_out; 
  wire hash_start;
  wire [1023:0] hash_data_in;
  wire message_length;
  wire store_intermediate;
  wire continue_intermediate;
  
  // interface to sha256_plain module
  // inputs
  wire sha256_plain_start;
  wire sha256_plain_init_message;
  wire [511:0] sha256_plain_data_in;
  wire sha256_plain_init_iv;
    // outputs
  wire [255:0] sha256_plain_data_out;
  wire sha256_plain_data_out_valid;
  wire sha256_plain_done;
  wire sha256_plain_busy;

gen_leaf #(.WOTS_W(WOTS_W), .WOTS_LEN(WOTS_LEN), .XMSS_HASH_PADDING_H(XMSS_HASH_PADDING_H), .XMSS_HASH_PADDING_F(XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) gen_leaf_inst (
    .clk(clk),
    .start(start),
    .reset(reset),
    .sec_seed(sec_seed),
    .pub_seed(pub_seed),
    .hash_addr(hash_addr),
    .leaf_out(leaf_out),
    .done(done),
    .hash_addr_out(hash_addr_out),
    .busy(busy),
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
    .gen_chain_store_intermediate(gen_chain_store_intermediate),
    .hash_done(hash_done),
    .hash_data_out(hash_data_out),
    .hash_start(hash_start),
    .hash_data_in(hash_data_in),
    .message_length(message_length),
    .store_intermediate(store_intermediate),
    .continue_intermediate(continue_intermediate) 
  );

  gen_chain #(.WOTS_W(WOTS_W), .XMSS_HASH_PADDING_F(XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) gen_chain_inst (
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

  sha256XMSS sha256_inst (
    .clk(clk),
    .reset(reset),
    .start(hash_start),
    .data_in(hash_data_in),
    .message_length(message_length),
    .store_intermediate(store_intermediate),
    .continue_intermediate(continue_intermediate), 
    .data_out(hash_data_out),
    .data_out_valid(),
    .done(hash_done),
    .second_block_data_available(1'b1),
    .init_iv(1'b0),
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

endmodule
""".format(WOTS_W=WOTS_W, WOTS_LEN=WOTS_LEN, KEY_LEN=KEY_LEN)

