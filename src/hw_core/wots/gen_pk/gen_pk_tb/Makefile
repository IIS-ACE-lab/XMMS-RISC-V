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
XMSS_HASH_PADDING_PRF = 3
KEY_LEN = 256

s = 123

data.in: gen_test.py
	python gen_test.py -w $(WOTS_W) -n $(WOTS_LEN) -s $(s) -l $(KEY_LEN) 

data.out: data.in

gen_pk_tb: ../../../util/clog2.v ../../../util/mem_dual.v ../../../util/delay.v gen_pk_tb.v ../gen_pk.v ../../gen_chain/gen_chain.v ../../seed_expand/seed_expand.v ../../thash_f/thash_f.v ../../../hash/sha256XMSSprecomp.v ../../../hash/sha256XMSS_core.v ../../../hash/sha256.v  
	iverilog -Wall -DWOTS_W=$(WOTS_W) -DWOTS_LEN=$(WOTS_LEN) -DXMSS_HASH_PADDING_F=$(XMSS_HASH_PADDING_F) -DXMSS_HASH_PADDING_PRF=$(XMSS_HASH_PADDING_PRF) -DKEY_LEN=$(KEY_LEN) -Wno-timescale $^ -o gen_pk_tb

test.out: gen_pk_tb data.in
	./gen_pk_tb < data.in 

run: data.out test.out
	@diff data.out test.out && echo "Test Passed!"

clean:
	rm -f *.in *.out *.vcd gen_pk_tb

