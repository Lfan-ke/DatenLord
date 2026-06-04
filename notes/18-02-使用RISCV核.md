<!-- 使用 BSV 实现的真实 RISC-V 核：Piccolo/Flute/Shakti（构建/跑测试/集成SoC） -->

# 使用 RISC-V 核（Piccolo / Flute / Shakti）

> 这些核**整核用 BSV 写**，由 bsc 编译成可综合 Verilog / Bluesim。本篇据真实仓库 Makefile 整理"怎么用"。
> 已作为浅子模块克隆：[Piccolo](https://github.com/bluespec/Piccolo)→`other/piccolo`、[Flute](https://github.com/bluespec/Flute)→`other/flute`、[Shakti c-class](https://gitlab.com/shaktiproject/cores/c-class)→`other/shakti`（**目录名均小写**；仓库内的 `builds/` 子目录名仍保留 `Piccolo` 大写）。Flute 结构与 Piccolo 几乎相同；Shakti 是另一套开源 RISC-V SoC 家族。

## 仓库结构（Piccolo，Flute 同构）

```
src_Core/        CPU(取指/译码/执行)、Near_Mem(caches)、MMU、PLIC、CSR…（全 BSV）
src_Testbench/   仿真测试台 + 内存模型
src_SSITH_P1/    SoC 包装（核 + AXI4 接口）示例
builds/          每种「配置 × 仿真器」一个目录
Tests/           RISC-V ISA 测试 + elf_to_hex 工具 + Run_regression.py
```

`builds/` 目录名编码 **配置 × 仿真器**：`RV32ACIMU_Piccolo_bluesim`、`RV64ACDFIMSU_Piccolo_verilator`、`..._iverilog` …
（RV32/64 + ISA 扩展 A/C/D/F/I/M/S/U；后端 bluesim/iverilog/verilator）。

## 构建 & 跑（真实 make 流程）

```bash
cd other/piccolo/builds/RV32ACIMU_Piccolo_bluesim   # 选配置+后端

make compile     # bsc -u -elab -sim ... 编译核（Bluesim 出中间件；verilog 目录则出 RTL）
make simulator   # bsc -sim 链接 → 可执行 exe_HW_sim
make all         # = compile + simulator

make test                     # 跑标准测试 rv32ui-p-add（elf_to_hex 转 ELF→Mem.hex 再 ./exe_HW_sim +tohost）
make test TEST=rv32um-p-mul   # 指定某个 ISA 测试
make isa_tests                # Run_regression.py 跑全部相关 RISC-V ISA 测试，日志存 Logs/
make run_example EXAMPLE=path/to/prog.elf   # 跑自己的 ELF

make clean / make full_clean
```

- 配置由该 build 目录 Makefile 里的 `-D RV32 -D ISA_M -D ISA_A …` 决定，传给 bsc。
- **输出 Verilog 跑综合/第三方仿真**：选 `..._verilog`/`..._verilator`/`..._iverilog` 的 build 目录，`make compile` 产 RTL；仓库也带**预生成的 Verilog RTL**(无需 bsc 即可综合)。
- `Tests/elf_to_hex/elf_to_hex prog.elf Mem.hex`：把 ELF 转成核加载的 hex 内存镜像。

## 本地实测（Piccolo RV32 / bluesim，真跑通）

```
cd other/piccolo/builds/RV32ACIMU_Piccolo_bluesim
make compile     # → INFO: Re-compiled Core (CPU, Caches)         ✓ 整核 BSV 用我们的 bsc 编译
make simulator   # → Simulation executable created: ./exe_HW_sim  ✓
# 跑 rv32ui-p-add：
./exe_HW_sim +tohost
#   CPU: Bluespec RISC-V Piccolo v3.0 (RV32)
#   Mem_Controller ... addr 0x80001000 (<tohost>) data 0x1
#   PASS                                                          ✓ 真实 RISC-V ISA 测试通过(1918 cycles)
```

> 坑(本机):`Tests/elf_to_hex/elf_to_hex.c` 里 `uint8_t mem_buf[MAX_MEM_SIZE]`(MAX=0x90000000≈2.4GB)是**超大静态数组**，本机 ld 报 `relocation truncated to fit`。
> 修:把它改成指针 + `calloc`（`uint8_t *mem_buf; … mem_buf=calloc(MAX_MEM_SIZE,1);`），用 `gcc -O2 -o elf_to_hex elf_to_hex.c -lelf` 重建即可（这是 host 工具链问题，与核/BSV 无关）。

## 集成进 SoC

核对外暴露 **AXI4 master**(访存 + MMIO)。集成：把核的 AXI4 接口接到 AXI4 fabric + 外设。
- fabric/transactor 用 **bsc-contrib 的 `AMBA_Fabrics`**(AXI4/Lite/Stream)，见 16-01：`-p +:/usr/local/bsc-contrib/Libraries/AMBA_Fabrics`。
- `src_SSITH_P1/` 是现成的"核+总线"SoC 包装范例可参考。

## 其他 B-Lang / 相关仓库（同样套路）

| 仓库 | 用途 | 用法 |
|:---:|:---:|:---:|
| `bsc` | 编译器/库/bluesim/bluetcl | 见 00–17 |
| `bsc-contrib` | 额外库(AMBA/GenC…) | 见 16，`-p +:.../Libraries/<cat>` |
| `bdw` | GUI 前端 | 见 17 |
| `bsc-testsuite` | DejaGnu 回归测试 | `make check`（设 BSCCONTRIBDIR） |
| Piccolo/Flute | RISC-V 核 | 本篇 |
| SHAKTI(C/E/...class) | RISC-V SoC 家族 | 各自仓库 `make`，思路同上 |

> 这些是**应用工程**：用前面学的 BSV/BH + bsc 工具链搭/跑真实处理器，不引入新语言知识点；是最佳实战阅读与练手材料。
