// Verilog 套壳：真实例化 VHDL 实体 vadd（逻辑全在 vadd.vhd）
// vadd 模块由 ghdl --synth 从 vadd.vhd 降级而来，故逻辑真正源自 VHDL，非手写等价
module vadd_wrapper(clk, rst_n, en, a, b, q);
   input        clk, rst_n, en;
   input  [7:0] a, b;
   output [7:0] q;
   vadd u_vadd(.clk(clk), .rst_n(rst_n), .en(en), .a(a), .b(b), .q(q));
endmodule
