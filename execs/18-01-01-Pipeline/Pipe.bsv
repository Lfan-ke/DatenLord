// 进阶惯用法合集（参考 Piccolo/Flute 风格，本地实跑）：
//   - tagged union 流水载荷 + case matches
//   - 级间 FIFO 选型：mkBypassFIFOF(0拍) 进、mkPipelineFIFOF(1拍) 出
//   - CReg 并发计数器(Cntrs/EHR)：多 rule 同拍可增
//   - ConfigReg 作 CSR/epoch 类状态
package Pipe;
import FIFOF::*; import SpecialFIFOs::*; import Cntrs::*; import ConfigReg::*;

typedef union tagged { Bit#(8) Compute; void Bubble; } Op deriving (Bits, Eq);

(* synthesize *)
module mkPipe(Empty);
   FIFOF#(Op)      s1 <- mkBypassFIFOF;     // 0 拍进入
   FIFOF#(Bit#(8)) s2 <- mkPipelineFIFOF;   // 1 拍流水寄存
   Count#(UInt#(16)) cycles <- mkCount(0);  // 性能计数器（CReg/EHR：可与其它 rule 同拍增）
   Count#(UInt#(16)) done   <- mkCount(0);
   Reg#(Bit#(1)) epoch <- mkConfigReg(0);   // CSR/epoch 类用 ConfigReg（读写无调度约束）
   Reg#(Bit#(8)) fed <- mkReg(0);

   rule tick; cycles.incr(1); endrule

   rule feed (fed < 4);
      s1.enq(tagged Compute (fed + 1));
      fed <= fed + 1;
   endrule

   rule exec;                               // 级1：执行（跳过 Bubble）
      let op = s1.first; s1.deq;
      case (op) matches
         tagged Compute .v: s2.enq(v * 2);
         tagged Bubble:     noAction;
      endcase
   endrule

   rule wb;                                 // 级2：写回 + 计数
      let r = s2.first; s2.deq; done.incr(1);
      $display("[wb] result=%0d cyc=%0d", r, cycles);
   endrule

   rule fin (done == 4); $display("done=%0d", done); $finish(0); endrule
endmodule
endpackage
