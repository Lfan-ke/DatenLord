OUT=output
run:
	mkdir -p $(OUT)
	bsc -sim -u -g mkTop -bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) Top.bsv
	bsc -sim -e mkTop -bdir $(OUT) -simdir $(OUT) -o $(OUT)/sim
	./$(OUT)/sim
clean:
	rm -rf $(OUT)
