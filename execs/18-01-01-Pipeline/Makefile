TOP = Pipe
MOD = mkPipe
OUT = output
all:
	mkdir -p $(OUT)
	bsc -sim -u -g $(MOD) -bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) $(TOP).bsv
run: all
	bsc -sim -e $(MOD) -bdir $(OUT) -simdir $(OUT) -o $(OUT)/sim
	./$(OUT)/sim
verilog:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) $(TOP).bsv
clean:
	rm -rf $(OUT)
