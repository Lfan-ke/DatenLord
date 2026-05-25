package SimpleRegConflict;

interface TestIFC;
    method Bit#(8) value;
endinterface

(* synthesize *)
module mkSimpleRegConflict(TestIFC);

    Reg#(Bit#(8)) r <- mkReg(0);

    rule writeA;
        r <= 8'hAA;
    endrule

    rule writeB;
        r <= 8'h55;
    endrule

    method Bit#(8) value;
        return r;
    endmethod

endmodule

endpackage
