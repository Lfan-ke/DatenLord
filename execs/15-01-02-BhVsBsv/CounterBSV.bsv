package CounterBSV;
interface Counter#(numeric type n);
   method Bit#(n) value;
   method Action  inc;
   method Action  clear;
endinterface
(* synthesize *)
module mkUpCounterBSV(Counter#(8));
   Reg#(Bit#(8)) cnt <- mkReg(0);
   rule wrap (cnt == maxBound); cnt <= 0; endrule
   method Bit#(8) value = cnt;
   method Action  inc;   cnt <= cnt + 1; endmethod
   method Action  clear; cnt <= 0;       endmethod
endmodule
endpackage
