// 调试/断言：Probe + Assert + messageM(静态期消息)
package Top;
import Probe::*; import Assert::*; import StmtFSM::*;

(* synthesize *)
module mkTop(Empty);
   messageM("elaborating mkTop");          // 静态细化期打印(编译时)
   Reg#(Bit#(8)) r <- mkReg(0);
   Probe#(Bit#(8)) p <- mkProbe;            // 只写探针，波形里出现 p$PROBE
   continuousAssert(True, "always true");   // 每拍检查
   Stmt s = seq
      action r <= 42; p <= 42; endaction    // 写探针
      action
         dynamicAssert(r == 42, "r should be 42");   // 运行期断言(成立则无事)
         $display("r=%0d (asserts passed)", r);
         $finish(0);
      endaction
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
