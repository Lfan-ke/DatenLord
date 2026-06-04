// BSV 文件负责 import "BDPI"（BH 不支持该串语法），导出 c_add 给 BH 用
package CImp;
import "BDPI" function Bit#(32) c_add(Bit#(32) a, Bit#(32) b);
endpackage
