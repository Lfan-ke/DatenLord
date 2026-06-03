package TlmMem;

// TLM(事务级建模)最小范例：CPU(Client) <-> 内存(Server)
//   - 一笔"事务"是整个结构体，经方法调用传递（而非逐 pin 接线）
//   - mkConnection 一行把 Client.request<->Server.request、Server.response<->Client.response 接通
//   - 这是 BSV 里 TLM 的基石（GetPut/ClientServer/Connectable，base 库自带）；
//     完整 AMBA 总线级 TLM 在 bsc-contrib（见 16-01）

import GetPut::*; import ClientServer::*; import Connectable::*;
import FIFO::*; import Vector::*; import StmtFSM::*;

typedef struct { Bool write; Bit#(4) addr; Bit#(8) data; } MemReq  deriving (Bits, Eq);
typedef struct { Bit#(8) data; }                          MemResp deriving (Bits, Eq);

// 内存从设备：Server#(请求类型, 响应类型)
module mkMem(Server#(MemReq, MemResp));
   Vector#(16, Reg#(Bit#(8))) mem <- replicateM(mkReg(0));
   FIFO#(MemResp) respQ <- mkFIFO;
   interface Put request;
      method Action put(MemReq r);
         if (r.write) begin mem[r.addr] <= r.data; respQ.enq(MemResp{data:r.data}); end
         else                                       respQ.enq(MemResp{data:mem[r.addr]});
      endmethod
   endinterface
   interface Get response = toGet(respQ);
endmodule

// CPU 主设备：Client#(请求类型, 响应类型)
module mkCpu(Client#(MemReq, MemResp));
   FIFO#(MemReq) reqQ <- mkFIFO;
   Reg#(Bit#(8))  got <- mkReg(0);
   function Action issue(Bool w, Bit#(4) a, Bit#(8) d) = action
      reqQ.enq(MemReq{write:w, addr:a, data:d});
      $display("[CPU] --> %s addr=%0d data=%0h", w?"WR":"RD", a, d);
   endaction;
   FSM fsm <- mkFSM(seq
      issue(True,  3, 8'hAA); issue(True,  5, 8'hBB);   // 两次写
      issue(False, 3, 0);     issue(False, 5, 0);       // 两次读（应读回 AA/BB）
   endseq);
   Reg#(Bool) started <- mkReg(False);
   rule go (!started); started <= True; fsm.start; endrule
   // 注意：用 mkFSM 而非 mkAutoFSM —— mkAutoFSM 序列结束即 $finish，会截断在途响应
   rule done (got == 4); $finish(0); endrule
   interface request = toGet(reqQ);
   interface Put response;
      method Action put(MemResp r);
         got <= got + 1;
         $display("[CPU] <-- resp data=%0h", r.data);
      endmethod
   endinterface
endmodule

(* synthesize *)
module mkTop(Empty);
   Client#(MemReq, MemResp) cpu <- mkCpu;
   Server#(MemReq, MemResp) mem <- mkMem;
   mkConnection(cpu, mem);
endmodule

endpackage
