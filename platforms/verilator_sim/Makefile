TARGET=Murax
TARGET_HW=MuraxHW

ifdef PRECOMP
  PROJECT = $(TARGET)_precomp
else
  PROJECT = $(TARGET)
endif

DEBUG?=no
TRACE?=no
PRINT_PERF?=no
TRACE_START=0
ADDCFLAGS += -CFLAGS -pthread -LDFLAGS -pthread
ADDCFLAGS += -CFLAGS -DVMURAX=V$(TARGET_HW)
ADDCFLAGS += -CFLAGS -DVMURAX_H=\\\"V$(TARGET_HW).h\\\"
ADDCFLAGS += -CFLAGS -DVMURAX_MURAX_H=\\\"V$(TARGET_HW)_$(TARGET_HW).h\\\"

ifeq ($(TRACE),yes)
	VERILATOR_ARGS += --trace --trace-depth 1
	ADDCFLAGS += -CFLAGS -DTRACE
endif
ifeq ($(DEBUG),yes)
	ADDCFLAGS += -CFLAGS "-g3 -O0"
endif
ifneq ($(DEBUG),yes)
	ADDCFLAGS += -CFLAGS "-O3"
endif
ifeq ($(PRINT_PERF),yes)
	ADDCFLAGS += -CFLAGS -DPRINT_PERF
endif

ADDCFLAGS += -CFLAGS -DTRACE_START=${TRACE_START}
ADDCFLAGS += -Wno-PINMISSING


SOURCES = $(shell grep VERILOG_FILE ../DE1-SoC/$(PROJECT).qsf  | cut -d " " -f 4)


all: compile


$(TARGET_HW).v:
	make -C ../Murax TARGET=$(TARGET_HW) TARGET_DIR=$(shell pwd)
	cp ../Murax/cpu0.yaml .
 
run: compile
	./obj_dir/V$(TARGET_HW)

verilate: $(SOURCES)
	rm -f $(TARGET_HW).v*.bin
	verilator --top-module $(TARGET_HW) -cc $(SOURCES) -CFLAGS -std=c++11  ${ADDCFLAGS} --gdbbt ${VERILATOR_ARGS} -Wno-WIDTH -Wno-UNOPTFLAT --x-assign unique --exe main.cpp

compile: verilate
	make  -j  -C obj_dir/ -f V$(TARGET_HW).mk V$(TARGET_HW)
 	
clean:
	rm -rf obj_dir
	rm -f $(TARGET_HW).v*.bin $(TARGET_HW).logTrace
	rm -rf $(TARGET_HW).v
	rm -rf cpu0.yaml *.logTrace *.v
 	
