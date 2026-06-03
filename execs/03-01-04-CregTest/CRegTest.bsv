package CRegTest;

// 目的：实证 mkCReg 的多端口语义
//   问题：同一周期多个端口写入时，是「低端口覆盖高端口」还是「高端口覆盖低端口」？前递方向如何？
//
// 教训 1（第一版踩坑）：在【同一个 rule】里同时用 CReg 的两个端口 -> 编译器报 G0004
//   「conflict in parallel」。CReg 的「排序 + 前递」语义是【跨 rule】才成立的：
//   把 port0 / port1 / port2 各放进【不同 rule】，它们能在【同一周期】按端口号顺序依次触发。
//
// 教训 2（第二版踩坑）：bluesim 代码生成时，$display 字符串里的【中文(非ASCII)】会触发
//   内部错误 "quoting a character value"。所以打印内容一律用 ASCII，中文只留在注释里。

(* synthesize *)
module mkCRegTest(Empty);

    // 3 端口 CReg，初值 = 0xAA = 170；port0 逻辑最早，port2 逻辑最晚
    Reg#(Bit#(8))  r[3] <- mkCReg(3, 8'hAA);
    Reg#(Bit#(16)) cyc  <- mkReg(0);

    rule tick;
        cyc <= cyc + 1;
        if (cyc > 7) $finish(0);
    endrule

    // ---------- 实验 A（cyc==1 三端口同拍写不同值；cyc==2 看提交值）----------
    rule a_p0 (cyc == 1);                       // 只用 port0
        r[0] <= 10;
        $display("[cyc1] @port0: write r[0]<=10");
    endrule
    rule a_p1 (cyc == 1);                       // 只用 port1：先读后写
        $display("[cyc1] @port1: read r[1]=%0d (sees port0 write? expect 10); write r[1]<=20", r[1]);
        r[1] <= 20;
    endrule
    rule a_p2 (cyc == 1);                       // 只用 port2：先读后写
        $display("[cyc1] @port2: read r[2]=%0d (sees port0,1 writes? expect highest=20); write r[2]<=30", r[2]);
        r[2] <= 30;
    endrule
    rule a_commit (cyc == 2);
        $display("[cyc2] committed r[0]=%0d (all 3 written; winner? expect highest port2 = 30)", r[0]);
    endrule

    // ---------- 实验 B（cyc==3 只写 port0、port1，不写 port2；cyc==4 看提交值）----------
    rule b_p0 (cyc == 3);
        r[0] <= 100;
        $display("[cyc3] @port0: write r[0]<=100");
    endrule
    rule b_p1 (cyc == 3);
        r[1] <= 101;
        $display("[cyc3] @port1: write r[1]<=101 (port2 not written this cycle)");
    endrule
    rule b_commit (cyc == 4);
        $display("[cyc4] committed r[0]=%0d (expect highest WRITTEN port1 = 101, NOT low-port-wins)", r[0]);
    endrule

    // ---------- 实验 C（cyc==5 只写最低端口 port0；cyc==6 看提交值）----------
    rule c_p0 (cyc == 5);
        r[0] <= 200;
        $display("[cyc5] @port0: write r[0]<=200");
    endrule
    rule c_commit (cyc == 6);
        $display("[cyc6] committed r[0]=%0d (expect 200)", r[0]);
        $display("CONCLUSION: low-port write only FORWARDS to higher-port reads; committed = value of the HIGHEST-numbered port written this cycle");
    endrule

endmodule

endpackage
