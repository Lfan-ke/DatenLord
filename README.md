# MIT 6.004 / 6.1910 — Computation Structures (BSV)

[![branch](https://img.shields.io/badge/branch-6.1910-blue)](https://github.com/Lfan-ke/DatenLord/tree/6.1910)
[![course](https://img.shields.io/badge/MIT-6.004%2F6.1910-red)](https://student.mit.edu/catalog/m6c.html)
[![lang](https://img.shields.io/badge/lang-BSV-purple)](https://bluespec.com/)
[![bsc](https://img.shields.io/badge/compiler-bsc-orange)](https://github.com/B-Lang-org/bsc)
[![id](https://img.shields.io/badge/ID-D202605002-lightgrey)](https://github.com/datenlord/training/issues/74)

Self-paced Bluespec SystemVerilog onboarding for the DatenLord MIT architecture program.

## Layout

| Path | Source |
|---|---|
| `tutorial/` | Snapshot of [`rsnikhil/Bluespec_BSV_Tutorial`](https://github.com/rsnikhil/Bluespec_BSV_Tutorial), `.git` stripped. Edited in place. |
| `tutorial/Reference/Lec01..Lec13_*.pdf` | 13-lecture theory backbone by R. S. Nikhil (BSV co-designer). |
| `tutorial/Example_Programs/Eg02..Eg09` | Per-topic labs with PDF spec + reference variants. |
| `notes/` | Personal study notes. |

## Toolchain

```bash
sudo apt install -y build-essential ghc libghc-regex-compat-dev libghc-syb-dev \
                    libghc-old-time-dev tcl-dev tk-dev autoconf gperf flex bison
git clone --recursive https://github.com/B-Lang-org/bsc
cd bsc && make install-src
```

Or grab a prebuilt release: <https://github.com/B-Lang-org/bsc/releases>

## Build & run a lab

```bash
cd tutorial/Example_Programs/Eg02a_HelloWorld
make
```

Start with `tutorial/START_HERE.pdf`, then walk `Reference/Lec01..Lec13` and `Example_Programs/Eg02..Eg09` in order.

## Resources

- <https://github.com/rsnikhil/Bluespec_BSV_Tutorial>
- <https://bluespec.com/>
- <https://www.cl.cam.ac.uk/teaching/2526/ECAD+Arch/bluespec.html>

## Progress

Tracked by `.github/workflows/log.yml` — every commit appends a row to the root [README log](https://github.com/Lfan-ke/DatenLord/blob/main/README.md) and posts a comment to [`datenlord/training#74`](https://github.com/datenlord/training/issues/74).

## Attribution

`tutorial/` is redistributed from [rsnikhil/Bluespec_BSV_Tutorial](https://github.com/rsnikhil/Bluespec_BSV_Tutorial) for personal study; upstream license applies (see `tutorial/README.md`).
