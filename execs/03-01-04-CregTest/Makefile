TOP = CRegTest
MOD = mkCRegTest
OUT = output

# 仅编译（bluesim 对象到 output/）
all:
	mkdir -p $(OUT)
	bsc -sim -u -g $(MOD) \
		-bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) \
		$(TOP).bsv

# 编译 -> 链接 bluesim 可执行 -> 运行（打印每端口读值与提交值）
run: all
	bsc -sim -e $(MOD) -bdir $(OUT) -simdir $(OUT) -o $(OUT)/$(MOD)
	./$(OUT)/$(MOD)

# 看 CReg 的调度关系（前递/冲突）
sched:
	mkdir -p $(OUT)
	bsc -verilog -u -g $(MOD) \
		-keep-fires -show-schedule \
		-vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) \
		$(TOP).bsv

clean:
	rm -rf $(OUT)
