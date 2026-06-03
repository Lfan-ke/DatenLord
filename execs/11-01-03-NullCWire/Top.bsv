package Top;

import Clocks::*;

(* synthesize *)
module mkTop(Empty);
    Clock src_clk <- mkAbsoluteClock(10, 10);  // 50MHz
    Clock dst_clk <- mkAbsoluteClock(20, 20);  // 25MHz

    // 源信号（使用默认时钟）
    Reg#(Bit#(8)) source <- mkReg(0);

    rule count;
        source <= source + 1;
        $display("[SRC] source=%0d", source);
    endrule

    // mkNullCrossingWire: 参数 (目标时钟, 源信号)
    ReadOnly#(Bit#(8)) crossed <- mkNullCrossingWire(dst_clk, source);

    rule peek;
        $display("[VIEW] crossed=%0d (unsafe direct wire)", crossed);
    endrule

endmodule

endpackage
