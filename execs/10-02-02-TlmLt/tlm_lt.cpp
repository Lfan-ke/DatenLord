// SystemC TLM-2.0 LT：CPU(initiator) 经 b_transport 读写 Memory(target)
#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include <iostream>
using namespace sc_core; using namespace std;

struct Memory : sc_module {
  tlm_utils::simple_target_socket<Memory> sock;
  unsigned int mem[16];
  SC_CTOR(Memory) : sock("sock") { sock.register_b_transport(this,&Memory::b_transport);
    for(int i=0;i<16;i++) mem[i]=0; }
  void b_transport(tlm::tlm_generic_payload& tr, sc_time& delay) {
    auto a=tr.get_address(); auto* d=reinterpret_cast<unsigned int*>(tr.get_data_ptr());
    if (tr.get_command()==tlm::TLM_WRITE_COMMAND) mem[a/4]=*d; else *d=mem[a/4];
    tr.set_response_status(tlm::TLM_OK_RESPONSE); delay += sc_time(10,SC_NS);
  }
};
struct Cpu : sc_module {
  tlm_utils::simple_initiator_socket<Cpu> sock;
  SC_CTOR(Cpu) : sock("sock") { SC_THREAD(run); }
  void access(tlm::tlm_command c, sc_dt::uint64 a, unsigned int& v) {
    tlm::tlm_generic_payload tr; sc_time d=SC_ZERO_TIME;
    tr.set_command(c); tr.set_address(a);
    tr.set_data_ptr(reinterpret_cast<unsigned char*>(&v)); tr.set_data_length(4);
    tr.set_streaming_width(4); tr.set_byte_enable_ptr(nullptr);
    tr.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
    sock->b_transport(tr,d); wait(d);
  }
  void run() {
    unsigned int v=0xAA; access(tlm::TLM_WRITE_COMMAND,0x4,v);
    v=0xBB; access(tlm::TLM_WRITE_COMMAND,0x8,v);
    access(tlm::TLM_READ_COMMAND,0x4,v); cout<<"read @4 = 0x"<<hex<<v<<"\n";
    access(tlm::TLM_READ_COMMAND,0x8,v); cout<<"read @8 = 0x"<<hex<<v<<"\n";
  }
};
int sc_main(int,char*[]){ Cpu cpu("cpu"); Memory m("mem"); cpu.sock.bind(m.sock); sc_start(); return 0; }
