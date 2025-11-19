This folder holds the files for simulating the software-hardware co-design based on Murax SoC.

Start the simulation

```sh  
# if $(TARGET)=Murax, change line 2 in Makefile to: TARGET_HW=Murax
make TARGET=$(TARGET) (PRECOMP=yes) clean
make TARGET=$(TARGET) (PRECOMP=yes) run
#check: platforms/DE1-SoC/README.md for $(TARGET) information, PRECOMP hardware feature can be optionally enabled by setting FLAG PRECOMP=yes
# after successfully running this step, you should see: BOOT in the terminal window A, now you are ready to start openocd
```
