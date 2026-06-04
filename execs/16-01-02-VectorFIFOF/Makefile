OUT=output
CONTRIB=/usr/local/bsc-contrib/Libraries/Misc
run:
	mkdir -p $(OUT)
	bsc -sim -u -g mkTop -p +:$(CONTRIB) -bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) Top.bsv
	bsc -sim -e mkTop -bdir $(OUT) -simdir $(OUT) -o $(OUT)/sim
	./$(OUT)/sim
clean:
	rm -rf $(OUT)
