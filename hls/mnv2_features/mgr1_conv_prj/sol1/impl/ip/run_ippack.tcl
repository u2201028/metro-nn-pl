# ==============================================================
# Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2024.2 (64-bit)
# Tool Version Limit: 2024.11
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
# 
# ==============================================================
source -notrace "F:/Vitis/2024.2/common/scripts/ipxhls.tcl"
set ip_dir "F:/metro-nn-pl/hls/mnv2_features/mgr1_conv_prj/sol1/impl/ip"
set data_file "F:/metro-nn-pl/hls/mnv2_features/mgr1_conv_prj/sol1/sol1_data.json"
set ip_types "vitis sysgen"
if { [catch {::ipx::utils::package_hls_ip $ip_dir $data_file $ip_types } res] } {
  puts "Caught error:\n$::errorInfo"
  error $res
}
