# 标准库用法 (五)：GetPut / ClientServer / Connectable

> 概念与进阶(仲裁/路由/流水/归结)详见 **04-01/04-02**；本篇只列包用法 + 最小可跑连接。可跑：`execs/13-06-01-GetPutConn`。

```bsv
import GetPut::*; import ClientServer::*; import Connectable::*;

interface Get#(type a);  method ActionValue#(a) get;  endinterface
interface Put#(type a);  method Action put(a x);      endinterface
interface Client#(type a,type b); interface Get#(a) request; interface Put#(b) response; endinterface
interface Server#(type a,type b); interface Put#(a) request; interface Get#(b) response; endinterface

// 转换：FIFO/FIFOF/Reg/RWire 都有 toGet/toPut 实例
Get#(t) g = toGet(fifof);   Put#(t) p = toPut(fifo);
Server#(req,rsp) s = toGPServer(reqFifo, respFifo);
Client#(req,rsp) c = toGPClient(reqFifo, respFifo);

// 连接(Connectable 类)：Get↔Put、Client↔Server、Tuple、Vector、ReadOnly↔WriteOnly… 都有实例
mkConnection(toGet(src), sink);   // 一行接通
mkConnection(client, server);
```

## 最小可跑（execs/13-06-01）

```
sink got 0
sink got 11
sink got 22
sink got 33
```
源(`toGet(FIFOF)`) 经 `mkConnection` 把每个值送到自定义 `Put` 汇。
