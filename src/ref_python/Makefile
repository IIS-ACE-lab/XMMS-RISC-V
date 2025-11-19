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

c_folder = ../ref_c/xmss-reference

SOURCES = $(c_folder)/wots.c $(c_folder)/randombytes.c $(c_folder)/params.c $(c_folder)/utils.c $(c_folder)/hash.c $(c_folder)/hash_address.c $(c_folder)/fips202.c $(c_folder)/xmss_core.c   
HEADERS = $(c_folder)/xmss_commons.h $(c_folder)/wots.h $(c_folder)/randombytes.h $(c_folder)/params.h $(c_folder)/utils.h $(c_folder)/hash.h $(c_folder)/hash_address.h $(c_folder)/fips202.h $(c_folder)/xmss_core.h  

xmss_leaf_test: xmss_leaf_test.c $(SOURCES) $(HEADERS)
	gcc -o xmss_leaf_test xmss_leaf_test.c $(SOURCES) -lssl -lcrypto

c_test: xmss_leaf_test
	./xmss_leaf_test 

py_test: wots.py hash.py hash_address.py utils.py
	@python wots.py

run: c_test py_test
	@diff pk_c.out pk_py.out && echo "  Python PK result matches C results."
#	@diff sig_c.out sig_py.out && echo "  Python signature result matches C results."

clean:
	rm -f *.pyc *.in *.out xmss_leaf_test
