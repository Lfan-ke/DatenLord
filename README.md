# MIT 6.175 / 6.1920 — Constructive Computer Architecture (BSV)

[![branch](https://img.shields.io/badge/branch-6.1920-green)](https://github.com/Lfan-ke/DatenLord/tree/6.1920)
[![course](https://img.shields.io/badge/MIT-6.175-red)](https://csg.csail.mit.edu/6.175/)
[![year](https://img.shields.io/badge/lab%20version-2016%20Fall-yellow)](https://csg.csail.mit.edu/6.175/)
[![id](https://img.shields.io/badge/ID-D202605002-lightgrey)](https://github.com/datenlord/training/issues/74)

Pipelined RISC-V processor in BSV. **2016 Fall** edition. Official course: <https://csg.csail.mit.edu/6.175/>.

## Layout

| Path | Contents |
|---|---|
| `labs/lab-1` | Multiplexers · Adders · Barrel shifter |
| `labs/lab-2` | FFT · FIFO · EHR |
| `labs/lab-3` | Multipliers (combinational / sequential / Booth) |
| `labs/lab-4` | `MyFifo` — concurrent FIFO with EHR |
| `labs/lab-5` | Single-cycle RISC-V + RISC-V test programs |
| `labs/lab-6` | Pipelined RISC-V |
| `labs/lab-7` | RISC-V + caches |
| `labs/Proj`  | Project 1 + Project 2 (combined, `CORENUM` param) — pipelined RISC-V with caches & branch prediction (P1), multicore + cache coherence (P2) |
| `notes/`     | Personal study notes |

## Build

```bash
cd labs/lab-1 && make
```
