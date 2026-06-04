OUT = output
MOD = mkUpCounter
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) Counter.bs
clean:
	rm -rf $(OUT)
