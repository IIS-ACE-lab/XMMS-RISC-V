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

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>

#include "../xmss_commons.h"
#include "../randombytes.h"
#include "../params.h"
#include <Murax.h>

int main()
{
    xmss_params params;
    // TODO test more different OIDs
    uint32_t oid = 0x00000001;

    /* For WOTS it doesn't matter if we use XMSS or XMSSMT. */
    xmss_parse_oid(&params, oid);

    unsigned char seed[params.n];
    unsigned char pub_seed[params.n];
    unsigned char leaf[params.n];

    uint32_t ots_addr[8] = {0};
    uint32_t ltree_addr[8] = {0};
    uint32_t idx = 1;

    ots_addr[3] = 0;
    ltree_addr[3] = 1;
    ots_addr[4] = idx;
    ltree_addr[4] = idx;

    randombytes(seed, params.n);
    randombytes(pub_seed, params.n);
    //randombytes((unsigned char *)addr, 8 * sizeof(uint32_t));

    printf("\nTesting Leaf PK derivation...\n");
    
    #ifndef x86
      uint64_t t0 = -cpucycles();
    #endif

    gen_leaf_wots(&params, leaf, seed, pub_seed, ltree_addr, ots_addr);
    
    #ifndef x86
      t0 += cpucycles();
    #endif

    printf("Public Key: ");
    for (unsigned int j = 0; j < params.n; j++)
      printf("%02x", leaf[j]);
    printf("\n\n");
    
    #ifndef x86
      printf("\n------------PERFORMANCE------------\n\n");
      printf("cycles for leaf: %" PRIu64 "\n\n", t0);
    #endif
}
 
