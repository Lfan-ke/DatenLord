// 计数器：Cntrs 的 Count(并发 incr/decr) 与 UCount(带比较)，Counter 原语
package Top;
import Cntrs::*; import Counter::*;

(* synthesize *)
module mkTop(Empty);
   Count#(UInt#(8))  c  <- mkCount(0);        // CReg 式：incr 与 decr 可同拍
   UCount            uc <- mkUCount(0, 100);   // 位宽按 maxValue 自动；带 isEqual 等
   Counter#(8)       k  <- mkCounter(0);       // Verilog Counter 原语
   Reg#(Bit#(8)) cyc <- mkReg(0);

   rule tick; cyc <= cyc + 1; if (cyc > 4) $finish(0); endrule
   rule a (cyc < 3); c.incr(5); endrule        // 这两条
   rule b (cyc < 3); c.decr(2); endrule        // 可同拍触发(净 +3/拍)
   rule u; uc.incr(1); k.up; endrule
   rule watch;
      $display("cyc=%0d  count=%0d  ucount=%0d(==3?%0d)  counter=%0d",
               cyc, c, uc.isEqual(3)?3:0, uc.isEqual(3)?1:0, k.value);
   endrule
endmodule
endpackage
