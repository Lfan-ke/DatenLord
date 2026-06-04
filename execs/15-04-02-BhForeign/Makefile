OUT = output
all:
	mkdir -p $(OUT)
	bsc -sim -u -g mkUseC -bdir $(OUT) -info-dir $(OUT) -simdir $(OUT) UseC.bs
run: all
	bsc -sim -e mkUseC -bdir $(OUT) -simdir $(OUT) -o $(OUT)/sim cfns.c
	./$(OUT)/sim
clean:
	rm -rf $(OUT) *.o     # bsc 链接把 cfns.o 放在顶层，一并清
