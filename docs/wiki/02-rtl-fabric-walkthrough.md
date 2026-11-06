# 02 — RTL fabric walkthrough (ingress, skid buffers, CSR)

The fabric is four hand-written SystemVerilog blocks plus one generated
constants package. All files elaboate under pyslang (`python3
tools/check_rtl.py`, 12 files / 6 tops) and carry run-level evidence in
`results/run_ledger.csv`.

## `rtl/mgr1_defs.svh` — the shared vocabulary

Packet sizes and beat counts from the ABI (docs/04): header 32 B, frame
payload 150,528 B = 9,408 beats, embedding 1,280 B = 82 beats, completion
16 B = 3 beats. Status codes live in `mgr1_csr` (ST_IDLE 0 … ST_FAULT 4,
commands 1..7).

## `rtl/axi/axis_packet_ingress.sv` — the front door

- Checks magic `32'h3152_474D` (little-endian byte order, byte 0 first),
  `abi_major == 1`, kind in `{1,2,3}`, flags == 0 on header beat 1.
- Counts the whole packet: header beats + `ceil(payload_len / 16)`.
- Faults: cause 1 bad magic, 2 early/short TLAST, 3 over-length, 4 illegal
  header field, 5 illegal TKEEP. The offending beat is dropped; a fault is
  **sticky** — `s_ready` stays low until reset.
- Passes every healthy beat through combinationally: `m_valid = s_valid &&
  !fault_sticky && !frame_bad`.

## `rtl/axi/axis_skid_buffer.sv` — three elastic modes

Modes 0/1/2 = bypass / one output register / full skid.  The invariant set
checked by `rtl/tb/tb_axis_skid_buffer.sv`:

- never more than 2 beats held in mode 2 (head + tail slots);
- no acceptance edge while two beats are still undelivered;
- `(data, keep, last)` stable while the downstream stalls — beats are
  replayed from the registered slots, not from live inputs.

Beat metadata (keep/last) is stored in the same slot registers as the data,
so a stalled downstream sees a byte-stable beat no matter what the upstream
does with `s_valid` after each accept.

## `rtl/shell/csr_block.sv` — the control plane

Rules implemented (from `ip/schema/csr_map.json`):

1. WSTRB honored — only strobed bytes commit (`apply_strb`).
2. Writes to read-only registers are ignored (`default: ;` in the case).
3. Decoupled AW/W capture — either channel may arrive first; BVALID/RVALID
   are HELD until their handshake (`b_valid <= 1'b1` until `b_ready`).
4. A sticky-error clear in the same cycle as a new fault keeps the new
   event: `if (!(error_valid_i && error_cause_i != '0)) error_q <= '0;`
   runs in one always_ff, so the fault-capture path wins the race.
   Implementation detail: the sticky-capture flag `clear_cmd_fire` is
   combinational, not a reg, so the same-edge clear + new-fault case
   preserves the NEW cause (fixed after the first draft registered it a
   cycle late).

## Write discipline

Generated artifacts (`csr_offsets.svh`, `activation_lut_contents.h`, the
cascade table) are regenerated, never hand-edited; the generator script is
the review object. Any oracle change first lands in
`model/integer_oracle/oracle.py`, then vectors + docs regenerate; pytest
must stay green before commit.
