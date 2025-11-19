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
#include <stdlib.h>
#include <inttypes.h>

#include "../xmss.h"
#include "../params.h"
#include "../randombytes.h"
#ifndef x86
#include <Murax.h>
#endif

#define XMSS_MLEN 32

#ifndef XMSS_SIGNATURES
  #ifdef X86_PROFILE
    #define XMSS_SIGNATURES 1
  #else
    #define XMSS_SIGNATURES 16
  #endif
#endif

#ifdef XMSSMT
    #define XMSS_PARSE_OID xmssmt_parse_oid
    #define XMSS_STR_TO_OID xmssmt_str_to_oid
    #define XMSS_KEYPAIR xmssmt_keypair
    #define XMSS_SIGN xmssmt_sign
    #define XMSS_SIGN_OPEN xmssmt_sign_open
    #define XMSS_VARIANT "XMSSMT-SHA2_20/2_256"
#else
    #define XMSS_PARSE_OID xmss_parse_oid
    #define XMSS_STR_TO_OID xmss_str_to_oid
    #define XMSS_KEYPAIR xmss_keypair
    #define XMSS_SIGN xmss_sign
    #define XMSS_SIGN_OPEN xmss_sign_open
    #define XMSS_VARIANT "XMSS-SHA2_10_256"
#endif

#ifdef x86
static unsigned long long cpucycles(void)
{
    unsigned long long result;
      __asm volatile(".byte 15;.byte 49;shlq $32,%%rdx;orq %%rdx,%%rax"
              : "=a" (result) ::  "%rdx");
        return result;
}
#endif

uint64_t average(uint64_t *t, int tlen)
{
  uint64_t acc=0;
  int i;
  for (i=0; i<tlen; i++)
    acc += t[i];
  return acc/(tlen);
}

int main()
{
     
    xmss_params params;
    uint32_t oid;
    int ret = 0;
    int i;

    // TODO test more different variants
    XMSS_STR_TO_OID(&oid, XMSS_VARIANT);
    XMSS_PARSE_OID(&params, oid);

    unsigned char pk[XMSS_OID_LEN + params.pk_bytes];
    unsigned char sk[XMSS_OID_LEN + params.sk_bytes];
    unsigned char m[XMSS_MLEN];
    unsigned char sm[params.sig_bytes + XMSS_MLEN];
    unsigned char mout[params.sig_bytes + XMSS_MLEN];
    unsigned long long smlen;
    unsigned long long mlen;

    uint64_t t0;
    uint64_t t1[XMSS_SIGNATURES];
    uint64_t t2[XMSS_SIGNATURES];

    int verify_valid;

    printf("generating key pair...\n");

    randombytes(m, XMSS_MLEN);

    t0 = -cpucycles();

    XMSS_KEYPAIR(pk, sk, oid);

    t0 += cpucycles(); 

    printf("Public Key: ");
    for (unsigned int j = 0; j < XMSS_OID_LEN + params.pk_bytes; j++)
      printf("%02x", pk[j]);

    printf("\ncycles key generation: %" PRIu64 "\n\n", t0);

    printf("\n\n");

    printf("Testing %d %s signatures.. \n", XMSS_SIGNATURES, XMSS_VARIANT);

    for (i = 0; i < XMSS_SIGNATURES; i++) {
        printf("\n  - iteration #%d:\n", i);

        t1[i] = -cpucycles();

        XMSS_SIGN(sk, sm, &smlen, m, XMSS_MLEN);
        
        t1[i] += cpucycles();
        printf("\n    cycles sign: %" PRIu64 "\n\n", t1[i]);

        printf("    Signature (partial - first 256 bytes):\n");
        printf("      ");
        for (unsigned int j = 0; j < 256; j++){ //params.sig_bytes + XMSS_MLEN; j+=32)
        //for (unsigned int j = 0; j < (params.sig_bytes + XMSS_MLEN); j++){
          if ((j%32)==0)
            printf("\n");
          printf("%02x", sm[j]);
        }
        printf("\n");


        if (smlen != params.sig_bytes + XMSS_MLEN) {
            printf("  X smlen incorrect [%llu != %u]!\n",
                   smlen, params.sig_bytes);
            ret = -1;
        }
        else {
            printf("    smlen as expected [%llu].\n", smlen);
        }

        /* Test if signature is valid. */

        t2[i] = -cpucycles();

        verify_valid = XMSS_SIGN_OPEN(mout, &mlen, sm, smlen, pk);
        
        t2[i] += cpucycles(); 
        printf("\n    cycles verify: %" PRIu64 "\n\n", t2[i]);

        //if (XMSS_SIGN_OPEN(mout, &mlen, sm, smlen, pk)) {
        if (verify_valid) {
            printf("  X verification failed!\n");
            ret = -1;
        }
        else {
            printf("    verification succeeded.\n");
        }

        /* Test if the correct message was recovered. */
        if (mlen != XMSS_MLEN) {
            printf("  X mlen incorrect [%llu != %u]!\n", mlen, XMSS_MLEN);
            ret = -1;
        }
        else {
            printf("    mlen as expected [%llu].\n", mlen);
        }
        if (memcmp(m, mout, XMSS_MLEN)) {
            printf("  X output message incorrect!\n");
            ret = -1;
        }
        else {
            printf("    output message as expected.\n");
        }

        /* Test if flipping bits invalidates the signature (it should). */

        /* Flip the first bit of the message. Should invalidate. */
        sm[smlen - 1] ^= 1;
        if (!XMSS_SIGN_OPEN(mout, &mlen, sm, smlen, pk)) {
            printf("  X flipping a bit of m DID NOT invalidate signature!\n");
            ret = -1;
        }
        else {
            printf("    flipping a bit of m invalidates signature.\n");
        }
        sm[smlen - 1] ^= 1;

#ifdef XMSS_TEST_INVALIDSIG
        int j;
        /* Flip one bit per hash; the signature is almost entirely hashes.
           This also flips a bit in the index, which is also a useful test. */
        for (j = 0; j < (int)(smlen - XMSS_MLEN); j += params.n) {
            sm[j] ^= 1;
            if (!XMSS_SIGN_OPEN(mout, &mlen, sm, smlen, pk)) {
                printf("  X flipping bit %d DID NOT invalidate sig + m!\n", j);
                sm[j] ^= 1;
                ret = -1;
                break;
            }
            sm[j] ^= 1;
        }
        if (j >= (int)(smlen - XMSS_MLEN)) {
            printf("    changing any signature hash invalidates signature.\n");
        }
#endif
    }

    printf("\n------------PERFORMANCE------------\n\n");
    printf("cycles key generation: %" PRIu64 "\n\n", t0);
    printf("cycles sign: %" PRIu64 "\n\n", average(t1, XMSS_SIGNATURES));
    printf("cycles verify: %" PRIu64 "\n\n", average(t2, XMSS_SIGNATURES));
      
    return ret;
}
