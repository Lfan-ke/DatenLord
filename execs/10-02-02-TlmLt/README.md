# 10-02-02 SystemC TLM-2.0 LT
CPU(initiator_socket) 经 b_transport + tlm_generic_payload 读写 Memory(target_socket)，一行 bind 互连。
`make run` → read @4=0xaa, read @8=0xbb（事务级，非 pin 级）。
