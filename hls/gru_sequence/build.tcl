# Vitis HLS 2025.2 build for the GRU sequence kernel (hardware-gated).
# Run on a host with Vitis HLS:  vitis_hls -f build.tcl
# Stages: csim (must match vectors/golden/gru_window.vec), cosim, export.
#
# The C simulation must reproduce the Python oracle bit-exactly; the
# sandbox run of tb_gru.cpp is the reference evidence (see
# results/run_ledger.csv).  Synthesis, co-simulation and export require
# the Vitis toolchain and are recorded as PENDING until run on hardware.

set prj      mgr1_gru_prj
set top      gru_step
set part     xck26-sfvc784-2LV-c
set clkperiod 6.67

open_project -reset $prj
# csim/cosim run from the project scratch dir; pass the golden
# vector by ABSOLUTE path so the argv survives any working dir.
# vitis_hls -f runs with CWD = this directory, per the tool log
set vecpath [file normalize ../../vectors/golden/gru_window.vec]

set_top $top
add_files ../common/activation_luts.cpp
# C++17 pinned because in-source PIPELINE pragmas (see gru_top.cpp)
# carry the interface/QoR contract; cflags keep csim == csynth == the sandbox g++ build.
add_files ./gru_top.cpp -cflags "-std=c++17 -I../common"
add_files -tb ./tb_gru.cpp -cflags "-I../common"
add_files -tb ../../vectors/golden/gru_window.vec

open_solution "sol1" -flow_target vivado
set_part $part
create_clock -period $clkperiod -name default

csim_design -argv "$vecpath"
csynth_design
cosim_design -tool xsim -argv "$vecpath"
export_design -format ip_catalog

exit
