#!/usr/bin/env bash
# RTL testbench runner - Vivado XSim only (per project discipline).
#
# Runs the four XSim testbenches in rtl/tb/ against the fixed RTL, in batch:
#   tb_axis_skid_buffer      - elastic buffer modes 0/1/2 (Section 7)
#   tb_axis_packet_ingress   - packet ABI v1 framing + fault classes
#   tb_csr_block             - CSR map, WSTRB, sticky-error rules
#   tb_gru_sequencer         - frozen cycle budget 412 / 13,184 / 17,028
#
# Requires: Vivado 2025.2 (xvlog / xelab / xsim).  Either set VIVADO_HOME or
# have the binaries on PATH, e.g.:
#   source /tools/Xilinx/Vivado/2025.2/settings64.sh
#   ./vivado/run_xsim.sh
#
# Each TB prints "TB PASS" on success.  The script fails if any TB misses its
# PASS line or reports FAILs, and appends one ledger row per TB (evidence
# level "RTL simulation") to results/run_ledger.csv.

set -u

VIVADO_HOME="${VIVADO_HOME:-/tools/Xilinx/Vivado/2025.2}"
if [ -x "$VIVADO_HOME/bin/xvlog" ]; then
  export PATH="$VIVADO_HOME/bin:$PATH"
fi
command -v xvlog >/dev/null 2>&1 || {
  echo "ERROR: xvlog not found - this run needs Vivado on PATH (VIVADO_HOME=$VIVADO_HOME)" >&2
  exit 2
}

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/vivado/xsim_out"
RES="$ROOT/results/tb_xsim"
mkdir -p "$OUT" "$RES"
cd "$OUT"

XVLOG_VERSION="$(xvlog -version 2>&1 | head -1)"

COMPILE_SRCS=(
  "$ROOT/rtl/mgr1_defs.svh"
  "$ROOT/rtl/shell/csr_offsets.svh"
  "$ROOT/rtl/axi/axis_skid_buffer.sv"
  "$ROOT/rtl/axi/axis_packet_ingress.sv"
  "$ROOT/rtl/shell/csr_block.sv"
  "$ROOT/rtl/gru/gru_sequencer.sv"
)

TBS=(
  tb_axis_skid_buffer
  tb_axis_packet_ingress
  tb_csr_block
  tb_gru_sequencer
)

overall=0
xvlog -sv -i "$ROOT/rtl" "${COMPILE_SRCS[@]}" > xvlog_all.log 2>&1 || {
  echo "ERROR: xvlog failed - see $OUT/xvlog_all.log"
  tail -20 xvlog_all.log
  exit 1
}

for tb in "${TBS[@]}"; do
  echo "=== $tb ==="
  xelab -debug typical -d MGR1_SVA "work.$tb" -s "snap_$tb" \
    > "xelab_$tb.log" 2>&1
  if [ $? -ne 0 ]; then
    echo "xelab FAILED: see $OUT/xelab_$tb.log"
    tail -15 "xelab_$tb.log"
    overall=1
    continue
  fi
  xsim "snap_$tb" -R > "xsim_$tb.log" 2>&1
  grep -q "TB PASS" "xsim_$tb.log" && pass=ok || pass=missing
  if [ "$pass" != "ok" ]; then
    echo "xsim FAILED (no TB PASS): see $OUT/xsim_$tb.log"
    tail -15 "xsim_$tb.log"
    overall=1
  else
    echo "PASS ($tb)"
  fi
done

# ---- ledger ----------------------------------------------------------------
if [ "$overall" -eq 0 ]; then
  for tb in "${TBS[@]}"; do
    printf 'RTB-%s,%s,%s,xsim,%s,"%s XSim testbench",RTL simulation,%s\n' \
      "$tb" "$(date +%F)" "$(hostname)" "$XVLOG_VERSION" "$tb" "$RES" \
      >> "$ROOT/results/run_ledger.csv"
  done
  echo "ALL TB PASS - ledger rows appended."
else
  echo "FAILURES - check $OUT/*.log"
fi
exit $overall
