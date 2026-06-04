# 18-01-01 迷你流水线（进阶惯用法合集）
参考 Piccolo/Flute 风格，演示：tagged union 载荷 + case matches、级间 FIFO 选型
(mkBypassFIFOF 0拍 / mkPipelineFIFOF 1拍)、CReg 并发计数器(Cntrs/EHR)、ConfigReg 作 CSR/epoch。
`make run` → result=2/4/6/8、done=4 ; `make verilog` 综合 ; `make clean`。
