package Top;

import Clocks::*;

(* synthesize *)
module mkTop(Empty);
    // 创建两个不同的时钟
    Clock src_clk <- mkAbsoluteClock(10, 10);  // 50MHz (源时钟域)
    Clock dst_clk <- mkAbsoluteClock(20, 20);  // 25MHz (目标时钟域)

    // 创建复位信号，并指定时钟域
    Reset src_rst <- mkInitialReset(2, clocked_by src_clk);
    Reset dst_rst <- mkInitialReset(2, clocked_by dst_clk);

    // ===== 源时钟域：使用 clocked_by 和 reset_by =====
    Reg#(Bit#(8)) src_counter <- mkReg(0, clocked_by src_clk, reset_by src_rst);
    Reg#(Bit#(8)) src_strobe <- mkReg(0, clocked_by src_clk, reset_by src_rst);

    rule generate_src;
        src_counter <= src_counter + 1;
        // 每 8 个周期产生一个脉冲
        src_strobe <= (src_counter % 8 == 0) ? 8'hFF : 8'h00;
        $display("[SRC_CLK @ %5t] counter=%0d, strobe=%0h",
                 $time, src_counter, src_strobe);
    endrule

    // ===== mkSyncReg：寄存器同步器 =====
    // 参数顺序: (initial_value, src_clock, src_reset, dst_clock)
    Reg#(Bit#(8)) synced_counter <- mkSyncReg(
        0,          // 初始值
        src_clk,    // 源时钟
        src_rst,    // 源复位（使用显式复位）
        dst_clk     // 目标时钟
    );

    // 使用 noReset 的版本（不需要复位）
    Reg#(Bit#(8)) synced_strobe <- mkSyncReg(
        0,          // 初始值
        src_clk,    // 源时钟
        noReset,    // 无复位
        dst_clk     // 目标时钟
    );

    // 目标时钟域的写入规则（注意：规则在默认时钟域，但 synced_* 在 dst_clk 域）
    rule write_to_synced;
        synced_counter <= src_counter;
        synced_strobe <= src_strobe;
    endrule

    // 读取同步后的数据
    rule display_synced;
        $display("[DST_VIEW @ %5t] synced_counter=%0d, synced_strobe=%0h",
                 $time, synced_counter, synced_strobe);
    endrule

    // ===== 对比：不安全直接跨域 =====
    ReadOnly#(Bit#(8)) unsafe_wire <- mkNullCrossingWire(
        dst_clk,
        src_counter
    );

    rule compare;
        $display("[COMPARE @ %5t] unsafe=%0d vs safe(synced)=%0d",
                 $time, unsafe_wire, synced_counter);
    endrule

endmodule

endpackage
