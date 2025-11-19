Generate and synthesize Murax cores for the DE1-SoC board.

Choose TARGET

- `Murax` plain Murax SoC

- `MuraxSHA256` Murax SoC + general-purpose sha256 hardware accelerator 

- `MuraxSHA256XMSS` Murax SoC + XMSS-specific sha256 hardware accelerator (precomp feature optional)
 
- `MuraxSHA256XMSSChain` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (precomp feature optional)
 
- `MuraxSHA256XMSSChainLeaf` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (precomp feature optional)

precomp feature can be optionally enabled by setting: 

PRECOMP=yes

#### Generate a Murax core:

```sh
make TARGET=target (PRECOMP=yes) gen
```


#### Synthesize (includes 'make gen'):

```sh 
make TARGET=target  (PRECOMP=yes)  
```

#### Program the FPGA:

```sh 
make TARGET=target (PRECOMP=yes) program
```

Sample instructions:

```sh
# generate bitstream for Murax SoC, then program the FPGA
make TARGET=Murax clean
make TARGET=Murax program
```

```sh
# generate bitstream for Murax SoC + a Leaf hardware accelerator + PRECOMP feature, then program the FPGA
make TARGET=MuraxLeaf PRECOMP=yes clean
make TARGET=MuraxLeaf PRECOMP=yes program
```

Note: Make sure the jtagd programming cable is detected

```sh
sudo killall jtagd
sudo $(PATH_OF_YOUR_LOCAL_QUARTUS_FOLDER)/quartus/bin/jtagd
sudo $(PATH_OF_YOUR_LOCAL_QUARTUS_FOLDER)/quartus/bin/jtagconfig
# the device information should be listed in the terminal now.
``` 
 
