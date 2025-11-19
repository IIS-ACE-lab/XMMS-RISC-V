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
'''
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
'''

sec_key = "1c349f208e70b458958c754e2adc32f1828f5c7379e39b8239f972a0d05eeb5f"
pub_key = "2072a1a266f236c93b46dfa9ce868e792981d0d0a047817446cb7c58698fd233"
pk_addr = []
l_tree_addr = []

for i in range(8):
	pk_addr.append(0)
	l_tree_addr.append(0) 
pk_addr[4] = 1
l_tree_addr[4] = 1

f.write("\n")
f.close()
 
# computation  
# compute public keys
pk_addr[3] = 0
(pk, addr_pk) = wots_pkgen(wots_w, wots_len, sec_key, pub_key, pk_addr)

f = open("pk_data.out", "w")
for i in range(wots_len):
  f.write("{0:0256b}".format(int(pk[i], 16)))
  f.write('\n')
f.close()

'''
for i in range(8):
  print addr_pk[i]
  print l_tree_addr[i]
'''

# compute l_tree hashing

pk_l_tree = []

for i in range(wots_len):
  pk_l_tree.append(pk[i])

l_tree_addr[3] = 1
leaf = l_tree(pk_l_tree, pub_key, l_tree_addr)

print "{0:064x}".format(int(leaf, 16))
 
# write results back
f = open("data.out", "w")
f.write("{0:064x}".format(int(leaf, 16)))
f.write('\n')
f.close()


  
