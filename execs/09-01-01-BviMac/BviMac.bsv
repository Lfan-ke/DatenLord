package BviMac;

// 给上层用的 BSV 接口
interface MacIFC;
   method Action       acc(Int#(16) a, Int#(16) b);   // out += a*b
   method Action       reset_acc(Int#(16) v);         // out  = v
   method Int#(16)     read_y;                         // 读 out
endinterface

// ===== import "BVI"：把 mymac.v 当黑盒导入 =====
// 关键：关键字是 enable（非 en）；输出端口放在方法名【前】；无 = (...) 右侧
import "BVI" mymac =
   module mkMac(MacIFC);
      default_clock clk(clk);
      default_reset rst(rst_b);

      method acc(a, b)              enable(EN);       // 参数→Verilog 输入端口 a,b；使能→EN
      method reset_acc(clear_value) enable(clear);    // 参数→clear_value；使能→clear
      method out read_y;                              // 值方法：输出端口 out 在方法名前

      schedule (read_y)  SB (acc, reset_acc);         // 读旧值在写之前
      schedule (acc)     C  (reset_acc);              // 两个写互斥
      schedule (read_y)  CF (read_y);
   endmodule

// ===== 测试台：驱动黑盒，验证乘加与清零 =====
(* synthesize *)
module mkTop(Empty);
   MacIFC mac <- mkMac;
   Reg#(Bit#(16)) cyc <- mkReg(0);
   rule tick; cyc <= cyc + 1; if (cyc > 8) $finish(0); endrule
   rule s1 (cyc==1); mac.acc(3, 4); endrule                                  // out=0+12=12
   rule s2 (cyc==2); mac.acc(5, 6); endrule                                  // out=12+30=42
   rule s3 (cyc==3); $display("after 3*4 + 5*6 : y=%0d (expect 42)", mac.read_y); endrule
   rule s4 (cyc==4); mac.reset_acc(100); endrule                             // out=100
   rule s5 (cyc==5); $display("after reset_acc(100): y=%0d (expect 100)", mac.read_y); endrule
endmodule

endpackage
