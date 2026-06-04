# BSC Contrib —— 额外贡献库

> 源：`other/bsc-contrib`（社区/Bluespec 贡献，尚未进核心 bsc 的库与工具）。各库**默认不在搜索路径**，要用时显式加 `-p +:<安装路径>/Libraries/<分类>`。

## 安装

```bash
# 源在 other/bsc-contrib，编译产物默认进 ./inst（PREFIX 可改）
cd other/bsc-contrib
make install PREFIX=$PWD/inst       # 装到 inst/lib/Libraries/<分类>、inst/lib/Verilog
# 装到系统目录（本机已装到 /usr/local/bsc-contrib）：
#   先本地 make install（普通用户，环境含 BLUESPECDIR），再 sudo cp inst/lib /usr/local/bsc-contrib
```

> 坑：直接 `sudo make install` 会因 sudo 剥离 `BLUESPECDIR` 而报 `Cannot find package 'Prelude'`；应**普通用户构建**再 `sudo cp`。

## 使用 & 验证

```bash
# 加对应分类的路径即可（% 代表 BLUESPECDIR；这里用绝对路径）
bsc -sim -u -g mkTop -p +:/usr/local/bsc-contrib/Libraries/Misc Top.bsv
```

```bsv
package Top;
import Cur_Cycle::*;                 // 来自 contrib/Misc
(* synthesize *)
module mkTop(Empty);
   rule r; $display("cyc=%0d", cur_cycle); $finish(0); endrule
endmodule
endpackage
// 实测：bsc -sim -u -g mkTop -p +:/usr/local/bsc-contrib/Libraries/Misc → 编译通过
```

---

## 各分类一览

| 分类 | 内容与用途 |
|:---:|:---:|
| **AMBA_Fabrics** | 现代 **AXI4 / AXI4-Lite / AXI4-Stream** fabric。`AXI4/` 下：`AXI4_Types`(请求/响应通道结构)、`AXI4_Fabric`(M×S 交叉互联)、`AXI4_Deburster`(突发拆分)、`AXI4_Widener`(位宽转换)、`AXI4_Clock_Crossers`(跨时钟域)、`AXI4_Mem_Model`(内存从机)、`AXI4_Addr_Translator`、`AXI4_Gate`；另有 `Adapters`/`Utils`。工业级片上互联首选。 |
| **AMBA_TLM2** | 事务级总线建模 v2：`TLM`(顶层)、`AHB`、`Axi`。对应 04-02 提到的"工业级 TLM"。 |
| **AMBA_TLM3** | TLM v3：`Ahb`/`Apb`/`Axi`/`Axi4`，含 `TLM3Defines`/`TLM3Api`/`TLM3BRAM` 等；标准 `TLMRequest`/`TLMResponse` + 突发 + 字节使能。 |
| **Bus** | 通用总线抽象：`Bus.bsv`(接口)、`BusDefines.bsv`(类型)、`BusFIFO.bsv`(带总线语义的 FIFO)。 |
| **COBS** | Consistent Overhead Byte Stuffing 流式编/解码（`.bs`/BH 写的流水模块）：把消息编成**不含 0 字节**的帧、0 作分隔符，串口/网络分帧常用。 |
| **FPGA** | 厂商原语封装：`Xilinx`/`Altera`/`DDR2`/`Misc`（PLL、IO、DDR2 控制器接口等）。 |
| **GenC** | 软硬件协同：`GenCMsg`(HW↔SW 消息通道，配 `build_ffi.py` 生 C 侧 FFI)、`GenCRepr`(把 BSV 类型自动生成等价 C `struct`/序列化，主机侧同布局收发)。 |
| **Misc** | 6 个常用小工具（见下表） |
| **SequenceRules** | 用 `List`/`MList` 把规则序列组合的轻量顺序控制（BH 写）；StmtFSM 之外另一种"按序触发规则"方案。 |
| **VerilogRepr** | 把 BSV 类型映射到 Verilog 表示(`VerilogRepr.bs`) + `Json.bs`(导出类型布局为 JSON 给外部工具)。 |

### Misc 工具

| 文件 | 接口/函数 | 用途 |
|:---:|:---:|:---:|
| `CreditCounter.bsv` | `mkCreditCounter` → `CreditCounter_IFC#(w)`：`value`/`incr`(< maxBound 守卫)/`decr`(>0 守卫)/`clear` | 信用流控计数器，用 CReg 实现，**同拍可并发 incr/decr** |
| `Cur_Cycle.bsv` | `cur_cycle`(ActionValue 返回周期号) | 取当前周期号（调试/打印） |
| `EdgeFIFOFs.bsv` | `mkM_EdgeFIFOF`(主侧)/`mkS_EdgeFIFOF`(从侧) → `FIFOF#(t)` | 1 元素边界 FIFOF，IP 接 AXI4-Lite/AHB-Lite 等总线的边界缓冲 |
| `GetPut_Aux.bsv` | `pop(f)`、`fa_show_FIFOF_state`、`mkDiscardFIFOF`、`mkMux_Clients_Server` | FIFO/Get/Put 便捷函数；`pop` 一步 first+deq |
| `Semi_FIFOF.bsv` | `FIFOF_I`(输入半)/`FIFOF_O`(输出半) + 转换 + `mkConnection` | 把 FIFOF 拆成"只入/只出"两半接，便于跨模块连 |
| `VectorFIFOF.bsv` | `mkVectorFIFOF` → `fifo`(标准 FIFOF) + `vector()`(全元素 `Vector#(depth,Maybe#(t))`) | 参数化深度 FIFOF，且可**并行查看全部元素**；enq/deq/clear 任意序 |

---

## 可跑示例（execs/16-01-01-Contrib）

`Misc` 的 `CreditCounter` + `GetPut_Aux.pop` + `Cur_Cycle`，演示信用流控（发包占信用、收包释放）：

```bsv
import CreditCounter::*; import GetPut_Aux::*; import Cur_Cycle::*; import FIFOF::*;
CreditCounter_IFC#(4) credit <- mkCreditCounter;   // 4 位信用，incr 到顶 / decr 到 0 自带守卫
FIFOF#(Bit#(8))       q      <- mkFIFOF;
// ... 发：credit.incr; q.enq(x);    收：let x <- pop(q); credit.decr;
```

编译要加 contrib 路径：

```bash
bsc -sim -u -g mkTop -p +:/usr/local/bsc-contrib/Libraries/Misc Top.bsv
```

实测输出：

```
cyc=4 credits_used=2      <- 连发 2 个，占用 2 信用
pop=a0  pop=a1            <- pop 一步取出（first+deq）
cyc=7 credits_used=0      <- 收完 2 个，信用归 0
```

### 示例 2：VectorFIFOF —— 并行查看全部元素（execs/16-01-02-VectorFIFOF）

普通 FIFOF 只能看队头；`VectorFIFOF` 额外给一个 `vector()`，一拍看到所有槽（空槽为 `Invalid`），常用于做"队列内容相关的调度/查找"：

```bsv
import VectorFIFOF::*;
VectorFIFOF#(4, Bit#(8)) vf <- mkVectorFIFOF;      // 深度 4
vf.fifo.enq(x);  vf.fifo.deq;  vf.fifo.first;       // .fifo 是标准 FIFOF 接口
Vector#(4, Maybe#(Bit#(8))) view = vf.vector;       // 同时并行查看全部元素
```

```
after enq 3: view=[11 22 33 ff]    <- ff = 空槽(Invalid)
after deq 1: view=[22 33 ff ff]
```

> AMBA/GenC/COBS 等更重的库各带例子在 `other/bsc-contrib/testing/` 与各库 README；上面两个是最小可跑的串通入口。

---

## 与 AMBA TLM 的关系（接 04-02）

04-02 用 base 库的 `GetPut`/`Client`/`Server` 手搓事务级模型；**真正的 AMBA 总线 TLM** 在这里：`AMBA_TLM2`/`AMBA_TLM3` 提供标准 `TLMRequest`/`TLMResponse`、突发传输、字节使能、`TLMSendIFC`/`TLMRecvIFC`，以及与 AHB/APB/AXI(4) 的桥接；`AMBA_Fabrics` 则是更现代的 AXI4 fabric/互联。需要时按上面的 `-p +:.../Libraries/AMBA_TLM3` 加路径。

---

## 测试（DejaGnu，接官方 bsc-testsuite）

`other/bsc-contrib/testing/bsc.contrib/` 下是各库的 **DejaGnu 回归测试**（`*.exp` + `contrib.tcl`，覆盖 COBS/Misc/SequenceRules/GenC/AMBA_Fabrics/VerilogRepr 等）。它本身**不带 runner**，复用官方 [bsc-testsuite](https://github.com/B-Lang-org/bsc-testsuite)（B-Lang-org 的 bsc 回归测试框架）的基础设施跑：

```bash
cp -r other/bsc-contrib/testing/bsc.contrib /path/to/bsc/testsuite/   # 放进 bsc 测试目录
cd /path/to/bsc/testsuite/bsc.contrib/
export BSCCONTRIBDIR=/path/to/bsc-contrib/inst   # 指向已安装的 contrib 库（contrib.tcl 据此判定是否跑）
make check                                        # DejaGnu 跑全部 .exp
```

> 即：`bsc-testsuite` 是**独立的官方仓库**（测 bsc 编译器本身，DejaGnu）；bsc-contrib 只提供测试**用例**插进去，靠 `BSCCONTRIBDIR` 定位被测的已装库。本仓库 `other/` 下**没有** bsc-testsuite。
