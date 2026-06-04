// bsc-contrib/Misc 示例：CreditCounter(信用流控) + pop(GetPut_Aux) + cur_cycle
package Top;
import CreditCounter::*; import GetPut_Aux::*; import Cur_Cycle::*;
import FIFOF::*; import StmtFSM::*;

(* synthesize *)
module mkTop(Empty);
   CreditCounter_IFC#(4) credit <- mkCreditCounter;   // 4 位信用计数（0~15），incr 到顶/decr 到 0 自带守卫
   FIFOF#(Bit#(8))       q      <- mkFIFOF;

   Stmt s = seq
      action credit.incr; q.enq(8'hA0); endaction   // 发 1 个，占 1 信用
      action credit.incr; q.enq(8'hA1); endaction   // 再发 1 个
      $display("cyc=%0d credits_used=%0d", cur_cycle, credit.value);
      action let x <- pop(q); $display("pop=%0h", x); credit.decr; endaction  // 收 1 个，释放 1 信用
      action let x <- pop(q); $display("pop=%0h", x); credit.decr; endaction
      $display("cyc=%0d credits_used=%0d", cur_cycle, credit.value);
      $finish(0);
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
