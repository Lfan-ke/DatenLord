TOP = Top
OUT = output

all:
	mkdir -p $(OUT)
	bsc -verilog \
		-u \
		-g mkTop \
		-keep-fires \
		-show-schedule \
		-vdir $(OUT) \
		-bdir $(OUT) \
		-info-dir $(OUT) \
		$(TOP).bsv

compile:
	mkdir -p $(OUT)
	bsc -verilog \
		-u \
		-g mkTop \
		-vdir $(OUT) \
		-bdir $(OUT) \
		-info-dir $(OUT) \
		$(TOP).bsv

show:
	@echo "=== mkReg 生成的寄存器 ==="
	@grep -E "reg_normal" $(OUT)/mkTop.v | head -5
	@echo ""
	@echo "=== mkCReg 生成的多端口寄存器 ==="
	@grep -E "creg" $(OUT)/mkTop.v | head -10
	@echo ""
	@echo "=== mkRWire 生成的线网 ==="
	@grep -E "rwire" $(OUT)/mkTop.v | head -10
	@echo ""
	@echo "=== mkPulseWire 生成的脉冲线网 ==="
	@grep -E "pulsewire" $(OUT)/mkTop.v | head -10

clean:
	rm -rf $(OUT)

help:
	@echo "可用目标:"
	@echo "  make all       - 编译并显示调度信息"
	@echo "  make compile   - 仅编译"
	@echo "  make show      - 显示生成的 Verilog 中的关键信号"
	@echo "  make clean     - 清理输出目录"
