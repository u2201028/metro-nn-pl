# Vitis HLS 2025.2 build for the MobileNetV2 conv kernels (hardware-gated).
# Run on a host with Vitis HLS:  vitis_hls -f build.tcl
# Stages: csim (must match vectors/golden/conv_sentinels.vec), cosim, export.

set prj      mgr1_conv_prj
set top      conv2d_int8
set part     xck26-sfvc784-2LV-c
set clkperiod 6.67

open_project -reset $prj
set_top $top
add_files ./conv_kernels.cpp -cflags "-I../common"
add_files -tb ./tb_conv.cpp -cflags "-I../common"
add_files -tb ../../vectors/golden/conv_sentinels.vec

open_solution "sol1" -flow target vivado
set_part $part
create_clock -period $clkperiod -name default

csim_design -argv "../../vectors/golden/conv_sentinels.vec"
csynth_design
cosim_design -argv "../../vectors/golden/conv_sentinels.vec"
export_design -format ip_catalog

exit
