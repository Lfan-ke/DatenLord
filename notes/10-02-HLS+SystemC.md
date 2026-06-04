# HLS + SystemC

> 重要前提：本篇是【通用 HLS 背景】，与本课的 `bsc -systemc` **无关**。
> `bsc -systemc` 生成的是 **Bluesim 驱动的时钟级 SystemC 仿真包装**（含 `SC_METHOD`/`bk_*` 内核桥），
> **不做** HLS/C→RTL 调度，下面的 `#pragma HLS ...` 对它不适用。详见 `execs/10-03-01-Adder2SC`。

“SystemC” 实际有两种完全不同用途：

- `TLM SystemC` - 系统级仿真
- `HLS SystemC` - 硬件综合（第三方 HLS 工具，非 bsc）

HLS, High-Level Synthesis, C/C++/SystemC/... -[`HLS 工具`]-> Verilog/VHDL/...

| 层次 | 工具/语言 | 核心目标 |
| :---: | :-----: | :-----: |
| **系统仿真** | TLM SystemC | 快速架构探索、软件开发 |
| **行为综合** | HLS SystemC | 从 C/SystemC 生成 RTL |
| **精确描述** | Verilog / BSV / Chisel | 精确控制硬件结构 |

**HLS 擅长 vs RTL 更适合**：

| HLS 擅长 | RTL 更适合 |
| :---: | :---: |
| DSP / FIR 滤波器 | Cache coherence |
| CNN / AI 加速器 | NoC (片上网络) |
| 图像处理 | Out-of-order CPU |
| Streaming pipeline | 精确协议 (PCIe/DDR) |

**Chisel/BSV vs HLS 的本质区别**：

| | Chisel / BSV | HLS |
| :---: | :---: | :---: |
| **本质** | RTL 构造语言 | 从行为推导电路 |
| **方式** | 直接构建电路 | 工具自动决定结构 |
| **可控性** | 高（知道每个 FF） | 低（编译器决定） |

HLS 编译器本质是一个 **“行为级硬件调度器”**，而非 C 编译器：

| 任务 | 说明 |
| :--: | :--: |
| **Scheduling (调度)** | 决定哪个操作在哪个 cycle 执行 |
| **Resource Allocation** | 决定用几个乘法器、ALU 等 |
| **Binding** | 操作绑定到具体硬件资源 |
| **FSM Generation** | 生成 `always @(posedge clk)` 状态机 |

**核心风格：SC_CTHREAD + wait()**

```cpp
void proc() {
    while (true) {
        c = a + b;
        // HLS 理解：wait() = 时钟边界，之前逻辑被寄存器锁存
        wait();
    }
}
```

对应RTL：

```verilog
always @(posedge clk) begin
    c <= a + b;
end
```

**HLS 核心能力：自动 Pipeline**

```cpp
for (i = 0; i < N; i++) y[i] = a[i] + b[i];
```

HLS 自动将循环迭代重叠执行，生成 streaming pipeline。

**Pragma 控制**：

| Pragma | 含义 | 硬件效果 |
| :---: | :---: | :---: |
| `#pragma HLS pipeline II=1` | 每周期启动新迭代 | 吞吐率最高 |
| `#pragma HLS pipeline II=2` | 每 2 周期启动新迭代 | 共享资源，面积更小 |
| `#pragma HLS unroll` | 完全展开循环 | 并行副本，面积 ×N |
| `#pragma HLS unroll factor=2` | 部分展开 | 2 路并行，面积 ×2 |

人话版本：

| Pragma | 意思是 |
| :---: | :---: |
| **`pipeline`** | “我要流水线，每 X 周期出一个结果” |
| **`unroll`** | “我要并行复制硬件，用面积换时间” |

> 通过一行特殊的注释，告诉 HLS 工具如何生成硬件

比如上面的：

```cpp
for (i = 0; i < N; i++) y[i] = a[i] + b[i];
```

这可以是：

- 顺序执行（用 1 个加法器，4 个周期）
- 并行执行（用 4 个加法器，1 个周期）
- 流水线执行（用 1 个加法器，但每周期处理一个新数据）

Pragma 就是用来告诉工具：我要哪种，比如：

**1. `#pragma HLS pipeline II=1`**

```c++
for (int i = 0; i < 4; i++) {
    #pragma HLS pipeline II=1   // 每周期来一个新的 i
    y[i] = a[i] + b[i];
}
```

硬件效果：
- **1 个加法器**
- 第 1 周期：计算 `y[0]`
- 第 2 周期：计算 `y[1]`（同时上一周期结果写回）
- 吞吐率：每周期 1 个结果

**2. `#pragma HLS pipeline II=2`**

```cpp
#pragma HLS pipeline II=2
```

硬件效果：
- **1 个加法器**
- 第 1 周期：计算 `y[0]`
- 第 2 周期：空闲
- 第 3 周期：计算 `y[1]`
- 吞吐率：每 2 周期 1 个结果（面积不变，但速度慢一倍）

**3. `#pragma HLS unroll`**

```cpp
#pragma HLS unroll    // 完全展开
```

硬件效果：
- **4 个加法器**（同时运行）
- 1 个周期内算出所有 `y[0]` ~ `y[3]`
- 吞吐率：1 周期 4 个结果，但面积 ×4

**4. `#pragma HLS unroll factor=2`**

```cpp
#pragma HLS unroll factor=2   // 部分展开，2 路并行
```

硬件效果：
- **2 个加法器**
- 第 1 周期：计算 `y[0]` 和 `y[1]`（同时）
- 第 2 周期：计算 `y[2]` 和 `y[3]`
- 面积 ×2，速度 ×2
