package Top;

import Clocks::*;

(* synthesize *)
module mkTop(Empty);
    Clock write_clk <- mkAbsoluteClock(10, 10);  // 50MHz
    Clock read_clk  <- mkAbsoluteClock(20, 20);  // 25MHz

    // mkSyncFIFO: 参数 (深度, 写时钟, 写复位, 读时钟)
    SyncFIFOIfc#(Bit#(8)) fifo <- mkSyncFIFO(4, write_clk, noReset, read_clk);

    // 写域
    Reg#(Bit#(8)) wdata <- mkReg(0, clocked_by write_clk, reset_by noReset);

    rule do_write (fifo.notFull);
        wdata <= wdata + 1;
        fifo.enq(wdata);
        $display("[WRITE] enq=%0d, notFull=%0d", wdata, fifo.notFull);
    endrule

    // 读域
    rule do_read (fifo.notEmpty);
        let d = fifo.first;
        fifo.deq;
        $display("[READ] deq=%0d, notEmpty=%0d", d, fifo.notEmpty);
    endrule

endmodule

endpackage
