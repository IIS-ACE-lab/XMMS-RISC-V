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

parser = argparse.ArgumentParser(description='Generate input polynomials.',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-n', '--seed_num', dest='n', type=int, required= True,
          help='number of outputs')
parser.add_argument('-s', '--seed', dest='seed', type=int, required=False, default=None,
          help='seed')
parser.add_argument('-l', '--key_len', dest='key_len', type=int, required=True, default=None,
          help='key length')

args = parser.parse_args()

seed_num = args.n
key_len = args.key_len

if args.seed:
  random.seed(args.seed)
  
f = open("data.in", "w")

# generate random input key
input_key = ""
for i in range(key_len/8):
  randbyte = random.randint(0, 255)
  f.write("{0:08b}".format(randbyte))
  input_key += ("{0:02x}".format(randbyte))

f.write("\n")
f.close()

# added for testing purpose
f = open("key.out", "w")
f.write(input_key)
f.close()
#
hex_seed = expand_seed(input_key, seed_num)

#print hex_seed # an array

f = open("data.out", "w")
for i in range(seed_num):
  f.write("{0:064x}".format(int(hex_seed[i], 16)))
  f.write('\n')
   
f.close()



  