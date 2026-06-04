module count4(CLK, RST_N, enable, inp, set, outp);
   input CLK, RST_N, enable, set; input [3:0] inp; output [3:0] outp;
   reg [3:0] outp;
   always @(posedge CLK or negedge RST_N)
     if (!RST_N) outp <= 0; else if (set) outp <= inp; else if (enable) outp <= outp + 1;
endmodule
