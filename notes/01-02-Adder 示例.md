# 通过加法器了解语法

## 通用接口定义

感觉就像 Rust 定义了一个 Trait ，将行为实现和数据分离...

```bluespec
// 文件名: Adder4.bsv
package Adder4;

// 4位加法器接口
interface Adder4IFC;
  // 输入：bit4 + cin
  method Action put(Bit#(4) a, Bit#(4) b, Bit#(1) cin);
  // 输出：sum4 + cout
  method ActionValue#(Tuple2#(Bit#(4), Bit#(1))) get();
endinterface

endpackage
```

## 行为描述版本

```bluespec
// 文件名: Adder4_Simple.bsv
package Adder4_Simple;

import Adder4::*;

(* synthesize *)
module mkAdder4_Simple(Adder4IFC);

  // 内部寄存器存储输入
  Reg#(Bit#(4)) a_reg <- mkRegU();
  Reg#(Bit#(4)) b_reg <- mkRegU();
  Reg#(Bit#(1)) cin_reg <- mkRegU();
  Reg#(Bool) valid <- mkReg(False);

  // 接收输入
  method Action put(Bit#(4) a, Bit#(4) b, Bit#(1) cin) if (!valid);
    a_reg <= a;
    b_reg <= b;
    cin_reg <= cin;
    valid <= True;
  endmethod

  // 计算结果并返回
  method ActionValue#(Tuple2#(Bit#(4), Bit#(1))) get() if (valid);
    // 扩展到5位进行加法，行为建模，使用`+`
    Bit#(5) sum = zeroExtend(a_reg) + zeroExtend(b_reg) + zeroExtend(cin_reg);

    Bit#(4) result = truncate(sum);      // 低4位是和
    Bit#(1) cout = sum[4];               // 第5位是进位

    valid <= False;
    return tuple2(result, cout);
  endmethod

endmodule

endpackage
```

## 级联版全加器

```bluespec
// 文件名: Adder4_Cascade.bsv
package Adder4_Cascade;

import Adder4::*;

// 1位全加器函数（组合逻辑）
function Tuple2#(Bit#(1), Bit#(1)) fullAdder(Bit#(1) a, Bit#(1) b, Bit#(1) cin);
  Bit#(1) sum = a ^ b ^ cin;           // XOR: a ⊕ b ⊕ cin
  Bit#(1) cout = (a & b) | (a & cin) | (b & cin);  // 多数表决
  return tuple2(sum, cout);
endfunction

(* synthesize *)
module mkAdder4_Cascade(Adder4IFC);

  Reg#(Bit#(4)) a_reg <- mkRegU();
  Reg#(Bit#(4)) b_reg <- mkRegU();
  Reg#(Bit#(1)) cin_reg <- mkRegU();
  Reg#(Bool) valid <- mkReg(False);

  method Action put(Bit#(4) a, Bit#(4) b, Bit#(1) cin) if (!valid);
    a_reg <= a;
    b_reg <= b;
    cin_reg <= cin;
    valid <= True;
  endmethod

  method ActionValue#(Tuple2#(Bit#(4), Bit#(1))) get() if (valid);
    // 级联4个全加器
    Bit#(1) c0 = cin_reg;

    match {.s0, .c1} = fullAdder(a_reg[0], b_reg[0], c0);
    match {.s1, .c2} = fullAdder(a_reg[1], b_reg[1], c1);
    match {.s2, .c3} = fullAdder(a_reg[2], b_reg[2], c2);
    match {.s3, .c4} = fullAdder(a_reg[3], b_reg[3], c3);

    Bit#(4) result = {s3, s2, s1, s0};

    valid <= False;
    return tuple2(result, c4);
  endmethod

endmodule

endpackage
```

## 八位的全加器

```bluespec
// 文件名: Adder8.bsv
package Adder8;

interface Adder8IFC;
  method Action put(Bit#(8) a, Bit#(8) b, Bit#(1) cin);
  method ActionValue#(Tuple2#(Bit#(8), Bit#(1))) get();
endinterface

endpackage
```

使用四位加法器实现：

```bluespec
// 文件名: Adder8_Compose.bsv
package Adder8_Compose;

import Adder4::*;      // 导入4位加法器
import Adder8::*;

(* synthesize *)
module mkAdder8_Compose(Adder8IFC);

  // **实例化**两个4位加法器
  Adder4IFC adder_low <- mkAdder4_Simple;
  Adder4IFC adder_high <- mkAdder4_Simple;

  // 内部寄存器
  Reg#(Bit#(8)) a_reg <- mkRegU();
  Reg#(Bit#(8)) b_reg <- mkRegU();
  Reg#(Bit#(1)) cin_reg <- mkRegU();
  Reg#(Bit#(1)) stage <- mkReg(0);

  // 中间结果
  Reg#(Bit#(4)) sum_low <- mkRegU();
  Reg#(Bit#(1)) carry_mid <- mkRegU();

  method Action put(Bit#(8) a, Bit#(8) b, Bit#(1) cin) if (stage == 0);
    a_reg <= a;
    b_reg <= b;
    cin_reg <= cin;
    stage <= 1;
  endmethod

  // 阶段1：计算低4位
  rule rl_stage1 (stage == 1);
    // 会发现，计算就是调用实例的方法
    adder_low.put(a_reg[3:0], b_reg[3:0], cin_reg);

    match {.sum, .carry} <- adder_low.get();

    sum_low <= sum;
    carry_mid <= carry;

    stage <= 2;
  endrule

  // 阶段2：计算高4位（带进位）
  rule rl_stage2 (stage == 2);
    adder_high.put(a_reg[7:4], b_reg[7:4], carry_mid);

    match {.sum, .carry} <- adder_high.get();

    Bit#(8) result = {sum, sum_low};

    stage <= 3;
    // 存储结果，等待 get
  endrule

  // 结果寄存器
  Reg#(Bit#(8)) result_reg <- mkRegU();
  Reg#(Bit#(1)) cout_reg <- mkRegU();
  Reg#(Bool) result_valid <- mkReg(False);

  rule rl_store (stage == 3);
    result_reg <= result;
    cout_reg <= carry;
    result_valid <= True;
    stage <= 0;
  endrule

  method ActionValue#(Tuple2#(Bit#(8), Bit#(1))) get() if (result_valid);
    result_valid <= False;
    return tuple2(result_reg, cout_reg);
  endmethod

endmodule

endpackage
```

任意位宽的通用全加器

```bluespec
// 文件名: AdderN.bsv
package AdderN;

interface AdderIFC#(numeric type n);  // 常量泛型
  method Action put(Bit#(n) a, Bit#(n) b, Bit#(1) cin);
  method ActionValue#(Tuple2#(Bit#(n), Bit#(1))) get();
endinterface

// 参数化加法器（任意位宽）
module mkAdder#(numeric type n)(AdderIFC#(n))
  provisos (Add#(1, n, m));  // n+1 = m，用于进位扩展

  Reg#(Bit#(n)) a_reg <- mkRegU();
  Reg#(Bit#(n)) b_reg <- mkRegU();
  Reg#(Bit#(1)) cin_reg <- mkRegU();
  Reg#(Bool) valid <- mkReg(False);

  method Action put(Bit#(n) a, Bit#(n) b, Bit#(1) cin) if (!valid);
    a_reg <= a;
    b_reg <= b;
    cin_reg <= cin;
    valid <= True;
  endmethod

  method ActionValue#(Tuple2#(Bit#(n), Bit#(1))) get() if (valid);
    // 扩展到 n+1 位进行加法
    Bit#(TAdd#(n,1)) sum = zeroExtend(a_reg) + zeroExtend(b_reg) + zeroExtend(cin_reg);

    Bit#(n) result = truncate(sum);
    Bit#(1) cout = sum[n];  // 最高位是进位

    valid <= False;
    return tuple2(result, cout);
  endmethod

endmodule

// 8位加法器的特化实例
typedef AdderIFC#(8) Adder8IFC;
module mkAdder8(Adder8IFC);
  let m <- mkAdder#(8);
  return m;
endmodule

endpackage
```

## 测试平台示例

```bluespec
// 文件名: Testbench.bsv
package Testbench;

import Adder4::*;
import Adder4_Simple::*;
import Adder8_Compose::*;
import StmtFSM::*;

(* synthesize *)
module mkTestbench(Empty);

  // 实例化待测模块
  Adder4IFC adder4 <- mkAdder4_Simple;
  Adder8IFC adder8 <- mkAdder8_Compose;

  // 测试函数
  function Action test4(Bit#(4) a, Bit#(4) b, Bit#(1) cin);
    action
      $display("Testing 4-bit: %d + %d + %d", a, b, cin);
      adder4.put(a, b, cin);
      match {.sum, .cout} <- adder4.get();

      // 验证
      Bit#(5) expected = zeroExtend(a) + zeroExtend(b) + zeroExtend(cin);
      $display("  Result: sum=%d (%b), cout=%d (%b)", sum, sum, cout, cout);
      $display("  Expected: sum=%d, cout=%d", truncate(expected), expected[4]);

      if (sum == truncate(expected) && cout == expected[4])
        $display("  [PASS]");
      else
        $display("  [FAIL]");
    endaction
  endfunction

  function Action test8(Bit#(8) a, Bit#(8) b, Bit#(1) cin);
    action
      $display("Testing 8-bit: %d + %d + %d", a, b, cin);
      adder8.put(a, b, cin);
      match {.sum, .cout} <- adder8.get();

      Bit#(9) expected = zeroExtend(a) + zeroExtend(b) + zeroExtend(cin);
      $display("  Result: sum=%d, cout=%d", sum, cout);
      $display("  Expected: sum=%d, cout=%d", truncate(expected), expected[8]);

      if (sum == truncate(expected) && cout == expected[8])
        $display("  [PASS]");
      else
        $display("  [FAIL]");
    endaction
  endfunction

  // 测试序列
  Stmt test_seq = seq

    $display("========== Testing 4-bit Adder ==========");

    test4(0, 0, 0);
    test4(1, 2, 0);
    test4(5, 7, 0);
    test4(15, 1, 0);      // 15+1 = 16，进位
    test4(15, 15, 1);      // 15+15+1 = 31，进位
    test4(8, 8, 1);        // 8+8+1 = 17
    test4(10, 5, 1);       // 10+5+1 = 16

    $display("========== Testing 8-bit Adder ==========");

    test8(0, 0, 0);
    test8(100, 200, 0);
    test8(255, 1, 0);      // 256，进位
    test8(128, 128, 0);    // 256，进位
    test8(255, 255, 1);    // 511，进位
    test8(200, 55, 1);     // 256，进位

    $display("========== All tests complete ==========");
    $finish;
  endseq;

  mkAutoFSM(test_seq);

endmodule

endpackage
```

编译执行，输出波形：

```bash
mkdir build

# 编译4位加法器
bsc -sim -u -g mkAdder4_Simple -bdir ./build ./Adder4_Simple.bsv

# 编译8位加法器
bsc -sim -u -g mkAdder8_Compose -bdir ./build ./Adder8_Compose.bsv

# 编译 Testbench
bsc -sim -u -g mkTestbench -bdir ./build ./Testbench.bsv

# 链接
bsc -sim -e mkTestbench -bdir ./build -o ./adder_test

# 运行
./build/adder_test -V
```
