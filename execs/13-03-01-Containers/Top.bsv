// 容器用法：Vector(可综合定长) 的常用操作 + Vector of Reg
package Top;
import Vector::*; import BuildVector::*; import StmtFSM::*;

(* synthesize *)
module mkTop(Empty);
   // Vector of Reg：寄存器组
   Vector#(4, Reg#(Bit#(8))) rs <- replicateM(mkReg(0));
   Reg#(Bit#(8)) acc <- mkReg(0);

   Stmt s = seq
      // 写寄存器组
      action for (Integer k=0;k<4;k=k+1) rs[k] <= fromInteger(k+1); endaction
      action
         // 纯值向量操作
         Vector#(4, Bit#(8)) a = vec(1,2,3,4);
         Vector#(4, Bit#(8)) b = replicate(10);
         Vector#(4, Bit#(8)) c = zipWith(\+ , a, b);     // 逐元素相加
         Bit#(8) total = fold(\+ , c);                   // 折叠求和(平衡树)
         Bit#(8) rsum  = fold(\+ , readVReg(rs));        // 读寄存器组求和
         $display("c=[%0d %0d %0d %0d] total=%0d rsum=%0d",
                  c[0],c[1],c[2],c[3], total, rsum);
         $display("map(*2): %0d  reverse[0]=%0d  elem3? %0d",
                  map( \* (2), a)[0], reverse(a)[0], (elem(3,a)?1:0));
         $finish(0);
      endaction
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
