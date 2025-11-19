## Index

- [Index](#index)
- [Description](#description) 
- [Code Organization](#code)
- [Install Pre-requisites](#install)
- [Tools Versions](#tool)
- [Simulation](#simulation)
- [Real Tests On FPGAs](#fpga)
- [Contact](#contact) 

## Description

This repository hosts the implementation of a software-hardware co-design of the [XMSS](https://datatracker.ietf.org/doc/rfc8391/) hash-based signature scheme based on the RISC-V platform called [Murax SoC](https://github.com/SpinalHDL/VexRiscv/blob/master/README.md#murax-soc). 

For more details of the design, please check our paper: [XMSS and Embedded Systems - XMSS Hardware Accelerators for RISC-V](https://eprint.iacr.org/2018/1225) and the project website: http://caslab.csl.yale.edu/research.html#pqc

## Code Organization

- `src/hw_core/` contains the dedicated hardware accelerators for accelerating XMSS computations.

- `src/xmss-reference/` contains the modified XMSS software implementation which is based on the [XMSS reference software implementation](https://github.com/joostrijneveld/xmss-reference/) with SHA-256 specific software optimizations and code modifications to support calling hardware accelerators from the software.

- `src/ref_c_riscv/` contains the software functions for calling the hardware accelerators.

- `src/ref_python/` contains a Python-based implementation of XMSS, which is used for verifying the correctness of the modified software code and the hardware accelerators.

- `platforms/rtl` contains the APB bridge modules and hardware accelerator wrapper modules developed for the communication between the software and hardware.

- `platforms/DE1-SoC/` contains the hardware development files targeting the Cyclone V 5CSEMA5F31C6 FPGA.

- `platforms/verilator_sim/` contains the simulation files for simulating the whole test in Verilator.


 
## Install Pre-requisites

You need to install the following tools before running our design:

All the following information are collected from the README.md files from: https://github.com/SpinalHDL/openocd_riscv and https://github.com/SpinalHDL/VexRiscv and https://github.com/SpinalHDL/SpinalHDL

On Ubuntu 14 :

Install JAVA JDK 7 or 8

```sh
sudo apt-get install openjdk-8-jdk
```

Install SBT

```sh
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
sudo apt-get update
sudo apt-get install sbt
```

Compile the latest SpinalHDL

```sh
rm -rf SpinalHDL
git clone https://github.com/SpinalHDL/SpinalHDL.git 
```
 
Download VexRiscv hardware code  

```sh
git clone https://github.com/SpinalHDL/VexRiscv.git 
```
Install RISC-V GCC toolchain

```sh
# Get pre-compiled GCC
wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6.tar.gz
tar -xzvf riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6.tar.gz
sudo mv riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6 /opt/riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6
sudo mv /opt/riscv64-unknown-elf-gcc-20171231-x86_64-linux-centos6 /opt/riscv
echo 'export PATH=/opt/riscv/bin:$PATH' >> ~/.bashrc
```

Download and build openocd

```sh
# Get OpenOCD version from SpinalHDL
git clone https://github.com/SpinalHDL/openocd_riscv.git
# Install OpenOCD dependencies:
sudo apt-get install libtool automake libusb-1.0.0-dev texinfo libusb-dev libyaml-dev pkg-config
./bootstrap
./configure --enable-ftdi --enable-dummy
make
```  

Install Verilator (for simulation):

```sh
sudo apt-get install verilator
```

## Tools Versions

Here are the versions of the tools that we use locally for testing, we recommend that users use the same version of the tools.

- SageMath (sage) 6.3 and 7.4

- Python (python) 2.7

- Icarus Verilog (iverilog) 0.9.7

- Quartus (quartus) 16.1

- Verilator 3.874

- gcc version 5.4.0

- others: newest versions

## Simulation

The following steps show how to simulate the whole software-hardware co-design (instantiate the SoC, compile the software code, load the binary file to the Murax SoC through jtagd, display outputs in the minicom window, etc.)
 
#### Step 1: Start the simulation in terminal window A

Choose **TARGET** from:

- `Murax` plain Murax SoC

- `MuraxSHA256` Murax SoC + general-purpose sha256 hardware accelerator 

- `MuraxSHA256XMSS` Murax SoC + XMSS-specific sha256 hardware accelerator (precomp feature optional)
 
- `MuraxSHA256XMSSChain` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (precomp feature optional)
 
- `MuraxSHA256XMSSChainLeaf` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (precomp feature optional)

precomp feature can be optionally enabled by setting: `PRECOMP=yes`

Run the simulation:
 
```sh
cd platforms/verilator_sim 
# if $(TARGET)=Murax, change line 2 in Makefile to: TARGET_HW=Murax
make TARGET=$(TARGET) (PRECOMP=yes) clean
# run the simulation
make TARGET=$(TARGET) (PRECOMP=yes) run
#check: platforms/DE1-SoC/README.md for more information 
```

After successfully running this step, you should see: `BOOT` in the terminal window A, now you are ready to start openocd


#### Step 2: Start openocd in a new terminal window B

Start a new terminal window

```sh 
cd $(PATH_OF_YOUR_LOCAL_OPENOCD_FOLDER)/openocd_riscv
# start openocd
sudo src/openocd -f tcl/interface/jtag_tcp.cfg -c "set MURAX_CPU0_YAML $(PATH_OF_YOUR_LOCAL_XMSS_FOLDER)/platforms/verilator_sim/cpu0.yaml" -f tcl/target/murax.cfg
```

After successfully running this step, you should see: `CONNECTED` after the previous `BOOT` in terminal A

#### Step 3: Load a code binary onto Murax:

Start a new terminal window

Compile the software code for the required **TARGET** and load it to the Murax SoC:

```sh
cd src/xmss-reference
# compile the code, generate the binary, then load to the Murax through the jtagd interface
make TARGET=$(TARGET) PROJ=$(PROJ) SIM=yes run 
# check README.md in src/xmss-reference for information of $(TARGET) and $(PROJ) 
```

The **TARGET** must fit to the hardware platform from Step 1; choose **TARGET** from:

- `x86` run the test on x86 CPUs

- `Murax` plain Murax SoC

- `MuraxSHA256` Murax SoC + general-purpose sha256 hardware accelerator

- `MuraxSHA256XMSS` Murax SoC + XMSS-specific sha256 hardware accelerator (no precomp feature)

- `MuraxSHA256XMSS_precomp` Murax SoC + XMSS-specific sha256 hardware accelerator (with precomp feature)

- `MuraxSHA256XMSSChain` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (no precomp feature)

- `MuraxSHA256XMSSChain_precomp` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (with precomp feature)

- `MuraxSHA256XMSSChainLeaf` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (no precomp feature)

- `MuraxSHA256XMSSChainLeaf_precomp` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (with precomp feature)

Then, choose **PROJ** from:

- `sha256` sha256 test

- `sha_fixed_inlen` sha256 with software `fixed-input-length` optimization test

- `sha_fixed_inlen_precomp` sha256 with `software pre-computation` optimization test

- `sha256xmss` XMSS-specific sha256 test

- `chain` WOTS-chain test

- `leaf` XMSS-leaf test

- `xmss` XMSS full test, including: key generation, signature generation and signature verification

Check the outputs displayed in the terminal window A, the results are shown below `BOOT` and `CONNECTED`

#### Start new tests

- To start a new software test with the same SoC configuration, re-do Step 3.

- To start a new software test with a different SoC configuration, re-do all the steps.

## Real Tests On FPGAs

Hardware pre-requisites: 

- Cyclone V (5CSEMA5F31C6) FPGA
- USB-JTAG connection for programming the FPGA
- USB-serial connection for IO of the Murax SoC
- USB-JTAG connection for programming and debugging the software on the Murax SoC

Note: We tested our designs on both Cyclone V (Intel-Altera) and an Arty S7 development board from Digilent with a medium-size Xilinx Spartan 7 FPGA with part number XC7S50-1CSGA324C. Our design is not FPGA specific and therefore should run on any FPGA which has more than 128kB on-chip memory.

The following steps show how to run the whole software-hardware co-design on the FPGA (compile the code, start openocd, start serial interface, load the binary to the Murax SoC through jtagd, check outputs, etc)

#### Step 0: Check the interface

Make sure the jtagd programming cable is detected

```sh
sudo killall jtagd
sudo $(PATH_OF_YOUR_LOCAL_QUARTUS_FOLDER)/quartus/bin/jtagd
sudo $(PATH_OF_YOUR_LOCAL_QUARTUS_FOLDER)/quartus/bin/jtagconfig
```

The device (FPGA) information should be listed in the terminal now.
 

Check USB devices that are connected (serial port and jtagd)

```sh
cd utils/
./list_usb_dev.sh
# Check output 
```

#### Step 1: Generate FPGA bitstream and program the FPGA

Choose **TARGET**

- `Murax` plain Murax SoC

- `MuraxSHA256` Murax SoC + general-purpose sha256 hardware accelerator 

- `MuraxSHA256XMSS` Murax SoC + XMSS-specific sha256 hardware accelerator (precomp feature optional)
 
- `MuraxSHA256XMSSChain` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (precomp feature optional)
 
- `MuraxSHA256XMSSChainLeaf` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (precomp feature optional)

precomp feature can be optionally enabled by setting: `PRECOMP=yes`

Generate the bitstream and program the FPGA:

```sh
#note: if TARGET=Murax, change line 32 in Makefile to: TARGET_HW = Murax
cd platforms/DE1-SoC/
make TARGET=$(TARGET) (PRECOMP=yes) clean 
make TARGET=$(TARGET) (PRECOMP=yes) program
#check: platforms/DE1-SoC/README.md for more information 
```

#### Step 2: Open serial port connection to the Muarx SoC on FPGA

Start a new terminal window

```sh
# Assuming /dev/ttyUSB0 is the serial port
# If $USER is not in "dialout" group, need to use add sudo before minicom
minicom --baudrate 9600 --device=/dev/ttyUSB0
``` 

#### Step 3: Open jtag connection to Murax on FPGA

Start a new terminal window

```sh 
cd openocd_riscv
sudo src/openocd -f tcl/interface/ftdi/c232hm.cfg -c "set MURAX_CPU0_YAML $(PATH_OF_YOUR_LOCAL_XMSS_FOLDER)/platforms/DE1-SoC/cpu0.yaml" -f tcl/target/murax.cfg
```

#### Step 4: Connect GDB to load binary onto the Murax SoC on FPGA through Murax jtag interface

Start a new terminal window

Now, compile the software code for the required **TARGET** and load it to the Murax SoC:

```sh
cd src/xmss-reference
make TARGET=$(TARGET) PROJ=$(PROJ) clean
make TARGET=$(TARGET) PROJ=$(PROJ) run 
# check README.md in src/xmss-reference for information of $(TARGET) and $(PROJ)
```

Also here, the **TARGET** must fit to the hardware platform from Step 1; choose **TARGET** from:

- `x86` run the test on x86 CPUs

- `Murax` plain Murax SoC, maps to `TARGET=Murax` in Step 1

- `MuraxSHA256` Murax SoC + general-purpose sha256 hardware accelerator, maps to `TARGET=MuraxSHA256` in Step 1 

- `MuraxSHA256XMSS` Murax SoC + XMSS-specific sha256 hardware accelerator (no precomp feature), maps to `TARGET=MuraxSHA256XMSS` in Step 1

- `MuraxSHA256XMSS_precomp` Murax SoC + XMSS-specific sha256 hardware accelerator (with precomp feature), maps to `TARGET=MuraxSHA256XMSS PRECOMP=yes` in Step 1

- `MuraxSHA256XMSSChain` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (no precomp feature), maps to `TARGET=MuraxChain` in Step 1

- `MuraxSHA256XMSSChain_precomp` Murax SoC + XMSS-specific WOTS-chain hardware accelerator (with precomp feature), maps to `TARGET=MuraxChain PRECOMP=yes` in Step 1

- `MuraxSHA256XMSSChainLeaf` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (no precomp feature), maps to `TARGET=MuraxLeaf` in Step 1

- `MuraxSHA256XMSSChainLeaf_precomp` Murax SoC + XMSS-specific XMSS-leaf hardware accelerator (with precomp feature), maps to `TARGET=MuraxLeaf PRECOMP=yes` in Step 1

Then, choose **PROJ** from:

- `sha256` sha256 test

- `sha_fixed_inlen` sha256 with software `fixed-input-length` optimization test

- `sha_fixed_inlen_precomp` sha256 with `software pre-computation` optimization test

- `sha256xmss` XMSS-specific sha256 test

- `chain` WOTS-chain test

- `leaf` XMSS-leaf test

- `xmss` XMSS full test, including: key generation, signature generation and signature verification

The outputs are displayed in the minicom window (Step 2).

#### Start new tests

- To start a new software test with the same SoC configuration, re-do Step 4.

- To start a new software test with a different SoC configuration, re-do Step 1 and Step 4.

## Contact

[Wen Wang](http://caslab.csl.yale.edu/~wen/): wen.wang.ww349@yale.edu 

[Jakub Szefer](http://csl.yale.edu/~jakub/): jakub.szefer@yale.edu 

[Ruben Niederhagen](http://polycephaly.org/): ruben@polycephaly.org

