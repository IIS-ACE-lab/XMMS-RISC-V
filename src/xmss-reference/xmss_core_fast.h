#ifndef XMSS_CORE_FAST_H
#define XMSS_CORE_FAST_H

#include "params.h"

 unsigned long long xmss_xmssmt_core_sk_bytes(const xmss_params *params);

 int xmss_core_keypair(const xmss_params *params,
                      unsigned char *pk, unsigned char *sk);


int xmss_core_sign(const xmss_params *params,
                   unsigned char *sk,
                   unsigned char *sm, unsigned long long *smlen,
                   const unsigned char *m, unsigned long long mlen);


int xmssmt_core_keypair(const xmss_params *params,
                        unsigned char *pk, unsigned char *sk);

int xmssmt_core_sign(const xmss_params *params,
                     unsigned char *sk,
                     unsigned char *sm, unsigned long long *smlen,
                     const unsigned char *m, unsigned long long mlen);

