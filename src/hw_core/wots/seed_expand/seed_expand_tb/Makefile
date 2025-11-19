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

seed_num = 67
XMSS_HASH_PADDING_PRF = 3
KEY_LEN = 256
s = 123

data.in: gen_test.py
	python gen_test.py -n $(seed_num) -s $(s) -l $(KEY_LEN) 

data.out: data.in

seed_expand_tb: ../../../util/clog2.v ../../../util/mem_dual.v seed_expand_tb.v ../seed_expand.v ../../../hash/sha256XMSSprecomp.v ../../../hash/sha256.v ../../../hash/sha256XMSS_core.v 
	iverilog -Wall -DSEED_NUM=$(seed_num) -DXMSS_HASH_PADDING_PRF=$(XMSS_HASH_PADDING_PRF) -DKEY_LEN=$(KEY_LEN) -Wno-timescale $^ -o seed_expand_tb

test.out: seed_expand_tb data.in
	./seed_expand_tb < data.in 

run: data.out test.out
	@diff data.out test.out && echo "Test Passed!"

clean:
	rm -f *.in *.out *.vcd seed_expand_tb

