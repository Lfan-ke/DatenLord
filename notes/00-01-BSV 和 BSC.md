# 基础入门

<!-- HDL补完计划 -> BSV子补完计划 -->

在README已经写了，如何安装BSC，以及编译和运行BSV的仿真等，这里就当一个补充+速记。

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
