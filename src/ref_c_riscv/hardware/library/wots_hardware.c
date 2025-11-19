/*
 * Function: bridge module
 *
 * Copyright (C) 2019
 * Authors: Wen Wang <wen.wang.ww349@yale.edu> 
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <wots_hardware.h>
#include <murax.h>
#include <sys/stat.h>

volatile uint32_t *ctrl_wots = (uint32_t*)0xf0030000;
 
/**
 * \brief          This function communicates with the wots hardware core.
 * \input          start, sec_seed, pub_seed and hash_addr
 * \return         leaf_value, hash_addr
**/
   
int wots_hardware( unsigned char *sec_seed,
                   const unsigned char *pub_seed,
                    unsigned char *hash_addr,
                    unsigned char *leaf)
{
	int i;
	unsigned char cmd_leaf = 4;
	
	// send input data to hw core
	volatile uint32_t *data = &ctrl_wots[DATA_BIT];

  // reset gen_leaf module
  ctrl_wots[CONTROL_BIT] = (RESET << 15);
   
	  // send sec_seed to hw core
	for (i = 0; i < 8; i++)
    data[i] = ((uint32_t*)sec_seed)[i];
		 
	  // send pub_seed to hw core
	for (i = 0; i < 8; i++)
		data[i+8] = ((uint32_t*)pub_seed)[i];
     
	  // send hash address to hw core, note in hw: address = addr[0] || addr[1] ... || addr[7]
	for (i = 0; i < 8; i++)
		data[i+16] = ((uint32_t*)hash_addr)[i];
	
	// trigger start for gen_leaf module
  ctrl_wots[CONTROL_BIT] = ((cmd_leaf << 8) | (START << 16));
	
	// hw core running/busy
	while (ctrl_wots[CONTROL_BIT] & BUSY == 1);
	
	// return output from hw core
	  // return leaf_out
	for (i = 0; i < 8; i++)
	  ((uint32_t*)leaf)[i] = ctrl_wots[i+4];
     

	return 0;
}

