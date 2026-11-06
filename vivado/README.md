# Vivado shell build — hardware-gated (roadmap Phase 1)

Run on the Vivado host only:

```bash
vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
```

`vivado/shell.tcl` (to be written on the Vivado host) must:

1. Create the project for xck26-sfvc784-2LV-c.
2. Add `rtl/` sources and `ip/schema/csr_map.json` as the CSR IP.
3. Instantiate the shell: AXI4-Lite CSR block, packet ingress, MGR1 IP.
4. Synthesize, implement, and record routed timing in `results/`.

Evidence: routed timing report + one `results/run_ledger.csv` row
(evidence level "routed timing") per Phase 8/9 of the runbook.
