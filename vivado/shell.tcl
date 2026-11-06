# Vivado shell build (roadmap Phase 1, runbook docs/07-vivado-runbook.md).
#
# Hardware-gated: run on the Vivado host only.
#   vivado -mode batch -source vivado/shell.tcl -tclargs xck26-sfvc784-2LV-c
#
# The script:
#   1. Creates a project for the requested part (K26 / KV260).
#   2. Adds the rtl/ sources (DUTs and shell; testbenches are excluded -
#      they run under XSim, see vivado/run_xsim.sh).
#   3. Adds rtl/shell/mgr1_ip_stub.sv so u_mgr1_ip binds; at roadmap Phase 8A
#      substitute the Vitis HLS export (export_design -format ip_catalog)
#      and the runbook's add_ip flow.
#   4. Synthesizes, implements, routes, and records timing/utilization into
#      results/vivado/ with one evidence row in results/run_ledger.csv.
#
# Evidence: routed timing report on xck26-sfvc784-2LV-c (target 150 MHz =
# 6.67 ns clock from the frozen cycle model).

if { $argc < 1 } {
    puts "ERROR: usage: vivado -mode batch -source vivado/shell.tcl -tclargs <part>"
    exit 1
}
set part [lindex $argv 0]

set repo_root [file normalize [file join [file dirname [info script]] ..]]
set files_dir [file join $repo_root rtl]
set out_dir   [file join $repo_root vivado mgr1_shell_build]
file mkdir $out_dir
file mkdir [file join $repo_root results vivado]

# ---- project ---------------------------------------------------------------
create_project -force mgr1_shell $out_dir -part $part

# ---- constraints (must exist before add_files) -----------------------------
# Minimal bring-up constraints: 150 MHz core clock; I/O and CDC refinement
# belongs to the phase-9 bring-up XDC (runbook).
file mkdir [file join $repo_root vivado constraints]
set xdc [file join $repo_root vivado constraints mgr1_shell.xdc]
if { ![file exists $xdc] } {
    set fh [open $xdc w]
    puts $fh "# Bring-up constraints (roadmap Phase 1 skeleton)."
    puts $fh "# 150 MHz system clock = 1 / 6.67 ns, per the frozen cycle model."
    puts $fh "create_clock -name aclk -period 6.670 \[get_ports aclk\]"
    close $fh
}

# ---- sources ---------------------------------------------------------------
# Exclusions: testbenches live in rtl/tb and are XSim territory; every other
# .sv file (including the IP stub) is synthesizable.
add_files -norecurse [file join $files_dir mgr1_defs.svh]
add_files -norecurse [file join $files_dir shell csr_offsets.svh]
add_files -norecurse [file join $files_dir shell csr_block.sv]
add_files -norecurse [file join $files_dir shell mgr1_ip_stub.sv]
add_files -norecurse [file join $files_dir shell mgr1_shell.sv]
add_files -norecurse [file join $files_dir axi axis_skid_buffer.sv]
add_files -norecurse [file join $files_dir axi axis_packet_ingress.sv]
add_files -norecurse [file join $files_dir gru gru_sequencer.sv]
add_files -fileset constrs_1 -norecurse $xdc

# The CSR schema is part of the IP definition (Section 11 provenance).
add_files -norecurse [file join $repo_root ip schema csr_map.json]

set_property top mgr1_shell [current_fileset]
set_property include_dirs [list $files_dir] [current_fileset]
# The shell is an IP for the KV260 dynamic region at this phase: synthesis
# runs out-of-context (no package I/O buffers - the pass-through PL/DMA pin
# mapping belongs to the Phase-9 bring-up XDC).  Placement errors of the
# form "could not place all instances" on an unconstrained bank plan are
# exactly the failure this flag removes; routed timing remains the gate.
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# ---- synthesis + implementation (routed timing, Phase 8) --------------------
puts "INFO: MGR1 shell synth on $part"
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

set status [get_property STATUS [get_runs impl_1]]
if { [string first "route_design Complete" $status] == -1 } {
    puts "ERROR: impl_1 did not complete: $status"
    exit 1
}

# ---- evidence ---------------------------------------------------------------
open_run impl_1
report_timing_summary -file [file join $repo_root results vivado timing_routed.txt]
report_utilization   -file [file join $repo_root results vivado utilization_routed.txt]
report_methodology   -file [file join $repo_root results vivado methodology.txt]

set wns [get_property SLACK [get_timing_paths -delay_type max]]
puts "INFO: MGR1 shell routed WNS = $wns ns"
if { $wns < 0 } {
    puts "ERROR: timing not closed (WNS $wns): gate freezes per docs/07."
    exit 1
}

puts "INFO: MGR1 shell build complete.  Append one row to results/run_ledger.csv"
puts "      with tool_version [version -short] and evidence level 'routed timing'."
exit 0
