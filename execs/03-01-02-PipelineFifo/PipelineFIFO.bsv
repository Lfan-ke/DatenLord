package PipelineFIFO;

import FIFOF::*;

interface TestIFC;
    method Action enq(Bit#(8) x);
    method Action deq;
    method Bit#(8) first;
    method Bool notEmpty;
    method Bool notFull;
endinterface

(* synthesize *)
module mkPipelineFIFO(TestIFC);

    FIFOF#(Bit#(8)) fifo <- mkFIFOF;

    method Action enq(Bit#(8) x) if (fifo.notFull);
        fifo.enq(x);
    endmethod

    method Action deq if (fifo.notEmpty);
        fifo.deq;
    endmethod

    method Bit#(8) first if (fifo.notEmpty);
        return fifo.first;
    endmethod

    method Bool notEmpty;
        return fifo.notEmpty;
    endmethod

    method Bool notFull;
        return fifo.notFull;
    endmethod

endmodule

endpackage
