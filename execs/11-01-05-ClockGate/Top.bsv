package Top;

import Clocks::*;

(* synthesize *)
module mkTop(Empty);
    // ============================================================
    // 第一部分：创建基础时钟（参考教材第9-10页）
    // ============================================================

    // 获取当前模块的默认时钟（振荡器）
    Clock osc_clk <- exposeCurrentClock();

    // 创建门控时钟1：初始状态为门控关闭（gate off = 时钟运行）
    // 正确语法：mkGatedClock(bool_param, clock)
    GatedClockIfc gc1 <- mkGatedClock(False, osc_clk);
    Clock gated_clk1 = gc1.new_clk;

    // 创建门控时钟2：从 gated_clk1 派生
    GatedClockIfc gc2 <- mkGatedClock(False, gated_clk1);
    Clock gated_clk2 = gc2.new_clk;

    // ============================================================
    // 第二部分：在不同时钟域创建寄存器
    // ============================================================

    // 在原始时钟域的计数器
    Reg#(Bit#(8)) counter_osc <- mkReg(0, clocked_by osc_clk, reset_by noReset);

    // 在门控时钟1域的计数器
    Reg#(Bit#(8)) counter_g1 <- mkReg(0, clocked_by gated_clk1, reset_by noReset);

    // 在门控时钟2域的计数器
    Reg#(Bit#(8)) counter_g2 <- mkReg(0, clocked_by gated_clk2, reset_by noReset);

    // ============================================================
    // 第三部分：控制门控时钟的规则
    // ============================================================

    // 用于控制门控的信号
    Reg#(Bit#(8)) gate_control1 <- mkReg(0);
    Reg#(Bit#(8)) gate_control2 <- mkReg(0);

    // 每周期更新门控状态
    rule update_gate_controls;
        gate_control1 <= gate_control1 + 1;
        gate_control2 <= gate_control2 + 1;

        // 门控时钟1：前20周期运行，中间20周期停止，后20周期运行
        Bool gate1_on = (gate_control1 >= 20 && gate_control1 < 40);
        gc1.setGateCond(gate1_on);

        // 门控时钟2：前10周期运行，中间10周期停止，后10周期运行
        Bool gate2_on = ((gate_control2 % 30) >= 10 && (gate_control2 % 30) < 20);
        gc2.setGateCond(gate2_on);

        if (gate_control1 % 10 == 0)
            $display("[GATE_CTRL] gate1_on=%0d, gate2_on=%0d", gate1_on, gate2_on);
    endrule

    // ============================================================
    // 第四部分：各时钟域的计数规则
    // ============================================================

    // 原始时钟域：始终运行
    rule r_osc;
        counter_osc <= counter_osc + 1;
        $display("[OSC_CLK] counter_osc=%0d", counter_osc);
    endrule

    // 门控时钟1域：门控开启时停止计数
    rule r_g1;
        counter_g1 <= counter_g1 + 1;
        $display("[GATED_CLK1] counter_g1=%0d", counter_g1);
    endrule

    // 门控时钟2域：门控开启时停止计数
    rule r_g2;
        counter_g2 <= counter_g2 + 1;
        $display("[GATED_CLK2] counter_g2=%0d", counter_g2);
    endrule

    // ============================================================
    // 第五部分：时钟族和祖先关系演示（参考教材第8页）
    // ============================================================

    rule show_clock_info (counter_osc % 30 == 0 && counter_osc > 0);
        $display("========================================");
        $display("CLOCK FAMILY INFO at cycle %0d:", counter_osc);
        $display("  osc_clk is ancestor of gated_clk1: %b", isAncestor(osc_clk, gated_clk1));
        $display("  gated_clk1 is ancestor of gated_clk2: %b", isAncestor(gated_clk1, gated_clk2));
        $display("  osc_clk and gated_clk1 same family: %b", sameFamily(osc_clk, gated_clk1));
        $display("  gated_clk1 and gated_clk2 same family: %b", sameFamily(gated_clk1, gated_clk2));
        $display("========================================");
    endrule

    // ============================================================
    // 第六部分：监视器
    // ============================================================

    rule monitor (counter_osc % 20 == 0 && counter_osc > 0);
        $display("----------------------------------------");
        $display("COUNTER VALUES at cycle %0d:", counter_osc);
        $display("  osc_clk:   %0d (always running)", counter_osc);
        $display("  gated_clk1: %0d (stops when gate1_on=1)", counter_g1);
        $display("  gated_clk2: %0d (stops when gate2_on=1)", counter_g2);
        $display("----------------------------------------");
    endrule

endmodule

endpackage
