# bluetcl + BDW

## bluetcl —— 带 Bluespec 扩展的 Tcl 壳

> `bluetcl` 是 `/usr/local/bsc/bin/bluetcl`：一个 Tcl 解释器，加了一组 `Bluetcl::*` 扩展命令，用来**读取并分析 bsc 生成的文件**——`.bo`(预细化信息：包/类型/定义) 与 `.ba`(后细化信息：端口/规则/调度)。

### 调用方式（两个坑）

```bash
bluetcl                 # 交互式 Tcl 壳
bluetcl script.tcl      # 跑脚本，EOF 自动退出（推荐，不挂）
```

> 注意：`bluetcl -e '命令'` 跑完会进交互模式等输入而**阻塞**；非交互请用**脚本文件**（或 `bluetcl -e '...' </dev/null`）。
>
> 注意：`module`/`schedule` 这些后细化命令需要 `.ba`，而 `.ba` **只有 `bsc -sim -g` 或 `bsc -elab` 才生成**（`-verilog -g` 只出 `.v`/`.bo`）。

### 常用命令（均已实跑验证）

| 命名空间命令 | 作用 |
|:---:|:---:|
| `Bluetcl::version` | 编译器版本 |
| `Bluetcl::flags set -sim -bdir <dir>` | 设置 bsc flags（后端/路径），其它命令前先设 |
| `Bluetcl::bpackage load <pkg>` / `list` / `clear` / `depend` | 载入/列出 `.bo` 包 |
| `Bluetcl::defs module <pkg>` / `defs all <pkg>` | 列包里的模块/全部定义 |
| `Bluetcl::type ...` `Bluetcl::syntax ...` | 类型/语法信息 |
| `Bluetcl::module load <mod>` | 载入模块（需 `.ba`） |
| `Bluetcl::module ports <mod>` / `porttypes` / `list` | 端口 / 端口类型 / 已载模块 |
| `Bluetcl::module rules <mod>` / `submodules <mod>` | 规则 / 子模块 |
| `Bluetcl::schedule execution <mod>` | 规则/方法的逻辑执行顺序 |
| `Bluetcl::rule ...` | 规则细节 |
| `Bluetcl::sim ...` / `Bluesim::sim ...` | 驱动 Bluesim 仿真 |

### 实跑示例

```tcl
# inspect.tcl —— 分析 mkFoo（先 bsc -sim -u -g mkFoo -bdir . 生成 mkFoo.ba）
Bluetcl::flags set -sim -bdir .
Bluetcl::module load mkFoo
foreach p [Bluetcl::module ports mkFoo] { puts $p }
puts "rules: [Bluetcl::module rules mkFoo]"
foreach r [Bluetcl::schedule execution mkFoo] { puts "exec: $r" }
```

```text
$ bluetcl inspect.tcl
# ports: interface {{method put ... {enable EN_put} {ready RDY_put}} {method get ... {ready RDY_get}}} ...
rules: RL_tick
exec: get
exec: RL_tick
exec: put
```

> 预细化信息只需 `.bo`：`Bluetcl::bpackage load Foo; Bluetcl::defs module Foo` → `Foo::mkFoo`（不需要 `.ba`、不需要 `-sim`）。
> BSC 自带的 Tcl 脚本示例（如 `expandPorts`）就是用这些命令写的。

---

## BDW —— BSC Development Workstation

> 源：`other/bdw`。BDW 是 **bsc 的图形化前端**，建立在 bluetcl 之上（GUI = Tcl/Tk + bluetcl + 图形工具）

### 它能做什么

| 模块 | 功能 |
|:---:|:---:|
| **Project 管理** | 建/存工程、设置编译/链接/仿真选项、文件窗口编辑；可为同一设计维护多套设置 |
| **Build** | 一键 Type Check / Compile / Link / Simulate / Full Rebuild / Stop / Clean |
| **Package 窗口** | 浏览已编译的包 |
| **Type Browser** | 浏览类型 |
| **Module Browser** | 浏览模块层次、端口、子模块 |
| **Schedule 分析** | 查看调度、**调度/冲突关系图**（Graphviz 渲染） |
| **波形** | 配合 Wavestcl 看仿真波形 |

### 启动 & 打开工程（`.bspec`）

```bash
bdw                    # 启动空 GUI（再从菜单建/开工程）
bdw project.bspec      # 直接打开一个已有工程（参数以 .bspec 结尾 → open_project）
bdw script.tcl         # 参数以 .tcl 结尾 → 当作脚本 source 执行
```

> 命令行参数解析见 `workstation.tcl: process_arguments`：`.bspec` → 打开工程；`.tcl` → 跑脚本；其它 → 当输出名。

**GUI 界面**：打开后工程项目`.bspec`即可一键 Type Check / Compile / Link / Simulate，并在 Module Browser / Schedule 窗口里分析。

### 本地安装

```bash
cd other/bdw
make install PREFIX=$PWD/inst            # 普通用户构建（需 BLUESPECDIR；构建期用 bluetcl 生成 tclIndex）
sudo cp -a inst/bin/. /usr/local/bsc/bin/   &&  sudo cp -a inst/lib/. /usr/local/bsc/lib/
#  → bdw 落到 /usr/local/bsc/bin/bdw（与 bsc/bluetcl 同目录，自动在 PATH）
```

依赖（apt）：`itcl3 itk3 iwidgets4`（[incr Tcl]/[incr Tk]/[incr Widgets]，GUI 必需）；可选 `libgv-tcl`（Graphviz 的 `Tcldot`，画**调度/冲突关系图**用，没有时该功能优雅降级、其余照常）。GUI 显示需 `DISPLAY`（WSL2 用 WSLg，已有 `:0`）。

### 与命令行的关系

BDW 把"编辑 → bsc 编译/链接/仿真 → 用 bluetcl 分析调度/端口/类型 → 看波形"整条流程包进 GUI；它做的事都能用 `bsc` + `bluetcl` 命令行完成（本笔记 + 00-01 的 flag 表即是命令行路径）。
