# 09-01-01 BviMac — import "BVI" 把 Verilog 黑盒导入 BSV

> 验证「正确的 BVI 方法语法」：用一个已有的 Verilog 乘加器 `mymac.v`，通过 `import "BVI"`
> 包成 BSV 接口 `MacIFC`，再由 BSV 测试台驱动，最后 iverilog 真跑。

## 跑法

```bash
make run     # bsc 生成 Verilog -> 链接 mymac.v -> iverilog 仿真
make clean
```

## 实测输出

```
after 3*4 + 5*6 : y=42  (expect 42)
after reset_acc(100): y=100 (expect 100)
```

## 关键点：BVI 方法语法（网上很多教程这里是错的）

| 写法 | 正确 | 错误（常见误写） |
|---|---|---|
| 使能关键字 | `enable(EN)` | ~~`en(EN)`~~ |
| 值方法输出端口 | `method out read_y;`（端口在名【前】） | ~~`method read_y() = out;`~~ |
| 右侧赋值 | 没有 `= (...)` | ~~`= (EN_acc, RDY_acc)`~~ |
| 方法参数 | 映射到 Verilog **输入端口名**（`a,b,clear_value`） | 随意命名 |

```bluespec
method acc(a, b)              enable(EN);     // Action：参数=Verilog输入端口，enable=使能端口
method reset_acc(clear_value) enable(clear);
method out read_y;                            // Value：输出端口在方法名前，无 = 右侧
```

无 `ready(...)` 子句 = 永远就绪。`schedule` 子句声明方法间关系（`SB`/`C`/`CF`）。

## VHDL 怎么办？

bsc 只读 Verilog。VHDL IP 需要先写一层 Verilog 包装器实例化 VHDL 实体，
BSV 的 `import "BVI"` 只对接那层 Verilog；真正读 VHDL 的是后端工具（iverilog 不支持 VHDL，
需 ghdl/vcs/quartus 等）。
