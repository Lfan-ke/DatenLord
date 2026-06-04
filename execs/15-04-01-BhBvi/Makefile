OUT = output
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g mkTop -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) BhCount.bs
run: all
	bsc -verilog -e mkTop -vsim iverilog -vsearch +:. -o $(OUT)/sim -vdir $(OUT) -bdir $(OUT) $(OUT)/mkTop.v count4.v
	./$(OUT)/sim
clean:
	rm -rf $(OUT)
