// 存储：RegFile(多读单写) + BRAM(Server 风格，带延迟)
package Top;
import RegFile::*; import BRAM::*; import DefaultValue::*; import StmtFSM::*;

(* synthesize *)
module mkTop(Empty);
   RegFile#(Bit#(4), Bit#(8)) rf <- mkRegFileFull;     // 16x8 寄存器堆
   BRAM_Configure cfg = defaultValue; cfg.memorySize = 16;
   BRAM2Port#(Bit#(4), Bit#(8)) bram <- mkBRAM2Server(cfg);

   function Action wr(Bit#(4) a, Bit#(8) d) = action
      rf.upd(a, d);
      bram.portA.request.put(BRAMRequest{write:True, responseOnWrite:False, address:a, datain:d});
   endaction;
   function Action rdReq(Bit#(4) a) =
      bram.portB.request.put(BRAMRequest{write:False, responseOnWrite:False, address:a, datain:?});

   Stmt s = seq
      wr(3, 8'hAA);  wr(5, 8'hBB);
      $display("RegFile[3]=%0h [5]=%0h", rf.sub(3), rf.sub(5));   // RegFile 当拍可读
      rdReq(3);
      action let d <- bram.portB.response.get; $display("BRAM[3]=%0h", d); endaction
      rdReq(5);
      action let d <- bram.portB.response.get; $display("BRAM[5]=%0h", d); endaction
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
