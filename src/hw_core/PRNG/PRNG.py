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

import numpy as np
import sys

def XorShift64(init, previous):
  if (int(init) == 1):
	return np.uint64(previous)
  else:
    x = np.uint64(previous)
    x ^= x << np.uint64(21)
    x ^= x >> np.uint64(35)
    x ^= x << np.uint64(4)
    return np.uint64(x)


  
	