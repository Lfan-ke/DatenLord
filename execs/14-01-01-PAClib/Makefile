TOP=Top
MOD=mkTop
OUT=output
run:
	mkdir -p $(OUT)
	bsc -sim -u -g $(MOD) -bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) $(TOP).bsv
	bsc -sim -e $(MOD) -bdir $(OUT) -simdir $(OUT) -o $(OUT)/sim
	./$(OUT)/sim
clean:
	rm -rf $(OUT)
