# Lab 01 · Combinational Logic — scratch notes

Setup pass to verify the rendering pipeline.

## Building blocks

- One-bit full adder from XOR + AND + OR.
- Ripple-carry adder: chain N full adders, carry-out of bit *i*
  feeds carry-in of bit *i+1*.
- Critical path scales **O(N)** with width — fine for 4-bit toys,
  unworkable for 64-bit.

## Carry-lookahead intuition

Generate / propagate signals:

- `G[i] = A[i] & B[i]` — bit *i* unconditionally produces a carry.
- `P[i] = A[i] ^ B[i]` — bit *i* forwards an incoming carry.
- `C[i+1] = G[i] | (P[i] & C[i])` — recursive.

Unrolling that recursion gives `O(log N)` depth with `O(N)` width —
the classic area-vs-delay tradeoff.

## Open questions

1. Where exactly does Bluespec emit the `G` / `P` trees? Need to read
   the generated Verilog after `bsc -verilog`.
2. Is there a clean way to expose carry-out as a `Maybe Bit#(1)` so
   downstream stages can `tagged Invalid` it on overflow?

## Next

Wire up the testbench, dump waveforms, compare against the reference
RippleCarry from the lab repo.
