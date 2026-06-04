// SystemC 基础：SC_METHOD(组合) + SC_THREAD(时序) + sc_clock
#include <systemc>
#include <iostream>
using namespace sc_core;

SC_MODULE(Adder) {                 // 组合：always_comb
  sc_in<int> a, b; sc_out<int> sum;
  void do_add() { sum.write(a.read() + b.read()); }
  SC_CTOR(Adder) { SC_METHOD(do_add); sensitive << a << b; }
};

SC_MODULE(Counter) {               // 时序：posedge clk
  sc_in<bool> clk; sc_signal<int> cnt;
  void proc() { while (true) { wait(); cnt.write(cnt.read()+1);
                  std::cout << sc_time_stamp() << " cnt=" << cnt.read() << "\n"; } }
  SC_CTOR(Counter) : cnt(0) { SC_THREAD(proc); sensitive << clk.pos(); }
};

int sc_main(int, char*[]) {
  sc_clock clk("clk", 10, SC_NS);
  Counter c("c"); c.clk(clk);
  Adder ad("ad"); sc_signal<int> a,b,s; a=3; b=4; ad.a(a); ad.b(b); ad.sum(s);
  sc_start(35, SC_NS);
  std::cout << "3+4=" << s.read() << "\n";
  return 0;
}
