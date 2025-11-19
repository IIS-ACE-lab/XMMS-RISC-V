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

XMSS_HASH_PADDING_H = 1
XMSS_HASH_PADDING_PRF = 3
KEY_LEN = 256
s = 123

data.in: gen_test.py
	python gen_test.py -s $(s) -l $(KEY_LEN) 

data.out: data.in

thash_h_tb: ../../../util/clog2.v thash_h_tb.v ../thash_h.v ../../../hash/sha256XMSSprecomp.v ../../../hash/sha256.v
	iverilog -Wall -DXMSS_HASH_PADDING_H=$(XMSS_HASH_PADDING_H) -DXMSS_HASH_PADDING_PRF=$(XMSS_HASH_PADDING_PRF) -DKEY_LEN=$(KEY_LEN) -Wno-timescale $^ -o thash_h_tb

test.out: thash_h_tb data.in
	./thash_h_tb < data.in 

run: data.out test.out
	@diff data.out test.out && echo "Test Passed!"

clean:
	rm -f *.in *.out *.vcd thash_h_tb

