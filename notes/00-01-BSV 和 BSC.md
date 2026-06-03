# 基础入门

<!-- HDL补完计划 -> BSV子补完计划 -->

在README已经写了，如何安装BSC，以及编译和运行BSV的仿真等，这里就当一个补充+速记。

> BSC, Bluespec Compiler

**常见的文件类型**：

`.bsv-源码文件`，`.ba-细化后的模块中间文件`，`.bo-包对象文件`，`.h/.o-BlueSim编译生成的Cpp头文件+对象文件`，`.so-共享库`

**常用的相关术语**：

Package     - 一个`.bsv`文件是一个包，且包名与文件名一致

Module      - 模块，设计的基本单元

TopModule   - 顶层模块，仿真的入口

Elaboration - 细化，将参数化模块实例化为具体电路

**最简编译仿真流程**：

```bash
# 编译
bsc -sim -g mkEmmTopModule emm.bsv
# -sim 生成BlueSim仿真代码
# -g <module> 指定要生成的顶层模块名
# 生成：mkEmmTopModule.{h,o,ba}

# 链接
bsc -sim -e mkEmmTopModule -o ./sim_executable
# -e <module> 指定顶层模块作为入口
# -o <file> 输出可执行文件名
# 生成：sim_exe sim_exe.so 以 Bluesim 为默认的仿真器

./sim_executable    # 运行仿真，需要生成波形可以附加`-V`参数或者`+bscvcd`参数
```

<!-- more -->

**中间文件目录指定**：

```bash
bsc -sim -bdir ./build -g mkEmmTopModule emm.bsv

# 使用 -bdir 指定中间文件 .{ba,bo} 的目录，避免污染当前目录
# -simdir 指定 .{h,o} 的目录
# -vdir 指定输出的 .v 的目录
# -info-dir 指定信息文件目录

# 如果不指定，就只会生成到当前目录
```

**Verilog仿真流程**：

```bash
# 生成 verilog，可加上 -show-schedule 调试标志，查看部分 reg 的规则调度顺序
bsc -verilog -g mkTestBench TestBench.bsv     # 习惯上 模块名有前缀小写 `mk`
# 链接 仿真器，比如：Icarus Verilog，也支持 verilator cvc 等
bsc -verilog -e mkTestBench -o ./vsim_exe -vsim iverilog mkTestbench.v
# 运行以及输出波形
./vsim_exe +bscvcd
```

**包管理路径相关**：

```bash
# `.`-为当前目录    `:`-为路径分隔符
# `%/`-为$BSC_LIB_DIR环境变量（安装的时候需要自己设置，在inst目录下）
bsc -p "path1:path2:%/Libraries" source.bsv
```

**优化等其他参数**：

```bash
# 诊断选项
bsc -sim -u -g mkTopModule source.bsv                # -u：检查所有包依赖（推荐）
bsc -sim -v -g mkTopModule source.bsv                # -v：详细输出编译信息
bsc -sim -check-assert -g mkTopModule source.bsv     # -check-assert：启用断言检查
bsc -sim -no-warn-unused -g mkTopModule source.bsv   # -no-warn-<warning>：禁用特定警告

# 优化选项
bsc -sim -aggressive-conditions -g mkTopModule source.bsv   # -aggressive-conditions：激进条件合并优化
bsc -sim -keep-fires -g mkTopModule source.bsv              # -keep-fires：保留WILL_FIRE信号（调试）
bsc -sim -remove-fires -g mkTopModule source.bsv            # -remove-fires：移除WILL_FIRE信号（优化）

# 波形生成
./sim_exe -V                                                # -V：生成波形（默认verilog.vcd）
./sim_exe -V waves.vcd                                      # -V <file>：指定波形文件名
./sim_exe +bscvcd                                           # +bscvcd：Bluesim波形生成
gtkwave dump.vcd                                            # gtkwave：查看波形

# ========== 单文件示例 ==========
mkdir -p build_bsim

# 步骤1：编译单个BSV文件
bsc -sim -u \
    -bdir build_bsim \
    -simdir build_bsim \
    -p ".:%/Libraries" \
    -g mkTestbench \
    src/Testbench.bsv

# 步骤2：链接生成可执行文件
bsc -sim -e mkTestbench \
    -bdir build_bsim \
    -simdir build_bsim \
    -o sim_exe

# 步骤3：运行仿真并生成波形
./sim_exe -V waves.vcd

# ========== 多文件示例 ==========
# 目录结构：
# project/
# ├── src/
# │   ├── Testbench.bsv   (顶层，依赖DeepThought.bsv)
# │   └── DeepThought.bsv (被依赖的模块)
# └── build_bsim/

mkdir -p build_bsim

# 步骤1：编译（bsc自动解析import语句，处理依赖关系）
bsc -sim -u \
    -bdir build_bsim \
    -simdir build_bsim \
    -p "src:%/Libraries" \
    -g mkTestbench \
    src/Testbench.bsv

# BSC会自动发现并编译 src/DeepThought.bsv

# 步骤2：链接
bsc -sim -e mkTestbench \
    -bdir build_bsim \
    -simdir build_bsim \
    -o sim_exe

# 步骤3：运行
./sim_exe -V waves.vcd

# 清理中间文件
rm -rf build_bsim sim_exe sim_exe.so waves.vcd
```

**推荐环境**：

bluespec-lsp + vscode with plugins:


- Blues - BSV language support
  - 依赖：cargo install blues-lsp
- Bluespec System Verilog
- Verilog-HDL/SystemVerilog/Bluespec SystemVerilog
- TerosHDL
- SystemVerilog and Verilog Formatter

---

# BSC 完整选项详解

## 基础用法

```bash
bsc -help                                # 显示帮助信息
bsc [flags] file.bsv                     # 部分编译一个BSV文件
bsc [flags] -verilog -g mod file.bsv     # 编译模块到Verilog
bsc [flags] -verilog -g mod -u file.bsv  # 递归编译模块到Verilog
bsc [flags] -verilog -e topmodule        # 链接Verilog到仿真模型
bsc [flags] -sim -g mod file.bsv         # 编译到Bluesim对象
bsc [flags] -sim -g mod -u file.bsv      # 递归编译到Bluesim对象
bsc [flags] -sim -e topmodule            # 链接对象到Bluesim二进制
bsc [flags] -systemc -e topmodule        # 链接对象到SystemC模型
```

## Compiler Flags

| 选项 | 说明 |
|:------:|:------:|
| `-D macro` | 为BSV或Verilog预处理器定义宏，如 `-D DEBUG` |
| `-E` | 仅运行预处理器，结果输出到标准输出 |
| `-I path` | 编译外部C/C++源码时的头文件包含路径 |
| `-L path` | 链接外部C/C++对象时的库文件搜索路径 |
| `-Xc arg` | 向C编译器传递参数 |
| `-Xc++ arg` | 向C++编译器传递参数 |
| `-Xcpp arg` | 向C预处理器传递参数 |
| `-Xl arg` | 向C/C++链接器传递参数 |
| `-Xv arg` | 向Verilog链接过程传递参数 |
| `-aggressive-conditions` | 激进地构建隐式条件（可能提高性能但增加面积） |
| `-bdir dir` | 输出.bo（Bluesim对象）和.ba（细化文件）的目录 |
| `-check-assert` | 使用Assert库测试断言 |
| `-continue-after-errors` | 检测到错误后继续激进编译（尽量多报错） |
| `-cpp` | 使用C预处理器预处理源码 |
| `-demote-errors list` | 将指定错误降级为警告（`:`分隔标签，如 `T0020:T0081`） |
| `-e module` | 指定顶层模块名用于仿真 |
| `-elab` | 细化和调度后生成.ba文件 |
| `-fdir dir` | 细化时相对文件路径的工作目录 |
| `-g module` | 为指定模块生成代码（需配合 -sim 或 -verilog） |
| `-help` | 生成帮助信息 |
| `-i dir` | 覆盖 `$BLUESPECDIR` 环境变量 |
| `-info-dir dir` | 输出信息文件（调度、冲突等）的目录 |
| `-keep-fires` | 保留CAN_FIRE和WILL_FIRE信号（用于调试） |
| `-keep-inlined-boundaries` | 保留内联的寄存器和线网边界 |
| `-l library` | 链接外部C/C++对象时使用的库 |
| `-lift` | 在"if"动作中提升方法调用 |
| `-o name` | 生成的可执行文件名称 |
| `-opt-undetermined-vals` | 激进优化未确定值（X值） |
| `-p path` | 源文件和中间文件的搜索路径（`:`分隔） |
| `-parallel-sim-link jobs` | 链接Bluesim时的并行任务数（加速链接） |
| `-print-flags` | 命令行解析后打印所有标志值 |
| `-promote-warnings list` | 将指定警告升级为错误（`:`分隔标签） |
| `-q` | 同 `-quiet` |
| `-quiet` | 输出更少信息（安静模式） |
| `-remove-dollar` | 从Verilog标识符中删除`$`符号 |
| `-remove-empty-rules` | 删除没有动作的规则 |
| `-remove-false-rules` | 删除条件可证明为永远为假的规则 |
| `-remove-starved-rules` | 删除调度中永远不会被触发的规则 |
| `-remove-unused-modules` | 从生成的Verilog中删除未连接的模块 |
| `-reset-prefix name` | 设置生成模块的复位名称或前缀 |
| `-resource-off` | 资源不足时报错（严格模式） |
| `-resource-simple` | 资源不足时重新调度（宽松模式） |
| `-sat-stp` | 使用STP SMT求解器进行互斥检测和SAT（用于复杂条件互斥证明） |
| `-sat-yices` | 使用Yices SMT求解器进行互斥检测和SAT（用于复杂条件互斥证明） |
| `-sched-dot` | 生成.dot格式的调度图文件（可用Graphviz查看） |
| `-show-compiles` | 显示重新编译信息 |
| `-show-elab-progress` | 显示细化过程（模块、规则、方法的细化进度） |
| `-show-method-bvi` | 在生成的代码中显示BVI格式的方法调度信息 |
| `-show-method-conf` | 在生成的代码中显示方法冲突信息 |
| `-show-module-use` | 输出实例化的Verilog模块名称列表 |
| `-show-range-conflict` | 报告并行组合错误时显示谓词（帮助理解冲突原因） |
| `-show-rule-rel r1 r2` | 显示规则r1和r2之间的调度关系信息 |
| `-show-schedule` | 显示编译器生成的调度顺序 |
| `-show-stats` | 显示包统计信息 |
| `-show-timestamps` | 生成的文件中包含时间戳 |
| `-show-version` | 生成的文件中包含编译器版本信息 |
| `-sim` | 编译BSV生成Bluesim对象（快速仿真） |
| `-simdir dir` | Bluesim中间文件输出目录 |
| `-split-if` | 拆分"if"语句中的动作 |
| `-steps n` | 终止细化前的函数展开步数上限 |
| `-steps-max-intervals n` | 消息条数上限后终止细化 |
| `-steps-warn-interval n` | 每执行N步展开时发出警告 |
| `-suppress-warnings list` | 忽略指定警告（`:`分隔标签） |
| `-systemc` | 生成SystemC模型 |
| `-u` | 检查并重新编译过期的包（推荐使用） |
| `-unspecified-to val` | 未指定的值设为：`X`（未知）、`0`、`1`、`Z`（高阻）、`A`（保持） |
| `-use-dpi` | 生成的Verilog使用DPI而非VPI（SystemVerilog DPI） |
| `-v` | 同 `-verbose` |
| `-v95` | 生成严格Verilog 95代码（兼容旧工具） |
| `-vdir dir` | 输出.v（Verilog文件）的目录 |
| `-verbose` | 输出更多详细信息（详细模式） |
| `-verilog` | 编译BSV生成Verilog文件 |
| `-verilog-filter cmd` | 调用外部命令后处理生成的Verilog文件 |
| `-vsearch path` | Verilog文件搜索路径（`:`分隔） |
| `-vsim simulator` | 指定Verilog仿真器（如 `vcs`, `ncverilog`, `iverilog`, `modelsim`） |
| `-warn-action-shadowing` | 警告：规则的动作被后续规则覆盖 |
| `-warn-method-urgency` | 警告：方法的优先级被任意选择 |

## 常用命令示例

| 场景 | 命令 |
|:------:|:------:|
| **日常编译到Verilog** | `bsc -u -g mkTop -verilog Top.bsv` |
| **指定输出目录** | `bsc -u -g mkTop -verilog -vdir output -bdir output Top.bsv` |
| **Bluesim快速仿真** | `bsc -sim -g mkTop -u Top.bsv && bsc -sim -e mkTop -o sim && ./sim` |
| **查看调度信息** | `bsc -u -g mkTop -show-schedule -verilog Top.bsv` |
| **生成调度图** | `bsc -u -g mkTop -sched-dot -verilog Top.bsv`（生成.dot文件） |
| **条件编译** | `bsc -u -g mkTop -D DEBUG_MODE -verilog Top.bsv` |
| **调试时钟域问题** | `bsc -u -g mkTop -keep-fires -verilog Top.bsv` |
| **查看模块依赖** | `bsc -u -g mkTop -show-module-use -verilog Top.bsv` |
| **忽略特定警告** | `bsc -u -g mkTop -suppress-warnings G0007:G0043 -verilog Top.bsv` |
| **使用SMT求解器** | `bsc -u -g mkTop -sat-yices -verilog Top.bsv`（复杂互斥条件证明） |

## 路径特殊字符说明

| 字符 | 含义 |
|:------:|:------:|
| `%` | 代表当前Bluespec目录 |
| `+` | 代表当前路径值（用于追加） |

示例：
```bash
-p %/lib:+:/usr/local/bsc/lib
```

## 错误/警告标签说明

| 值 | 含义 |
|:------:|:------:|
| `ALL` | 所有错误/警告 |
| `NONE` | 无错误/警告 |

示例：
```bash
-suppress-warnings ALL          # 忽略所有警告
-suppress-warnings G0007:G0043  # 忽略指定警告
-promote-warnings ALL           # 所有警告升级为错误
```

## 标志取反说明

大多数标志前加 `no-` 可取消效果：
```bash
-no-remove-empty-rules    # 保留空规则
-no-remove-unused-modules # 保留未使用模块
```

## 默认配置

```bash
Bluespec directory: /usr/local/bsc/lib        # BSV库目录
import path: .:/usr/local/bsc/lib/Libraries   # 默认导入路径
```

## 退出状态码

| 状态码 | 含义 |
|:------:|:------:|
| 0 | 编译成功 |
| 非0 | 编译失败（错误数量 > 0） |
