// SystemC 测试台：驱动 bsc -systemc 导出的 mkAdder，验证 0x12 + 0x34 = 0x46
#include "systemc.h"
#include "mkAdder_systemc.h"
#include <iostream>

int sc_main(int, char**) {
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst_n, en_set, rdy_set, rdy_get_sum, ready, rdy_ready;
    sc_signal<sc_bv<8>> set_a, set_b, get_sum;

    mkAdder uut("uut");
    uut.CLK(clk); uut.RST_N(rst_n);
    uut.EN_set(en_set); uut.set_a(set_a); uut.set_b(set_b); uut.RDY_set(rdy_set);
    uut.get_sum(get_sum); uut.RDY_get_sum(rdy_get_sum);
    uut.ready(ready); uut.RDY_ready(rdy_ready);

    rst_n = false; sc_start(20, SC_NS); rst_n = true;
    en_set = true; set_a = 0x12; set_b = 0x34; sc_start(10, SC_NS); en_set = false;

    int guard = 0;
    while (!ready.read() && guard++ < 100) sc_start(10, SC_NS);
    std::cout << "sum = 0x" << std::hex << get_sum.read() << " (expect 0x46)" << std::endl;
    return 0;
}
