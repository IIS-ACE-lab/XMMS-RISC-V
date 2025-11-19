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


import hashlib
from hashlib import sha256 # use sha-256 as basic hash function
from utils import ull_to_bytes
from hash_address import *

# parameters/hardcode
XMSS_HASH_PADDING_F = 0
XMSS_HASH_PADDING_H = 1
XMSS_HASH_PADDING_PRF = 3

BYTE_LEN_n = 32 # n in the c code


# convert an address array(int) into a hex string
def addr_to_bytes(addr = []):
  addrHex = ''
  for i in range(8):
    addrHex += ull_to_bytes(addr[i], 4)
  return addrHex

# input and output are all hex strings 
def core_hash(message): 
  message_latin = message.decode("hex") 
  hexres = sha256(message_latin).hexdigest()  
  return hexres

# pseudorandom function, based on hash function, input and output are all hex strings 
def prf(inHex, keyHex):
  padding = ull_to_bytes(XMSS_HASH_PADDING_PRF, BYTE_LEN_n)
  inData = padding + keyHex + inHex   
   
  return core_hash(inData)

# F function, input and output are all hex strings
def thash_f(inHex, pub_seedHex, addr):
  padding= ull_to_bytes(XMSS_HASH_PADDING_F, BYTE_LEN_n) 
  addr = set_key_and_mask(0, addr)
  addr_as_bytes = addr_to_bytes(addr) 
  f_key = prf(addr_as_bytes, pub_seedHex)  
  addr = set_key_and_mask(1, addr)
  addr_as_bytes = addr_to_bytes(addr) 
  f_mask = prf(addr_as_bytes, pub_seedHex) 
  in_xor_mask = ('{:0%dx}' %(2*BYTE_LEN_n)).format(int(inHex, 16) ^ int(f_mask, 16)) 
  inData = padding + f_key + in_xor_mask
  return core_hash(inData)

def thash_h(inHex, pub_seedHex, addr):
  padding= ull_to_bytes(XMSS_HASH_PADDING_H, BYTE_LEN_n) 
  addr = set_key_and_mask(0, addr)
  addr_as_bytes = addr_to_bytes(addr)
  
  h_key = prf(addr_as_bytes, pub_seedHex) 
    
  addr = set_key_and_mask(1, addr)
  addr_as_bytes = addr_to_bytes(addr)
   
  h_mask_1 = prf(addr_as_bytes, pub_seedHex)
  
    
  addr = set_key_and_mask(2, addr)
  addr_as_bytes = addr_to_bytes(addr)
 
  h_mask_2 = prf(addr_as_bytes, pub_seedHex) 
  
  h_mask = h_mask_1 + h_mask_2
   
  in_xor_mask = ('{:0%dx}' %(4*BYTE_LEN_n)).format(int(inHex, 16) ^ int(h_mask, 16))
   
  inData = padding + h_key + in_xor_mask
   
  return core_hash(inData)

####################################################################
#testing

#addr = [0, 0, 0, 0, 0, 0, 0, 0]
#inHex = 'ff'*32
#pub_seedHex = '35'*32
#print 'Computation for F in hex:' 
#print thash_f(inHex, pub_seedHex, addr)

