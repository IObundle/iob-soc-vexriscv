ROOT_DIR:=.
include ./config.mk

#
# BUILD EMBEDDED SOFTWARE
#

fw-build:
	$(MAKE) -C $(FIRM_DIR) build-all

fw-clean:
	$(MAKE) -C $(FIRM_DIR) clean-all

#
# EMULATE ON PC
#

pc-emul-build:
	$(MAKE) fw-build
	$(MAKE) -C $(PC_DIR)

pc-emul-run: pc-emul-build
	$(MAKE) -C $(PC_DIR) run

pc-emul-clean: fw-clean
	$(MAKE) -C $(PC_DIR) clean

pc-emul-test: pc-emul-clean
	$(MAKE) -C $(PC_DIR) test

#
# SIMULATE RTL
#

sim-build:
	$(MAKE) fw-build
	$(MAKE) -C $(SIM_DIR) build

sim-run: sim-build
	$(MAKE) -C $(SIM_DIR) run

sim-clean: fw-clean
	$(MAKE) -C $(SIM_DIR) clean

sim-test:
	$(MAKE) -C $(SIM_DIR) test

#
# BUILD, LOAD AND RUN ON FPGA BOARD
#

fpga-build:
	$(MAKE) fw-build BAUD=115200
	$(MAKE) -C $(BOARD_DIR) build

fpga-run: fpga-build
	$(MAKE) -C $(BOARD_DIR) run TEST_LOG="$(TEST_LOG)"

fpga-clean: fw-clean
	$(MAKE) -C $(BOARD_DIR) clean

fpga-test:
	$(MAKE) -C $(BOARD_DIR) test

#
# SYNTHESIZE AND SIMULATE ASIC
#

asic-synth:
	$(MAKE) fw-build BAUD=115200
	$(MAKE) -C $(ASIC_DIR) synth

asic-sim-post-synth:
	$(MAKE) -C $(ASIC_DIR) all TEST_LOG="$(TEST_LOG)" BAUD=115200

asic-clean:
	$(MAKE) -C $(ASIC_DIR) clean-all

asic-test:
	$(MAKE) -C $(ASIC_DIR) test

#
# COMPILE DOCUMENTS
#

doc-build:
	$(MAKE) -C $(DOC_DIR) $(DOC).pdf

doc-clean:
	$(MAKE) -C $(DOC_DIR) clean

doc-test:
	$(MAKE) -C $(DOC_DIR) test

#
# CLEAN
#

clean: pc-emul-clean sim-clean fpga-clean doc-clean

#
# TEST ALL PLATFORMS
#

test-pc-emul: pc-emul-test

test-pc-emul-clean: pc-emul-clean

test-sim:
	$(MAKE) sim-test SIMULATOR=verilator
	$(MAKE) sim-test SIMULATOR=icarus

test-sim-clean:
	$(MAKE) sim-clean SIMULATOR=verilator
	$(MAKE) sim-clean SIMULATOR=icarus

test-fpga:
	$(MAKE) fpga-test BOARD=CYCLONEV-GT-DK
	$(MAKE) fpga-test BOARD=AES-KU040-DB-G

test-fpga-clean:
	$(MAKE) fpga-clean BOARD=CYCLONEV-GT-DK
	$(MAKE) fpga-clean BOARD=AES-KU040-DB-G

test-doc:
	$(MAKE) fpga-clean BOARD=CYCLONEV-GT-DK
	$(MAKE) fpga-clean BOARD=AES-KU040-DB-G
	$(MAKE) fpga-build BOARD=CYCLONEV-GT-DK
	$(MAKE) fpga-build BOARD=AES-KU040-DB-G
	$(MAKE) doc-test DOC=pb
	$(MAKE) doc-test DOC=presentation

test-doc-clean:
	$(MAKE) doc-clean DOC=pb
	$(MAKE) doc-clean DOC=presentation

test: test-clean test-pc-emul test-sim test-fpga test-doc

test-clean: test-pc-emul-clean test-sim-clean test-fpga-clean test-doc-clean

debug:
	@echo $(UART_DIR)
	@echo $(CACHE_DIR)


.PHONY: fw-build fw-clean \
	pc-emul-build pc-emul-run pc-emul-clean pc-emul-test \
	sim-build sim-run sim-clean sim-test \
	fpga-build fpga-run fpga-clean fpga-test \
	doc-build doc-clean doc-test \
	clean \
	test-pc-emul test-pc-emul-clean \
	test-sim test-sim-clean \
	test-fpga test-fpga-clean \
	test-doc test-doc-clean \
	test test-clean \
	debug
