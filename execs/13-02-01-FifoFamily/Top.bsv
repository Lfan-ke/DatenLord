// FIFO 家族用法：生产者-消费者经 FIFOF(notFull/notEmpty)；附 special FIFO 构造
package Top;
import FIFO::*; import FIFOF::*; import SpecialFIFOs::*; import BRAMFIFO::*;

(* synthesize *)
module mkTop(Empty);
   FIFOF#(Bit#(8)) f <- mkFIFOF;               // 带标志的 FIFO
   // 其它变体（构造演示）：
   FIFO#(Bit#(8))  p <- mkPipelineFIFO;        // 1拍流水
   FIFO#(Bit#(8))  b <- mkBypassFIFO;          // 0拍旁路
   FIFO#(Bit#(8))  s <- mkSizedBRAMFIFO(64);   // BRAM 背书的大 FIFO
   Reg#(Bit#(8)) i <- mkReg(0);
   Reg#(Bit#(8)) o <- mkReg(0);

   rule prod (i < 5 && f.notFull);             // 满则自动 stall
      f.enq(i * 10); i <= i + 1;
   endrule
   rule cons (f.notEmpty);                     // 空则自动 stall
      $display("got %0d", f.first); f.deq; o <= o + 1;
      if (o == 4) $finish(0);
   endrule
   // 让 p/b/s 不被优化掉（仅构造演示）
   rule touch (i == 99); p.enq(1); b.enq(1); s.enq(1); endrule
endmodule
endpackage
