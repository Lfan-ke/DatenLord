TOP = Top
OUT = output

all:
	mkdir -p $(OUT)
	bsc -u -g mkTop -verilog -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) $(TOP).bsv

clean:
	rm -rf $(OUT)
