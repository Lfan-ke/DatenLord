TOP=Top
MOD=mkTop
OUT=output
CONTRIB=/usr/local/bsc-contrib/Libraries/Misc
run:
	mkdir -p $(OUT)
	bsc -sim -u -g $(MOD) -p +:$(CONTRIB) -bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) $(TOP).bsv
	bsc -sim -e $(MOD) -bdir $(OUT) -simdir $(OUT) -o $(OUT)/sim
	./$(OUT)/sim
clean:
	rm -rf $(OUT)
