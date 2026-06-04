// GetPut/Connectable：源(Get) 经 mkConnection 接到 汇(Put)
package Top;
import GetPut::*; import Connectable::*; import FIFOF::*;

(* synthesize *)
module mkTop(Empty);
   FIFOF#(Bit#(8)) src <- mkFIFOF;     // 数据源用 FIFOF 的 Get 侧
   Reg#(Bit#(8)) i <- mkReg(0);
   Reg#(Bit#(8)) n <- mkReg(0);

   // 汇：把收到的值打印
   let sink = interface Put#(Bit#(8));
                 method Action put(Bit#(8) x);
                    $display("sink got %0d", x);
                    n <= n + 1; if (n == 3) $finish(0);
                 endmethod
              endinterface;

   mkConnection(toGet(src), sink);     // 一行连：Get -> Put

   rule fill (i < 4); src.enq(i * 11); i <= i + 1; endrule
endmodule
endpackage
