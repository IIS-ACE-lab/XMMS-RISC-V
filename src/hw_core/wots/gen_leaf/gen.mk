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

gen: $(SRC)/main.v gen_cp

gen_cp: $(SRC)/clog2.v $(SRC)/delay.v $(SRC)/mem_dual.v $(SRC)/gen_leaf.v $(SRC)/thash_h.v $(SRC)/gen_pk.v $(SRC)/l_tree.v $(SRC)/gen_chain.v $(SRC)/seed_expand.v $(SRC)/thash_f.v $(SRC)/sha256XMSSprecomp.v $(SRC)/sha256.v

$(SRC)/main.v: ../gen_main.py
	python ../gen_main.py -w $(WOTS_W) -l $(WOTS_LEN) -k $(KEY_LEN) > $(SRC)/main.v

$(SRC)/clog2.v: ../../../util/clog2.v
	cp ../../../util/clog2.v $(SRC)/

$(SRC)/delay.v: ../../../util/delay.v 
	cp ../../../util/delay.v $(SRC)/

$(SRC)/mem_dual.v: ../../../util/mem_dual.v
	cp ../../../util/mem_dual.v $(SRC)/

$(SRC)/gen_leaf.v: ../gen_leaf.v
	cp ../gen_leaf.v $(SRC)/

$(SRC)/thash_h.v: ../../thash_h/thash_h.v
	cp ../../thash_h/thash_h.v $(SRC)/

$(SRC)/gen_pk.v: ../../gen_pk/gen_pk.v
	cp ../../gen_pk/gen_pk.v $(SRC)/

$(SRC)/l_tree.v: ../../l_tree/l_tree.v
	cp ../../l_tree/l_tree.v $(SRC)/

$(SRC)/gen_chain.v: ../../gen_chain/gen_chain.v
	cp ../../gen_chain/gen_chain.v $(SRC)/

$(SRC)/seed_expand.v: ../../seed_expand/seed_expand.v
	cp ../../seed_expand/seed_expand.v $(SRC)/

$(SRC)/thash_f.v: ../../thash_f/thash_f.v
	cp ../../thash_f/thash_f.v $(SRC)/

$(SRC)/sha256XMSSprecomp.v: ../../../hash/sha256XMSSprecomp.v
	cp ../../../hash/sha256XMSSprecomp.v $(SRC)/

$(SRC)/sha256.v: ../../../hash/sha256.v
	cp ../../../hash/sha256.v $(SRC)/

gen_clean:
	rm -f $(SRC)/*.v
