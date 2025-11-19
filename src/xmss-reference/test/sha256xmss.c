/*
 *  
 *
 * Copyright (C) 2019
 * Authors: Wen Wang <wen.wang.ww349@yale.edu>
 *          Ruben Niederhagen <ruben@polycephaly.org>
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

#include <stdint.h>
#include <string.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <inttypes.h>

 
#include "../hash.c"
#include "Murax.h"

int main()
{
  SHA256_CTX prf;
  SHA256_CTX ctx;

  #define LOAD_IV 4
  #define CONTROL_BIT 1

  uint8_t out[32];

  uint64_t t0;

	uint8_t data[128] = {0x3, 0xDA, 0x40, 0x57, 0x48, 0x5F, 0x96, 0x51, 0xA3, 0xB8, 0x6, 0xA3, 0xA3, 0xFE, 0x5A, 0x38, 0xBC, 0x87, 0x2C, 0x17, 0xE9, 0x75, 0x47, 0xE3, 0xDD, 0x3B, 0xDD, 0xD9, 0xF5, 0x3B, 0xF2, 0xCB, 0x9C, 0xAF, 0x73, 0xB2, 0x70, 0x88, 0xB4, 0xCB, 0x55, 0x7E, 0xC6, 0x48, 0xCC, 0x54, 0x76, 0xA5, 0xAD, 0x35, 0x97, 0xB4, 0x88, 0xBD, 0x58, 0x4, 0xB4, 0xE4, 0xBF, 0x8B, 0x43, 0x20, 0xB0, 0x53, 0xD, 0xC8, 0x4F, 0xAE, 0xB1, 0xA5, 0x4A, 0xB2, 0x32, 0x34, 0xAC, 0x40, 0x1B, 0x37, 0x8B, 0x95, 0xD7, 0x58, 0x71, 0x8D, 0xF9, 0x16, 0x93, 0x12, 0x8F, 0xC, 0x14, 0xCD, 0xE8, 0x42, 0xFE, 0x6D, 0x47, 0xBC, 0x62, 0xF3, 0x1F, 0x80, 0x74, 0x34, 0x5E, 0x5D, 0x83, 0x50, 0x6, 0x7F, 0x8, 0x7, 0x79, 0xF3, 0x53, 0xEE, 0x80, 0x27, 0x7C, 0x65, 0x96, 0x19, 0xBF, 0xB0, 0x43, 0x65, 0x5A, 0x5A};
  
  t0 = -cpucycles();

  sha256_store_hardware(data, 0, 0, 0, out);

  t0 += cpucycles(); 

  printf("\n sha256xmss msg=768 bits without SW_PRECOMP, cycles = %" PRIu64 "\n", t0);

  //

  sha256_store_hardware(data, 0, 1, 0, out);

  hash_store(&prf);

  t0 = -cpucycles();

  volatile uint32_t *hw_ctrl = (uint32_t*)0xf0030000;
  // write data to SHA256/SHA256XMSS module
  for (int i = 0; i < 8; i++)
    hw_ctrl[i+4] = ((uint32_t*)((&prf))->buffer)[7-i];

  // set IV
  hw_ctrl[CONTROL_BIT] = LOAD_IV;

  //hash_restore(&prf, &ctx);

  sha256_store_hardware(data, 0, 0, 1, out);

  t0 += cpucycles(); 

  printf("\n sha256xmss msg=768 bits, cycles = %" PRIu64 "\n", t0);

  t0 = -cpucycles();

  sha256_store_hardware(data, 1, 0, 0, out);

  t0 += cpucycles(); 

  printf("\n sha256xmss msg=1024 bits, cycles = %" PRIu64 "\n", t0);

}