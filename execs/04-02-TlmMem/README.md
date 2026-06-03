# 04-02 TlmMem — TLM(事务级建模)最小范例

> CPU(`Client`) ↔ 内存(`Server`)，整笔事务经方法层传递，一行 `mkConnection` 接通。
> 这是 BSV 里 TLM 的基石（`GetPut`/`ClientServer`/`Connectable`，base 库自带）；
> 完整 AMBA 总线级 TLM 在 bsc-contrib（见 16-01）。

## 跑法

```bash
make run     # bluesim 编译+运行
make clean
```

## 实测输出

```
[CPU] --> WR addr=3 data=aa
[CPU] --> WR addr=5 data=bb
[CPU] <-- resp data=aa        # 写回执
[CPU] --> RD addr=3 data=0
[CPU] <-- resp data=bb
[CPU] --> RD addr=5 data=0
[CPU] <-- resp data=aa        # 读回 0xAA ✓
[CPU] <-- resp data=bb        # 读回 0xBB ✓
```

## 关键点

- **事务是整个结构体**：`MemReq{write,addr,data}` / `MemResp{data}` 经 `put/get` 传递，不在 pin 级接线。
- **Client/Server 配对**：`Client#(req,resp)` 的 `request` 是 `Get`、`response` 是 `Put`；`Server` 反之。
- **`mkConnection(cpu, mem)`** 自动把 `client.request<->server.request`、`server.response<->client.response` 接起来。
- **用 `mkFSM` 而非 `mkAutoFSM`**：`mkAutoFSM` 在 `seq` 结束时会调 `$finish`，会**截断仍在路上的响应**；这里用 `mkFSM`+手动 `start`，由 `rule done (got==4)` 收尾。
