OUT = output
MOD = mkAccum
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) Accum.bs
clean:
	rm -rf $(OUT)
