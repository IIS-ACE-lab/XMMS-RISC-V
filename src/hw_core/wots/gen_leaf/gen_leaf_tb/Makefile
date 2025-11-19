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

SHELL := /bin/bash
all: run

WOTS_W = 16
WOTS_LEN = 67

XMSS_HASH_PADDING_F = 0
XMSS_HASH_PADDING_H = 1
XMSS_HASH_PADDING_PRF = 3
KEY_LEN = 256

s = 123

SRC = src

include ../gen.mk

data.in: gen_test.py
	python gen_test.py -w $(WOTS_W) -n $(WOTS_LEN) -s $(s) -l $(KEY_LEN) 

data.out: data.in

pk_data.out: data.out

$(SRC)/gen_leaf_tb.v: gen_gen_leaf_tb.py
	python gen_gen_leaf_tb.py -k $(KEY_LEN) > $(SRC)/gen_leaf_tb.v 

gen_leaf_tb: $(SRC)/clog2.v $(SRC)/main.v $(SRC)/gen_leaf_tb.v $(SRC)/delay.v $(SRC)/mem_dual.v $(SRC)/gen_leaf.v $(SRC)/thash_h.v $(SRC)/gen_pk.v $(SRC)/l_tree.v $(SRC)/gen_chain.v $(SRC)/seed_expand.v $(SRC)/thash_f.v $(SRC)/sha256XMSSprecomp.v $(SRC)/sha256.v
	iverilog -Wall -Wno-timescale $^ -o gen_leaf_tb

test_2.out: gen_leaf_tb  
	./gen_leaf_tb  

run: data.out test_2.out
	@diff data.out test.out && echo "Test Passed!"

clean:
	rm -f *.in *.out *.vcd gen_leaf_tb

