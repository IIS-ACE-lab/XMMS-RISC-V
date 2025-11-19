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
start_step = 0
end_step = 14

XMSS_HASH_PADDING_F = 0
XMSS_HASH_PADDING_PRF = 3
KEY_LEN = 256

s = 123

data.in: gen_test.py
	python gen_test.py -i $(start_step) -e $(end_step) -s $(s) -l $(KEY_LEN) 

data.out: data.in

gen_chain_tb: ../../../util/clog2.v ../../../util/delay.v gen_chain_tb.v ../gen_chain.v ../gen_chain_with_sha.v ../../thash_f/thash_f.v ../../../hash/sha256XMSS.v ../../../hash/sha256XMSS_core.v ../../../hash/sha256.v  
	iverilog -Wall -DWOTS_W=$(WOTS_W) -Dstart_step=$(start_step) -Dend_step=$(end_step) -DXMSS_HASH_PADDING_F=$(XMSS_HASH_PADDING_F) -DXMSS_HASH_PADDING_PRF=$(XMSS_HASH_PADDING_PRF) -DKEY_LEN=$(KEY_LEN) -Wno-timescale $^ -o gen_chain_tb

test.out: gen_chain_tb data.in
	./gen_chain_tb < data.in 

run: data.out test.out
	@diff data.out test.out && echo "Test Passed!"

clean:
	rm -f *.in *.out *.vcd gen_chain_tb

