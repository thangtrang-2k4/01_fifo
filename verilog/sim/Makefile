TESTNAME 	?= test
TB_NAME 	?= tb_sync_fifo
RADIX			?= hexadecimal

all: build run

build:
	vlib work
	vmap work work
	vlog -f compile.f | tee compile.log
run:
	vsim -voptargs=+acc -debugDB -c $(TB_NAME) -l $(TESTNAME).log -do "log -r /*;run -all;"
wave:
	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)" &
clean:
	rm -rf work
	rm -rf vsim.dbg
	rm -rf *.ini
	rm -rf *.log
	rm -rf *.wlf
	rm -rf transcript
help:
	@echo ""
	@echo "****************************************"
	@echo "** make build: compile the design and testbench"
	@echo "** make run  : run simulation"
	@echo "** make all  : compile and run simulation"
	@echo "** make wave : open waveform"
	@echo "** make clean: clean all compiled data"
	@echo "****************************************"
	@echo ""
