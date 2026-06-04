<!-- 流式编程框架 - Pipeline Architecture Composers Library - Streaming Dataflow DSL -->

# PAClib —— 流式数据流组合子库

> 源：`specs/src/Libraries/Base3-Misc/PAClib.bsv`（1697 行）。`import PAClib::*;`
> PAClib 用「组合子」把流水线拼起来：基本单元是 **`PipeOut#(t)`（一条 t 值的流）**，每个组合子吃若干个 `PipeOut` 输入、产出一个新 `PipeOut`。
> 约定:**每个组合子的最后一个参数是输入 `PipeOut`**，返回新 `PipeOut`，所以代码自上而下链式读。
> 依赖 FIFO/FIFOF/SpecialFIFOs/GetPut/ClientServer/Vector/CompletionBuffer。

---

## 核心接口

```bsv
// 流接口 = FIFOF 的输出子集（只有 first/deq/notEmpty，没有 enq/notFull）
interface PipeOut#(type t);
   method t      first;
   method Action deq;
   method Bool   notEmpty;
endinterface

// 一个"未接输入"的流水级（部分应用的 module）
typedef (function Module#(PipeOut#(tb)) mkFoo(PipeOut#(ta) ifc)) Pipe#(type ta, type tb);
```

接口转换：

```bsv
function PipeOut#(a) f_FIFOF_to_PipeOut(FIFOF#(a) fifof);   // 把 FIFOF 输出端当 PipeOut
instance ToGet#(PipeOut#(a), a);                            // toGet(po)：get = {po.deq; return po.first;}
module mkPipe_to_Server#(Pipe#(ta,tb) pipe)(Server#(ta,tb)) provisos (Bits#(ta,_)); // 整条流水包成 Server
```

---

## 1. 源与汇

```bsv
module mkSource_from_fav#(ActionValue#(a) f)(PipeOut#(a)) provisos (Bits#(a,_)); // 反复取 AV 产流
module mkSource_from_constant#(a x)(PipeOut#(a));                                // 恒定流
module mkSink#(PipeOut#(a) po_in)(Empty);                                        // 丢弃整条流
module mkSink_to_fa#(function Action f(a x), PipeOut#(a) po_in)(Empty);          // 每个值先 f 再丢
```

## 2. 把函数提升为流水级

```bsv
module mkFn_to_Pipe#(function tb fn(ta x), PipeOut#(ta) po_in)(PipeOut#(tb));    // 纯组合函数，无缓冲
module mkAVFn_to_Pipe#(function ActionValue#(tb) avfn(ta x), PipeOut#(ta) po_in)(PipeOut#(tb))
   provisos (Bits#(ta,_), Bits#(tb,_));                                          // AV 函数，后插 PipelineFIFOF
module mkFn_to_Pipe_Buffered#(Bool bufBefore, function b fn(a x), Bool bufAfter, PipeOut#(a) po_in)(PipeOut#(b));
module mkTap#(function Action tapFn(a x), PipeOut#(a) po_in)(PipeOut#(a));        // 旁路观测，数据原样穿过
```

> 提示（源码注释）：要对向量逐元素映射，用 `mkFn_to_Pipe(map(f))` 比 `mkMap(mkFn_to_Pipe(f))` 更省。

## 3. 缓冲（流水寄存器 / 流控）

```bsv
module mkBuffer#(PipeOut#(a) po_in)(PipeOut#(a)) provisos (Bits#(a,_));            // 1级异步(FIFO式)缓冲
module mkBuffer_n#(Integer n, PipeOut#(a) po_in)(PipeOut#(a));                     // n级
module mkSynchBuffer#(a init, PipeOut#(a) po_in)(PipeOut#(a));                     // 1级同步(寄存器式)
module mkSynchBuffer_n#(Integer n, a init, PipeOut#(a) po_in)(PipeOut#(a));        // n级寄存器
```

## 4. 分叉 / 汇合（并行结构）

```bsv
module mkFork#(function Tuple2#(b,c) forkFn(a v), PipeOut#(a) poa)(Tuple2#(PipeOut#(b),PipeOut#(c)));
module mkFork2#(function Tuple2#(b,c) forkFn(a v), PipeOut#(a) poa)(Tuple2#(PipeOut#(b),PipeOut#(c)))
   provisos (Bits#(a,_),Bits#(b,_),Bits#(c,_));                                    // 带缓冲版（解耦两路）
module mkForkVector#(PipeOut#(a) po)(Vector#(n, PipeOut#(a)));                     // 复制成 n 条
module mkExplodeVector#(PipeOut#(Vector#(n,a)) po)(Vector#(n, PipeOut#(a)));       // 拆成 n 条
module mkForkAndBufferRight#(PipeOut#(a) poa)(Tuple2#(PipeOut#(a),PipeOut#(a)));   // 左不缓冲、右缓冲
module mkJoin#(function c joinFn(a va, b vb), PipeOut#(a) poa, PipeOut#(b) pob)(PipeOut#(c)); // 同步取两头合一
```

## 5. 漏斗 / 反漏斗（位宽 ↔ 时间）

```bsv
// 把一个 mk-向量串行成 k 个 m-向量片（m*k=mk），每拍一片
module mkFunnel#(PipeOut#(Vector#(mk,a)) po_in)(PipeOut#(Vector#(m,a))) provisos (Mul#(m,k,mk), ...);
module mkFunnel_Indexed#(PipeOut#(Vector#(mk,a)) po_in)(PipeOut#(Vector#(m, Tuple2#(a, UInt#(logmk))))); // 元素带原始下标
module mkUnfunnel#(Bool stateIfK1, PipeOut#(Vector#(m,a)) po_in)(PipeOut#(Vector#(mk,a)));               // 收回成 mk-向量
```

## 6. 映射（SIMD 多车道）

```bsv
module mkMap#(Pipe#(a,b) mkP, PipeOut#(Vector#(n,a)) po_in)(PipeOut#(Vector#(n,b))) provisos (Bits#(a,_));
// 给 n 路各放一份流水级 mkP；各路延迟可不同，FIFO 保持同步
module mkMap_with_funnel_indexed#(UInt#(m) dummy_m, Pipe#(Tuple2#(a,UInt#(logmk)),b) mkP,
                                  Bool bufUnfunnel, PipeOut#(Vector#(mk,a)) po_in)(PipeOut#(Vector#(mk,b)));
// 漏斗成 k×m 片 → m 路并行 mkP（带下标）→ 反漏斗：用更少硬件处理大向量
```

## 7. 组合 / 线性流水

```bsv
module mkCompose#(Pipe#(a,b) pab, Pipe#(b,c) pbc, PipeOut#(a) pa)(PipeOut#(c));     // pa→pab→pbc
module mkCompose_buffered#(Bool withBuf, Pipe#(a,b) pab, Pipe#(b,c) pbc, PipeOut#(a) pa)(PipeOut#(c));
module mkLinearPipe_S#(Integer n, function Pipe#(a,a) mkStage(UInt#(logn) j), PipeOut#(a) po_in)(PipeOut#(a));
// n 级线性流水，mkStage 收到静态级号 j（0..n-1）
```

## 8. 条件 / 循环 / 折叠

```bsv
module mkIfThenElse#(Integer latency, Pipe#(a,b) pipeT, Pipe#(a,b) pipeF,
                     PipeOut#(Tuple2#(a,Bool)) poa)(PipeOut#(b));  // 按 pred 选 T/F 路，保序(latency=两路最大延迟)
module mkIfThenElse_unordered#(Pipe#(a,b) pipeT, Pipe#(a,b) pipeF, PipeOut#(Tuple2#(a,Bool)) poa)(PipeOut#(b));

module mkWhileLoop#(Pipe#(a,Tuple2#(b,Bool)) mkPreTest, Pipe#(b,a) mkPostTest,
                    Pipe#(b,c) mkFinal, PipeOut#(a) po_in)(PipeOut#(c)); // 回流优先于新输入
module mkForLoop#(Integer nIters, Pipe#(Tuple2#(a,UInt#(wj)),Tuple2#(a,UInt#(wj))) mkBody,
                  Pipe#(a,b) mkFinal, PipeOut#(a) po_in)(PipeOut#(b));   // 每项跑 body nIters 次

module mkWhileFold#(Pipe#(Tuple2#(a,a),a) mkCombine, PipeOut#(Tuple2#(a,Bool)) po_in)(PipeOut#(a)); // (值,组末)分组累积
module mkForFold#(UInt#(wj) nItems, Pipe#(Tuple2#(a,a),a) mkCombine, PipeOut#(a) po_in)(PipeOut#(a)); // 定长组
```

## 9. 重排 / 树归约

```bsv
module mkReorder#(Pipe#(Tuple2#(CBToken#(n),a),Tuple2#(CBToken#(n),b)) mkBody, PipeOut#(a) po_in)(PipeOut#(b));
// body 可能乱序产出，用 CompletionBuffer 的令牌恢复输入序

// 向量树归约（typeclass，n 须 2 的幂；addBuffer 每位控制每层是否缓冲）
typeclass VectorTreeReduce#(numeric type n, type a);
   module mkTreeReducePipe#(Pipe#(Tuple2#(a,a),a) reducepipe, Bit#(32) addBuffer,
                            PipeOut#(Vector#(n,a)) pin)(PipeOut#(a));
   module mkTreeReduceFn#(function a reduce2(a x,a y), function a reduce1(a x), Bit#(32) addBuffer,
                          PipeOut#(Vector#(n,a)) pin)(PipeOut#(a));
endtypeclass
```

---

## 典型用法

```bsv
function Int#(32) f1(Int#(32) x) = x + 1;
function Int#(32) f2(Int#(32) x) = x * 2;
function Int#(32) g (Int#(32) a, Int#(32) b) = a + b;

module mkExample#(PipeOut#(Int#(32)) po_in)(Empty);
   PipeOut#(Int#(32)) p1 <- mkFn_to_Pipe(f1, po_in);              // 提升纯函数
   PipeOut#(Int#(32)) p2 <- mkBuffer(p1);                         // 插一级流水寄存器
   Tuple2#(PipeOut#(Int#(32)), PipeOut#(Int#(32))) fk <- mkForkAndBufferRight(p2);  // 分叉
   PipeOut#(Int#(32)) pb <- mkFn_to_Pipe(f2, tpl_2(fk));          // 一支再算
   PipeOut#(Int#(32)) pj <- mkJoin(g, tpl_1(fk), pb);             // 汇合
   Empty done <- mkSink(pj);                                      // 收尾
endmodule
```

## 可跑示例

三个都用同一个驱动法：一头 `FIFOF` + `f_FIFOF_to_PipeOut` 当源，另一头直接 `po.first/deq` 当汇（无需 `mkSource_*`/`mkSink` 也能跑）。

### 示例 1：线性流水（execs/14-01-01-PAClib）—— `(x+1)*2`

```bsv
import PAClib::*; import FIFOF::*;
function Int#(32) f_inc(Int#(32) x) = x + 1;
function Int#(32) f_dbl(Int#(32) x) = x * 2;

FIFOF#(Int#(32)) inq <- mkFIFOF;
PipeOut#(Int#(32)) src = f_FIFOF_to_PipeOut(inq);    // FIFOF 输出端 = 流入口
PipeOut#(Int#(32)) p1  <- mkFn_to_Pipe(f_inc, src);  // 提升 +1
PipeOut#(Int#(32)) p2  <- mkBuffer(p1);              // 插一级流水寄存器
PipeOut#(Int#(32)) p3  <- mkFn_to_Pipe(f_dbl, p2);   // 再 ×2
```

```
in=0 -> out=2   in=1 -> out=4   in=2 -> out=6   in=3 -> out=8
```

### 示例 2：分叉/汇合（execs/14-01-02-ForkJoin）—— `(x+1)+(x*2)=3x+1`

```bsv
function Tuple2#(Int#(32),Int#(32)) dup(Int#(32) x) = tuple2(x, x);
function Int#(32) f_add(Int#(32) a, Int#(32) b) = a + b;

Tuple2#(PipeOut#(Int#(32)), PipeOut#(Int#(32))) fk <- mkFork(dup, src);  // 复制成两路
PipeOut#(Int#(32)) pa <- mkFn_to_Pipe(f_inc, tpl_1(fk));   // 上路 +1
PipeOut#(Int#(32)) pb <- mkFn_to_Pipe(f_dbl, tpl_2(fk));   // 下路 *2
PipeOut#(Int#(32)) pj <- mkJoin(f_add, pa, pb);            // 同步合并相加
```

```
x=0 -> 3x+1=1   x=1 -> 3x+1=4   x=2 -> 3x+1=7   x=3 -> 3x+1=10
```

> `mkJoin` 同步取两路队头合一；两路都是组合 `mkFn_to_Pipe`（同拍），故无需额外缓冲；若两路延迟不同要用 `mkFork2`/`mkForkAndBufferRight` 解耦。

### 示例 3：树归约（execs/14-01-03-TreeReduce）—— `Vector#(4)` 求和

```bsv
import Vector::*;
function Int#(32) add2(Int#(32) x, Int#(32) y) = x + y;
function Int#(32) id1 (Int#(32) x) = x;

FIFOF#(Vector#(4, Int#(32))) inq <- mkFIFOF;
PipeOut#(Vector#(4, Int#(32))) src = f_FIFOF_to_PipeOut(inq);
PipeOut#(Int#(32)) sumP <- mkTreeReduceFn(add2, id1, 0, src);  // log 深加法树（n 须 2 的幂）
```

```
treeSum=10     <- [1,2,3,4]
treeSum=100    <- [10,20,30,40]
```

> `mkTreeReduceFn(reduce2, reduce1, addBuffer, pin)`：`reduce2` 合并一对、`reduce1` 处理落单元素、`addBuffer`(Bit#(32)) 逐位控制每层是否插缓冲（这里 0=全组合）。要插自定义流水级用 `mkTreeReducePipe`。

---

要点：
- 每个组合子**最后一个参数是输入流**、返回新流 → 链式书写。
- 未接输入的 `Pipe#(a,b)` 传给高阶组合子（`mkCompose`/`mkMap`/`mkIfThenElse`/`mkWhileLoop`/`mkForLoop`/`mkTreeReducePipe`）。
- `mkFn_to_Pipe`/`mkAVFn_to_Pipe` 提升函数；`mkBuffer`/`mkSynchBuffer` 插寄存器；`mkFork*`/`mkJoin` 搭并行；`mkFunnel`/`mkUnfunnel` 拿位宽换时间；`mkMap*` 多车道；循环/折叠做迭代；`mkPipe_to_Server` 把整条流水暴露成 `Server`。

> 源码备注：没有 `mkMap_fn`（用 `mkFn_to_Pipe(map(f))`）；`mkLinearPipe_D` 标注 "NOT YET TESTED"；只同步不缓冲的分叉（mkFork/mkForkVector/mkMap）用零宽 `Bit#(0)` 的 bypass FIFO 当 "taken" 信号。
