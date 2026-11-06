open_project -reset mgr1_gru_prj
set_top gru_step
add_files ../common/activation_luts.cpp
add_files ./gru_top.cpp -cflags "-std=c++17 -I../common"
add_files -tb ./tb_gru.cpp -cflags "-I../common"
add_files -tb ../../vectors/golden/gru_window.vec
open_solution "sol1" -flow_target vivado
set_part xck26-sfvc784-2LV-c
create_clock -period 6.67 -name default
csynth_design
export_design -format ip_catalog -output ./mgr1_gru_ip.zip
exit
