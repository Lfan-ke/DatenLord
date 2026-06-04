<!-- BH 的规则与 Action/ActionValue -->

# BH 规则·Action

> 接 15-02。规则语法 **`[标签:] when 守卫 ==> Action`**；Action 用 `action`/`do` 块组织。

## rules / when / ==>

```haskell
rules
    "incr": when (cnt < maxv)            -- 标签可选；守卫在 ==> 左边
            ==> cnt := cnt + 1           -- ==> 右边是一个 Action

    when (Add r1 r2 r3 <- decode instr)  -- 守卫可含模式绑定 pat <- e
        ==> action { pc := pc + 1
                     rf[r1] := rf[r2] + rf[r3] }
```

- **守卫**：`==>` 左边是逗号分隔的布尔表达式 / `pat <- e` 绑定。
- **RHS**：`==>` 右边必须是 `Action`。
- 嵌套 `when` 提取公共条件：`when c rules { when c1 ==> a1 ; when c2 ==> a2 }`。

## action / do / ActionValue

```haskell
action               -- 顺序若干 Action（或 action { a1; a2 }）
   x := x + 1
   y := z
noAction             -- 空 Action == action {}

-- ActionValue：带返回值的 Action，用 <- 取值
action
   v <- fifo.first'  -- 假设返回 ActionValue
   sink.put (v + 1)  -- put :: a -> Action，() 被丢弃
```

- `Action = ActionValue ()`。`do` 是通用单子写法，末项常为 `return e`。
- 同 BSV：一条规则是原子事务；规则间冲突由调度决定（见 02-01/02-02）。

## Rules 是一等值（组合）

```haskell
-- Rules 类型的值可组合后再加入模块
rs = r1 <+> r2      -- 对称并（无优先）
rs = r1 <+  r2      -- r1 优先于 r2（有向）
rs = r1  +> r2      -- r2 优先于 r1
addRules rs         -- 把 Rules 加进当前模块
```

## 完整示例：GCD（15-03-01）

```haskell
package GCD (ArithIO(..), mkGCD) where
interface ArithIO a =
    start  :: a -> a -> Action     -- 注意别用 input/output 当方法名（撞 Verilog 关键字 → G0105）
    result :: a
mkGCD :: Module (ArithIO (Bit 32))
mkGCD = module
    x    :: Reg (Bit 32) <- mkRegU
    y    :: Reg (Bit 32) <- mkRegU
    busy :: Reg Bool     <- mkReg False
    rules
      "swap": when busy, (x > y), (y /= 0)  ==> action { x := y; y := x }
      "sub":  when busy, (x <= y), (y /= 0) ==> y := y - x
      "fin":  when busy, (y == 0)           ==> busy := False
    interface
      start a b = action { x := a; y := b; busy := True } when (not busy)
      result    = x                                       when (not busy)
```

> 坑：BH 方法名若是 Verilog 关键字（`input`/`output`/`reg`/`wire`…），生成端口会撞名报 **G0105**，改名即可。
> 可跑：`execs/15-03-01-BhGcd`（编译出 `mkGCD.v`）。

## 规则语法 BH ↔ BSV 速记

| | BH | BSV |
|:---:|:---:|:---:|
| 规则 | `"名": when (c) ==> body` | `rule 名 (c); body endrule` |
| 守卫多条件 | 逗号 `when a, b, c` | `&&`：`rule r (a && b && c)` |
| 守卫含绑定 | `when (p <- e) ==>` | `case (e) matches tagged …` |
| Action 块 | `action { … }` | `action … endaction` |
| 组合规则 | `<+>` / `<+` / `+>` + `addRules` | `(* descending_urgency *)` 等注解 |
