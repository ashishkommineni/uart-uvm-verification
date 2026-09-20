XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=uart_test
SEED?=random
.PHONY: uvm regress lint smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log
regress:
	@for seed in 7 23 41 71 113;do $(MAKE) uvm SEED=$$seed||exit 1;done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/uart.sv
smoke:
	rm -rf build/obj_uart;mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal --top-module tb_uart_smoke --Mdir build/obj_uart rtl/uart.sv tb/smoke/tb_uart_smoke.sv
	./build/obj_uart/Vtb_uart_smoke|tee results_smoke.log
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
