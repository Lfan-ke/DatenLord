OUT = output
# BLUESPECDIR 一般是 <bsc安装>/lib；未设置则回退到 /usr/local/bsc/lib
BSCDIR ?= $(shell echo $${BLUESPECDIR:-/usr/local/bsc/lib})

# 所有产物统一进 output/（扁平，与其他 execs 一致）
compile:
	@mkdir -p $(OUT)
	bsc -systemc -g mkAdder \
		-vdir $(OUT) -bdir $(OUT) -info-dir $(OUT) \
		-no-warn-action-shadowing Adder.bsv

link:
	bsc -systemc -e mkAdder -vdir $(OUT) -bdir $(OUT) -info-dir $(OUT)
	@mv -f *.h *.cxx *.o $(OUT)/ 2>/dev/null || true

all: compile link

# 用系统 SystemC + bsc Bluesim 运行时编译 main.cpp 并运行
run: all
	g++ -std=c++17 -o $(OUT)/adder_sim main.cpp \
		$(OUT)/mkAdder_systemc.o $(OUT)/mkAdder.o $(OUT)/model_mkAdder.o \
		-I$(OUT) -I$(BSCDIR)/Bluesim \
		-L$(BSCDIR)/Bluesim -lbskernel -lbsprim -lsystemc
	./$(OUT)/adder_sim

clean:
	rm -rf $(OUT)

.DEFAULT_GOAL := all
