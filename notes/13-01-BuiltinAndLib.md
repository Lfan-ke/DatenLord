# 内置内容与标准类库

> 结合 BSC 源码（`$BLUESPECDIR/Libraries`，源在 `specs/src/Libraries/{Base1,Base2,Base3-*}`）整理各库的接口、模块构造子、关键 API 与用法。
> `.bs` 是 Bluespec Classic 语法、`.bsv` 是 BSV 语法；下面统一用 BSV 写法。
> 时钟域库见 11-01、StmtFSM 见 05-01、PAClib 见 14-01、并发原语见 12-01/03-01。

---

## FIFO 家族

### FIFO / FIFOF（Base1）

```bsv
interface FIFO#(type a);                 interface FIFOF#(type a);   // 多了两个标志
   method Action enq(a x);                  method Action enq(a x);
   method Action deq;                       method Action deq;
   method a      first;                     method a      first;
   method Action clear;                     method Bool   notFull;
endinterface                                method Bool   notEmpty;
                                            method Action clear;
                                         endinterface
```

| 构造子 | 深度/语义 |
|:---:|:---:|
| `mkFIFO` / `mkFIFOF` | 默认深度 2 |
| `mkFIFO1` / `mkFIFOF1` | 深度 1 |
| `mkSizedFIFO(n)` / `mkSizedFIFOF(n)` | 深度 n |
| `mkLFIFO` / `mkLFIFOF` | 深度1 "loopy"，满时可同拍 deq+enq（**deq 先于 enq**） |
| `mkUGFIFOF*` | 无隐式条件（要自己查 notFull/notEmpty） |
| `mkGFIFOF#(Bool ugenq, Bool ugdeq)` | 逐端口选择是否去守卫（恰两个 Bool 参数） |

> 普通 `mkFIFO`(深度≥2) 满时**不能**同拍 enq+deq；方法默认带隐式条件（rule 会自动 stall）。

```bsv
FIFO#(int) f <- mkFIFO;
rule prod; f.enq(x); endrule
rule cons; let v = f.first; f.deq; endrule
```

### SpecialFIFOs（Base3-Misc）—— 1 元素、可同拍但调度方向不同

| 构造子 | 语义 |
|:---:|:---:|
| `mkPipelineFIFO` / `mkPipelineFIFOF` | 满时可 deq、或同拍 deq+enq（**deq 先于 enq**），寄存器式、1 拍延迟 |
| `mkBypassFIFO` / `mkBypassFIFOF` | 空时可 enq、或同拍 enq+deq（**enq 先于 deq**），**enq→deq 是组合通路**，0 拍 |
| `mkDFIFOF(dflt)` | deq/first 无隐式条件，空时 first 返回 dflt |
| `mkSizedBypassFIFOF(n)` | 深度 n 的 bypass |

> 口诀：Pipeline=deq先(寄存器/1拍)，Bypass=enq先(组合/0拍)。

### 其他 FIFO

- `mkFIFOLevel`（Base1）：`FIFOLevelIfc#(a, depth)` 多了 `isLessThan(c)`/`isGreaterThan(c)`（**c 是编译期常量**）、`notFull/notEmpty`；深度须 >2。`FIFOCountIfc` 暴露 `count`。
- `mkSizedBRAMFIFO(n)` / `mkSizedBRAMFIFOF(n)`（Base3-Misc）：BRAM 背书的大深度 FIFO（元素宽 ≥1 位），自带 1 项写旁路。

---

## 接口与连接（事务级，详见 04-01/04-02）

```bsv
interface Get#(type a);  method ActionValue#(a) get;  endinterface
interface Put#(type a);  method Action put(a x);      endinterface
typedef Tuple2#(Get#(a), Put#(a)) GetPut#(type a);

interface Client#(type a, type b);  interface Get#(a) request; interface Put#(b) response; endinterface
interface Server#(type a, type b);  interface Put#(a) request; interface Get#(b) response; endinterface
```

- 转换：`toGet(x)` / `toPut(x)`（对 FIFO/FIFOF/Reg/RWire 等都有实例）；`toGPClient(g,p)` / `toGPServer(p,g)`。
- 连接：`mkConnection(a, b)`（`Connectable` 类）——Get↔Put、Client↔Server、Tuple、Vector、`ReadOnly↔WriteOnly`、`Action↔Action`、Inout 等都有实例。
- 缓冲：`mkGetPut`/`mkGPFIFO`、`mkRequestResponseBuffer`、`joinServers`/`splitServer`。

```bsv
mkConnection(producer.out, consumer.in);   // out::Get, in::Put
Server#(Req,Rsp) s = toGPServer(reqFifo, respFifo);
```

---

## 容器

### Vector（Base1）—— 定长 `Vector#(n, a)`，可综合（元素0在低位）

```bsv
// 生成
newVector  :: Vector#(n,a)                 // 全未定义
replicate(c)            genWith(f)         // n个c / f(0..n-1)
// 索引/更新（动态索引→mux）
v[i]      select(v,i)   update(v,i,x)      head/last/tail/init
take/drop/takeAt        append(a,b)  concat(vv)
// 高阶
map(f,v)   zipWith(f,a,b)   zip/unzip
foldr/foldl(f,z,v)         fold(f,v)        // fold=平衡树 O(log n)；foldl/r=线性链 O(n)
scanl/scanr/mapAccumL      reverse/rotate/rotateR
elem/any/all/find          findElem/findIndex/countElem
// monad（实例化 N 份硬件）
mapM/mapM_/zipWithM/genWithM/replicateM
```

```bsv
Vector#(8, Reg#(Bit#(32))) rs <- replicateM(mkReg(0));   // 8 个寄存器
let total = fold(\+ , zipWith(\+ , va, vb));             // log 深加法树
```

### List / ListN（Base1）

- `List#(a)`：**编译期/elaboration** 结构（非可综合状态），长度是运行时 `Integer`；用于生成循环、配置表。API 似 Vector，但 `take/drop/replicate` 的计数 `Integer` 在**第一个参数**；额外有 `upto(n,m)`、`sort`、`lookup`。
- `ListN#(n,a)`：定长 list，可 `Bits`；顺序处理（head/tail/fold）首选，随机索引用 Vector。

---

## 寄存器变体

| 模块 | 语义 / 调度 |
|:---:|:---:|
| `mkReg(v)` | 同步复位到 v；`read < write`（读到旧值） |
| `mkRegU` | 无复位（更省面积，承诺先写后读） |
| `mkRegA(v)` | **异步**复位到 v |
| `mkConfigReg(v)`（Base1/ConfigReg） | 同 mkReg 硬件，但 **read/write 无调度约束**（读恒得旧值，用于打破读写冲突） |
| `mkDReg(v)`（Base2/DReg） | 写入值只保持 1 拍，之后**自动回到默认 v**（one-shot 脉冲/valid） |
| `mkBypassReg(v)`（Base3-Misc） | `WReg`：`bypass(x)` 同拍组合前递给 `_read` |
| `mkRevertingVirtualReg(v)`（Base1） | 纯**调度用**虚寄存器，强制 `read<write` 排序，写值被忽略 |

---

## 计数器

```bsv
// Counter（Base1）：包装 Verilog Counter 原语
interface Counter#(numeric type n);
   method Action inc(Bit#(n) v); method Action dec(Bit#(n) v);
   method Action up; method Action down; method Bit#(n) value;
   method Action setC(Bit#(n) v); method Action setF(Bit#(n) v); method Action clear;
endinterface
module mkCounter#(Bit#(n) init)(Counter#(n));

// Cntrs（Base3-Misc）：CReg 式并发计数器，多 rule 同拍可分别 incr/decr
interface Count#(type t);
   method Action incr(t v); method Action decr(t v); method Action update(t v);
   method Action _write(t v); method t _read;
endinterface
module mkCount#(t resetVal)(Count#(t)) provisos (Arith#(t), ModArith#(t), Bits#(t,st));
// 调度：_read < update < (incr, decr) < _write；incr 与 decr 互不冲突
// UCount：mkUCount#(Integer init, Integer maxValue) —— 位宽按 maxValue 自动选，带 isEqual/isLessThan/isGreaterThan
```

```bsv
Count#(UInt#(8)) c <- mkCount(0);
rule a; c.incr(1); endrule    // 这两条
rule b; c.decr(2); endrule    // 可同拍触发
```

---

## 存储

```bsv
// RegFile（Base1）：多读口/单写口数组
interface RegFile#(type i, type a);
   method Action upd(i idx, a val);  method a sub(i idx);
endinterface
module mkRegFile#(i lo, i hi)(RegFile#(i,a));   // sub < upd（读旧值）
module mkRegFileFull(RegFile#(i,a)) provisos (Bounded#(i), …);
module mkRegFileWCF#(i lo, i hi)(RegFile#(i,a)); // upd/sub 无冲突
// 文件初始化：mkRegFileLoad("hex.txt", lo, hi)（一般仅仿真）

// BRAM（Base3-Misc，core 在 Base2/BRAMCore）：Server 风格
typedef struct { Bool write; Bool responseOnWrite; addr address; data datain; } BRAMRequest#(type addr,type data);
module mkBRAM2Server#(BRAM_Configure cfg)(BRAM2Port#(addr,data));   // cfg = defaultValue 再改字段
// cfg: memorySize/latency/loadFormat/outFIFODepth/allowWriteResponseBypass
```

```bsv
BRAM_Configure cfg = defaultValue; cfg.memorySize = 1024;
BRAM2Port#(Bit#(10), Bit#(32)) mem <- mkBRAM2Server(cfg);
mem.portA.request.put(BRAMRequest{write:False, responseOnWrite:False, address:a, datain:?});
let d <- mem.portA.response.get;
```

---

## 数学（Base3-Math）

```bsv
// FixedPoint#(isize, fsize)：有符号定点
typedef struct { Bit#(isize) i; Bit#(fsize) f; } FixedPoint#(numeric type isize, numeric type fsize);
fromInt / fromUInt / fromRational(num,den) / fromReal(r)   // 构造
fxptMult / fxptAdd / fxptSub / fxptQuot                    // 全精度（输入可不同位宽）
fxptTruncate / fxptSignExtend / fxptTruncateRoundSat(rmode,smode,x)
fxptWrite(fwidth, x)                                       // 打印小数（fwidth 位，截断）
// 实例：Arith/Ord/Bounded/Bitwise/Literal/RealLiteral/FShow；epsilon() 是最小量 2^-f

// Complex#(t)：复数
typedef struct { t rel; t img; } Complex#(type t);
cmplx(re, im)  c.rel  c.img  cmplxMap(f,c)  cmplxConj(c)  cmplxSwap(c)
// Arith：+/- 分量、* 全复乘(4 乘法器)、/ 除以模平方

// Real（Base1/Real.bs）：仅编译期（elaboration），不可综合
sin/cos/tan/sqrt/pow/atan2/pi/floor/ceil/round/trunc …
```

---

## 随机 / 校验 / 编码

```bsv
// Randomizable（Base3-Misc）
interface Randomize#(type a);
   interface Control cntrl;            // cntrl.init() 先调一次
   method ActionValue#(a) next();
endinterface
module mkGenericRandomizer(Randomize#(a)) provisos (Bits#(a,sa), Bounded#(a));      // 全范围
module mkConstrainedRandomizer#(a min, a max)(Randomize#(a));                       // 限定区间

// LFSR（Base2）：伪随机/计数
interface LFSR#(type a); method Action seed(a x); method a value; method Action next; endinterface
module mkLFSR_16(LFSR#(Bit#(16)));  // 还有 _4/_8/_32、mkPolyLFSR(taps)、mkFeedLFSR(mask)、mkRCounter

// CRC（Base3-Misc）
interface CRC#(numeric type n);
   method Action add(Bit#(8) data); method Action clear; method Bit#(n) result;
   method ActionValue#(Bit#(n)) complete;
endinterface
module mkCRC32(CRC#(32));   // 还有 mkCRC16/mkCRC_CCITT、通用 mkCRC#(poly,init,finalXor,reflD,reflR)

// Gray（Base3-Misc）：跨时钟域安全的格雷码
grayEncode(v) / grayDecode(g) / grayIncr(g) / grayDecr(g)
module mkGrayCounter#(Gray#(n) init, Clock dClk, Reset dRstN)(GrayCounter#(n)); // 计数同步到 dClk
```

```bsv
Randomize#(Bit#(16)) rnd <- mkConstrainedRandomizer(0, 99);
rule start;   rnd.cntrl.init; endrule
rule consume; let x <- rnd.next; endrule   // 注意 use 是保留字，不能做 rule 名
```

---

## 调试 / 断言 / 杂项

```bsv
// Probe（Base1）：只写，永不被优化掉；波形里出现 <inst>$PROBE
Probe#(Bit#(8)) p <- mkProbe;   // 然后 p <= sig; 观察
// Assert（Base1）
staticAssert(cond, "msg");      // 编译期
dynamicAssert(cond, "msg");     // 运行期（Action 内）
continuousAssert(cond, "msg");  // 每拍检查
// DefaultValue（在 Prelude）：typeclass DefaultValue#(t); t defaultValue;

// 静态细化期消息（编译时，不是仿真 $display）—— 用于库/参数检查
messageM("...")   // 细化时打印
errorM("...")     // 细化时报错终止
warningM("...")   // 细化时警告
```

---

## 全库目录（124 个包，`ls $BLUESPECDIR/Libraries`）

> 编译产物 `.bo`；源在 `specs/src/Libraries/{Base1,Base2,Base3-Contexts,Base3-Math,Base3-Misc}`。
> 标 ★ 的有专篇用法 + 可跑示例（见对应 13-xx / 14-01）。下面按类别**逐包**给一句话功能。

### FIFO / 队列（16）

| 包 | 功能 |
|:---:|:---:|
| `FIFO` ★ | 基础 FIFO 接口/构造子（mkFIFO/1/Sized/LFIFO），见 13-02 |
| `FIFOF` ★ | 带 notFull/notEmpty 的 FIFO，见 13-02 |
| `FIFOF_` | FIFOF 的底层实现包（带 `_` 的原始版，一般不直接用） |
| `SpecialFIFOs` ★ | mkPipelineFIFO(deq先)/mkBypassFIFO(enq先)/mkDFIFOF/mkSizedBypassFIFOF |
| `FIFOLevel` ★ | 带 level 比较（isLessThan/count）的 FIFO，见 13-02 |
| `LevelFIFO` | FIFOLevel 的旧别名（兼容保留） |
| `BRAMFIFO` ★ | BRAM 背书的大深度 FIFO（mkSizedBRAMFIFO），见 13-02 |
| `AlignedFIFOs` | 跨时钟域、可参数化对齐的同步 FIFO 族 |
| `FoldFIFO` / `FoldFIFOF` | 入队时即时做归约（fold）的 FIFO |
| `ListFIFO` | 用 List 实现、可遍历内容的 FIFO |
| `NullCrossingFIFOF` | 0 延迟跨时钟域 FIFO（`CrossingFIFOF`，配 Clocks 用） |
| `TurboFIFO` | 高吞吐内部实现 FIFO |
| `MIMO` ★ | 多入多出，一拍 enq/deq 任意个数（变长打包），见 13-11 |
| `Gearbox` ★ | 位宽/速率转换 FIFO（如 32↔128），见 13-11 |
| `CompletionBuffer` ★ | 重排序缓冲：乱序完成、按预订顺序流出，见 13-11 |

### 接口 / 连接（11）

| 包 | 功能 |
|:---:|:---:|
| `GetPut` ★ | Get/Put 及 toGet/toPut，见 13-06 |
| `ClientServer` ★ | Client/Server（req+rsp 对），见 13-06 |
| `Connectable` ★ | `mkConnection` 类型类，见 13-06 |
| `BGetPut` / `CGetPut` | 带缓冲 / 带握手协议（credit）的 Get/Put 变体 |
| `CommitIfc` | accept/acknowledge 提交协议（FIFO 两端模型） |
| `Pull` / `Push` / `RPush` | 数据流接口：拉式 / 推式 / 带反压推式 |
| `Memory` | 通用 `MemoryRequest/Response`（读写统一）接口 |
| `Mcp` | 多周期路径（multi-cycle path）单元封装 |

### 容器 / 数据结构（11）

| 包 | 功能 |
|:---:|:---:|
| `Vector` ★ | 定长可综合向量 + 高阶函数，见 13-03 |
| `List` ★ | 编译期变长列表（生成用），见 13-03 |
| `ListN` ★ | 定长可 Bits 列表，见 13-03 |
| `BuildVector` ★ | `vec(a,b,c)` 变参构造向量 |
| `BuildList` | `list(a,b,c)` 变参构造 List |
| `UnitAppendList` | 可 O(1) 追加的列表（tagged union） |
| `HList` | 异构列表（不同元素类型，编译期） |
| `IVec` | 索引向量类型类 |
| `OInt` | one-hot 整数（`OInt#(n)`，索引天然 one-hot 编码） |
| `TreeMap` | 平衡树映射（编译期容器） |
| `Array` | 数组原语辅助（`primArray*`） |

### 寄存器变体（7）

| 包 | 功能 |
|:---:|:---:|
| `ConfigReg` ★ | 读写无调度约束的寄存器，见 13-04 |
| `DReg` ★ | 写后 1 拍自动回默认值（one-shot），见 13-04 |
| `BypassReg` | 同拍组合前递（`bypass(x)` → `_read`） |
| `RevertingVirtualReg` | 纯调度用虚寄存器，强制 read<write |
| `ListReg` | 把 Reg 串成可移位的列表寄存器 |
| `RegTwo` | 双写口寄存器（两端口语义） |
| `RegFile` ★ | 多读单写寄存器堆，见 13-07 |

### 计数器（3）

| 包 | 功能 |
|:---:|:---:|
| `Counter` ★ | Verilog 原语封装计数器，见 13-05 |
| `Cntrs` ★ | CReg 式并发计数器（同拍 incr/decr），见 13-05 |
| `GrayCounter` | 格雷码计数器，跨时钟域安全 |

### 存储 / RAM（13）

| 包 | 功能 |
|:---:|:---:|
| `BRAM` ★ | Server 风格块 RAM，见 13-07 |
| `BRAMCore` | BRAM 底层（无 FIFO，贴硬件 BRAM_PORT） |
| `BRAM_Compat` | 旧 BRAM API 兼容层 |
| `RAM` | 通用 RAM 接口抽象 |
| `SRAM` / `SPSRAM` / `DPSRAM` | 单端口 / 单口 / 双口 SRAM 外部封装 |
| `SyncSRAM` | 同步 SRAM 封装 |
| `SRAMFile` | 文件初始化的 SRAM（仿真） |
| `TRAM` / `STRAM` / `SplitTRAM` | **带标签 RAM**（TRAM=Tagged RAM，读请求附 tag 随响应返回；STRAM=带标签 SRAM；SplitTRAM 拆分 TRAM） |
| `SplitPorts` | 把读写端口拆分成独立信号 |

### 数学 / 算术（10）

| 包 | 功能 |
|:---:|:---:|
| `FixedPoint` ★ | 有符号定点，见 13-08 |
| `Complex` ★ | 复数，见 13-08 |
| `Real` ★ | 编译期浮点函数（sin/sqrt…不可综合），见 13-08 |
| `Math` | 汇总包：一次性 re-export Complex/FixedPoint/NumberTypes/Divide/SquareRoot/FloatingPoint |
| `FloatingPoint` | 可综合 IEEE 浮点（加减乘除/比较） |
| `Divide` | 非恢复除法器（多周期 Server） |
| `SquareRoot` | 开方器（多周期 Server） |
| `Wallace` | Wallace 树多数相加压缩（`wallaceAdd`/`wallaceAddBags`） |
| `PopCount` ★ | 数 1 的个数（树形 popCount），见 13-11 |
| `FlexBitArith` | 灵活位宽算术辅助 |

### 随机 / 校验 / 编码（5）

| 包 | 功能 |
|:---:|:---:|
| `Randomizable` ★ | 受约束随机数发生器，见 13-09 |
| `LFSR` ★ | 线性反馈移位寄存器，见 13-09 |
| `CRC` ★ | 循环冗余校验，见 13-09 |
| `Gray` ★ | 格雷码编/解码，见 13-09 |
| `BitonicSort` | 组合双调排序网络 |

### 调试 / 断言（5）

| 包 | 功能 |
|:---:|:---:|
| `Probe` ★ | 只写波形探针，见 13-10 |
| `ProbeWire` | wire 形式探针 |
| `Assert` ★ | static/dynamic/continuous 断言，见 13-10 |
| `OVLAssertions` | OVL 标准断言库封装 |
| `SVA` | SystemVerilog Assertion 辅助 |

### 时钟 / 复位 / 模拟接口（3）

| 包 | 功能 |
|:---:|:---:|
| `Clocks` ★ | 时钟/复位原语与同步器，见 11-01 |
| `Inout` | `Inout` 双向端口类型 |
| `TriState` | 三态缓冲 `mkTriState` |

### 仲裁 / 路由 / 总线（5）

| 包 | 功能 |
|:---:|:---:|
| `Arbiter` ★ | 轮转仲裁器（mkArbiter），见 13-11 |
| `Arbitrate` | 通用仲裁类型类 `ArbRequestTC` |
| `Fork` | 复制值以规避编译器 CSE（公共子表达式消除）：`fork`/`forkL`/`forkLN` |
| `ZBus` / `ZBusUtil` | 三态总线建模与辅助 |

### 显示 / 格式化（5）

| 包 | 功能 |
|:---:|:---:|
| `FShow` ★ | `fshow` 把类型转 `Fmt`（见 02-01） |
| `CShow` | 自动派生紧凑 show |
| `SShow` | 字符串化 show（`ToString` 配套） |
| `Printf` | C 风格 `printf`/`sprintf` 格式 |
| `ToString` | 类型转 `String` 类型类 |

### 配置总线（2）

| 包 | 功能 |
|:---:|:---:|
| `CBus` | 配置总线“后门”接口（寄存器映射） |
| `LBus` | 本地总线（地址 24 位映射寄存器组） |

### ModuleContext / 收集（5）

| 包 | 功能 |
|:---:|:---:|
| `Contexts` | 隐式上下文（`Contexts`）总入口 |
| `ModuleContext` / `ModuleContextCore` | 带上下文的 module（隐式参数/收集状态） |
| `ModuleCollect` | 细化期收集信息（如 CBus 项） |
| `ModuleAugmented` | 空占位包（`package ModuleAugmented() where {}`，无内容） |

### 类型 / 工具 / 杂项（23）

| 包 | 功能 |
|:---:|:---:|
| `Prelude` ★ | 语言内建（Bit/Reg/rule…），自动 import |
| `PreludeBSV` | BSV 专属内建（RWire/Wire/PulseWire/ReadOnly、`mkCReg` 等），自动 import |
| `DefaultValue` ★ | `defaultValue` 类型类（见 13-07 BRAM_Configure） |
| `Reserved` | `Reserved#(n)` 占位 n 位空间 |
| `NumberTypes` | `WrapNumber` 等数值封装 |
| `UIntRange` | 限定范围 UInt 类型 |
| `Enum` | 枚举辅助 |
| `Boolify` | `boolify` 类：把一个函数改写成只用 `&&`/`\|\|`/`not` 布尔原语的等价函数 |
| `BitUtils` / `BUtils` | 位操作辅助（grab_left/对齐/打包等） |
| `EqFunction` | 函数相等（编译期比较） |
| `EdgeDetect` | 请求边沿检测 `mkRequestDetect`（接口 `RequestDetect`，无 `mkEdgeDetect`） |
| `Once` ★ | 只执行一次的 Action 封装，见 13-11 |
| `TieOff` | 给未用接口接默认值（`mkTieOff`） |
| `DummyDriver` | 给接口接空驱动（防悬空） |
| `UniqueWrappers` | 把组合函数包成共享硬件实例 |
| `Tabulate` | 把函数预制成查找表 |
| `RWire` ★ | 无状态同拍传值线（见 03-01/12-01） |
| `ActionSeq` | 顺序 Action 序列（构造子 `actionSeq` + `\|>` 操作符，StmtFSM 前身） |
| `StmtFSM` ★ | 顺序/并行 FSM 描述（见 05-01） |
| `Environment` | 空占位包（`package Environment() where {}`，无内容） |
| `Misc` | Base3-Misc 的汇总 re-export 伞包（import+export 一批库以生成 .bo，自身无函数） |
| `PAClib` ★ | 流水线组合子库（见 14-01） |

> 共 124 个包。★ = 有专篇用法 + `execs/` 可跑示例（13-02…13-11、14-01）；其余在本表给出一句话定位，需要时查 `specs/src/Libraries` 源码。
