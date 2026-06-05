<div align="center">

# MIT 6.175 / 6.1920 — Constructive Computer Architecture

[![branch](https://img.shields.io/badge/branch-6.1920-green)](https://github.com/Lfan-ke/DatenLord/tree/6.1920)
[![course](https://img.shields.io/badge/MIT-6.175-red)](https://csg.csail.mit.edu/6.175/)
[![year](https://img.shields.io/badge/lab%20version-2016%20Fall-yellow)](https://csg.csail.mit.edu/6.175/)
[![id](https://img.shields.io/badge/ID-D202605002-lightgrey)](https://github.com/datenlord/training/issues/74)

Pipelined RISC-V processor in BSV. **2016 Fall** edition. Official course: <https://csg.csail.mit.edu/6.175/>.

</div>

## Layout

| Path | Contents |
| :---: | :---: |
| `labs/lab-0` | Getting Started — toolchain & flow setup (no graded BSV) |
| `labs/lab-1` | Multiplexers · Adders · Barrel shifter |
| `labs/lab-2` | FFT |
| `labs/lab-3` | Multipliers (combinational / sequential / Booth) |
| `labs/lab-4` | FIFO & EHR (`MyFifo`) |
| `labs/lab-5` | RISC-V — multi-cycle / two-stage pipeline |
| `labs/lab-6` | RISC-V — six-stage pipeline & branch prediction |
| `labs/lab-7` | RISC-V — caches |
| `labs/lab-8` | RISC-V — exceptions (`ExcepProc` + CSR traps) |
| `labs/Proj`  | Project Part 1–2 — pipeline, caches, branch prediction, multicore + coherence |
| `notes/`     | Personal study notes |

## Build

```bash
cd labs/lab-1 && make
```
