# MIT 6.375 / 6.5900 — Computer System Architecture

[![branch](https://img.shields.io/badge/branch-6.5900-purple)](https://github.com/Lfan-ke/DatenLord/tree/6.5900)
[![course](https://img.shields.io/badge/MIT-6.375-red)](https://csg.csail.mit.edu/6.375/6_375_2019_www/handouts/labs/)
[![year](https://img.shields.io/badge/lab%20version-2019-yellow)](https://csg.csail.mit.edu/6.375/6_375_2019_www/handouts/labs/)
[![id](https://img.shields.io/badge/ID-D202605002-lightgrey)](https://github.com/datenlord/training/issues/74)

Audio DSP, FFT, FPGA-deployable hardware in BSV, plus a deeply-pipelined RISC-V with caches. **2019** edition. Official labs: <https://csg.csail.mit.edu/6.375/6_375_2019_www/handouts/labs/>.

## Layout

| Path | Contents |
|---|---|
| `labs/lab1` | Design-only paper lab — sequential modules, scheduling intuition (PDF only) |
| `labs/lab2` | Audio chain harness — Chunker / FFT / IFFT framework |
| `labs/lab3` | Pitch adjustment on the audio chain |
| `labs/lab4` | Connectal — FPGA host / device co-design |
| `labs/lab5` | RISC-V with multi-level caches, branch prediction, FPGA-deployable |
| `notes/`    | Personal study notes |

## Build

```bash
cd labs/lab2/audio/fft   # or whichever harness sub-target
make
```
