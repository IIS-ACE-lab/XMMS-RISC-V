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


def set_key_and_mask(key_and_mask, addr = []):
	addr[7] = key_and_mask
	return addr

def set_hash_addr(hash_in, addr = []):
  addr[6] = hash_in
  return addr

def set_chain_addr(chain_in, addr = []):
  addr[5] = chain_in
  return addr

# set addresses inside a L_tree
def set_tree_height(tree_height, addr = []):
  addr[5] = tree_height
  return addr

def set_tree_index(tree_index, addr = []):
  addr[6] = tree_index
  return addr