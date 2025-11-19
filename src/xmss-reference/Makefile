#
# Modified based on: https://github.com/XMSS/xmss-reference
#

ifeq ($(TARGET),x86)
  CC = /usr/bin/gcc
  CFLAGS = -Wall -pg -g -O3 -Wextra -Wpedantic 
  LDFLAGS += -lcrypto
 
else
  DEBUG=no
  BENCH=no
  MULDIV=no

  SOURCES = util/crt.S \
            util/util.c \
            util/Murax.c

  INC += -I../murax/software/VexRiscvSocSoftware/libs/
  INC += -I../murax/software/VexRiscvSocSoftware/projects/murax/libs/
  INC += -Iutil/

  LDSCRIPT = resources/linker.ld

  include resources/gcc.mk
  include resources/subproject.mk

endif

include $(TARGET).mk

OBJDIR = test

PROJ_NAME=$(TARGET)_$(PROJ)

CFLAGS += -DTARGET=$(TARGET) -D$(TARGET)

ifdef SIM
  CFLAGS += -DSIM
else
  CFLAGS += -DDE1_SoC
endif

ifdef MBEDTLS
  CFLAGS += -DMBEDTLS
endif

ifdef SW_FIXED_INLEN
  CFLAGS += -DSW_FIXED_INLEN
endif

ifdef SW_PRECOMP
  CFLAGS += -DSW_PRECOMP
endif

ifdef SHA256_HARDWARE
  CFLAGS += -DSHA256_HARDWARE
endif

# slow sign
#SOURCES += params.c hash.c fips202.c hash_address.c randombytes.c wots.c xmss.c xmss_core.c xmss_commons.c utils.c
#HEADERS += params.h hash.h fips202.h hash_address.h randombytes.h wots.h xmss.h xmss_core.h xmss_commons.h utils.h
# fast sign
SOURCES += params.c hash.c fips202.c hash_address.c randombytes.c wots.c xmss.c xmss_core_fast.c xmss_commons.c utils.c
HEADERS += params.h hash.h fips202.h hash_address.h randombytes.h wots.h xmss.h xmss_core_fast.h xmss_commons.h utils.h

SOURCES_FAST = $(subst xmss_core.c,xmss_core_fast.c,$(SOURCES))
HEADERS_FAST = $(subst xmss_core.h,xmss_core_fast.h,$(HEADERS))

TESTS = test/*_wots \
		test/*_oid \
		test/*_speed \
		test/*_xmss_determinism \
		test/*_xmss \
		test/*_xmss_fast \
		test/*_xmssmt \
		test/*_xmssmt_fast \
		test/*_sha256 \
		test/*_chain \
		test/*_leaf \

UI = ui/xmss_keypair \
	 ui/xmss_sign \
	 ui/xmss_open \
	 ui/xmssmt_keypair \
	 ui/xmssmt_sign \
	 ui/xmssmt_open \
	 ui/xmss_keypair_fast \
	 ui/xmss_sign_fast \
	 ui/xmss_open_fast \
	 ui/xmssmt_keypair_fast \
	 ui/xmssmt_sign_fast \
	 ui/xmssmt_open_fast \

XMSS_SIGNATURES = 4

all: $(OBJDIR)/$(PROJ_NAME)

test/$(TARGET)_%: test/%.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)

tests: $(TESTS)
ui: $(UI)

test: $(TESTS:=.exec)

.PHONY: clean test

test/$(TARGET)_%.exec: test/%
	@$<

test/$(TARGET)_xmss_fast: test/xmss.c $(SOURCES_FAST) $(OBJS) $(HEADERS_FAST)
	$(CC) -DXMSS_SIGNATURES=$(XMSS_SIGNATURES) $(CFLAGS) $(INC) -o $@ $(SOURCES_FAST) $< $(LDFLAGS)

test/$(TARGET)_xmss: test/xmss.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)

test/$(TARGET)_xmssmt_fast: test/xmss.c $(SOURCES_FAST) $(OBJS) $(HEADERS_FAST)
	$(CC) -DXMSSMT -DXMSS_SIGNATURES=$(XMSS_SIGNATURES) $(CFLAGS) $(INC) -o $@ $(SOURCES_FAST) $< $(LDFLAGS)

test/$(TARGET)_xmssmt: test/xmss.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) -DXMSSMT $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)

test/$(TARGET)_speed: test/speed.c $(SOURCES_FAST) $(OBJS) $(HEADERS_FAST)
	$(CC) -DXMSSMT -DXMSS_VARIANT=\"XMSSMT-SHA2_20/2_256\" $(CFLAGS) $(INC) -o $@ $(SOURCES_FAST) $< $(LDFLAGS)

test/$(TARGET)_%: test/%.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)

ui/$(TARGET)_xmss_%_fast: ui/%.c $(SOURCES_FAST) $(OBJS) $(HEADERS_FAST)
	$(CC) $(CFLAGS) $(INC) -o $@ $(SOURCES_FAST) $< $(LDFLAGS)

ui/$(TARGET)_xmssmt_%_fast: ui/%.c $(SOURCES_FAST) $(OBJS) $(HEADERS_FAST)
	$(CC) -DXMSSMT $(CFLAGS) $(INC) -o $@ $(SOURCES_FAST) $< $(LDFLAGS)

ui/$(TARGET)_xmss_%: ui/%.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)

ui/$(TARGET)_xmssmt_%: ui/%.c $(SOURCES) $(OBJS) $(HEADERS)
	$(CC) -DXMSSMT $(CFLAGS) $(INC) -o $@ $(SOURCES) $< $(LDFLAGS)


ifeq ($(TARGET),x86)
run: $(OBJDIR)/$(PROJ_NAME)
	$(OBJDIR)/$(PROJ_NAME)
else
run: $(OBJDIR)/$(PROJ_NAME)
	/opt/riscv/bin/riscv64-unknown-elf-gdb \
         -ex "target remote localhost:3333" \
         -ex "set remotetimeout 60" \
         -ex "set arch riscv:rv32" \
         -ex "monitor reset halt" \
         -ex "load" \
         -ex "continue" \
         $(OBJDIR)/$(PROJ_NAME)
endif

clean:
	-$(RM) $(TESTS)
	-$(RM) $(UI)

