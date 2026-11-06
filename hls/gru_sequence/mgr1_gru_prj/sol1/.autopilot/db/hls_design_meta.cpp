#include "hls_design_meta.h"
const Port_Property HLS_Design_Meta::port_props[]={
	Port_Property("ap_clk", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_rst", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_start", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_done", 1, hls_out, -1, "", "", 1),
	Port_Property("ap_idle", 1, hls_out, -1, "", "", 1),
	Port_Property("ap_ready", 1, hls_out, -1, "", "", 1),
	Port_Property("x", 32, hls_in, 0, "ap_none", "in_data", 1),
	Port_Property("h_prev", 32, hls_in, 1, "ap_none", "in_data", 1),
	Port_Property("w_ih", 8, hls_in, 2, "ap_none", "in_data", 1),
	Port_Property("w_hh", 8, hls_in, 3, "ap_none", "in_data", 1),
	Port_Property("b_ih", 32, hls_in, 4, "ap_none", "in_data", 1),
	Port_Property("b_hh", 32, hls_in, 5, "ap_none", "in_data", 1),
	Port_Property("mult_gx", 32, hls_in, 6, "ap_none", "in_data", 1),
	Port_Property("shift_gx", 32, hls_in, 7, "ap_none", "in_data", 1),
	Port_Property("mult_gh", 32, hls_in, 8, "ap_none", "in_data", 1),
	Port_Property("shift_gh", 32, hls_in, 9, "ap_none", "in_data", 1),
	Port_Property("h_out", 32, hls_out, 10, "ap_vld", "out_data", 1),
	Port_Property("h_out_ap_vld", 1, hls_out, 10, "ap_vld", "out_vld", 1),
	Port_Property("h_size", 32, hls_in, 11, "ap_none", "in_data", 1),
};
const char* HLS_Design_Meta::dut_name = "mgr1::gru_step";
