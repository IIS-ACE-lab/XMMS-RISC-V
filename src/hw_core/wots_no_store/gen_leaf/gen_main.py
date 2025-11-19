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
  parameter KEY_LEN = {KEY_LEN}
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
    output wire [255:0] hash_addr_out // updated hash address
);

gen_leaf #(.WOTS_W(WOTS_W), .WOTS_LEN(WOTS_LEN), .XMSS_HASH_PADDING_H(XMSS_HASH_PADDING_H), .XMSS_HASH_PADDING_F(XMSS_HASH_PADDING_F), .XMSS_HASH_PADDING_PRF(XMSS_HASH_PADDING_PRF), .KEY_LEN(KEY_LEN)) gen_leaf_inst (
    .clk(clk),
    .start(start),
    .reset(reset),
    .sec_seed(sec_seed),
    .pub_seed(pub_seed),
    .hash_addr(hash_addr),
    .leaf_out(leaf_out),
    .done(done),
    .hash_addr_out(hash_addr_out)
  );

endmodule
""".format(WOTS_W=WOTS_W, WOTS_LEN=WOTS_LEN, KEY_LEN=KEY_LEN)

