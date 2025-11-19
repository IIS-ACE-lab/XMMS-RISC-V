WOTS_W = 16
WOTS_LEN = 67
KEY_LEN = 256

SRC = src

PROJECT = proj

TOP_LEVEL_ENTITY = $(shell grep -v '\#' $(PROJECT).qsf | grep TOP_LEVEL_ENTITY | cut -d " " -f 4)
SOURCE_FILES = $(shell grep -v '\#' $(PROJECT).qsf | grep  "VERILOG_FILE\|TEXT_FILE" | cut -d " " -f 4)

STA_TCL = sta.tcl

all: summary

include ../gen.mk

map: $(PROJECT).map.rpt
fit: $(PROJECT).fit.rpt
asm: $(PROJECT).asm.rpt
sta: $(PROJECT).sta.rpt

MAP_ARGS = --read_settings_files=on --write_settings_files=off
FIT_ARGS = --read_settings_files=on --write_settings_files=off
ASM_ARGS = 
STA_ARGS =


$(PROJECT).map.rpt: $(SOURCE_FILES) 
	quartus_map $(MAP_ARGS) $(PROJECT)

$(PROJECT).fit.rpt: $(PROJECT).map.rpt proj.sdc
	quartus_fit $(FIT_ARGS) $(PROJECT)

$(PROJECT).asm.rpt: $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT) 

timing: $(PROJECT).sta.rpt $(STA_TCL)
	quartus_sta -t $(STA_TCL)

summary: $(PROJECT).sta.rpt
	@echo ""
	@grep -B 1 -A 5 "; Clocks *;" $^
	@echo ""
	@grep -B 1 -A 5 "; Slow 900mV 85C Model Fmax Summary *;" $^
	@echo ""
	@grep -B 1 -A 5 "; Slow 900mV 85C Model Setup Summary ;" $^
	@echo ""
	@grep -B 1 -A 5 "; Slow 900mV 85C Model Hold Summary ;" $^
	@echo ""

resources: $(PROJECT).fit.rpt
	@echo ""
	grep -B 1 -A 30 "; Fitter Summary" $(PROJECT).fit.rpt
	@echo ""
	grep -B 1 -A 16 "; Fitter Resource Usage Summary" $(PROJECT).fit.rpt
	@echo ""

program: $(PROJECT).sof
	quartus_pgm --no_banner --mode=jtag -o "P;$(PROJECT).sof"


clean:
	rm -rf *.rpt *.htm *.eqn *.pin *.sof *.pof $(PROJECT).done $(PROJECT).qws db incremental_db *.smsg *.summar *.summary

