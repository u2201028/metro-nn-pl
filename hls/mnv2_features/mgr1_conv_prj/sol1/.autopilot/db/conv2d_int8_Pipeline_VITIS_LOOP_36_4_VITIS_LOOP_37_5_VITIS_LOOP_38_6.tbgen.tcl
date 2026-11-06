set moduleName conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6
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
set cdfgNum 4
set C_modelName {conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
set C_modelArgList {
	{ acc int 32 regular  }
	{ kw int 32 regular  }
	{ mul_ln23_1 int 93 regular  }
	{ mul_ln23 int 62 regular  }
	{ empty_10 int 1 regular  }
	{ empty int 63 regular  }
	{ sext_ln32_2 int 32 regular  }
	{ phi_mul int 63 regular  }
	{ sext_ln32 int 32 regular  }
	{ sext_ln32_1 int 32 regular  }
	{ sext_ln44 int 8 regular  }
	{ zx_cast int 32 regular  }
	{ sext_ln32_3 int 8 regular  }
	{ acc_2_out int 64 regular {pointer 1}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "acc", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "kw", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "mul_ln23_1", "interface" : "wire", "bitwidth" : 93, "direction" : "READONLY"} , 
 	{ "Name" : "mul_ln23", "interface" : "wire", "bitwidth" : 62, "direction" : "READONLY"} , 
 	{ "Name" : "empty_10", "interface" : "wire", "bitwidth" : 1, "direction" : "READONLY"} , 
 	{ "Name" : "empty", "interface" : "wire", "bitwidth" : 63, "direction" : "READONLY"} , 
 	{ "Name" : "sext_ln32_2", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "phi_mul", "interface" : "wire", "bitwidth" : 63, "direction" : "READONLY"} , 
 	{ "Name" : "sext_ln32", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "sext_ln32_1", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "sext_ln44", "interface" : "wire", "bitwidth" : 8, "direction" : "READONLY"} , 
 	{ "Name" : "zx_cast", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "sext_ln32_3", "interface" : "wire", "bitwidth" : 8, "direction" : "READONLY"} , 
 	{ "Name" : "acc_2_out", "interface" : "wire", "bitwidth" : 64, "direction" : "WRITEONLY"} ]}
# RTL Port declarations: 
set portNum 21
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ acc sc_in sc_lv 32 signal 0 } 
	{ kw sc_in sc_lv 32 signal 1 } 
	{ mul_ln23_1 sc_in sc_lv 93 signal 2 } 
	{ mul_ln23 sc_in sc_lv 62 signal 3 } 
	{ empty_10 sc_in sc_lv 1 signal 4 } 
	{ empty sc_in sc_lv 63 signal 5 } 
	{ sext_ln32_2 sc_in sc_lv 32 signal 6 } 
	{ phi_mul sc_in sc_lv 63 signal 7 } 
	{ sext_ln32 sc_in sc_lv 32 signal 8 } 
	{ sext_ln32_1 sc_in sc_lv 32 signal 9 } 
	{ sext_ln44 sc_in sc_lv 8 signal 10 } 
	{ zx_cast sc_in sc_lv 32 signal 11 } 
	{ sext_ln32_3 sc_in sc_lv 8 signal 12 } 
	{ acc_2_out sc_out sc_lv 64 signal 13 } 
	{ acc_2_out_ap_vld sc_out sc_logic 1 outvld 13 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "acc", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "acc", "role": "default" }} , 
 	{ "name": "kw", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "kw", "role": "default" }} , 
 	{ "name": "mul_ln23_1", "direction": "in", "datatype": "sc_lv", "bitwidth":93, "type": "signal", "bundle":{"name": "mul_ln23_1", "role": "default" }} , 
 	{ "name": "mul_ln23", "direction": "in", "datatype": "sc_lv", "bitwidth":62, "type": "signal", "bundle":{"name": "mul_ln23", "role": "default" }} , 
 	{ "name": "empty_10", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "empty_10", "role": "default" }} , 
 	{ "name": "empty", "direction": "in", "datatype": "sc_lv", "bitwidth":63, "type": "signal", "bundle":{"name": "empty", "role": "default" }} , 
 	{ "name": "sext_ln32_2", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "sext_ln32_2", "role": "default" }} , 
 	{ "name": "phi_mul", "direction": "in", "datatype": "sc_lv", "bitwidth":63, "type": "signal", "bundle":{"name": "phi_mul", "role": "default" }} , 
 	{ "name": "sext_ln32", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "sext_ln32", "role": "default" }} , 
 	{ "name": "sext_ln32_1", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "sext_ln32_1", "role": "default" }} , 
 	{ "name": "sext_ln44", "direction": "in", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "sext_ln44", "role": "default" }} , 
 	{ "name": "zx_cast", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "zx_cast", "role": "default" }} , 
 	{ "name": "sext_ln32_3", "direction": "in", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "sext_ln32_3", "role": "default" }} , 
 	{ "name": "acc_2_out", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "acc_2_out", "role": "default" }} , 
 	{ "name": "acc_2_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "acc_2_out", "role": "ap_vld" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2"],
		"CDFG" : "conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "-1", "EstimateLatencyMax" : "-1",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"IsBlackBox" : "0",
		"Port" : [
			{"Name" : "acc", "Type" : "None", "Direction" : "I"},
			{"Name" : "kw", "Type" : "None", "Direction" : "I"},
			{"Name" : "mul_ln23_1", "Type" : "None", "Direction" : "I"},
			{"Name" : "mul_ln23", "Type" : "None", "Direction" : "I"},
			{"Name" : "empty_10", "Type" : "None", "Direction" : "I"},
			{"Name" : "empty", "Type" : "None", "Direction" : "I"},
			{"Name" : "sext_ln32_2", "Type" : "None", "Direction" : "I"},
			{"Name" : "phi_mul", "Type" : "None", "Direction" : "I"},
			{"Name" : "sext_ln32", "Type" : "None", "Direction" : "I"},
			{"Name" : "sext_ln32_1", "Type" : "None", "Direction" : "I"},
			{"Name" : "sext_ln44", "Type" : "None", "Direction" : "I"},
			{"Name" : "zx_cast", "Type" : "None", "Direction" : "I"},
			{"Name" : "sext_ln32_3", "Type" : "None", "Direction" : "I"},
			{"Name" : "acc_2_out", "Type" : "Vld", "Direction" : "O"}],
		"Loop" : [
			{"Name" : "VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6", "PipelineType" : "UPC",
				"LoopDec" : {"FSMBitwidth" : "1", "FirstState" : "ap_ST_fsm_pp0_stage0", "FirstStateIter" : "ap_enable_reg_pp0_iter0", "FirstStateBlock" : "ap_block_pp0_stage0_subdone", "LastState" : "ap_ST_fsm_pp0_stage0", "LastStateIter" : "ap_enable_reg_pp0_iter2", "LastStateBlock" : "ap_block_pp0_stage0_subdone", "QuitState" : "ap_ST_fsm_pp0_stage0", "QuitStateIter" : "ap_enable_reg_pp0_iter2", "QuitStateBlock" : "ap_block_pp0_stage0_subdone", "OneDepthLoop" : "0", "has_ap_ctrl" : "1", "has_continue" : "0"}}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_33s_8s_41_1_1_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.flow_control_loop_pipe_sequential_init_U", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6 {
		acc {Type I LastRead 0 FirstWrite -1}
		kw {Type I LastRead 0 FirstWrite -1}
		mul_ln23_1 {Type I LastRead 0 FirstWrite -1}
		mul_ln23 {Type I LastRead 0 FirstWrite -1}
		empty_10 {Type I LastRead 0 FirstWrite -1}
		empty {Type I LastRead 0 FirstWrite -1}
		sext_ln32_2 {Type I LastRead 0 FirstWrite -1}
		phi_mul {Type I LastRead 0 FirstWrite -1}
		sext_ln32 {Type I LastRead 0 FirstWrite -1}
		sext_ln32_1 {Type I LastRead 0 FirstWrite -1}
		sext_ln44 {Type I LastRead 0 FirstWrite -1}
		zx_cast {Type I LastRead 0 FirstWrite -1}
		sext_ln32_3 {Type I LastRead 0 FirstWrite -1}
		acc_2_out {Type O LastRead -1 FirstWrite 1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "-1", "Max" : "-1"}
	, {"Name" : "Interval", "Min" : "-1", "Max" : "-1"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	acc { ap_none {  { acc in_data 0 32 } } }
	kw { ap_none {  { kw in_data 0 32 } } }
	mul_ln23_1 { ap_none {  { mul_ln23_1 in_data 0 93 } } }
	mul_ln23 { ap_none {  { mul_ln23 in_data 0 62 } } }
	empty_10 { ap_none {  { empty_10 in_data 0 1 } } }
	empty { ap_none {  { empty in_data 0 63 } } }
	sext_ln32_2 { ap_none {  { sext_ln32_2 in_data 0 32 } } }
	phi_mul { ap_none {  { phi_mul in_data 0 63 } } }
	sext_ln32 { ap_none {  { sext_ln32 in_data 0 32 } } }
	sext_ln32_1 { ap_none {  { sext_ln32_1 in_data 0 32 } } }
	sext_ln44 { ap_none {  { sext_ln44 in_data 0 8 } } }
	zx_cast { ap_none {  { zx_cast in_data 0 32 } } }
	sext_ln32_3 { ap_none {  { sext_ln32_3 in_data 0 8 } } }
	acc_2_out { ap_vld {  { acc_2_out out_data 1 64 }  { acc_2_out_ap_vld out_vld 1 1 } } }
}
