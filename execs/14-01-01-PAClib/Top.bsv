// PAClib 流水线示例：源(FIFOF)→ +1 →(缓冲)→ ×2 → 打印
package Top;
import PAClib::*; import FIFOF::*; import GetPut::*;

function Int#(32) f_inc(Int#(32) x) = x + 1;
function Int#(32) f_dbl(Int#(32) x) = x * 2;

(* synthesize *)
module mkTop(Empty);
   FIFOF#(Int#(32)) inq <- mkFIFOF;
   PipeOut#(Int#(32)) src = f_FIFOF_to_PipeOut(inq);     // FIFOF 输出端当作流入口
   PipeOut#(Int#(32)) p1  <- mkFn_to_Pipe(f_inc, src);   // 提升纯函数 +1
   PipeOut#(Int#(32)) p2  <- mkBuffer(p1);               // 插一级流水寄存器
   PipeOut#(Int#(32)) p3  <- mkFn_to_Pipe(f_dbl, p2);    // 再 ×2，整体 (x+1)*2

   Reg#(Int#(32)) feed <- mkReg(0);
   Reg#(Int#(32)) got  <- mkReg(0);

   rule produce (feed < 4);
      inq.enq(feed); feed <= feed + 1;                   // 喂 0,1,2,3
   endrule
   rule consume;
      let v = p3.first; p3.deq;
      $display("in=%0d -> out=%0d", got, v);             // 期望 (got+1)*2
      got <= got + 1;
      if (got == 3) $finish(0);
   endrule
endmodule
endpackage
