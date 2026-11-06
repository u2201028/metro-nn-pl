set moduleName conv2d_int8
set isTopModule 1
set isCombinational 0
set isDatapathOnly 0
set isPipelined 0
set pipeline_type none
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
set C_modelName {mgr1::conv2d_int8}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
set C_modelArgList {
	{ x int 8 regular {pointer 0}  }
	{ w int 8 regular {pointer 0}  }
	{ b int 32 regular {pointer 0}  }
	{ zx int 32 regular  }
	{ mult int 32 regular {pointer 0}  }
	{ shift int 32 regular {pointer 0}  }
	{ zout int 32 regular  }
	{ hin int 32 regular  }
	{ win int 32 regular  }
	{ cin int 32 regular  }
	{ cout int 32 regular  }
	{ kh int 32 regular  }
	{ kw int 32 regular  }
	{ stride int 32 regular  }
	{ pad int 32 regular  }
	{ out_r int 8 regular {pointer 1}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "x", "interface" : "wire", "bitwidth" : 8, "direction" : "READONLY"} , 
 	{ "Name" : "w", "interface" : "wire", "bitwidth" : 8, "direction" : "READONLY"} , 
 	{ "Name" : "b", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "zx", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "mult", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "shift", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "zout", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "hin", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "win", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "cin", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "cout", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "kh", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "kw", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "stride", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "pad", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "out_r", "interface" : "wire", "bitwidth" : 8, "direction" : "WRITEONLY"} ]}
# RTL Port declarations: 
set portNum 23
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ x sc_in sc_lv 8 signal 0 } 
	{ w sc_in sc_lv 8 signal 1 } 
	{ b sc_in sc_lv 32 signal 2 } 
	{ zx sc_in sc_lv 32 signal 3 } 
	{ mult sc_in sc_lv 32 signal 4 } 
	{ shift sc_in sc_lv 32 signal 5 } 
	{ zout sc_in sc_lv 32 signal 6 } 
	{ hin sc_in sc_lv 32 signal 7 } 
	{ win sc_in sc_lv 32 signal 8 } 
	{ cin sc_in sc_lv 32 signal 9 } 
	{ cout sc_in sc_lv 32 signal 10 } 
	{ kh sc_in sc_lv 32 signal 11 } 
	{ kw sc_in sc_lv 32 signal 12 } 
	{ stride sc_in sc_lv 32 signal 13 } 
	{ pad sc_in sc_lv 32 signal 14 } 
	{ out_r sc_out sc_lv 8 signal 15 } 
	{ out_r_ap_vld sc_out sc_logic 1 outvld 15 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "x", "direction": "in", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "x", "role": "default" }} , 
 	{ "name": "w", "direction": "in", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "w", "role": "default" }} , 
 	{ "name": "b", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "b", "role": "default" }} , 
 	{ "name": "zx", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "zx", "role": "default" }} , 
 	{ "name": "mult", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "mult", "role": "default" }} , 
 	{ "name": "shift", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "shift", "role": "default" }} , 
 	{ "name": "zout", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "zout", "role": "default" }} , 
 	{ "name": "hin", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "hin", "role": "default" }} , 
 	{ "name": "win", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "win", "role": "default" }} , 
 	{ "name": "cin", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "cin", "role": "default" }} , 
 	{ "name": "cout", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "cout", "role": "default" }} , 
 	{ "name": "kh", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "kh", "role": "default" }} , 
 	{ "name": "kw", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "kw", "role": "default" }} , 
 	{ "name": "stride", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "stride", "role": "default" }} , 
 	{ "name": "pad", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "pad", "role": "default" }} , 
 	{ "name": "out_r", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "out_r", "role": "default" }} , 
 	{ "name": "out_r_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "out_r", "role": "ap_vld" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "4", "5", "6", "7", "8", "9"],
		"CDFG" : "conv2d_int8",
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
			{"Name" : "x", "Type" : "None", "Direction" : "I"},
			{"Name" : "w", "Type" : "None", "Direction" : "I"},
			{"Name" : "b", "Type" : "None", "Direction" : "I"},
			{"Name" : "zx", "Type" : "None", "Direction" : "I"},
			{"Name" : "mult", "Type" : "None", "Direction" : "I"},
			{"Name" : "shift", "Type" : "None", "Direction" : "I"},
			{"Name" : "zout", "Type" : "None", "Direction" : "I"},
			{"Name" : "hin", "Type" : "None", "Direction" : "I"},
			{"Name" : "win", "Type" : "None", "Direction" : "I"},
			{"Name" : "cin", "Type" : "None", "Direction" : "I"},
			{"Name" : "cout", "Type" : "None", "Direction" : "I"},
			{"Name" : "kh", "Type" : "None", "Direction" : "I"},
			{"Name" : "kw", "Type" : "None", "Direction" : "I"},
			{"Name" : "stride", "Type" : "None", "Direction" : "I"},
			{"Name" : "pad", "Type" : "None", "Direction" : "I"},
			{"Name" : "out_r", "Type" : "Vld", "Direction" : "O"}],
		"Loop" : [
			{"Name" : "VITIS_LOOP_34_3", "PipelineType" : "no",
				"LoopDec" : {"FSMBitwidth" : "110", "FirstState" : "ap_ST_fsm_state39", "LastState" : ["ap_ST_fsm_state110"], "QuitState" : ["ap_ST_fsm_state39"], "PreState" : ["ap_ST_fsm_state38"], "PostState" : ["ap_ST_fsm_state38"], "OneDepthLoop" : "0", "OneStateBlock": ""}},
			{"Name" : "VITIS_LOOP_33_2", "PipelineType" : "no",
				"LoopDec" : {"FSMBitwidth" : "110", "FirstState" : "ap_ST_fsm_state38", "LastState" : ["ap_ST_fsm_state39"], "QuitState" : ["ap_ST_fsm_state38"], "PreState" : ["ap_ST_fsm_state37"], "PostState" : ["ap_ST_fsm_state37"], "OneDepthLoop" : "0", "OneStateBlock": ""}},
			{"Name" : "VITIS_LOOP_32_1", "PipelineType" : "no",
				"LoopDec" : {"FSMBitwidth" : "110", "FirstState" : "ap_ST_fsm_state37", "LastState" : ["ap_ST_fsm_state38"], "QuitState" : ["ap_ST_fsm_state37"], "PreState" : ["ap_ST_fsm_state36"], "PostState" : ["ap_ST_fsm_state1"], "OneDepthLoop" : "0", "OneStateBlock": ""}}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.grp_conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6_fu_271", "Parent" : "0", "Child" : ["2", "3"],
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
	{"ID" : "2", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6_fu_271.mul_33s_8s_41_1_1_U1", "Parent" : "1"},
	{"ID" : "3", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6_fu_271.flow_control_loop_pipe_sequential_init_U", "Parent" : "1"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_31ns_31ns_62_1_1_U17", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_31ns_62ns_93_1_1_U18", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_64s_32s_64_1_1_U19", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.sdiv_32ns_32s_32_36_seq_1_U20", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.sdiv_32ns_32s_32_36_seq_1_U21", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.srem_64ns_64ns_64_68_seq_1_U22", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	conv2d_int8 {
		x {Type I LastRead 35 FirstWrite -1}
		w {Type I LastRead 35 FirstWrite -1}
		b {Type I LastRead 35 FirstWrite -1}
		zx {Type I LastRead 35 FirstWrite -1}
		mult {Type I LastRead 35 FirstWrite -1}
		shift {Type I LastRead 35 FirstWrite -1}
		zout {Type I LastRead 35 FirstWrite -1}
		hin {Type I LastRead 0 FirstWrite -1}
		win {Type I LastRead 0 FirstWrite -1}
		cin {Type I LastRead 34 FirstWrite -1}
		cout {Type I LastRead 35 FirstWrite -1}
		kh {Type I LastRead 0 FirstWrite -1}
		kw {Type I LastRead 0 FirstWrite -1}
		stride {Type I LastRead 0 FirstWrite -1}
		pad {Type I LastRead 0 FirstWrite -1}
		out_r {Type O LastRead -1 FirstWrite 38}}
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
	, {"Name" : "Interval", "Min" : "0", "Max" : "0"}
]}

set PipelineEnableSignalInfo {[
]}

set Spec2ImplPortList { 
	x { ap_none {  { x in_data 0 8 } } }
	w { ap_none {  { w in_data 0 8 } } }
	b { ap_none {  { b in_data 0 32 } } }
	zx { ap_none {  { zx in_data 0 32 } } }
	mult { ap_none {  { mult in_data 0 32 } } }
	shift { ap_none {  { shift in_data 0 32 } } }
	zout { ap_none {  { zout in_data 0 32 } } }
	hin { ap_none {  { hin in_data 0 32 } } }
	win { ap_none {  { win in_data 0 32 } } }
	cin { ap_none {  { cin in_data 0 32 } } }
	cout { ap_none {  { cout in_data 0 32 } } }
	kh { ap_none {  { kh in_data 0 32 } } }
	kw { ap_none {  { kw in_data 0 32 } } }
	stride { ap_none {  { stride in_data 0 32 } } }
	pad { ap_none {  { pad in_data 0 32 } } }
	out_r { ap_vld {  { out_r out_data 1 8 }  { out_r_ap_vld out_vld 1 1 } } }
}

set maxi_interface_dict [dict create]

# RTL port scheduling information:
set fifoSchedulingInfoList { 
}

# RTL bus port read request latency information:
set busReadReqLatencyList { 
}

# RTL bus port write response latency information:
set busWriteResLatencyList { 
}

# RTL array port load latency information:
set memoryLoadLatencyList { 
}
