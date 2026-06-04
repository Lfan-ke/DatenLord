OUT = output
MOD = mkGCD
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) GCD.bs
clean:
	rm -rf $(OUT)
