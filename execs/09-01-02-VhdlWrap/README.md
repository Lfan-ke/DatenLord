# 09-01-02 VhdlWrap — Verilog 套壳真实例化 VHDL，被 BSV 导入

> `VHDL 实体 → Verilog 套壳(真实例化) → import "BVI" → BSV`，逻辑**真正写在 VHDL 里**。
> bsc 只读 Verilog，所以 VHDL IP 必须有一层 Verilog 套壳；BVI 只对接套壳模块名。

## 文件（execs/*/ 下只有源 + output/）

| 文件 | 角色 |
|---|---|
| `vadd.vhd` | **逻辑源头**：带使能的寄存器加法器 `q<=a+b`（VHDL） |
| `vadd_wrapper.v` | Verilog 套壳，**真实例化 `vadd`**（无内联逻辑） |
| `VhdlWrap.bsv` | `import "BVI" vadd_wrapper` + 测试台 |

## 跑法

```bash
make run     # ghdl 降级 VHDL -> bsc 生成 Verilog -> iverilog 仿真
make clean
```

实测输出：

```
q = 30 (expect 30)     # put(10,20) -> 下一拍 q=30，加法由 VHDL 计算
```

## 流程（关键：逻辑确实来自 VHDL）

iverilog 不读 VHDL。为在本机真实跑通且**逻辑不离开 VHDL**：

1. `ghdl -a vadd.vhd` 分析 VHDL；
2. `ghdl --synth --out=verilog vadd` 把 VHDL **降级**成 Verilog 网表 `output/vadd_synth.v`
   （网表里 `assign ... = a + b` 还标注着源 `vadd.vhd:13` —— 逻辑机械地来自 VHDL，非手写）；
3. `vadd_wrapper.v` 实例化 `vadd`，由该网表提供；
4. iverilog 仿真 `mkTop.v + vadd_wrapper.v + vadd_synth.v`。

> 生产中（VCS/Questa/Riviera 等混合语言仿真器）可直接读 `vadd.vhd`，连 `--synth` 这步都省了，
> 套壳与 BSV 侧完全不变。

## BVI 要点（与 09-01-01 一致）

```bluespec
method put(a, b) enable(en);   // Action：参数=Verilog输入端口，enable=使能（关键字 enable 非 en）
method q get;                   // Value：输出端口 q 在方法名前，无 = 右侧
schedule (get) SB (put);
```
