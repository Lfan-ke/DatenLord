package Top;

(* synthesize *)
module mkTop(Empty);
    // ============================================================
    // 1. mkReg - normal register (read < write, not visible in same cycle)
    // ============================================================
    Reg#(Bit#(8)) reg_normal <- mkReg(0);

    rule r_reg_normal;
        reg_normal <= reg_normal + 1;
        $display("[mkReg] write=%0d (visible next cycle, read < write)", reg_normal);
    endrule

    // ============================================================
    // 2. mkRegU - uninitialized register (read < write, not visible in same cycle)
    // ============================================================
    Reg#(Bit#(8)) reg_uninit <- mkRegU;

    rule r_reg_uninit;
        reg_uninit <= reg_uninit + 2;
        $display("[mkRegU] write=%0d (read < write)", reg_uninit);
    endrule

    // ============================================================
    // 3. mkCReg - concurrent register (p0 < p1 < p2...)
    //    higher index sees writes from lower index in same cycle
    //    (ports used in SEPARATE rules below — two ports in one rule would be G0004)
    // ============================================================
    Reg#(Bit#(8)) creg[2] <- mkCReg(2, 0);

    rule r_creg_p0;
        creg[0] <= creg[0] + 1;
        $display("[mkCReg p0] write=%0d (p0 < p1)", creg[0]);
    endrule

    rule r_creg_p1;
        let val = creg[1];
        $display("[mkCReg p1] read=%0d (visible same cycle from p0)", val);
    endrule

    // ============================================================
    // 4. mkRWire - same-cycle wire (wset < wget, returns Maybe)
    // ============================================================
    RWire#(Bit#(8)) rwire <- mkRWire();

    rule r_rwire_set;
        rwire.wset(42);
        $display("[mkRWire] wset(42) (wset < wget)");
    endrule

    rule r_rwire_get;
        case (rwire.wget) matches
            tagged Valid .x: $display("[mkRWire] got Valid: %0d (visible same cycle)", x);
            tagged Invalid: $display("[mkRWire] got Invalid");
        endcase
    endrule

    // ============================================================
    // 5. mkPulseWire - pulse wire (send < read, pulse only)
    // ============================================================
    PulseWire pulsewire <- mkPulseWire();

    rule r_pulse_send;
        pulsewire.send();
        $display("[mkPulseWire] send pulse (send < read)");
    endrule

    rule r_pulse_read;
        if (pulsewire._read())
            $display("[mkPulseWire] pulse detected (visible same cycle)");
        else
            $display("[mkPulseWire] no pulse");
    endrule

    // ============================================================
    // 6. mkDWire - default value wire (write < read, visible same cycle, has default)
    // ============================================================
    Wire#(Bit#(8)) dwire <- mkDWire(0);

    rule r_dwire_write;
        dwire <= 100;
        $display("[mkDWire] write=100 (write < read)");
    endrule

    rule r_dwire_read;
        $display("[mkDWire] read=%0d (same cycle write visible, else default 0)", dwire);
    endrule

    // ============================================================
    // 7. mkBypassWire - bypass wire (write < read, visible same cycle, no default)
    //    write side is always_enabled — must be written every cycle (r_bwire_write below)
    // ============================================================
    Wire#(Bit#(8)) bwire <- mkBypassWire();

    rule r_bwire_write;
        bwire <= 200;
        $display("[mkBypassWire] write=200 (write < read)");
    endrule

    rule r_bwire_read;
        $display("[mkBypassWire] read=%0d (same cycle write visible)", bwire);
    endrule

    // ============================================================
    // Monitor - show status every 10 cycles
    // ============================================================
    Reg#(Bit#(16)) cycle <- mkReg(0);

    rule r_monitor;
        cycle <= cycle + 1;
        if (cycle % 10 == 0 && cycle > 0) begin
            $display("==========================================");
            $display("CYCLE %0d SUMMARY:", cycle);
            $display("  mkReg:      %0d", reg_normal);
            $display("  mkRegU:     %0d", reg_uninit);
            $display("==========================================");
        end
    endrule

endmodule

endpackage
