# 15-04-01 BH 导入 Verilog（module verilog = BH 的 BVI，真跑通）
真实 Verilog `count4.v` 经 BH `module verilog` 导入；`mkTop` 驱动它(preset 10、两次 up)，iverilog 仿真。
要点：Action 方法用 **PrimAction**，规则里用 `fromPrimAction` 升为 Action；调度用 `<>`/`<`/`<<`。
`make run` → `count=12`（逻辑全在真实 count4.v 里）。
