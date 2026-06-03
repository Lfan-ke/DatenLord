package Adder;

interface AdderIFC;
    method Action set(Bit#(8) a, Bit#(8) b);
    method Bit#(8) get_sum();
    method Bool ready();
endinterface

(* synthesize *)
module mkAdder(AdderIFC);
    Reg#(Bit#(8)) a_reg <- mkReg(0);
    Reg#(Bit#(8)) b_reg <- mkReg(0);
    Reg#(Bit#(8)) sum_reg <- mkReg(0);
    Reg#(Bool) valid <- mkReg(False);

    rule r_compute;
        sum_reg <= a_reg + b_reg;
        valid <= True;
    endrule

    method Action set(Bit#(8) a, Bit#(8) b);
        a_reg <= a;
        b_reg <= b;
        valid <= False;
    endmethod

    method Bit#(8) get_sum();
        return sum_reg;
    endmethod

    method Bool ready();
        return valid;
    endmethod
endmodule

endpackage
