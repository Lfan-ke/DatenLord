OUT = output
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g mkUpCounter    -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) CounterBH.bs
	bsc -verilog -u -g mkUpCounterBSV -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) CounterBSV.bsv
clean:
	rm -rf $(OUT)
