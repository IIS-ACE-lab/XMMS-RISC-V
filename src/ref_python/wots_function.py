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
 

def expand_seed(inseed, num):
	outseed = []
	for i in range(num):
		outseed.append(prf(ull_to_bytes(i, 32), inseed))
	return outseed

def get_seed(sk_seed, addr = []):
  addr = set_chain_addr(0, addr)
  addr = set_hash_addr(0, addr)
  addr = set_key_and_mask(0, addr)
  addr_as_bytes = addr_to_bytes(addr)
  wots_seed = prf(addr_as_bytes, sk_seed)
  return wots_seed

#inseed = '9f'*32

#print expand_seed(inseed, 6)

# compute the chaining function
def gen_chain(w, inHex, start, steps, pub_seed, addr = []): 
  for i in range(start, min(start+steps, w)):
    addr = set_hash_addr(i, addr)
    inHex = thash_f(inHex, pub_seed, addr)   
  return inHex

#input: hex string
#output: array of base w representation
def base_w(inHex, outlen):
  bits = 0
  incount = 0
  outcount = 0
  outInt = []
  for i in range(0, outlen):
    if (bits == 0):
      total = int(inHex[0:2], 16)
      inHex = inHex[2:]
      incount += 1
      bits += 8
    bits -= wots_log_w
    #print outInt
    outInt.append((total >> bits) & (wots_w-1)) 
    outcount += 1
  return outInt
   
# compute the checksum 
# input: message in base w
# output: checksum in base w
def wots_checksum(msg_base_w = []):
  csum_bytes_len = int((wots_len2*wots_log_w + 7)/8)
  # compute checksum as integer
  csum = 0
  for i in range(wots_len1):
    csum += (wots_w -1 - msg_base_w[i])
  csum = csum << (8 - (wots_len2*wots_log_w) % 8)
  csum_bytes = ull_to_bytes(csum, csum_bytes_len)
  csum_base_w = base_w(csum_bytes, wots_len2)
  return csum_base_w

# derive the chain length
# input: message in Hex
# output: chain lengths array
def chain_lengths(msg):
  msglengths = base_w(msg, wots_len1)
  csumlengths = wots_checksum(msglengths)
  lengths = msglengths + csumlengths
  return lengths

# public key generation
# input: hex format of seed(for seed expanding, sk) and pub_seed(for thash_f->prf)
# output: pk
def wots_pkgen(w, w_len, seedHex, pub_seedHex, addr):
  outseed = expand_seed(seedHex, w_len)
  #print outseed
  pk = []
  for i in range(w_len):
    addr = set_chain_addr(i, addr)
    pk.append(gen_chain(w, outseed[i], 0, w-1, pub_seedHex, addr))
  return pk, addr
  
# L_tree
# input: pk list, public seed, hash addr
# output: leaf value
def l_tree(pk, pub_seedHex, addr):
  l = len(pk)
  height = 0
  addr = set_tree_height(height, addr)
  while (l > 1):
    parent_nodes = l >> 1
    for i in range(parent_nodes):
      addr = set_tree_index(i, addr)
      #print 'addr = ', addr
      #print 'inData = ', pk[2*i]+pk[2*i+1]
      pk[i] = thash_h(pk[2*i]+pk[2*i+1], pub_seedHex, addr)
      #print 'res = ', i, pk[i]
      #print '\n'
    if (l & 1):
        pk[l >> 1] = pk[l-1]
        l = (l >> 1) + 1
    else:
        l = l >> 1
    height += 1
    addr = set_tree_height(height, addr)
  return pk[0]

# signing
# input: message, seed, pub_seed, hash address
# output: signature hex
def wots_sign(w, msg, seedHex, pub_seedHex, addr):
  lengths = chain_lengths(msg)
  #print lengths
  outseed = expand_seed(seedHex, wots_len)
  sig = []
  for i in range(wots_len):
    addr = set_chain_addr(i, addr)
    sig.append(gen_chain(w, outseed[i], 0, lengths[i], pub_seedHex, addr))
  return sig

# verification
# input: pk, signature, message
# output: verification result
def wots_pk_from_sig(w, msg, pub_seed, addr = [], signature = []):
  lengths = chain_lengths(msg)
  pk_from_ver = []
  for i in range(wots_len):
    addr = set_chain_addr(i, addr)
    pk_from_ver.append(gen_chain(w, signature[i], lengths[i], w-1-lengths[i], pub_seed, addr))
  return pk_from_ver


# generate random byte strings in hex format
def randhex(byte_len):
  hexout = ''
  for i in range(byte_len):
    byte = randint(0, math.pow(2, 8)-1)
    hexout += "{:02x}".format(byte)
  return hexout