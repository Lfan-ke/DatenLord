# 一个简单的 Adder 示例...

## 输出文件说明

| 文件 | 类型 | 用途 |
|:----:|------:|------:|
| `mkAdder.ba` | Bluesim 中间码 | 中间表示，供链接使用 |
| `mkAdder.h` / `.o` | C++ 头/对象 | BSV 模型类（规则、方法实现） |
| `model_mkAdder.h` / `.o` | C++ 头/对象 | 模型封装（创建、销毁、复位） |
| `mkAdder_systemc.h` / `.o` | SystemC 头/对象 | **用户直接使用的 SystemC 模块** |

--

## BSV 到 SystemC 端口映射

| BSV 接口 | 生成的 SystemC 端口 | 方向 | 类型 |
|:----:|:--------------------:|:------:|:------:|
| `method Action set(a,b)` | `EN_set` | 输入 | `sc_in<bool>` |
| | `set_a` | 输入 | `sc_in<sc_bv<8>>` |
| | `set_b` | 输入 | `sc_in<sc_bv<8>>` |
| | `RDY_set` | 输出 | `sc_out<bool>` |
| `method Bit#(8) get_sum()` | `get_sum` | 输出 | `sc_out<sc_bv<8>>` |
| | `RDY_get_sum` | 输出 | `sc_out<bool>` |
| `method Bool ready()` | `ready` | 输出 | `sc_out<bool>` |
| | `RDY_ready` | 输出 | `sc_out<bool>` |
| 隐含时钟 | `CLK` | 输入 | `sc_in<bool>` |
| 隐含复位 | `RST_N` | 输入 | `sc_in<bool>` |

## 使用示例

```cxx
// main.cpp
#include "systemc.h"
#include "output/mkAdder_systemc.h"
#include <iostream>

int sc_main(int argc, char* argv[]) {
    // 时钟和复位
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst_n;

    // set 方法信号
    sc_signal<bool> en_set;
    sc_signal<sc_bv<8>> set_a, set_b;
    sc_signal<bool> rdy_set;

    // get_sum 方法信号
    sc_signal<sc_bv<8>> get_sum;
    sc_signal<bool> rdy_get_sum;

    // ready 方法信号
    sc_signal<bool> ready;
    sc_signal<bool> rdy_ready;

    // 实例化 BSV 导出的模块
    mkAdder uut("uut");
    uut.CLK(clk);
    uut.RST_N(rst_n);
    uut.EN_set(en_set);
    uut.set_a(set_a);
    uut.set_b(set_b);
    uut.RDY_set(rdy_set);
    uut.get_sum(get_sum);
    uut.RDY_get_sum(rdy_get_sum);
    uut.ready(ready);
    uut.RDY_ready(rdy_ready);

    // 波形输出
    sc_trace_file* tf = sc_create_vcd_trace_file("wave");
    sc_trace(tf, clk, "clk");
    sc_trace(tf, rst_n, "rst_n");
    sc_trace(tf, en_set, "en_set");
    sc_trace(tf, set_a, "set_a");
    sc_trace(tf, set_b, "set_b");
    sc_trace(tf, rdy_set, "rdy_set");
    sc_trace(tf, get_sum, "get_sum");
    sc_trace(tf, ready, "ready");

    // 复位
    rst_n = false;
    sc_start(20, SC_NS);
    rst_n = true;

    // 测试：设置输入 0x12 + 0x34
    en_set = true;
    set_a = 0x12;
    set_b = 0x34;
    sc_start(10, SC_NS);
    en_set = false;

    // 等待计算完成
    while (!ready.read()) {
        sc_start(10, SC_NS);
    }

    std::cout << "sum = 0x" << std::hex << get_sum.read() << std::endl;
    // 期望输出: sum = 0x46

    sc_start(100, SC_NS);
    sc_close_vcd_trace_file(tf);
    return 0;
}
```

编译运行（已实测，本机 SystemC 为系统安装 `/usr/include`，bsc 库在 `/usr/local/bsc/lib`）：

```sh
# BLUESPECDIR 一般是 <bsc安装>/lib，这里 = /usr/local/bsc/lib
# 关键：除 SystemC 外，还必须链接 bsc 的 Bluesim 运行时（头 + libbskernel/libbsprim），
#       否则会报 bluesim_kernel_api.h 找不到 / bk_* 未定义引用
g++ -std=c++17 -o adder_sim main.cpp \
    output/mkAdder_systemc.o output/mkAdder.o output/model_mkAdder.o \
    -Ioutput -I$BLUESPECDIR/Bluesim \
    -L$BLUESPECDIR/Bluesim -lbskernel -lbsprim \
    -lsystemc

# 运行 -> sum = 0x46（0x12 + 0x34）
./adder_sim

# 若开了 sc_trace，可看波形
gtkwave wave.vcd
```

> 注：若 SystemC 非系统安装，再补 `-I$SYSTEMC_HOME/include -L$SYSTEMC_HOME/lib -Wl,-rpath,$SYSTEMC_HOME/lib`。
