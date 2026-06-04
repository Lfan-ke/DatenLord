// PAClib 树归约：把每拍一个 Vector#(4) 用加法树归约成标量和
package Top;
import PAClib::*; import FIFOF::*; import Vector::*;
function Int#(32) add2(Int#(32) x, Int#(32) y) = x + y;
function Int#(32) id1 (Int#(32) x) = x;

(* synthesize *)
module mkTop(Empty);
   FIFOF#(Vector#(4, Int#(32))) inq <- mkFIFOF;
   PipeOut#(Vector#(4, Int#(32))) src = f_FIFOF_to_PipeOut(inq);
   PipeOut#(Int#(32)) sumP <- mkTreeReduceFn(add2, id1, 0, src);   // log 深加法树

   Vector#(2, Vector#(4, Int#(32))) data = newVector;
   data[0] = vectorOf4(1, 2, 3, 4);     // = 10
   data[1] = vectorOf4(10, 20, 30, 40); // = 100
   Reg#(Bit#(2)) feed <- mkReg(0); Reg#(Bit#(2)) got <- mkReg(0);
   rule produce (feed < 2); inq.enq(data[feed]); feed <= feed + 1; endrule
   rule consume; let v = sumP.first; sumP.deq; $display("treeSum=%0d", v); got <= got+1; if (got==1) $finish(0); endrule
endmodule

function Vector#(4, Int#(32)) vectorOf4(Int#(32) a, Int#(32) b, Int#(32) c, Int#(32) d);
   Vector#(4, Int#(32)) v = newVector; v[0]=a; v[1]=b; v[2]=c; v[3]=d; return v;
endfunction
endpackage
