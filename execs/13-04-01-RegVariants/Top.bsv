// 寄存器变体：mkReg / mkRegU / mkRegA / mkConfigReg / mkDReg / mkBypassReg
package Top;
import DReg::*; import ConfigReg::*; import BypassReg::*; import Vector::*;

(* synthesize *)
module mkTop(Empty);
   Reg#(Bit#(8)) plain <- mkReg(0);            // 同步复位
   Reg#(Bit#(8)) cfg   <- mkConfigReg(0);      // 读写无调度约束
   Reg#(Bit#(8)) dreg  <- mkDReg(0);           // 写入只保持1拍，之后自动回默认 0
   Reg#(Bit#(8)) cyc   <- mkReg(0);

   rule tick; cyc <= cyc + 1; if (cyc > 5) $finish(0); endrule
   rule drive (cyc == 2); dreg <= 99; plain <= 99; cfg <= 99; endrule   // 第2拍写 99
   rule watch;
      $display("cyc=%0d  plain=%0d  dreg=%0d  cfg=%0d", cyc, plain, dreg, cfg);
   endrule
endmodule
endpackage
