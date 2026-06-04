// bsc-contrib/Misc：VectorFIFOF —— FIFOF + 同时并行查看全部元素
package Top;
import VectorFIFOF::*; import FIFOF::*; import Vector::*; import StmtFSM::*;

function Bit#(8) m2v(Maybe#(Bit#(8)) m) = fromMaybe(8'hFF, m);  // 空槽显示 FF

(* synthesize *)
module mkTop(Empty);
   VectorFIFOF#(4, Bit#(8)) vf <- mkVectorFIFOF;   // 深度 4
   function Action showVec(String tag);
      action
         Vector#(4, Bit#(8)) view = map(m2v, vf.vector);
         $display("%s view=[%0h %0h %0h %0h]", tag, view[0], view[1], view[2], view[3]);
      endaction
   endfunction
   Stmt s = seq
      vf.fifo.enq(8'h11); vf.fifo.enq(8'h22); vf.fifo.enq(8'h33);
      showVec("after enq 3:");           // 期望 [11 22 33 FF]
      action vf.fifo.deq; endaction
      showVec("after deq 1:");           // 期望 [22 33 FF FF]
      $finish(0);
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
