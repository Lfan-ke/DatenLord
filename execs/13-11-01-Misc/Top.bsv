// 其余实用包：CompletionBuffer(乱序完成→顺序流出) + Once(只做一次) + countOnes
package Top;
import CompletionBuffer::*; import GetPut::*; import Once::*; import StmtFSM::*;

(* synthesize *)
module mkTop(Empty);
   CompletionBuffer#(8, Bit#(8)) cb <- mkCompletionBuffer;
   Reg#(CBToken#(8)) t0 <- mkRegU; Reg#(CBToken#(8)) t1 <- mkRegU; Reg#(CBToken#(8)) t2 <- mkRegU;

   Reg#(Bit#(4)) hits <- mkReg(0);
   Once once <- mkOnce(action hits <= hits + 1; endaction);
   // start 的隐式条件 when ready：此 rule 每拍都想跑，但 Once 内部只放行一次
   rule fire_once; once.start; endrule

   Stmt s = seq
      $display("countOnes(8'hB3)=%0d", countOnes(8'hB3));     // 0xB3=10110011 → 5
      action let x <- cb.reserve.get; t0 <= x; endaction      // 按序预订 3 个槽
      action let x <- cb.reserve.get; t1 <= x; endaction
      action let x <- cb.reserve.get; t2 <= x; endaction
      action cb.complete.put(tuple2(t2, 8'hCC)); endaction     // 乱序完成
      action cb.complete.put(tuple2(t0, 8'hAA)); endaction
      action cb.complete.put(tuple2(t1, 8'hBB)); endaction
      action let v <- cb.drain.get; $display("drain=%0h", v); endaction   // 顺序流出 AA
      action let v <- cb.drain.get; $display("drain=%0h", v); endaction   // BB
      action let v <- cb.drain.get; $display("drain=%0h", v); endaction   // CC
      $display("once hits=%0d", hits);                         // 只 +1
      $finish(0);
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
