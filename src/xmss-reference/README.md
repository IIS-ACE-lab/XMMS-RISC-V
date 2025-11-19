This folder includes the modified XMSS software implementation which includes: 

- SHA-256-specific software optimizations 

- software support for calling hardware accelerators from the software

- `test/` testing functions

TARGET=

- `x86` run the test on x86 CPUs

- `Murax` plain Murax SoC

- `MuraxSHA256` Murax SoC + general-purpose sha256 hardware accelerator 

- `MuraxSHA256XMSS` Murax SoC + XMSS-specific sha256 hardware accelerator (no precomp feature)

- `MuraxSHA256XMSS_precomp` Murax SoC + XMSS-specific sha256 hardware accelerator (with precomp feature)

- `MuraxSHA256XMSSChain` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (no precomp feature)

- `MuraxSHA256XMSSChain_precomp` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (with precomp feature)

- `MuraxSHA256XMSSChainLeaf` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (no precomp feature)

- `MuraxSHA256XMSSChainLeaf_precomp` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (with precomp feature)
 
PROJ =

- `sha256` sha256 test

- `sha_fixed_inlen` sha256 with software `fixed-input-length` optimization test

- `sha_fixed_inlen_precomp` sha256 with `software pre-computation` optimization test

- `sha256xmss` XMSS-specific sha256 test

- `chain` WOTS-chain test

- `leaf` XMSS-leaf test

- `xmss` XMSS full test, including: key generation, signature generation and signature verification
 
Sample instructions:

```sh
# run the leaf test on x86 CPUs
make TARGET=x86 PROJ=leaf clean
make TARGET=x86 PROJ=leaf run
```

```sh
# run the leaf test simulation on a Murax SoC with a Leaf accelerator
make TARGET=MuraxLeaf SIM=yes PROJ=leaf clean
make TARGET=MuraxLeaf SIM=yes PROJ=leaf run
```

```sh
# run the xmss test on FPGA on a Murax SoC with a Chain accelerator with precomp feature enabled
make TARGET=MuraxSHA256XMSSChain_precomp PROJ=xmss clean
make TARGET=MuraxSHA256XMSSChain_precomp PROJ=xmss run
```



