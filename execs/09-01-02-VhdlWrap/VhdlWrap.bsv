package VhdlWrap;
interface AddIfc;
   method Action  put(Bit#(8) a, Bit#(8) b);
   method Bit#(8) get;
endinterface
import "BVI" vadd_wrapper =
   module mkVadd(AddIfc);
      default_clock clk(clk);
      default_reset rst(rst_n);
      method put(a, b) enable(en);   // 参数→Verilog 端口 a,b；使能→en
      method q get;                   // 值方法：输出端口 q 在名前
      schedule (get) SB (put);
      schedule (get) CF (get);
   endmodule
(* synthesize *)
module mkTop(Empty);
   AddIfc dut <- mkVadd;
   Reg#(Bit#(16)) cyc <- mkReg(0);
   rule tick; cyc<=cyc+1; if (cyc>5) $finish(0); endrule
   rule p (cyc==1); dut.put(10, 20); endrule          // q <= 30
   rule g (cyc==3); $display("q = %0d (expect 30)", dut.get); endrule
endmodule
endpackage
