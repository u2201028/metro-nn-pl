# 05 — PYNQ 3.1.0 runtime (dma, packet ABI, event watch)

## Software system map

- `runtime/pynq_bringup.ipynb` — staged bring-up: DMA loopback (beats
  9,410 / 82 / 3 on the ILA) BEFORE the live camera path; packet drivers
  next; event watch last.
- `runtime/packet_abi.py` — codec shared with the C++ tests; every packet
  begins with the 32-B header; the completion packet is 3 framed beats.
- `runtime/csr_defs.py` + `rtl/shell/csr_offsets.svh` — generated from
  `ip/schema/csr_map.json` by `tools/gen_csr.py`; never hand-edit them.
- `bench/event_metrics.py` — threshold semantics: precision/recall/F1 and
  event recall/false alerts per negative camera-hour come from THIS module,
  not re-implemented in the notebook.

## Event loop (v1)

```python
from pynq import allocate, Overlay
ol = Overlay("mgr1_shell.bit")
dma = ol.axi_dma_0  # names fixed by the Vivado address editor

with allocate(shape=(150528,), dtype=np.uint8) as tx, \\
     allocate(shape=(1280,),   dtype=np.int8)  as emb, \\
     allocate(shape=(16,),     dtype=np.uint32) as done:
    tx[:] = frame_bytes
    dma.sendchannel.transfer(tx)
    dma.recvchannel.transfer(emb)
    dma.sendchannel.wait(); dma.recvchannel.wait()
    status, logit = int(done[0]), int(done[1])  # per docs/04 completion fields
```

Edge cases: (a) a rejected frame (`STATUS_REJECTED`) must NOT break the
ring — drop, count, continue; (b) reset during the final hidden write —
`mgr1_accel_top` fails the completion terminally, never scores partials;
(c) `emb` stays Q1.15 int16-commit values packed as Q7.8 int8 — a scale
change is a regeneration, not a runtime knob (hard rule: oracle first).

## The ring + scheduling contract

A launch ring (32 slots) holds cached INT32 input projections; replay
consumes them verbatim.  Each wait owns a counter and changes measured
latency, so a stalled ring slot must be counted (docs/09 section 8) before
you trust a latency number.
