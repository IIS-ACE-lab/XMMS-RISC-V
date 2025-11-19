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

CFLAGS += -DCHAIN_HARDWARE
CFLAGS += -DSHA256XMSS_HARDWARE
CFLAGS += -DMBEDTLS
CFLAGS += -DSW_PRECOMP -DSW_FIXED_INLEN
 
INC += -I../ref_c_riscv/hardware/include/
INC += -I../mbedtls-2.8.0/include/

SOURCES += ../ref_c_riscv/hardware/library/chain_hardware.c
SOURCES += ../ref_c_riscv/hardware/library/sha256_store_hardware.c
SOURCES += ../mbedtls-2.8.0/library/sha256.c

