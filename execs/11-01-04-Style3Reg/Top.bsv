package Top;

import Clocks::*;

(* synthesize *)
module mkTop(Empty);
    // ============================================================
    // 第一部分：创建时钟和复位（参考教材第12-14页）
    // ============================================================

    // 创建两个不同的时钟域
    Clock src_clk <- mkAbsoluteClock(10, 10);   // 50MHz (源时钟域)
    Clock dst_clk <- mkAbsoluteClock(20, 20);   // 25MHz (目标时钟域)

    // 创建复位信号
    Reset src_rst <- mkInitialReset(2, clocked_by src_clk);
    Reset dst_rst <- mkInitialReset(2, clocked_by dst_clk);

    // ============================================================
    // 第二部分：6 种寄存器创建风格（全部在 src_clk 域）
    // ============================================================

    // 风格1：最简风格 - 使用 clocked_by 和 reset_by
    Reg#(Bit#(8)) reg_style1 <- mkReg(0, clocked_by src_clk, reset_by src_rst);

    // 风格2：指定时钟 + noReset（无复位）
    Reg#(Bit#(8)) reg_style2 <- mkReg(0, clocked_by src_clk, reset_by noReset);

    // 风格3：指定时钟 + 显式复位（与风格1相同写法）
    Reg#(Bit#(8)) reg_style3 <- mkReg(0, clocked_by src_clk, reset_by src_rst);

    // 风格4：mkRegU - 未初始化（综合时节省资源）
    Reg#(Bit#(8)) reg_style4 <- mkRegU(clocked_by src_clk, reset_by noReset);

    // 风格5：mkRegA - 异步复位寄存器
    Reg#(Bit#(8)) reg_style5 <- mkRegA(0, clocked_by src_clk, reset_by src_rst);

    // 风格6：带初始值的寄存器
    Reg#(Bit#(8)) reg_style6 <- mkReg(100, clocked_by src_clk, reset_by src_rst);

    // ============================================================
    // 第三部分：源时钟域的规则（所有操作在同一时钟域 src_clk）
    // ============================================================

    rule r_style1;
        reg_style1 <= reg_style1 + 1;
        $display("[STYLE1] reg=%0d", reg_style1);
    endrule

    rule r_style2;
        reg_style2 <= reg_style2 + 2;
        $display("[STYLE2] noReset: reg=%0d", reg_style2);
    endrule

    rule r_style3;
        reg_style3 <= reg_style3 + 3;
        $display("[STYLE3] with reset: reg=%0d", reg_style3);
    endrule

    rule r_style4;
        reg_style4 <= reg_style4 + 4;
        $display("[STYLE4] mkRegU: reg=%0d", reg_style4);
    endrule

    rule r_style5;
        reg_style5 <= reg_style5 + 5;
        $display("[STYLE5] mkRegA: reg=%0d", reg_style5);
    endrule

    rule r_style6;
        reg_style6 <= reg_style6 + 6;
        $display("[STYLE6] init100: reg=%0d", reg_style6);
    endrule

    // ============================================================
    // 第四部分：CDC 原语演示（参考教材第30-34页）
    // ============================================================

    // 4.1 mkSyncReg - 寄存器同步器
    // 教材第30页: mkSyncReg(0, src_clk, src_rst, dst_clk)
    Reg#(Bit#(8)) sync_reg <- mkSyncReg(0, src_clk, src_rst, dst_clk);

    // 写入同步寄存器（必须在 src_clk 域）
    rule write_sync_reg;
        sync_reg <= reg_style1;
        $display("[SYNC_REG_WRITE] value=%0d", reg_style1);
    endrule

    // 4.2 mkSyncFIFO - FIFO 同步器
    // 教材第31-32页: mkSyncFIFO(4, src_clk, src_rst, dst_clk)
    SyncFIFOIfc#(Bit#(8)) fifo_sync <- mkSyncFIFO(4, src_clk, src_rst, dst_clk);

    // 生产者：写 FIFO（必须在 src_clk 域）
    rule fifo_enq (fifo_sync.notFull);
        fifo_sync.enq(reg_style1);
        $display("[FIFO_ENQ] enq=%0d, notFull=%0d", reg_style1, fifo_sync.notFull);
    endrule

    // 4.3 mkNullCrossingWire - 空同步器
    // 教材第33-34页: mkNullCrossingWire(dst_clk, src_signal)
    ReadOnly#(Bit#(8)) null_crossed <- mkNullCrossingWire(dst_clk, reg_style1);

    rule read_null_cross;
        $display("[NULL_CROSS] unsafe=%0d", null_crossed);
    endrule

    // ============================================================
    // 第五部分：目标时钟域的规则（读取 dst_clk 域的信号）
    // ============================================================

    // 读取同步寄存器（必须在 dst_clk 域）
    rule read_sync_reg;
        $display("[SYNC_REG_READ] synced=%0d (dst_clk domain)", sync_reg);
    endrule

    // 消费者：读 FIFO（必须在 dst_clk 域）
    rule fifo_deq (fifo_sync.notEmpty);
        let d = fifo_sync.first;
        fifo_sync.deq;
        $display("[FIFO_DEQ] deq=%0d, notEmpty=%0d (dst_clk domain)", d, fifo_sync.notEmpty);
    endrule

    // ============================================================
    // 第六部分：源时钟域监视器（只使用 src_clk 域的信号）
    // ============================================================

    Reg#(Bit#(16)) cycle_cnt <- mkReg(0, clocked_by src_clk, reset_by src_rst);

    rule monitor;
        cycle_cnt <= cycle_cnt + 1;
        if (cycle_cnt % 50 == 0 && cycle_cnt > 0) begin
            $display("========================================");
            $display("CYCLE %0d SUMMARY (src_clk domain):", cycle_cnt);
            $display("  Style1: %0d", reg_style1);
            $display("  Style2(noReset): %0d", reg_style2);
            $display("  Style3: %0d", reg_style3);
            $display("  Style4(mkRegU): %0d", reg_style4);
            $display("  Style5(mkRegA): %0d", reg_style5);
            $display("  Style6(init100): %0d", reg_style6);
            $display("========================================");
        end
    endrule

endmodule

endpackage
