// 已有的 RTL IP：乘加器 out <= out + a*b（EN 时），clear 时 out <= clear_value
module mymac(clk, rst_b, EN, a, b, clear, clear_value, out);
   input         clk, rst_b, EN, clear;
   input  [15:0] a, b, clear_value;
   output [15:0] out;
   reg    [15:0] out;
   always @(posedge clk or negedge rst_b)
     if (!rst_b)      out <= 16'd0;
     else if (clear)  out <= clear_value;
     else if (EN)     out <= out + a * b;
endmodule
