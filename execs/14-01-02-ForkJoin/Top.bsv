// PAClib 并行结构：fork 复制 → 两路各算 → join 合并   out = (x+1)+(x*2) = 3x+1
package Top;
import PAClib::*; import FIFOF::*;
function Tuple2#(Int#(32),Int#(32)) dup(Int#(32) x) = tuple2(x, x);
function Int#(32) f_inc(Int#(32) x) = x + 1;
function Int#(32) f_dbl(Int#(32) x) = x * 2;
function Int#(32) f_add(Int#(32) a, Int#(32) b) = a + b;

(* synthesize *)
module mkTop(Empty);
   FIFOF#(Int#(32)) inq <- mkFIFOF;
   PipeOut#(Int#(32)) src = f_FIFOF_to_PipeOut(inq);
   Tuple2#(PipeOut#(Int#(32)), PipeOut#(Int#(32))) fk <- mkFork(dup, src);  // 复制成两路
   PipeOut#(Int#(32)) pa <- mkFn_to_Pipe(f_inc, tpl_1(fk));   // 上路 +1
   PipeOut#(Int#(32)) pb <- mkFn_to_Pipe(f_dbl, tpl_2(fk));   // 下路 *2
   PipeOut#(Int#(32)) pj <- mkJoin(f_add, pa, pb);            // 同步合并相加

   Reg#(Int#(32)) feed <- mkReg(0); Reg#(Int#(32)) got <- mkReg(0);
   rule produce (feed < 4); inq.enq(feed); feed <= feed + 1; endrule
   rule consume; let v = pj.first; pj.deq; $display("x=%0d -> 3x+1=%0d", got, v); got <= got+1; if (got==3) $finish(0); endrule
endmodule
endpackage
