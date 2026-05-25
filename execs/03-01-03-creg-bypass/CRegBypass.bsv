package CRegBypass;

interface TestIFC;
    method Action write(Bit#(8) x);
    method Bit#(8) readOld;
    method Bit#(8) readNew;
endinterface

(* synthesize *)
module mkCRegBypass(TestIFC);

    // 2端口 CReg：r[0] 较早时间，r[1] 较晚时间
    Reg#(Bit#(8)) r[2] <- mkCReg(2, 0);

    // 写操作：使用 r[1]（较晚时间）
    method Action write(Bit#(8) x);
        r[1] <= x;
    endmethod

    // 读旧值：使用 r[0]（较早时间）
    // 同一周期内：write 的值对 readOld 不可见
    method Bit#(8) readOld;
        return r[0];
    endmethod

    // 读新值：使用 r[1]（较晚时间）
    // 同一周期内：write 的值对 readNew 可见
    method Bit#(8) readNew;
        return r[1];
    endmethod

endmodule

endpackage
