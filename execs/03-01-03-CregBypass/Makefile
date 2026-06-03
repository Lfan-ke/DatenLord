TOP = CRegBypass
MOD = mkCRegBypass
OUT = output

all:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) -show-schedule \
		-vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) \
		$(TOP).bsv

clean:
	rm -rf $(OUT)
