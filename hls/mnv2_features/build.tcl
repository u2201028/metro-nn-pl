# Vitis HLS 2025.2 build for the MobileNetV2 conv kernels (hardware-gated).
# Run on a host with Vitis HLS:  vitis_hls -f build.tcl
# Stages: csim (must match vectors/golden/conv_sentinels.vec), cosim, export.

set prj      mgr1_conv_prj
set top      conv2d_int8
set part     xck26-sfvc784-2LV-c
set clkperiod 6.67

open_project -reset $prj
# csim/cosim run from the project scratch dir; pass the golden
# vector by ABSOLUTE path so the argv survives any working dir.
# vitis_hls -f runs with CWD = this directory, per the tool log
set vecpath [file normalize ../../vectors/golden/conv_sentinels.vec]

set_top $top
# C++17 pinned because in-source PIPELINE pragmas (see conv_kernels.cpp)
# carry the interface/QoR contract; cflags keep csim == csynth == the sandbox g++ build.
add_files ./conv_kernels.cpp -cflags "-std=c++17 -I../common"
add_files -tb ./tb_conv.cpp -cflags "-I../common"
add_files -tb ../../vectors/golden/conv_sentinels.vec

open_solution "sol1" -flow_target vivado
set_part $part
create_clock -period $clkperiod -name default

csim_design -argv "$vecpath"
csynth_design
cosim_design -tool xsim -argv "$vecpath"
export_design -format ip_catalog

exit
