TOP = BviMac
MOD = mkTop
OUT = output

# 仅编译：BSV -> Verilog（黑盒实例化 mymac）
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) \
		-vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) \
		$(TOP).bsv

# 编译 -> 链接外部 mymac.v -> iverilog 仿真
run: all
	bsc -verilog -e $(MOD) -vsim iverilog -vsearch +:. \
		-o $(OUT)/sim -vdir $(OUT) -bdir $(OUT) \
		$(OUT)/mkTop.v mymac.v
	./$(OUT)/sim

clean:
	rm -rf $(OUT)
