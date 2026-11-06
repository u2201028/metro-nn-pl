set moduleName gru_step_Pipeline_VITIS_LOOP_76_6
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
set C_modelName {gru_step_Pipeline_VITIS_LOOP_76_6}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict z { MEM_WIDTH 15 MEM_SIZE 256 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
dict set ap_memory_interface_dict n { MEM_WIDTH 16 MEM_SIZE 256 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
set C_modelArgList {
	{ empty int 31 regular  }
	{ z int 15 regular {array 128 { 1 3 } 1 1 }  }
	{ sext_ln76 int 32 regular  }
	{ n int 16 regular {array 128 { 1 3 } 1 1 }  }
	{ retval_0_i_phi_out int 8 regular {pointer 1}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "empty", "interface" : "wire", "bitwidth" : 31, "direction" : "READONLY"} , 
 	{ "Name" : "z", "interface" : "memory", "bitwidth" : 15, "direction" : "READONLY"} , 
 	{ "Name" : "sext_ln76", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "n", "interface" : "memory", "bitwidth" : 16, "direction" : "READONLY"} , 
 	{ "Name" : "retval_0_i_phi_out", "interface" : "wire", "bitwidth" : 8, "direction" : "WRITEONLY"} ]}
# RTL Port declarations: 
set portNum 16
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ empty sc_in sc_lv 31 signal 0 } 
	{ z_address0 sc_out sc_lv 7 signal 1 } 
	{ z_ce0 sc_out sc_logic 1 signal 1 } 
	{ z_q0 sc_in sc_lv 15 signal 1 } 
	{ sext_ln76 sc_in sc_lv 32 signal 2 } 
	{ n_address0 sc_out sc_lv 7 signal 3 } 
	{ n_ce0 sc_out sc_logic 1 signal 3 } 
	{ n_q0 sc_in sc_lv 16 signal 3 } 
	{ retval_0_i_phi_out sc_out sc_lv 8 signal 4 } 
	{ retval_0_i_phi_out_ap_vld sc_out sc_logic 1 outvld 4 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "empty", "direction": "in", "datatype": "sc_lv", "bitwidth":31, "type": "signal", "bundle":{"name": "empty", "role": "default" }} , 
 	{ "name": "z_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":7, "type": "signal", "bundle":{"name": "z", "role": "address0" }} , 
 	{ "name": "z_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "z", "role": "ce0" }} , 
 	{ "name": "z_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":15, "type": "signal", "bundle":{"name": "z", "role": "q0" }} , 
 	{ "name": "sext_ln76", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "sext_ln76", "role": "default" }} , 
 	{ "name": "n_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":7, "type": "signal", "bundle":{"name": "n", "role": "address0" }} , 
 	{ "name": "n_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "n", "role": "ce0" }} , 
 	{ "name": "n_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":16, "type": "signal", "bundle":{"name": "n", "role": "q0" }} , 
 	{ "name": "retval_0_i_phi_out", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "retval_0_i_phi_out", "role": "default" }} , 
 	{ "name": "retval_0_i_phi_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "retval_0_i_phi_out", "role": "ap_vld" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7"],
		"CDFG" : "gru_step_Pipeline_VITIS_LOOP_76_6",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "55", "EstimateLatencyMax" : "309",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"IsBlackBox" : "0",
		"Port" : [
			{"Name" : "empty", "Type" : "None", "Direction" : "I"},
			{"Name" : "z", "Type" : "Memory", "Direction" : "I"},
			{"Name" : "sext_ln76", "Type" : "None", "Direction" : "I"},
			{"Name" : "n", "Type" : "Memory", "Direction" : "I"},
			{"Name" : "retval_0_i_phi_out", "Type" : "Vld", "Direction" : "O"}],
		"Loop" : [
			{"Name" : "VITIS_LOOP_76_6", "PipelineType" : "UPC",
				"LoopDec" : {"FSMBitwidth" : "1", "FirstState" : "ap_ST_fsm_pp0_stage0", "FirstStateIter" : "ap_enable_reg_pp0_iter0", "FirstStateBlock" : "ap_block_pp0_stage0_subdone", "LastState" : "ap_ST_fsm_pp0_stage0", "LastStateIter" : "ap_enable_reg_pp0_iter53", "LastStateBlock" : "ap_block_pp0_stage0_subdone", "QuitState" : "ap_ST_fsm_pp0_stage0", "QuitStateIter" : "ap_enable_reg_pp0_iter53", "QuitStateBlock" : "ap_block_pp0_stage0_subdone", "OneDepthLoop" : "0", "has_ap_ctrl" : "1", "has_continue" : "0"}}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_15ns_32s_47_1_1_U27", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_31s_33ns_63_1_1_U28", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_47s_49ns_95_1_1_U29", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.srem_47s_16ns_47_51_1_U30", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_16s_15ns_31_1_1_U31", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.srem_31s_16ns_31_35_1_U32", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.flow_control_loop_pipe_sequential_init_U", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	gru_step_Pipeline_VITIS_LOOP_76_6 {
		empty {Type I LastRead 0 FirstWrite -1}
		z {Type I LastRead 0 FirstWrite -1}
		sext_ln76 {Type I LastRead 0 FirstWrite -1}
		n {Type I LastRead 16 FirstWrite -1}
		retval_0_i_phi_out {Type O LastRead -1 FirstWrite 52}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "55", "Max" : "309"}
	, {"Name" : "Interval", "Min" : "55", "Max" : "309"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	empty { ap_none {  { empty in_data 0 31 } } }
	z { ap_memory {  { z_address0 mem_address 1 7 }  { z_ce0 mem_ce 1 1 }  { z_q0 mem_dout 0 15 } } }
	sext_ln76 { ap_none {  { sext_ln76 in_data 0 32 } } }
	n { ap_memory {  { n_address0 mem_address 1 7 }  { n_ce0 mem_ce 1 1 }  { n_q0 mem_dout 0 16 } } }
	retval_0_i_phi_out { ap_vld {  { retval_0_i_phi_out out_data 1 8 }  { retval_0_i_phi_out_ap_vld out_vld 1 1 } } }
}
