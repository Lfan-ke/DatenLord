// 数学：FixedPoint(定点) + Complex(复数)
package Top;
import FixedPoint::*; import Complex::*; import StmtFSM::*;

(* synthesize *)
module mkTop(Empty);
   Stmt s = seq
      action
         FixedPoint#(4,8) x = fromRational(7, 8);    // 0.875
         FixedPoint#(4,8) y = fromRational(1, 2);    // 0.5
         FixedPoint#(4,8) z = x + y;                  // 1.375
         $write("x="); fxptWrite(3, x);
         $write("  x+y="); fxptWrite(3, z);
         $write("  x*y="); fxptWrite(3, x * y); $display("");   // 0.4375

         Complex#(Int#(8)) a = cmplx(2, 3);          // 2+3i
         Complex#(Int#(8)) b = cmplx(1, -1);         // 1-1i
         Complex#(Int#(8)) c = a * b;                 // (2+3i)(1-i)=5+1i
         $display("c.rel=%0d c.img=%0d", c.rel, c.img);
         $finish(0);
      endaction
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
