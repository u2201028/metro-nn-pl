set moduleName gru_step_Pipeline_VITIS_LOOP_61_5
set isTopModule 0
set isCombinational 0
set isDatapathOnly 0
set isPipelined 1
set pipeline_type loop_auto_rewind
set FunctionProtocol ap_ctrl_hs
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set isEnableWaveformDebug 1
set hasInterrupt 0
set DLRegFirstOffset 0
set DLRegItemOffset 0
set svuvm_can_support 1
set cdfgNum 7
set C_modelName {gru_step_Pipeline_VITIS_LOOP_61_5}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict z { MEM_WIDTH 15 MEM_SIZE 256 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
dict set ap_memory_interface_dict n { MEM_WIDTH 16 MEM_SIZE 256 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
dict set ap_memory_interface_dict a_ar { MEM_WIDTH 32 MEM_SIZE 1536 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
dict set ap_memory_interface_dict u_ar { MEM_WIDTH 32 MEM_SIZE 1536 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
set C_modelArgList {
	{ empty_25 int 31 regular  }
	{ z int 15 regular {array 128 { 0 3 } 0 1 }  }
	{ n int 16 regular {array 128 { 0 3 } 0 1 }  }
	{ empty int 9 regular  }
	{ a_ar int 32 regular {array 384 { 1 1 } 1 1 }  }
	{ u_ar int 32 regular {array 384 { 1 1 } 1 1 }  }
	{ conv_i int 32 regular  }
	{ mul1 int 9 regular  }
	{ sh_prom_i int 32 regular  }
	{ den_assign int 64 regular  }
	{ sub_i_i int 64 regular  }
	{ shift_gx int 32 regular  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "empty_25", "interface" : "wire", "bitwidth" : 31, "direction" : "READONLY"} , 
 	{ "Name" : "z", "interface" : "memory", "bitwidth" : 15, "direction" : "WRITEONLY"} , 
 	{ "Name" : "n", "interface" : "memory", "bitwidth" : 16, "direction" : "WRITEONLY"} , 
 	{ "Name" : "empty", "interface" : "wire", "bitwidth" : 9, "direction" : "READONLY"} , 
 	{ "Name" : "a_ar", "interface" : "memory", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "u_ar", "interface" : "memory", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "conv_i", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "mul1", "interface" : "wire", "bitwidth" : 9, "direction" : "READONLY"} , 
 	{ "Name" : "sh_prom_i", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "den_assign", "interface" : "wire", "bitwidth" : 64, "direction" : "READONLY"} , 
 	{ "Name" : "sub_i_i", "interface" : "wire", "bitwidth" : 64, "direction" : "READONLY"} , 
 	{ "Name" : "shift_gx", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} ]}
# RTL Port declarations: 
set portNum 34
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ empty_25 sc_in sc_lv 31 signal 0 } 
	{ z_address0 sc_out sc_lv 7 signal 1 } 
	{ z_ce0 sc_out sc_logic 1 signal 1 } 
	{ z_we0 sc_out sc_logic 1 signal 1 } 
	{ z_d0 sc_out sc_lv 15 signal 1 } 
	{ n_address0 sc_out sc_lv 7 signal 2 } 
	{ n_ce0 sc_out sc_logic 1 signal 2 } 
	{ n_we0 sc_out sc_logic 1 signal 2 } 
	{ n_d0 sc_out sc_lv 16 signal 2 } 
	{ empty sc_in sc_lv 9 signal 3 } 
	{ a_ar_address0 sc_out sc_lv 9 signal 4 } 
	{ a_ar_ce0 sc_out sc_logic 1 signal 4 } 
	{ a_ar_q0 sc_in sc_lv 32 signal 4 } 
	{ a_ar_address1 sc_out sc_lv 9 signal 4 } 
	{ a_ar_ce1 sc_out sc_logic 1 signal 4 } 
	{ a_ar_q1 sc_in sc_lv 32 signal 4 } 
	{ u_ar_address0 sc_out sc_lv 9 signal 5 } 
	{ u_ar_ce0 sc_out sc_logic 1 signal 5 } 
	{ u_ar_q0 sc_in sc_lv 32 signal 5 } 
	{ u_ar_address1 sc_out sc_lv 9 signal 5 } 
	{ u_ar_ce1 sc_out sc_logic 1 signal 5 } 
	{ u_ar_q1 sc_in sc_lv 32 signal 5 } 
	{ conv_i sc_in sc_lv 32 signal 6 } 
	{ mul1 sc_in sc_lv 9 signal 7 } 
	{ sh_prom_i sc_in sc_lv 32 signal 8 } 
	{ den_assign sc_in sc_lv 64 signal 9 } 
	{ sub_i_i sc_in sc_lv 64 signal 10 } 
	{ shift_gx sc_in sc_lv 32 signal 11 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "empty_25", "direction": "in", "datatype": "sc_lv", "bitwidth":31, "type": "signal", "bundle":{"name": "empty_25", "role": "default" }} , 
 	{ "name": "z_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":7, "type": "signal", "bundle":{"name": "z", "role": "address0" }} , 
 	{ "name": "z_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "z", "role": "ce0" }} , 
 	{ "name": "z_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "z", "role": "we0" }} , 
 	{ "name": "z_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":15, "type": "signal", "bundle":{"name": "z", "role": "d0" }} , 
 	{ "name": "n_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":7, "type": "signal", "bundle":{"name": "n", "role": "address0" }} , 
 	{ "name": "n_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "n", "role": "ce0" }} , 
 	{ "name": "n_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "n", "role": "we0" }} , 
 	{ "name": "n_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":16, "type": "signal", "bundle":{"name": "n", "role": "d0" }} , 
 	{ "name": "empty", "direction": "in", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "empty", "role": "default" }} , 
 	{ "name": "a_ar_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "a_ar", "role": "address0" }} , 
 	{ "name": "a_ar_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "a_ar", "role": "ce0" }} , 
 	{ "name": "a_ar_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "a_ar", "role": "q0" }} , 
 	{ "name": "a_ar_address1", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "a_ar", "role": "address1" }} , 
 	{ "name": "a_ar_ce1", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "a_ar", "role": "ce1" }} , 
 	{ "name": "a_ar_q1", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "a_ar", "role": "q1" }} , 
 	{ "name": "u_ar_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "u_ar", "role": "address0" }} , 
 	{ "name": "u_ar_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "u_ar", "role": "ce0" }} , 
 	{ "name": "u_ar_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "u_ar", "role": "q0" }} , 
 	{ "name": "u_ar_address1", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "u_ar", "role": "address1" }} , 
 	{ "name": "u_ar_ce1", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "u_ar", "role": "ce1" }} , 
 	{ "name": "u_ar_q1", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "u_ar", "role": "q1" }} , 
 	{ "name": "conv_i", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "conv_i", "role": "default" }} , 
 	{ "name": "mul1", "direction": "in", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "mul1", "role": "default" }} , 
 	{ "name": "sh_prom_i", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "sh_prom_i", "role": "default" }} , 
 	{ "name": "den_assign", "direction": "in", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "den_assign", "role": "default" }} , 
 	{ "name": "sub_i_i", "direction": "in", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "sub_i_i", "role": "default" }} , 
 	{ "name": "shift_gx", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "shift_gx", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7"],
		"CDFG" : "gru_step_Pipeline_VITIS_LOOP_61_5",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "74", "EstimateLatencyMax" : "-1",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"IsBlackBox" : "0",
		"Port" : [
			{"Name" : "empty_25", "Type" : "None", "Direction" : "I"},
			{"Name" : "z", "Type" : "Memory", "Direction" : "O"},
			{"Name" : "n", "Type" : "Memory", "Direction" : "O"},
			{"Name" : "empty", "Type" : "None", "Direction" : "I"},
			{"Name" : "a_ar", "Type" : "Memory", "Direction" : "I"},
			{"Name" : "u_ar", "Type" : "Memory", "Direction" : "I"},
			{"Name" : "conv_i", "Type" : "None", "Direction" : "I"},
			{"Name" : "mul1", "Type" : "None", "Direction" : "I"},
			{"Name" : "sh_prom_i", "Type" : "None", "Direction" : "I"},
			{"Name" : "den_assign", "Type" : "None", "Direction" : "I"},
			{"Name" : "sub_i_i", "Type" : "None", "Direction" : "I"},
			{"Name" : "shift_gx", "Type" : "None", "Direction" : "I"},
			{"Name" : "MGR1_SIGMOID_LUT", "Type" : "Memory", "Direction" : "I"},
			{"Name" : "MGR1_TANH_LUT", "Type" : "Memory", "Direction" : "I"}],
		"Loop" : [
			{"Name" : "VITIS_LOOP_61_5", "PipelineType" : "UPC",
				"LoopDec" : {"FSMBitwidth" : "1", "FirstState" : "ap_ST_fsm_pp0_stage0", "FirstStateIter" : "ap_enable_reg_pp0_iter0", "FirstStateBlock" : "ap_block_pp0_stage0_subdone", "LastState" : "ap_ST_fsm_pp0_stage0", "LastStateIter" : "ap_enable_reg_pp0_iter72", "LastStateBlock" : "ap_block_pp0_stage0_subdone", "QuitState" : "ap_ST_fsm_pp0_stage0", "QuitStateIter" : "ap_enable_reg_pp0_iter72", "QuitStateBlock" : "ap_block_pp0_stage0_subdone", "OneDepthLoop" : "0", "has_ap_ctrl" : "1", "has_continue" : "0"}}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.MGR1_SIGMOID_LUT_U", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.MGR1_TANH_LUT_U", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_33s_32s_64_1_1_U7", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_33s_32s_64_1_1_U8", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.srem_64ns_64ns_64_68_1_U9", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.srem_64ns_64ns_64_68_1_U10", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.flow_control_loop_pipe_sequential_init_U", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	gru_step_Pipeline_VITIS_LOOP_61_5 {
		empty_25 {Type I LastRead 0 FirstWrite -1}
		z {Type O LastRead -1 FirstWrite 72}
		n {Type O LastRead -1 FirstWrite 72}
		empty {Type I LastRead 0 FirstWrite -1}
		a_ar {Type I LastRead 1 FirstWrite -1}
		u_ar {Type I LastRead 1 FirstWrite -1}
		conv_i {Type I LastRead 0 FirstWrite -1}
		mul1 {Type I LastRead 0 FirstWrite -1}
		sh_prom_i {Type I LastRead 0 FirstWrite -1}
		den_assign {Type I LastRead 0 FirstWrite -1}
		sub_i_i {Type I LastRead 0 FirstWrite -1}
		shift_gx {Type I LastRead 0 FirstWrite -1}
		MGR1_SIGMOID_LUT {Type I LastRead -1 FirstWrite -1}
		MGR1_TANH_LUT {Type I LastRead -1 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "74", "Max" : "-1"}
	, {"Name" : "Interval", "Min" : "74", "Max" : "-1"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	empty_25 { ap_none {  { empty_25 in_data 0 31 } } }
	z { ap_memory {  { z_address0 mem_address 1 7 }  { z_ce0 mem_ce 1 1 }  { z_we0 mem_we 1 1 }  { z_d0 mem_din 1 15 } } }
	n { ap_memory {  { n_address0 mem_address 1 7 }  { n_ce0 mem_ce 1 1 }  { n_we0 mem_we 1 1 }  { n_d0 mem_din 1 16 } } }
	empty { ap_none {  { empty in_data 0 9 } } }
	a_ar { ap_memory {  { a_ar_address0 mem_address 1 9 }  { a_ar_ce0 mem_ce 1 1 }  { a_ar_q0 mem_dout 0 32 }  { a_ar_address1 MemPortADDR2 1 9 }  { a_ar_ce1 MemPortCE2 1 1 }  { a_ar_q1 MemPortDOUT2 0 32 } } }
	u_ar { ap_memory {  { u_ar_address0 mem_address 1 9 }  { u_ar_ce0 mem_ce 1 1 }  { u_ar_q0 mem_dout 0 32 }  { u_ar_address1 MemPortADDR2 1 9 }  { u_ar_ce1 MemPortCE2 1 1 }  { u_ar_q1 MemPortDOUT2 0 32 } } }
	conv_i { ap_none {  { conv_i in_data 0 32 } } }
	mul1 { ap_none {  { mul1 in_data 0 9 } } }
	sh_prom_i { ap_none {  { sh_prom_i in_data 0 32 } } }
	den_assign { ap_none {  { den_assign in_data 0 64 } } }
	sub_i_i { ap_none {  { sub_i_i in_data 0 64 } } }
	shift_gx { ap_none {  { shift_gx in_data 0 32 } } }
}
