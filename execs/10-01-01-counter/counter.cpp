#include <systemc.h>

class Counter : public sc_module {
public:
    sc_in<bool> clk;
    sc_in<bool> rst;
    sc_out<sc_uint<8>> count;

    sc_uint<8> max_value = 255;

    Counter(const sc_module_name& name, sc_uint<8> max_val = 255)
        : sc_module(name), max_value(max_val), debug_enabled(false)
    {
        SC_HAS_PROCESS(Counter);  // 必需的宏

        SC_CTHREAD(process, clk.pos());
        async_reset_signal_is(rst, true);

        SC_METHOD(check_overflow);
        sensitive << count;

        #ifdef ENABLE_DEBUG
        SC_METHOD(debug_print);
        sensitive << count;
        #endif

        std::cout << sc_time_stamp() << " [INFO] Counter '" << name << "' constructed" << std::endl;
    }

    void enable_debug(bool enable) { debug_enabled = enable; }
    sc_uint<8> peek() const { return count.read(); }

    void trace(sc_trace_file* tf) const {
        if (!tf) return;
        sc_trace(tf, clk, "clk");
        sc_trace(tf, rst, "rst");
        sc_trace(tf, count, "count");
        sc_trace(tf, internal_state, "internal_state");
        sc_trace(tf, overflow_flag, "overflow_flag");
        sc_trace(tf, max_value, "max_value");
    }

private:
    sc_signal<sc_uint<4>> internal_state;
    sc_signal<bool> overflow_flag;
    bool debug_enabled;

    void process() {
        sc_uint<8> c = 0;
        internal_state.write(0);
        overflow_flag.write(false);
        wait();
        while (true) {
            wait();
            if (rst.read()) {
                c = 0;
                internal_state.write(0);
                overflow_flag.write(false);
                if (debug_enabled) std::cout << sc_time_stamp() << " [DEBUG] Counter reset" << std::endl;
            } else {
                if (c >= max_value) {
                    c = 0;
                    overflow_flag.write(true);
                    if (debug_enabled) std::cout << sc_time_stamp() << " [DEBUG] Counter overflow!" << std::endl;
                } else {
                    c = c + 1;
                    overflow_flag.write(false);
                }
                internal_state.write(c.range(3, 0));
            }
            count.write(c);
        }
    }

    void check_overflow() {
        if (count.read() == max_value) {}
    }

    void debug_print() {
        if (debug_enabled) {
            std::cout << sc_time_stamp() << " [DEBUG] count=" << count.read()
                      << " internal_state=" << internal_state.read()
                      << " overflow=" << overflow_flag.read() << std::endl;
        }
    }
};

class Tester : public sc_module {
public:
    sc_out<bool> rst;
    sc_in<sc_uint<8>> count;

    Tester(const sc_module_name& name) : sc_module(name) {
        SC_HAS_PROCESS(Tester);  // 必需的宏
        SC_THREAD(run_tests);
    }

    void trace(sc_trace_file* tf) const {
        if (!tf) return;
        sc_trace(tf, rst, "tester_rst");
        sc_trace(tf, count, "tester_count");
    }

private:
    void run_tests() {
        rst.write(true);
        wait(15, SC_NS);
        rst.write(false);
        std::cout << sc_time_stamp() << " [TEST] Reset released" << std::endl;

        while (count.read() < 10) wait(10, SC_NS);
        std::cout << sc_time_stamp() << " [TEST] Count reached 10" << std::endl;

        while (count.read() < 50) wait(10, SC_NS);
        std::cout << sc_time_stamp() << " [TEST] Count reached 50" << std::endl;

        sc_uint<8> prev = count.read();
        while (count.read() >= prev) {
            prev = count.read();
            wait(10, SC_NS);
        }
        std::cout << sc_time_stamp() << " [TEST] Overflow detected!" << std::endl;

        wait(50, SC_NS);
        std::cout << sc_time_stamp() << " [TEST] Simulation complete" << std::endl;
        sc_stop();
    }
};

int sc_main(int, char*[]) {
    std::cout << "========================================" << std::endl;
    std::cout << "SystemC Counter Demo" << std::endl;
    std::cout << "========================================" << std::endl;

    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst;
    sc_signal<sc_uint<8>> cnt;

    Counter dut("counter", 255);
    Tester tester("tester");

    dut.clk(clk);
    dut.rst(rst);
    dut.count(cnt);
    tester.rst(rst);
    tester.count(cnt);

    dut.enable_debug(false);

    sc_trace_file* tf = sc_create_vcd_trace_file("waveform");
    tf->set_time_unit(1, SC_NS);
    sc_trace(tf, clk, "top_clk");
    dut.trace(tf);
    tester.trace(tf);

    std::cout << sc_time_stamp() << " [MAIN] Simulation started" << std::endl;
    sc_start(3000, SC_NS);

    sc_close_vcd_trace_file(tf);
    sc_stop();

    std::cout << "========================================" << std::endl;
    std::cout << "Waveform saved to waveform.vcd" << std::endl;
    std::cout << "View with: make show" << std::endl;
    std::cout << "========================================" << std::endl;
    return 0;
}
