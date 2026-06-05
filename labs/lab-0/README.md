# Lab 0 — Getting Started

The setup lab for MIT **6.175 / 6.1920 — Constructive Computer Architecture**.
There is no graded BSV to write here; it gets the toolchain and flow working.

## Toolchain

- **bsc** (Bluespec compiler) — build from <https://github.com/B-Lang-org/bsc> or use a prebuilt release.
- A C/C++ toolchain (for Bluesim linking) and `make`.
- For the RISC-V labs (5–8): a `riscv` GCC cross-toolchain to assemble the test programs.

## Per-lab flow

Each lab is a self-contained directory (`lab-1` … `lab-8`, `Proj`). Typical loop:

```bash
cd labs/lab-N
make            # compile with bsc (Bluesim)
./simulator     # or: make <target> — run the provided test bench
```

The RISC-V labs select a processor variant with a build define, e.g. the
exceptions lab (lab-8): `make build.bluesim VPROC=EXCEP`.

## Reference

Official course & handouts: <https://csg.csail.mit.edu/6.175/> ·
labs list: <https://csg.csail.mit.edu/6.175/labs.html>

> Labs: 0 Getting Started · 1 Mux/Adder/Shifter · 2 FFT · 3 Multipliers ·
> 4 FIFO & EHR · 5 RISC-V intro · 6 RISC-V pipelined · 7 RISC-V caches ·
> 8 RISC-V exceptions · Project Part 1–2.
