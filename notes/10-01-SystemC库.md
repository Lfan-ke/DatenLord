# SystemC 简介

src: [官网](systemc.org/overview/systemc), [官文](systemc.org/resources/standards/), [TLM](https://systemc.org/overview/systemc-tlm), [官仓](https://github.com/accellera-official/systemc)

C++ 的一个类库<!-- 本质：一个 C++ 库 + 离散事件仿真内核（simulation kernel） -->，提供了一组 C++ 类和宏，用于在 C++ 环境中描述硬件（电路、时钟、信号...）和软硬件协同行为，用于设计和验证硬件系统。

可以直接仿真，也支持通过 HLS<!-- High Level Synthesis --> 导出 Verilog 进行综合，其中，常见的 HLS 工具：

- [AMD Vitis HLS](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vitis/vitis-hls.html)
- [Siemens Catapult HLS](https://eda.sw.siemens.com/en-US/products/ic/catapult-high-level-synthesis/hls/c-cplus/)
- [Intel HLS Compiler](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/hls-compiler.html)
- [Microchip SmartHLS](https://www.microchip.com/en-us/products/fpgas-and-plds/fpga-and-soc-design-tools/smarthls-compiler)
- [Cadence Stratus HLS](https://www.cadence.com/en_US/home/tools/digital-design-and-signoff/high-level-synthesis/stratus-high-level-synthesis.html)

## 第一印象

```cpp
#include <systemc>

用 SC_MODULE 写模块
用 sc_signal 连线
用 SC_THREAD/SC_METHOD 写行为
用 wait() 控制时序
用 sc_time 表示时间
用 TLM 写高层事务模型
```

SC ≈ 使用 Cpp 写 Verilog 风格的并发系统

| 技术      | 核心模型 |
|:-------:|:----------:|
| Verilog | Event-driven RTL |
| BSV | Rule-based atomic scheduling |
| Chisel | Scala DSL → FIRRTL → Verilog |
| SystemC | C++ Event-driven simulator |

SC有三个抽象层次：RTL、TLM、SL<!-- System Level -->，业界RTL级没有Verilog常见，但是TLM层级非常常见。

| 层次                    | 用途                  | 类似        |
| :---------------------: | :------------------: | :---------: |
| RTL                     | cycle-accurate 硬件建模 | Verilog   |
| Transaction-Level (TLM) | 总线/SoC建模            | gem5/QEMU |
| System-Level            | HW/SW co-sim        | 虚拟平台      |

## 语法速成

### 基础类型

| 层次 | 类型族 | 代表类型 | 用途 |
| :---: | :---: | :---: | :---: |
| **C++ 原生** | 标准类型 | `int`, `char`, `bool` | 算法、控制、测试激励 |
| **硬件基础** | 位/逻辑 | `sc_bit`, `sc_logic` | 单比特信号 |
| **硬件向量** | 位向量 | `sc_bv<N>`, `sc_lv<N>` | 多比特线网/寄存器 |
| **硬件整数** | 任意精度整数 | `sc_int<N>`, `sc_uint<N>`<br />`sc_bigint<N>`, `sc_biguint<N>` | 计数器、地址、数据通路 |
| **DSP/ML** | 固定点 | `sc_fixed<W,I>` | 数字信号处理、AI 加速器 |
| **系统级** | 事务级 | `tlm_generic_payload` | TLM-2.0 建模 |

#### 原生类型

```cpp
// 用于：控制逻辑、测试激励、算法描述
int        a = -42;       // 有符号，平台相关，通常32位
unsigned   b = 255;       // 无符号
bool       c = true;      // 布尔
char       d = 'A';       // 字符
double     e = 3.14;      // 浮点（注：f/d在HLS中不可综合，仅仿真）
```

#### 单比特类型

> `sc_bit` / `sc_logic`

| 类型 | 取值 | 对应 Verilog | 用途 |
| :---: | :---: | :---: | :---: |
| `sc_bit` | `0`, `1` | `bit` | 无 X/Z 状态，仿真更快 |
| `sc_logic` | `0`, `1`, `X`, `Z` | `logic` | 完整硬件建模（总线、三态） |

```cpp
#include "systemc.h"

sc_logic val;
val = SC_LOGIC_0;   // '0'
val = SC_LOGIC_1;   // '1'
val = SC_LOGIC_X;   // 'X' (未知)
val = SC_LOGIC_Z;   // 'Z' (高阻)

if (val == SC_LOGIC_Z) {
    // 检测总线高阻态
}
```

#### 位向量

**01向量**：

`sc_bv<N>` - bit vector - 0/1 only no x/z

```cpp
#include "systemc.h"

sc_bv<8> data;             // 8位 0/1 向量
data[0] = 1;               // 位赋值
data.range(7,4) = "1010";  // 部分赋值

sc_bv<4> nibble = "1100";
sc_bv<8> byte = nibble;    // 扩展为 "00001100"
```

**逻辑向量**：

`sc_lv<N>` - logic vector - 0/1/X/Z

```cpp
sc_lv<8> bus;        // 8位 4态向量
bus = "ZZZZ1111";    // 高4位高阻，低4位为1
bus[2] = SC_LOGIC_X;

// 比较（注意 X/Z 传播）
if (bus.is_01()) {   // 检查是否不含 X/Z
    // 安全操作
}
```

#### 任意精度整数

> `sc_int` / `sc_bigint` / `sc_uint` / `sc_biguint`

`sc_int<N>` / `sc_uint<N>` - 1 ~ 64位

`sc_bigint<N>` / `sc_biguint<N>` - 任意 > 64 位

```cpp
sc_int<32>    normal;   // 32 位有符号
sc_biguint<128> wide;   // 128位无符号

normal = -233;
wide = "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
```

#### 固定点类型

<!-- DSP/ML 核心 -->

```cpp
#include "systemc.h"

// sc_fixed<总位宽, 整数位宽, 量化模式, 溢出模式>
sc_fixed<16, 8>  fix;      // 16位总宽，8 位整数，8 位小数
sc_fixed<8, 2>   small;    // 8 位总宽，2 位整数，6 位小数
sc_fixed<24, 12> dsp_val;  // 24位总宽，12位整数，12位小数
```

> 数值范围与精度

| 配置 | 整数位 | 小数位 | 范围 | 精度（LSB） |
| :---: | :---: | :---: | :---: | :---: |
| `<16,8>` | 8 | 8 | -128 ~ 127.996 | 1/256 ≈ 0.0039 |
| `<8,2>` | 2 | 6 | -2 ~ 1.984 | 1/64 ≈ 0.0156 |
| `<24,12>` | 12 | 12 | -2048 ~ 2047.999 | 1/4096 ≈ 0.00024 |

**简易示例**：

```cpp
#include "systemc.h"

SC_MODULE(FixedPointDemo) {
    sc_in<sc_fixed<16,8>> a, b;
    sc_out<sc_fixed<16,8>> y;

    void multiply() {
        sc_fixed<16,8> prod = a.read() * b.read();  // DSP 乘法
        y.write(prod);
    }

    SC_CTOR(FixedPointDemo) {
        SC_METHOD(multiply);
        sensitive << a << b;
    }
};

// 使用示例
sc_fixed<16,8> x = 3.14159;   // 自动量化
sc_fixed<16,8> y = 2.5;
sc_fixed<16,8> z = x * y;     // 约 7.8539816...（精度受限）
```

**量化与溢出**：

```c++
// 完整的固定点声明
sc_fixed<16, 8,
    SC_RND,  // 量化：四舍五入
    SC_SAT>  // 溢出：饱和

// 常见量化模式
// SC_RND:   四舍五入 (round)
// SC_TRN:   截断 (truncate)
// SC_RND_ZERO: 向零舍入

// 常见溢出模式
// SC_SAT:   饱和 (saturate)
// SC_WRAP:  回绕 (wrap)
// SC_SAT_SYM: 对称饱和
```

**DSP/ML 加速器中的应用示例**：

```cpp
// 卷积层中的固定点累加
sc_fixed<32,16> conv_accumulate(
    sc_fixed<8,2>  input[64],
    sc_fixed<8,2>  weight[64]
) {
    sc_fixed<32,16> sum = 0;
    for (int i = 0; i < 64; i++) {
        sum += input[i] * weight[i];  // 固定点乘法
    }
    return sum;
}
```

**大致类型归结对照表**：

| 功能 | Verilog | SystemC | 说明 |
| :---: | :---: | :---: | :---: |
| 单比特 | `bit` | `sc_bit` | 2值 |
| 单比特 | `logic` | `sc_logic` | 4值 |
| 位向量 | `bit [7:0]` | `sc_bv<8>` | 2值向量 |
| 逻辑向量 | `logic [7:0]` | `sc_lv<8>` | 4值向量 |
| 整数 | `integer` | `sc_int<32>` | 32位有符号 |
| 无符号 | - | `sc_uint<32>` | 32位无符号 |
| 固定点 | `real` (不可综合) | `sc_fixed<W,I>` | **可综合！** |
| 大整数 | - | `sc_bigint<N>` | 任意精度 |

**`LLM`推荐的类型选型**：

| 场景 | 推荐类型 | 理由 |
| :---: | :---: | :---: |
| **计数器 (0-255)** | `sc_uint<8>` | 位宽精确，无 X/Z 开销 |
| **地址总线 (32位)** | `sc_uint<32>` | 直接映射到硬件 |
| **状态机状态** | `sc_uint<4>` 或 `enum` | 配合 enum 更清晰 |
| **三态总线** | `sc_lv<N>` | 需要 Z 态 |
| **不确定值传播** | `sc_lv<N>` | 需要 X 态 |
| **FIR 滤波器** | `sc_fixed<16,8>` | DSP 最优 |
| **CNN 权重** | `sc_fixed<8,2>` | 8位量化 |
| **大数运算 (>64位)** | `sc_biguint<N>` | 密码学/哈希 |
| **测试激励/算法** | `int`, `double` | 仅仿真用，快 |

### module

```cpp
// 一开始就支持两种风格：C 风格宏、C++ 风格类，前者在预处理阶段就会被展开为后者
SC_MODULE(Adder) {
    ...  // 这种设计让早期的 SC 代码看起来更接近 V 的 module 语法，方便硬件工程师上手
};
// 现代 C++ 语法
struct Adder : sc_module {
    ...
};
```

### port

类似 Verilog input/output

```c++
sc_in<bool> clk;
sc_in<int> a, b;
sc_out<int> sum;
```

等价：

```verilog
input clk;
input [31:0] a, b;
output [31:0] sum;
```

### signal

```cpp
sc_signal<int> sig;
```

类似于：

```verilog
wire/reg
```

> 本质是：带事件通知的 C++ 对象

### process <!-- SystemC 的核心 -->

有三种描述/映射方案：

| 进程类型 | 硬件类比 | 行为类比 | 说明 | 综合后典型结构 | 主要用途 |
| :---: | :---: | :---: | :---: | :--- | :--- |
| `SC_METHOD` | `always_comb` | 纯函数 | 组合逻辑 | 组合逻辑网表 | 译码器、加法器、MUX |
| `SC_CTHREAD` | `always_ff` | 时钟驱动寄存器 | 同步时钟，仅在时钟边沿停 | 寄存器 + 组合 | 计数器、状态机、流水线 |
| `SC_THREAD` | 复杂 FSM | **coroutine** | 行为级/FSM | FSM + 数据路径 | CPU模型、总线BFM、测试激励 |

#### 组合描述

```cpp
SC_MODULE(CombinAdd) {
    sc_in<int> a, b;
    sc_out<int> y;

    void add() {
        y.write(a.read() + b.read());  // 立即计算
    }

    SC_CTOR(CombinAdd) {
        SC_METHOD(add);
        sensitive << a << b;  // 任何输入变化都触发
    }
};
```

等价于：

```verilog
module CombinAdd (
    input [31:0] a, b,
    output [31:0] y
);
    assign y = a + b;  // 纯组合逻辑加法器
endmodule
```

#### 同步时序

```cpp
SC_MODULE(RegAdd) {
    sc_in<bool> clk, rst;
    sc_in<int> a, b;
    sc_out<int> y;

    void add_register() {
        int sum = 0;
        while (true) {
            wait();  // 等待时钟沿
            if (rst.read()) {
                sum = 0;
            } else {
                sum = a.read() + b.read();
            }
            y.write(sum);
        }
    }

    SC_CTOR(RegAdd) {
        // 可类比注册了一个协程，每次时钟沿触发一次
        SC_CTHREAD(add_register, clk.pos());
        async_reset_signal_is(rst, true);
    }
};
```

等价于：

```verilog
module RegAdd (
    input clk, rst,
    input [31:0] a, b,
    output reg [31:0] y
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            y <= 0;
        else
            y <= a + b;
    end
endmodule
```

#### 行为级混合

```cpp
SC_MODULE(HandshakeAdd) {
    sc_in<bool> clk, rst;
    sc_in<int> a, b;
    sc_in<bool> req;           // 请求输入
    sc_out<int> y;
    sc_out<bool> ack;          // 应答输出

    void add_with_handshake() {
        int sum = 0;

        // 初始化
        y.write(0);
        ack.write(false);

        while (true) {
            // 等待请求信号（沿触发或电平均可，这里用电平+时钟）
            wait(req.posedge_event());  // 等待 req 上升沿

            // 读取输入并计算
            sum = a.read() + b.read();

            // 模拟计算延迟（1个时钟周期）
            wait();  // 等待一个时钟沿
            y.write(sum);  // y <- sum;

            // 发出应答（保持1个周期）
            ack.write(true);
            wait();  // 等待一个时钟沿
            ack.write(false);
        }
    }

    SC_CTOR(HandshakeAdd) {
        SC_THREAD(add_with_handshake);
        // 更 RTL 的写法，等待上升沿触发
        sensitive << clk.pos();   // 线程由时钟驱动
        // 支持同步rst：reset_signal_is
        async_reset_signal_is(rst, true);
    }
};
```

等价于：

```verilog
module HandshakeAdd (
    input clk, rst,
    input [31:0] a, b,
    input req,
    output reg [31:0] y,
    output reg ack
);
    // 状态编码
    localparam IDLE    = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam SEND_ACK = 2'b10;

    reg [1:0] state, next_state;
    reg [31:0] sum_reg;

    // 状态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 下一状态逻辑（组合）
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (req) next_state = COMPUTE;
            COMPUTE: next_state = SEND_ACK;
            SEND_ACK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y <= 0;
            ack <= 0;
            sum_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ack <= 0;
                    if (req) sum_reg <= a + b;
                end
                COMPUTE: y <= sum_reg;
                SEND_ACK: ack <= 1;
            endcase
        end
    end
endmodule
```

#### 仨对比总结

| 进程类型 | 代码中的 `wait()` | 综合后结构 | 典型应用 |
| :---: | :---: | :--- | :--- |
| `SC_METHOD` | 0 个 | 纯组合逻辑 | 加法器、MUX、译码器 |
| `SC_CTHREAD` | 1 个（循环开头） | 组合 + 1级寄存器 | 累加器、计数器 |
| `SC_THREAD` | **N 个**（任意位置） | **FSM + 数据路径** | 握手协议、总线控制器、CPU |

#### 一句话总结

- **`SC_METHOD`**：一根线，输入变，输出立刻变
- **`SC_CTHREAD`**：一个寄存器，时钟到，才更新
- **`SC_THREAD`**：一个状态机，多个时钟步，完成一个完整事务

### 时间单位

用于指定时间的单位，例如纳秒、微秒、毫秒等

```cpp
sc_time t(10, SC_NS);
```

| 单位  | 含义 |
| :--: | :--: |
| SC_FS | 飞秒 |
| SC_PS | 皮秒 |
| SC_NS | 纳秒 |
| SC_US | 微秒 |
| SC_MS | 毫秒 |

### 仿真入口

```cpp
int sc_main(int argc, char* argv[]) {
    ...
    sc_start();  // 类似 C 的 main
}
```

完整示例：

```cpp
#include <systemc>

SC_MODULE(Hello) {
    void run() {
        while (true) {
            std::cout << sc_time_stamp()
                      << " hello\n";

            wait(1, SC_NS);
        }
    }

    SC_CTOR(Hello) {
        SC_THREAD(run);
    }
};

int sc_main(int argc, char* argv[]) {
    // 创建一个名为 "h" 的 Hello 模块实例，对象变量名为 h
    Hello h("h");

    sc_start(5, SC_NS);

    return 0;
}
```

输出：

```
0 s hello
1 ns hello
2 ns hello
...
```

### 时钟生成

```c++
#include <systemc.h>

// 最简单的时钟：周期 10ns，50% 占空比
sc_clock clk("clk", 10, SC_NS);

// 完整参数
sc_clock clk(
    "clk",           // 时钟实例名称
    10, SC_NS,       // 周期
    0.5,             // 占空比 (默认 0.5)
    0, SC_NS,        // 起始时刻的延迟 (默认 0)
    false            // 起始电平 (默认 false = 0)
);

// 常见示例
sc_clock clk_100m("clk_100m", 10, SC_NS);  // 100MHz 时钟 (周期 10ns)
sc_clock clk_50m("clk_50m", 20, SC_NS, 0.3);  // 50MHz 时钟，占空比 30%
sc_clock pll_out("pll_out", 5, SC_NS, 0.5, 2, SC_NS, false);  // 带初始延迟的时钟 (模拟 PLL 锁定)
sc_clock slow("slow", 1000, SC_NS);  // 1us 周期，低频时钟 (1MHz)

// 使用示例
SC_MODULE(MyModule) {
    sc_in<bool> clk;

    void process() {
        while (true) {
            // 等待上升沿
            wait(clk.posedge_event());  // 等价于 wait(clk->posedge_event());
            // 下降沿
            wait(clk.negedge_event());
        }
    }
};

// 连接时钟
sc_clock clk("clk", 10, SC_NS);
MyModule mod("mod");
mod.clk(clk);  // 直接连接/设置时钟
```

**完整的示例**：

```cpp
#include <systemc.h>

SC_MODULE(Counter) {
    sc_in<bool> clk;
    sc_in<bool> rst;
    sc_out<sc_uint<8>> count;

    void inc() {
        sc_uint<8> c = 0;
        while (true) {
            wait(clk.posedge_event());
            if (rst.read()) {
                c = 0;
            } else {
                c++;
            }
            count.write(c);
        }
    }

    SC_CTOR(Counter) {
        SC_CTHREAD(inc, clk.pos());
        async_reset_signal_is(rst, true);
    }
};

int sc_main(int, char*[]) {
    // 生成时钟
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst;
    sc_signal<sc_uint<8>> cnt;

    Counter dut("dut");
    dut.clk(clk);
    dut.rst(rst);
    dut.count(cnt);

    // 测试激励
    rst.write(true);
    sc_start(5, SC_NS);
    rst.write(false);
    sc_start(100, SC_NS);

    sc_stop();
    return 0;
}
```

### 波形导出

**基本使用示例**：

```cpp
#include <systemc.h>

int sc_main(int argc, char* argv[]) {
    // 创建 VCD 文件
    sc_trace_file* tf = sc_create_vcd_trace_file("my_emm_wave_file");
    // 可选：设置文件注释
    tf->set_comment("这是一个Emm233计数器的波形文件");
    // 可选：设置时间单位
    tf->set_time_unit(1, SC_NS);

    // 添加要追踪的信号
    sc_trace(tf, clk, "clk");      // 时钟
    sc_trace(tf, rst, "rst");      // 复位
    sc_trace(tf, data, "data");    // 数据信号
    sc_trace(tf, count, "count");  // 计数器

    // 运行仿真
    sc_start(100, SC_NS);

    // 关闭文件
    sc_close_vcd_trace_file(tf);

    return 0;
}
```

**其他相关介绍**：

```cpp
/* | - | 支持追踪的信号类型 | - | */
// 几乎所有 SystemC 类型都可追踪
sc_trace(tf, a, "a");           // sc_in/sc_out
sc_trace(tf, b, "b");           // sc_signal
sc_trace(tf, c, "c");           // sc_uint<8>
sc_trace(tf, d, "d");           // sc_bv<16>
sc_trace(tf, e, "e");           // sc_logic
sc_trace(tf, f, "f");           // sc_fixed<16,8>

// 时钟特殊处理
sc_trace(tf, clk, "clk");       // 自动识别边沿

/* | - | 带层次的追踪 | - | */
// 完整路径会包含模块层次
sc_trace(tf, dut.signal_a, "dut.signal_a");
sc_trace(tf, dut.sub.signal_b, "dut.sub.signal_b");

// 或使用相对路径
sc_trace(tf, signal_a, "signal_a");  // 相对于当前根模块下

/* | - | 条件追踪 | - | */
// 只在特定条件下才记录
if (dump_enable) {
    sc_trace(tf, large_bus, "large_bus");
}

// 追踪前 1000 个周期
sc_start(1000, SC_NS);
// 然后关闭追踪或不再添加新信号
```

### 简易示例

```cpp
#include <systemc.h>

// ============================================================
// 计数器模块
// 功能：8位向上计数器，带内部状态追踪和调试支持
// ============================================================

// 旧的写法：SC_MODULE(Counter) { ... };
class Counter : public sc_module {
public:
    // ---------- 端口接口（必须 public）----------
    sc_in<bool> clk;      // 时钟输入
    sc_in<bool> rst;      // 异步复位（高有效）
    sc_out<sc_uint<8>> count;  // 计数值输出

    // ---------- 配置参数 ----------
    sc_uint<8> max_value = 255;   // 最大计数值（可配置）

    // ---------- 构造函数 ----------
    // 旧的写法：SC_CTOR(Counter) { ... }
    Counter(const sc_module_name& name, sc_uint<8> max_val = 255)
        : sc_module(name)
        , max_value(max_val)
        , debug_enabled(false)
    {
        SC_HAS_PROCESS(Counter);  // 现代 C++ 风格类必需
        // 注册主进程（时钟线程）
        SC_CTHREAD(process, clk.pos());
        async_reset_signal_is(rst, true);

        // 注册溢出检测进程（方法进程，组合逻辑）
        SC_METHOD(check_overflow);
        sensitive << count;

        // 可选：注册调试进程（条件编译）
        #ifdef ENABLE_DEBUG
        SC_METHOD(debug_print);
        sensitive << count;
        #endif

        // 输出构造信息
        std::cout << sc_time_stamp() << " [INFO] Counter '" << name
                  << "' constructed, max_value=" << max_value << std::endl;
    }

    // ---------- 公共接口 ----------
    void enable_debug(bool enable) { debug_enabled = enable; }

    void reset_to(sc_uint<8> value) {
        // 通过复位信号强制设置（实际应通过进程实现，这里仅示例接口设计）
        std::cout << sc_time_stamp() << " [CMD] Reset counter to " << value << std::endl;
    }

    sc_uint<8> peek() const {
        return count.read();
    }

    // 波形追踪封装
    void trace(sc_trace_file* tf) const {
        if (!tf) return;

        sc_trace(tf, clk, "clk");
        sc_trace(tf, rst, "rst");
        sc_trace(tf, count, "count");
        sc_trace(tf, internal_state, "internal_state");
        sc_trace(tf, overflow_flag, "overflow_flag");
        sc_trace(tf, max_value, "max_value");
    }

private:
    // ---------- 内部信号 ----------
    sc_signal<sc_uint<4>> internal_state;   // 内部状态（低4位）
    sc_signal<bool> overflow_flag;          // 溢出标志

    // ---------- 内部配置 ----------
    bool debug_enabled;

    // ---------- 主进程（时序逻辑）----------
    void process() {
        sc_uint<8> c = 0;
        internal_state.write(0);
        overflow_flag.write(false);

        // 等待复位释放
        wait();

        while (true) {
            wait();  // 等待下一个时钟沿

            if (rst.read()) {
                // 复位逻辑
                c = 0;
                internal_state.write(0);
                overflow_flag.write(false);
                if (debug_enabled) {
                    std::cout << sc_time_stamp() << " [DEBUG] Counter reset" << std::endl;
                }
            } else {
                // 正常计数
                if (c >= max_value) {
                    c = 0;
                    overflow_flag.write(true);
                    if (debug_enabled) {
                        std::cout << sc_time_stamp() << " [DEBUG] Counter overflow!" << std::endl;
                    }
                } else {
                    c = c + 1;
                    overflow_flag.write(false);
                }
                // 更新内部状态（低4位）
                internal_state.write(c.range(3, 0));
            }
            count.write(c);
        }
    }

    // ---------- 溢出检测进程（组合逻辑）----------
    void check_overflow() {
        // 纯组合逻辑，不可包含 wait()
        if (count.read() == max_value) {
            // 可以添加额外处理，如触发中断等
        }
    }

    // ---------- 调试进程（可选）----------
    void debug_print() {
        if (debug_enabled) {
            std::cout << sc_time_stamp()
                      << " [DEBUG] count=" << count.read()
                      << " (0x" << std::hex << count.read() << std::dec << ")"
                      << " internal_state=" << internal_state.read()
                      << " overflow=" << overflow_flag.read()
                      << std::endl;
        }
    }
};


// ============================================================
// 测试激励模块（独立模块，演示模块间交互）
// ============================================================

class Tester : public sc_module {
public:
    // 端口
    sc_out<bool> rst;
    sc_in<sc_uint<8>> count;

    // 构造函数
    // 旧的写法：SC_CTOR(Tester)
    Tester(const sc_module_name& name) : sc_module(name) {
        SC_HAS_PROCESS(Tester);  // 现代 C++ 风格类必需
        SC_THREAD(run_tests);
        // 不敏感于时钟，使用 wait(time) 控制
    }

    void trace(sc_trace_file* tf) const {
        if (!tf) return;
        sc_trace(tf, rst, "tester_rst");
        sc_trace(tf, count, "tester_count");
    }

private:
    void run_tests() {
        // 初始化
        rst.write(true);
        wait(15, SC_NS);

        // 释放复位
        rst.write(false);
        std::cout << sc_time_stamp() << " [TEST] Reset released" << std::endl;

        // 等待计数到 10
        while (count.read() < 10) {
            wait(10, SC_NS);
        }
        std::cout << sc_time_stamp() << " [TEST] Count reached 10" << std::endl;

        // 等待计数到 50
        while (count.read() < 50) {
            wait(10, SC_NS);
        }
        std::cout << sc_time_stamp() << " [TEST] Count reached 50" << std::endl;

        // 等待溢出（255 → 0）
        sc_uint<8> prev = count.read();
        while (count.read() >= prev) {
            prev = count.read();
            wait(10, SC_NS);
        }
        std::cout << sc_time_stamp() << " [TEST] Overflow detected!" << std::endl;

        // 等待一段时间后结束
        wait(50, SC_NS);
        std::cout << sc_time_stamp() << " [TEST] Simulation complete" << std::endl;
        sc_stop();
    }
};


// ============================================================
// 顶层仿真
// ============================================================

int sc_main(int argc, char* argv[]) {
    std::cout << "========================================" << std::endl;
    std::cout << "SystemC Counter Demo with TLM-style" << std::endl;
    std::cout << "========================================" << std::endl;

    // ---------- 1. 创建时钟和信号 ----------
    sc_clock clk("clk", 10, SC_NS);      // 100MHz 时钟
    sc_signal<bool> rst;
    sc_signal<sc_uint<8>> cnt;

    // ---------- 2. 实例化模块 ----------
    Counter dut("counter", 255);          // 最大计数值 255
    Tester tester("tester");

    // ---------- 3. 端口连接 ----------
    dut.clk(clk);
    dut.rst(rst);
    dut.count(cnt);

    tester.rst(rst);
    tester.count(cnt);

    // 可选：启用调试输出
    dut.enable_debug(false);  // 设为 true 可看到详细调试信息

    // ---------- 4. 波形导出（封装调用）----------
    sc_trace_file* tf = sc_create_vcd_trace_file("counter_demo");
    tf->set_time_unit(1, SC_NS);

    // 追踪顶层时钟
    sc_trace(tf, clk, "top_clk");

    // 各模块自行追踪内部信号（优雅封装）
    dut.trace(tf);
    tester.trace(tf);

    // ---------- 5. 运行仿真 ----------
    std::cout << sc_time_stamp() << " [MAIN] Simulation started" << std::endl;
    sc_start(3000, SC_NS);  // 仿真 3000ns（足够观察到溢出 255→0）

    // ---------- 6. 清理 ----------
    sc_close_vcd_trace_file(tf);

    std::cout << "========================================" << std::endl;
    std::cout << "Waveform saved to counter_demo.vcd" << std::endl;
    std::cout << "View with: gtkwave counter_demo.vcd" << std::endl;
    std::cout << "========================================" << std::endl;

    return 0;
}
```

**编译运行**：

```shell
g++ -std=c++17 -DENABLE_DEBUG \
    -I/usr/include \
    -L/lib/x86_64-linux-gnu \
    -o counter_demo counter_demo.cpp \
    -lsystemc-2.3.4 -lm -lpthread

./counter_demo && gtkwave counter_demo.vcd
```

**关键编译配置**：

| 配置项 | 说明 |
|:---:|:---|
| `-std=c++17` | SystemC 2.3.4 库用 C++17 编译，必须匹配 ABI |
| `-I/usr/include` | SystemC 头文件路径 |
| `-L/lib/x86_64-linux-gnu` | SystemC 库文件路径 |
| `-lsystemc-2.3.4` | 指定具体版本的库 |
| `-DSC_INCLUDE_DYNAMIC_PROCESSES` | 启用动态进程支持 |

## 事务建模

> TLM, Transaction Level Modeling - 事务级建模，TLM 不是为了替代 RTL 或 HLS，而是为了简化系统级的通信建模，IEEE 1666-2023

芯片越复杂，RTL 仿真就越慢得无法接受，就直接使用事务驱动，减少无所谓的时钟周期浪费，不关心时钟边沿和具体信号，只关心模块之间是何时、传输了什么数据

`TLM1.0`时代：提供了基础的建模思想，但接口五花八门，A的CPU和B的内存接口可能不同，甚至得重复造轮子

`TLM2.0`时代：OSCI, Open SystemC Initiative 主导，定义了一套事实上的行业标准，提供了高标准的互操作性

**TLM = 系统级通信建模**

它关注：

```
“谁和谁通信”
“传了什么”
“多久完成”
```

而不是：

```
每拍怎么 toggle
ready/valid 怎么握手
wire 如何变化
```

关心的层次不一样，即：

```plaintext
// RTL 级别 AXI read

Cycle 0:
ARVALID=1

Cycle 1:
ARREADY=1

Cycle 2:
RVALID=1
RDATA=...

// TLM 级别 AXI read

直接：
mem.read(addr, data);

或者：
socket->b_transport(trans, delay);

RTL:
wire + handshake

TLM:
function call + payload

RTL:
master.valid <= 1;
master.addr  <= addr;

TLM:
trans.set_address(addr);
socket->b_transport(trans, delay);
```

### 五个基础概念

TLM-2.0 的强大之处在于其标准化和互操作性，这由五大支柱共同保证。

| 概念 | 本质 | 工业界对应物 | 一句话解释 |
| :---: | :---: | :---: | :---: |
| **Socket** | 通信接口 (连接器) | USB 或 PCIe 物理插槽 | 模块间标准化的连接点，定义了发起方 (`initiator`) 和目标方 (`target`) 的角色。 |
| **Transaction** | 总线事务对象 (数据包) | 快递包裹单 | 携带地址、数据、命令等所有信息的标准化 C++ 对象 (`tlm_generic_payload`)，是通信的载体。 |
| **Transport Interface** | 通信 API (快递服务) | 快递公司协议 (如联邦快递) | 定义了如何“发送”一个事务。主要有阻塞式 (`b_transport`) 和非阻塞式 (`nb_transport_fw`/`bw`)。 |
| **Timing Model** | 抽象时序模型 | 快递的“次日达”或“同城 2 小时达” | 用 `sc_time` 参数注解事务的耗时，**不模拟**每个时钟周期，只模拟关键的时间点。 |
| **Base Protocol** | 事务生命周期协议 | 快递“揽收-运输-派送”状态机 | 为非阻塞传输 (`nb_transport`) 定义了事务的标准阶段 (如 `BEGIN_REQ`, `END_RESP`)，确保不同模型能正确交互。 |

### 核心建模风格

> 工业界的核心建模风格：`LT vs. AT`

| 特性 | **Loosely-Timed (LT)** 松散定时 | **Approximately-Timed (AT)** 近似定时 |
| :---: | :---: | :---: |
| **一句话总结** | **“快递次日达”**：只管开始和结束，过程快且简单。 | **“快递物流跟踪”**：关心关键节点，时序更准。 |
| **核心接口** | 阻塞传输接口 (`b_transport`) | 非阻塞传输接口 (`nb_transport_fw`/`bw`) |
| **时序点数量** | 每事务 2 个 (开始，结束) | 每事务 ≥ 4 个 (协议阶段：请求开始/结束，响应开始/结束) |
| **同步方式** | **时间解耦 (Temporal Decoupling)**。发起者可“跑过头” (`run ahead`)，批量执行操作，定期与内核同步，开销极小。 | **锁步 (Lock-step)**。与 SystemC 内核严格同步，每个动作后可能 `wait(delay)`。 |
| **仿真速度** | **极快** (MHz 级别) | **相对较慢**，但仍远超 RTL |
| **主要用途** | *   **软件开发**：驱动、固件、操作系统移植<br>*   **虚拟原型**：软硬件协同验证<br>*   **性能分析** (粗略) | *   **微架构探索**：评估总线仲裁、流水线、内存控制器策略<br>*   **硬件性能验证** (时序相关) |
| **类比 (软件世界)** | 远端过程调用 (RPC) | 异步非阻塞 I/O + 回调 |

### Agent补充的阿吧阿巴...

#### LT 风格的工业级实现细节

LT 是工业虚拟原型中使用最广泛、价值最直接的风格。其高性能归功于两项关键技术。

##### 1. 时间解耦 (Temporal Decoupling)

*   **原理**：允许 CPU 指令集模拟器 (ISS) 等发起者模块在内部维护一个 `local_time`，一次性模拟执行多条指令 (例如 1000 条)，期间只累加 `local_time`，**而不进行任何 SystemC 内核的上下文切换**。只有当 `local_time` 超过一个预设的“时间量子” (`time quantum`)，或者需要与外界 (如访问外设) 同步时，才调用 `wait(local_time)` 让内核将仿真时间推进并切换进程。
*   **效果**：极大减少了内核调度和进程切换的开销，这是 TLM 实现 MHz 仿真速度的基石。

##### 2. 直接内存接口 (DMI)

*   **原理**：一种**旁路**机制。当 CPU 频繁访问一大段连续内存 (如执行代码) 时，CPU 模型可以通过 DMI 接口向内存模型申请一个**直接指针**。申请成功后，CPU 模型在时间量子内，可以直接通过 `memcpy` 这样的 C++ 操作访问主机内存，**完全绕过** TLM 的 `b_transport` 调用、总线互连模型和地址解码逻辑。
*   **类比**：相当于软件中的 **内存映射 (mmap)**。
*   **效果**：将数万次缓慢的 TLM 事务调用，转换为几次快速的本地内存拷贝，再次实现数量级的性能提升。这也是为什么 TLM 虚拟原型能流畅运行 Linux 的关键。

---

#### AT 风格的核心概念：非阻塞传输

当一个事务被分解成多个阶段时，就需要非阻塞接口来支持复杂的流水线和乱序行为。

1.  **协议阶段 (`tlm_phase`)**：
    标准的基础协议定义了四个核心阶段：
    *   `BEGIN_REQ`：请求开始
    *   `END_REQ`：请求结束 (请求已发送)
    *   `BEGIN_RESP`：响应开始
    *   `END_RESP`：响应结束
    这类似于 AXI 总线的地址/数据阶段分离。

2.  **双向接口**：
    *   **前向路径 (`nb_transport_fw`)**：从发起者到目标者。
    *   **后向路径 (`nb_transport_bw`)**：从目标者返回到发起者。
    *   这种设计允许目标者在收到请求后，主动通过后向路径发起一个响应阶段。

3.  **非阻塞语义**：
    *   函数 `nb_transport_fw` 会立即返回一个 `tlm_sync_enum` 状态，告诉调用者是完成了 (`TLM_COMPLETED`)，还是需要等待后续 (`TLM_UPDATED`/`TLM_ACCEPTED`)，从而精细地建模流水线和握手。

> **重要提醒**：对于初学者，AT 模型非常复杂，且会显著降低仿真速度。**除非你明确需要进行精确的微架构时序分析，否则应优先使用 LT 风格。**

---

#### 澄清常见误区：TLM vs. HLS vs. RTL

| 建模层次 | 目标 | 抽象程度 | 典型用途 | 可综合性 |
| :--- | :--- | :--- | :--- | :--- |
| **RTL** (Verilog/VHDL) | 精确描述硬件逻辑 | **最低** (时钟/信号级) | 芯片逻辑设计与综合 | **是** (标准流程) |
| **HLS** (C/C++/SystemC子集) | 描述算法与数据流 | **中** (算法/状态机级) | 快速生成高质量 RTL，加速硬件设计 | **是** (通过 HLS 工具) |
| **TLM** (SystemC TLM-2.0) | **快速系统级仿真** | **最高** (事务/函数调用级) | 软件开发、架构探索、虚拟原型 | **否** (特征：含动态内存、虚函数、操作系统抽象) |

**结论**：TLM 模型 (尤其是 LT 风格) 通常**不可综合**，其价值在于**仿真速度**而非硬件实现。HLS 和 TLM 使用类似的 C++ 语法，但解决的问题域和代码风格截然不同。**不要混淆两者**。

> todo-list: TLM 风格的以后再说吧，，，
