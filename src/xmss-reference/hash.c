/*
* Modified based on: https://github.com/XMSS/xmss-reference
*/

#include <stdint.h>
#include <string.h>

#ifdef MBEDTLS
  #include <mbedtls/sha256.h>
  
  void SHA256_Init(mbedtls_sha256_context *ctx)
  {
    mbedtls_sha256_init(ctx);
    mbedtls_sha256_starts_ret(ctx, 0);
  }
  
  unsigned char *SHA256(const unsigned char *d, size_t n, unsigned char *md)
  {
    mbedtls_sha256(d, n, md, 0);
  
    return md;
  }
  
  #define SHA256_Update mbedtls_sha256_update
  #define SHA256_Final(A, B) mbedtls_sha256_finish_ret(B, A)

  #define SHA256_CTX mbedtls_sha256_context
#else
  #include <openssl/sha.h> 
#endif

#ifdef SHA256XMSS_HARDWARE
  #include "sha256_store_hardware.h"
#endif


#include "hash_address.h"
#include "utils.h"
#include "params.h"
#include "hash.h"
#include "fips202.h"

#define XMSS_HASH_PADDING_F 0
#define XMSS_HASH_PADDING_H 1
#define XMSS_HASH_PADDING_HASH 2
#define XMSS_HASH_PADDING_PRF 3

void addr_to_bytes(unsigned char *bytes, const uint32_t addr[8])
{
    int i;
    for (i = 0; i < 8; i++) {
        ull_to_bytes(bytes + i*4, 4, addr[i]);
    }
}

#ifdef SW_FIXED_INLEN
void hash_update_fixed_inlen(SHA256_CTX *ctx, uint8_t *data) {
  mbedtls_internal_sha256_process(ctx, data);
}

void hash_final_fixed_inlen(SHA256_CTX *ctx, uint8_t *out) {
#ifdef SHA256_HARDWARE
  #define CONTROL_BIT 1

  volatile uint32_t *hw_ctrl = (uint32_t*)0xf0030000;

  // wait finish of SHA256 module
  while ((hw_ctrl[CONTROL_BIT] & 1) == 1);

  // read data from SHA256 module
  for (int i = 0; i < 8; i++)
    ((uint32_t*)out)[i] = hw_ctrl[i+4];
#else
  for (int k=0; k<8; k++) {
    ull_to_bytes(out+4*k, 4, ctx->state[k]);
  }
#endif
}

uint8_t pad_hash768[128] = {0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x3, 0x0};
uint8_t pad_hash1024[192] = {0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x80, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x4, 0x0};
#endif

int core_hash(const xmss_params *params,
                     unsigned char *out,
                     const unsigned char *in, unsigned long long inlen)
{
    if (params->n == 32 && params->func == XMSS_SHA2) {
        SHA256(in, inlen, out);
    }
#ifndef MBEDTLS
    else if (params->n == 32 && params->func == XMSS_SHAKE) {
        shake128(out, 32, in, inlen);
    }
    else if (params->n == 64 && params->func == XMSS_SHA2) {
        SHA512(in, inlen, out);
    }
    else if (params->n == 64 && params->func == XMSS_SHAKE) {
        shake256(out, 64, in, inlen);
    }
#endif
    else {
        return -1;
    }
    return 0;
}


int hash768(const xmss_params *params,
             unsigned char *out,
             const unsigned char *in, unsigned long long inlen)
{
  if (params->n == 32 && params->func == XMSS_SHA2)
#if   defined (SHA256XMSS_HARDWARE)
      sha256_store_hardware(in, 0, 0, 0, out);
#elif defined (SW_FIXED_INLEN)
  {
    SHA256_CTX ctx;

    memcpy(pad_hash768, in, 96);

    SHA256_Init(&ctx);
    hash_update_fixed_inlen(&ctx,pad_hash768);
    hash_update_fixed_inlen(&ctx,pad_hash768+64);
    hash_final_fixed_inlen(&ctx, out);

    return 0;
  }
#else
    return core_hash(params, out, in, inlen);
#endif
  else {
    return core_hash(params, out, in, inlen);
  }
}

int hash1024(const xmss_params *params,
              unsigned char *out,
              const unsigned char *in, unsigned long long inlen)
{
  if (params->n == 32 && params->func == XMSS_SHA2)
#if   defined (SHA256XMSS_HARDWARE)
      sha256_store_hardware(in, 1, 0, 0, out);
#elif defined (SW_FIXED_INLEN)
  {
    SHA256_CTX ctx;

    memcpy(pad_hash1024, in, 128);

    SHA256_Init(&ctx);
    hash_update_fixed_inlen(&ctx,pad_hash1024);
    hash_update_fixed_inlen(&ctx,pad_hash1024+64);
    hash_update_fixed_inlen(&ctx,pad_hash1024+128);
    hash_final_fixed_inlen(&ctx, out);

    return 0;
  }
#else
  return core_hash(params, out, in, inlen);
#endif
  else {
    return core_hash(params, out, in, inlen);
  }
}


/*
 * Computes PRF(key, in), for a key of params->n bytes, and a 32-byte input.
 */
int prf(const xmss_params *params,
        unsigned char *out, const unsigned char in[32],
        const unsigned char *key)
{
    unsigned char buf[2*params->n + 32];

    ull_to_bytes(buf, params->n, XMSS_HASH_PADDING_PRF);
    memcpy(buf + params->n, key, params->n);
    memcpy(buf + 2*params->n, in, 32);

    return hash768(params, out, buf, 2*params->n + 32);
}

#ifdef SW_PRECOMP
void hash_store(SHA256_CTX *out) {
#if defined(SHA256_HARDWARE) || defined(SHA256XMSS_HARDWARE)
  #define CONTROL_BIT 1

#ifdef SHA256_HARDWARE
  volatile uint32_t *hw_ctrl = (uint32_t*)0xf0030000;
  // wait finish of SHA256 module
  while ((hw_ctrl[CONTROL_BIT] & 1) == 1);

#elif defined (SHA256XMSS_HARDWARE)
  volatile uint32_t *hw_ctrl = (uint32_t*)0xf0030000;
  // don't need to wait for finish signal, already finished in the sha256_store_hardware call
#endif
   
  // read data from SHA256/SHA256XMSS module
  for (int i = 0; i < 8; i++)
    ((uint32_t*)(out->buffer))[i] = hw_ctrl[i+4];
#endif
}

void hash_restore(SHA256_CTX *in, SHA256_CTX *out) {
  memcpy(out,in,sizeof(SHA256_CTX));
 
#if defined(SHA256_HARDWARE) || defined(SHA256XMSS_HARDWARE)
  #define CONTROL_BIT 1

#ifdef SHA256_HARDWARE
  #define LOAD_IV 4
  volatile uint32_t *hw_ctrl = (uint32_t*)0xf0030000;

  // wait finish of SHA256/SHA256XMSS module
  while ((hw_ctrl[CONTROL_BIT] & 1) == 1);

#elif defined (SHA256XMSS_HARDWARE)
  #define LOAD_IV 64
  volatile uint32_t *hw_ctrl = (uint32_t*)0xf0030000;
  // don't need to wait for finish signal, already finished in the sha256_store_hardware call
#endif

  // write data to SHA256/SHA256XMSS module
  for (int i = 0; i < 8; i++) 
    hw_ctrl[i+4] = ((uint32_t*)(in->buffer))[i];

  // set IV
  hw_ctrl[CONTROL_BIT] = LOAD_IV;
#endif
}



int prf_pub(const xmss_params *params,
        unsigned char *out, const unsigned char in[32],
        const unsigned char *key)
{
  if (params->n == 32 && params->func == XMSS_SHA2) {
    static int have_pre = 0;

    static SHA256_CTX prf;

    if (have_pre == 0)
    {
      unsigned char buf[64]; // max

      ull_to_bytes(buf, 32, XMSS_HASH_PADDING_PRF);
      memcpy(buf+32, key, 32);

#ifdef SHA256XMSS_HARDWARE
      sha256_store_hardware(buf, 0, 1, 0, out);
      // sha256xmss (no hw_precomp) supports sw_precomp feature
   #ifndef HW_PRECOMP
      hash_store(&prf);
   #endif
#else
      SHA256_Init(&prf);

      SHA256_Update(&prf, buf, 64);

      hash_store(&prf);
#endif

      have_pre = 1;
    }

#ifdef SHA256XMSS_HARDWARE
    //
  #ifndef HW_PRECOMP
    // sha256xmss (no hw_precomp) supports sw_precomp feature
    SHA256_CTX ctx;
    hash_restore(&prf, &ctx);
  #endif
    sha256_store_hardware(in-(2*params->n), 0, 0, 1, out);
#else
    SHA256_CTX ctx;

    hash_restore(&prf, &ctx);

#ifdef SW_FIXED_INLEN
      unsigned char in_pad[64];
      memcpy(in_pad, in, 32);
      memcpy(in_pad+32, pad_hash768+96, 32);
      hash_update_fixed_inlen(&ctx, in_pad);
      hash_final_fixed_inlen(&ctx, out);
#else
    SHA256_Update(&ctx, in, 32);
    SHA256_Final(out, &ctx);
#endif
#endif // #ifdef SHA256XMSS_HARDWARE

    return 0;
  }
  else
  {
    unsigned char buf[2*params->n + 32];

    ull_to_bytes(buf, params->n, XMSS_HASH_PADDING_PRF);
    memcpy(buf + params->n, key, params->n);
    memcpy(buf + 2*params->n, in, 32);

    return hash768(params, out, buf, 2*params->n + 32);
  }
}
#else
#define prf_pub prf
#endif

/*
 * Computes the message hash using R, the public root, the index of the leaf
 * node, and the message. Notably, it requires m_with_prefix to have 4*n bytes
 * of space before the message, to use for the prefix. This is necessary to
 * prevent having to move the message around (and thus allocate memory for it).
 */
int hash_message(const xmss_params *params, unsigned char *out,
                 const unsigned char *R, const unsigned char *root,
                 unsigned long long idx,
                 unsigned char *m_with_prefix, unsigned long long mlen)
{
    /* We're creating a hash using input of the form:
       toByte(X, 32) || R || root || index || M */
    ull_to_bytes(m_with_prefix, params->n, XMSS_HASH_PADDING_HASH);
    memcpy(m_with_prefix + params->n, R, params->n);
    memcpy(m_with_prefix + 2*params->n, root, params->n);
    ull_to_bytes(m_with_prefix + 3*params->n, params->n, idx);

    return core_hash(params, out, m_with_prefix, mlen + 4*params->n);
}

/**
 * We assume the left half is in in[0]...in[n-1]
 */
int thash_h(const xmss_params *params,
            unsigned char *out, const unsigned char *in,
            const unsigned char *pub_seed, uint32_t addr[8])
{
    unsigned char buf[4 * params->n];
    unsigned char bitmask[2 * params->n];
    unsigned char addr_as_bytes[32];
    unsigned int i;

    /* Set the function padding. */
    ull_to_bytes(buf, params->n, XMSS_HASH_PADDING_H);

    /* Generate the n-byte key. */
    set_key_and_mask(addr, 0);
    addr_to_bytes(addr_as_bytes, addr);
    prf_pub(params, buf + params->n, addr_as_bytes, pub_seed);

    /* Generate the 2n-byte mask. */
    set_key_and_mask(addr, 1);
    addr_to_bytes(addr_as_bytes, addr);
    prf_pub(params, bitmask, addr_as_bytes, pub_seed);

    set_key_and_mask(addr, 2);
    addr_to_bytes(addr_as_bytes, addr);
    prf_pub(params, bitmask + params->n, addr_as_bytes, pub_seed);

    for (i = 0; i < 2 * params->n; i++) {
        buf[2*params->n + i] = in[i] ^ bitmask[i];
    }
    return hash1024(params, out, buf, 4 * params->n);
}

int thash_f(const xmss_params *params,
            unsigned char *out, const unsigned char *in,
            const unsigned char *pub_seed, uint32_t addr[8])
{
    unsigned char buf[3 * params->n];
    unsigned char bitmask[params->n];
    unsigned char addr_as_bytes[32];
    unsigned int i;

    /* Set the function padding. */
    ull_to_bytes(buf, params->n, XMSS_HASH_PADDING_F);

    /* Generate the n-byte key. */
    set_key_and_mask(addr, 0);
    addr_to_bytes(addr_as_bytes, addr);
    prf_pub(params, buf + params->n, addr_as_bytes, pub_seed);

    /* Generate the n-byte mask. */
    set_key_and_mask(addr, 1);
    addr_to_bytes(addr_as_bytes, addr);
    prf_pub(params, bitmask, addr_as_bytes, pub_seed);

    for (i = 0; i < params->n; i++) {
        buf[2*params->n + i] = in[i] ^ bitmask[i];
    }
    return hash768(params, out, buf, 3 * params->n);
}
