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


from hash import *
from utils import *
from hash_address import *
from wots_function import *
import random
from random import randint
import math

# seed for random() function
s = 123

random.seed(s)

BYTE_LEN_n = 32
wots_w = 16 # Winternitz parameter
wots_log_w = 4
wots_len1 = (8*BYTE_LEN_n/wots_log_w)
wots_len2 = 3
wots_len = wots_len1 + wots_len2
wots_sig_bytes = wots_len*BYTE_LEN_n
 
  
f = open("seed.in", "r")
seed = f.readline()
f.close()

f = open("pub_seed.in", "r")
pub_seed = f.readline()
f.close()

f = open("msg.in", "r")
msg = f.readline()
f.close()

f = open("addr.in", "r")
addr = []
l_tree_addr = []
for i in range(8):
  addr.append(int(f.readline()))
f.close()

for i in range(8):
  l_tree_addr.append(addr[i])

# set type
addr[3] = 0
l_tree_addr[3] = 1

print("Results from Python:\n")

print "check wots params:"
print "------wots_w = %d" %wots_w
print "------n = %d" %BYTE_LEN_n
print "------wots_len1 = %d" %wots_len1
print "------wots_len2 = %d" %wots_len2
print "------wots_len = %d\n" %wots_len

 
wots_seed = get_seed(seed, addr)
(pk_gen, addr_pk) = wots_pkgen(wots_w, wots_len, wots_seed, pub_seed, addr)
 
pk_l_tree = []

for i in range(wots_len):
  pk_l_tree.append(pk_gen[i])
  
# compute l_tree hashing
leaf = l_tree(pk_l_tree, pub_seed, l_tree_addr)

print("\n  ----------------------------------------------");
print "  computing leaf by use of l_tree..."
print "  leaf = {0:064x}".format(int(leaf, 16))
print("  ----------------------------------------------\n");
  
print "signing...\n"
signature = wots_sign(wots_w, msg, seed, pub_seed, addr)
 
print "verifying...\n"
pk_from_verification = wots_pk_from_sig(wots_w, msg, pub_seed, addr, signature)

print "testing result:"
if (pk_gen == pk_from_verification):
  print "  python result: wots testing (key gen, sign, and verify) passed!"
else:
  print "  wots testing fails."
  
f = open("pk_py.out", "w")
for i in range(wots_len):
  f.write(pk_gen[i])
f.close()

f = open("sig_py.out", "w")
for i in range(wots_len):
  f.write(signature[i])
f.close()




