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
#include <sha256_store_hardware.h>

#include <sys/stat.h>

volatile uint32_t *ctrl_sha256_store = (uint32_t*)0xf0030000;

/**
 * \brief          This function communicates with the sha256 hardware core(with store functionality).
 * \input          data_in, message_length, store_intermediate, continue_intermediate 
 * \return         data_out
**/

int sha256_store_hardware(const unsigned char *data_in, //1024-bits  
                          unsigned char message_length, //1 or 0
                          unsigned char store_intermediate, // 1 or 0
                          unsigned char continue_intermediate, // 1 or 0
                          unsigned char *data_out)
{
  int i;
  
  // send input data (1024-bits) to hw core
  volatile uint32_t *data = &ctrl_sha256_store[DATA_BIT];
  unsigned char cmd_sha256xmss = 2; 

  if (continue_intermediate) 
  { 
    for (i=16; i<(message_length?32:24); i++)
      data[i] = ((uint32_t*)data_in)[i];
    
    // set message_length, store_intermediate, continue_intermediate and
    // trigger start, they should be of one-clock high at the same clock cycle
    // ctrl_sha256_store[CONTROL_BIT] = (message_length << 24) | (store_intermediate << 16) | (continue_intermediate << 8) | START;
    ctrl_sha256_store[CONTROL_BIT] = ((cmd_sha256xmss << 8) | (message_length << 7) | (store_intermediate << 4) | (continue_intermediate << 5) | START);
  }
    
  else
  {
    // send the first hash block
    for (i=0; i<16; i++)
      data[i] = ((uint32_t*)data_in)[i];

    // set message_length, store_intermediate, continue_intermediate and
    // trigger start, they should be of one-clock high at the same clock cycle
     
    // ctrl_sha256_store[CONTROL_BIT] = (message_length << 24) | (store_intermediate << 16) | (continue_intermediate << 8) | START;
    ctrl_sha256_store[CONTROL_BIT] = ((cmd_sha256xmss << 8) | message_length << 7) | (store_intermediate << 4) | (continue_intermediate << 5) | START;
    
    if (store_intermediate == 0)
    {
      // send the rest of the data
      for (i=16; i<(message_length?32:24); i++)
        data[i] = ((uint32_t*)data_in)[i];
    }
  }  
   
  // hw core busy/running
  while (ctrl_sha256_store[CONTROL_BIT] & BUSY == 1);
  
  //return output value
  if (store_intermediate == 0)
  {
    for (i=0; i<8; i++)
      ((uint32_t*)data_out)[i] = ctrl_sha256_store[i+DATA_BIT]; 
  }
}
