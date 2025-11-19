/*
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
*/


#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <openssl/sha.h>

#include "../ref_c/xmss-reference/wots.h"
#include "../ref_c/xmss-reference/randombytes.h"
#include "../ref_c/xmss-reference/params.h"
#include "../ref_c/xmss-reference/hash.h"
#include "../ref_c/xmss-reference/hash_address.h"
#include "../ref_c/xmss-reference/xmss_commons.c"

#include "../ref_c/cpucycles.c"

 
#ifdef RND_SEED
unsigned long long x = RND_SEED LL;
#else
unsigned long long x = 88172645463325252LL;
#endif

unsigned long long xor64()
{
    x^=(x<<13);
      x^=(x>>7);
        return (x^=(x<<17));
}


int rnd(unsigned char *x, int xlen)
{
  for (int i = 0; i < xlen; i++)
  {
    uint64_t val = xor64();

    x[i] = val ^ (val >> 8) ^ (val >> 16) ^ (val >> 24);
  }
}
 
 
int main()
{
  unsigned long t0;
  unsigned long t1;

  unsigned long ts;

	xmss_params params;
	
	uint32_t oid = 0x01000001;
	
	xmss_parse_oid(&params, oid);
	
	unsigned char seed[params.n];
  unsigned char wots_seed[params.n];
	unsigned char pub_seed[params.n];
	unsigned char msg[params.n];
	unsigned char pk1[params.wots_sig_bytes];
	unsigned char sig[params.wots_sig_bytes];
	uint32_t pk_addr[8] = {0};
	uint32_t l_tree_addr[8] = {0};
	unsigned char leaf[params.n];
	
	FILE *f_seed;
	FILE *f_pubseed;
	FILE *f_msg;
	FILE *f_addr;
	FILE *f_pk;
	FILE *f_sig;
	
	rnd(seed, params.n);
	rnd(pub_seed, params.n);
	rnd(msg, params.n);
	//rnd((unsigned char *)addr, 8 * sizeof(uint32_t));
	pk_addr[4] = 32;
	l_tree_addr[4] = 32;
	 
  f_seed = fopen("seed.in", "w+");
	f_pubseed = fopen("pub_seed.in", "w+");
	f_msg = fopen("msg.in", "w+");
	f_addr = fopen("addr.in", "w+");
	f_pk = fopen("pk_c.out", "w+");
	f_sig = fopen("sig_c.out", "w+");
	
	int a;
	for (a = 0; a < params.n; a++){
	  fprintf(f_seed, "%02x", seed[a]);
	  fprintf(f_pubseed, "%02x", pub_seed[a]);
	  fprintf(f_msg, "%02x", msg[a]);
	}
	
	int b;
	for (b = 0; b < 8; b++){ 
	  fprintf(f_addr, "%u\n", pk_addr[b]);
	}
	 
	// set type
	pk_addr[3] = 0;
	l_tree_addr[3] = 1;
  
  printf("\n--!!!outputs following hw sequence!!!--\n\n");
  
  printf("\n------------returning inputs------------\n\n");
  
  printf("  secret seed = \n");
  
  for (int i=0; i<32; i++) {
    printf("%02x", seed[i]);
  }
  
  printf("\n\n");
  
  printf("  public seed = \n");
  
  for (int i=0; i<32; i++) {
    printf("%02x", pub_seed[i]);
  }
  
  printf("\n\n");
  
  printf("  hash address = \n");
   
  for (int i=0; i<8; i++) {
    printf("%08x", pk_addr[i]);
  }
  
  printf("\n\n");
  
  get_seed(&params, wots_seed, seed, pk_addr);
  wots_pkgen(&params, pk1, wots_seed, pub_seed, pk_addr);
  l_tree(&params, leaf, pk1, pub_seed, l_tree_addr);

  t0 = cpucycles(); 

  int rep = 0;

  for (; rep < 100; rep++)
  {
    get_seed(&params, wots_seed, seed, pk_addr);
    wots_pkgen(&params, pk1, wots_seed, pub_seed, pk_addr);
    l_tree(&params, leaf, pk1, pub_seed, l_tree_addr);
  }

  t1 = cpucycles();
  ts = (t1-t0) / rep;

  /*
  printf("\n------------returning pk------------\n\n");
 
  for (a = 0; a < params.wots_sig_bytes; a++){ 
	  fprintf(f_pk, "%02x", pk1[a]);
	}
   
  printf("\n");
	*/
	printf("\nResults from C:\n");
	
	printf("\n  ----------------------------------------------\n");
	printf("  computing leaf by use of l_tree...\n");
	
	 
	printf("  leaf = ");
	
	for (int k=0; k<params.n; k++) {
	  printf("%02x", leaf[k]);
	}
  
  printf("\n\n");
  
  printf("  returned pk hash address = \n");
   
  for (int i=0; i<8; i++) {
    printf("%08x", pk_addr[i]);
  }
  
  printf("\n\n");
  
  printf("  returned l_tree hash address = \n");
   
  for (int i=0; i<8; i++) {
    printf("%08x", l_tree_addr[i]);
  }
  
  printf("\n\n");
	
	printf("\n  ------------------------------------------------\n\n");
	/*
    wots_sign(&params, sig, msg, seed, pub_seed, addr);
	
	for (a = 0; a < params.wots_sig_bytes; a++){
	  fprintf(f_pk, "%02x", pk1[a]);
	  fprintf(f_sig, "%02x", sig[a]);
	}
    */

  printf("\n------------PERFORMANCE------------\n\n");
  printf("cycles sw: %lu\n\n", ts);


	fclose(f_seed);
	fclose(f_pubseed);
	fclose(f_msg);
	fclose(f_addr);
	fclose(f_pk);
	fclose(f_sig);
	
}
