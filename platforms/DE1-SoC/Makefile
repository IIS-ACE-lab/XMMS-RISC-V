#
# Copyright (C) 2019
# Authors: Ruben Niederhagen <ruben@polycephaly.org>
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

TARGETS = $(shell ls Murax*.qsf | sed "s/\.qsf//" | sed "s/_precomp/ PRECOMP=yes/" | sort  | paste -sd "," - | sed "s/,/, /g")

ifndef TARGET
  $(error $(TARGET) Choose TARGET from list "$(TARGETS)", eg. "make TARGET=MuraxChain PRECOMP=yes")
endif


ifdef PRECOMP
  PROJECT = $(TARGET)_precomp
else
  PROJECT = $(TARGET)
endif

TARGET_HW = MuraxHW

SOURCE_FILES = $(shell grep -v '\#' $(PROJECT).qsf | grep  "VERILOG_FILE\|TEXT_FILE" | cut -d " " -f 4)

include quartus.mk

include gen.mk

clean:
	make quartus_clean
	make gen_clean

