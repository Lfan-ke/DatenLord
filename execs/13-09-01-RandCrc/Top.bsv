package Top;
import LFSR::*; import CRC::*; import Gray::*; import StmtFSM::*;
(* synthesize *)
module mkTop(Empty);
   LFSR#(Bit#(8)) lfsr <- mkLFSR_8;
   CRC#(16)       crc  <- mkCRC_CCITT;
   Stmt s = seq
      lfsr.seed(8'h1);
      repeat(3) seq
         $display("lfsr=%0h", lfsr.value);
         lfsr.next;
      endseq
      crc.add(8'h31);                 // 每个 add 独立一拍（方法每 rule 只能调一次）
      crc.add(8'h32);
      crc.add(8'h33);
      $display("crc=%0h", crc.result);
      action
         $display("gray(6)=%0h decode=%0d", grayEncode(6'd6).code, grayDecode(grayEncode(6'd6)));
         $finish(0);
      endaction
   endseq;
   mkAutoFSM(s);
endmodule
endpackage
