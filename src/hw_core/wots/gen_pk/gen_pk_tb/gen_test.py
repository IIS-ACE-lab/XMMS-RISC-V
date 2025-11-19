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
import random

sys.path.insert(0, "../../../../ref_python")

from hash import *
from utils import *
from hash_address import *
from wots_function import *
 

import argparse

parser = argparse.ArgumentParser(description='Generate random inputs.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-w', '--wots_w', dest='wots_w', type=int, required=True, default=0,
          help='wots_w')
parser.add_argument('-n', '--wots_len', dest='wots_len', type=int, required=True, default=0,
          help='wots_len')
parser.add_argument('-s', '--seed', dest='seed', type=int, required=False, default=None,
          help='seed')
parser.add_argument('-l', '--key_len', dest='key_len', type=int, required=True, default=None,
          help='key length')

args = parser.parse_args()

wots_w = args.wots_w
wots_len = args.wots_len
key_len = args.key_len

if args.seed:
  random.seed(args.seed)
  
f = open("data.in", "w")

# generate random input secret key
sec_key = ""
for i in range(key_len/8):
  randbyte = random.randint(0, 255)
  f.write("{0:08b}".format(randbyte))
  sec_key += ("{0:02x}".format(randbyte))

f.write("\n")

# generate random input public key
pub_key = ""
for i in range(key_len/8):
  randbyte = random.randint(0, 255)
  f.write("{0:08b}".format(randbyte))
  pub_key += ("{0:02x}".format(randbyte))

f.write("\n")

# generate random addr array
# addr hex str = addr[0] + addr[1] + ... + addr[7]
addr = []
for i in range(8):
  randint = random.randint(0, 2**32-1)
  f.write("{0:032b}".format(randint))
  addr.append(randint)

f.write("\n")
f.close()

# computation gen_chain
(pk, addr) = wots_pkgen(wots_w, wots_len, sec_key, pub_key, addr)

# write results back
f = open("data.out", "w")
for i in range(wots_len):
  f.write("{0:064x}".format(int(pk[i], 16)))
  f.write('\n')
f.close()



  