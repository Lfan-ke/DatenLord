<div align="center">

# MIT 6.004 / 6.1910 — Computation Structures and BSV

[![branch](https://img.shields.io/badge/branch-6.1910-blue)](https://github.com/Lfan-ke/DatenLord/tree/6.1910)
[![course](https://img.shields.io/badge/MIT-6.004%2F6.1910-red)](https://student.mit.edu/catalog/m6c.html)
[![lang](https://img.shields.io/badge/lang-BSV-purple)](https://bluespec.com/)
[![bsc](https://img.shields.io/badge/compiler-bsc-orange)](https://github.com/B-Lang-org/bsc)
[![id](https://img.shields.io/badge/ID-D202605002-lightgrey)](https://github.com/datenlord/training/issues/74)

Self-paced Bluespec SystemVerilog onboarding for the DatenLord MIT architecture program.

</div>

## Layout

| Path | Source |
| :---: | :---: |
| `tutorial/` | Snapshot of [`rsnikhil/Bluespec_BSV_Tutorial`](https://github.com/rsnikhil/Bluespec_BSV_Tutorial). |
| `tutorial/Reference/Lec01..Lec13_*.pdf` | 13-lecture theory backbone by R. S. Nikhil (BSV co-designer). |
| `tutorial/Example_Programs/Eg02..Eg09` | Per-topic labs with PDF spec + reference variants. |
| `notes/` | Personal study notes. |

## Toolchain

```bash
sudo apt install -y build-essential ghc autoconf gperf flex bison \
                    tcl-dev tk-dev libx11-dev libxft-dev libfontconfig1-dev \
                    cabal-install
cabal update
cabal install split strict-concurrency regex-compat syb old-time --lib
git clone --recursive --depth 1 https://github.com/B-Lang-org/bsc
cd bsc && make install-src    # ls inst/bin/  &&  inst/bin/bsc -v
# Bluespec Compiler, version 2026.01-54-ge8b70f8c (build e8b70f8c)
```

## Build & run a lab

```bash
# method 1: add the ba path
cd tutorial/Build
bsc -sim -g mkTestbench ../Example_Programs/Eg02a_HelloWorld/src_BSV/Testbench.bsv
bsc -sim -e mkTestbench -o ./hello_sim -bdir ../Example_Programs/Eg02a_HelloWorld/src_BSV
./hello_sim

# method 2: using build dir only
cd Build
bsc -sim -bdir . -g mkTestbench ../Example_Programs/Eg02a_HelloWorld/src_BSV/Testbench.bsv
bsc -sim -bdir . -e mkTestbench -o ./hello_sim
./hello_sim

# method 3: make only
cd Build
# make EG=Eg02a_HelloWorld full_clean
# make EG=Eg02a_HelloWorld compile
# make EG=Eg02a_HelloWorld link
# make EG=Eg02a_HelloWorld simulate
# same as:
make EG=Eg02a_HelloWorld all_bsim
```

Start with `tutorial/START_HERE.pdf`, then walk `Reference/Lec01..Lec13` and `Example_Programs/Eg02..Eg09` in order.

## Resources

- <https://github.com/rsnikhil/Bluespec_BSV_Tutorial>
- <https://bluespec.com/>
- <https://www.cl.cam.ac.uk/teaching/2526/ECAD+Arch/bluespec.html>
