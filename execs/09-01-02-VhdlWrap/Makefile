TOP = VhdlWrap
MOD = mkTop
OUT = output

# 编译：VHDL(逻辑源头) 经 ghdl 降级为 Verilog 网表 + BSV 生成 Verilog
all:
	mkdir -p $(OUT)
	ghdl -a --std=08 --workdir=$(OUT) vadd.vhd
	ghdl --synth --std=08 --workdir=$(OUT) --out=verilog vadd > $(OUT)/vadd_synth.v
	bsc -verilog -u -g $(MOD) \
		-vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) \
		$(TOP).bsv

# 运行：链接「套壳(实例化 vadd) + VHDL 网表」，iverilog 仿真
run: all
	bsc -verilog -e $(MOD) -vsim iverilog -vsearch +:. \
		-o $(OUT)/sim -vdir $(OUT) -bdir $(OUT) \
		$(OUT)/mkTop.v vadd_wrapper.v $(OUT)/vadd_synth.v
	./$(OUT)/sim

clean:
	rm -rf $(OUT) *.cf
