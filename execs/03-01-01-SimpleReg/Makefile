TOP = SimpleRegConflict
MOD = mkSimpleRegConflict
OUT = output

# 两个 Rule 写同一 Reg 的冲突演示；-show-schedule 看调度（B 覆盖 A）
all:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) -show-schedule \
		-vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) \
		$(TOP).bsv

clean:
	rm -rf $(OUT)
