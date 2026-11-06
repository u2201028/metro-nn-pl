set moduleName gru_step
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
set cdfgNum 7
set C_modelName {mgr1::gru_step}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
set C_modelArgList {
	{ x int 32 regular {pointer 0}  }
	{ h_prev int 32 regular {pointer 0}  }
	{ w_ih int 8 regular {pointer 0}  }
	{ w_hh int 8 regular {pointer 0}  }
	{ b_ih int 32 regular {pointer 0}  }
	{ b_hh int 32 regular {pointer 0}  }
	{ mult_gx int 32 regular  }
	{ shift_gx int 32 regular  }
	{ mult_gh int 32 unused  }
	{ shift_gh int 32 unused  }
	{ h_out int 32 regular {pointer 1}  }
	{ h_size int 32 regular  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "x", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "h_prev", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "w_ih", "interface" : "wire", "bitwidth" : 8, "direction" : "READONLY"} , 
 	{ "Name" : "w_hh", "interface" : "wire", "bitwidth" : 8, "direction" : "READONLY"} , 
 	{ "Name" : "b_ih", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "b_hh", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "mult_gx", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "shift_gx", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "mult_gh", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "shift_gh", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "h_out", "interface" : "wire", "bitwidth" : 32, "direction" : "WRITEONLY"} , 
 	{ "Name" : "h_size", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} ]}
# RTL Port declarations: 
set portNum 19
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ x sc_in sc_lv 32 signal 0 } 
	{ h_prev sc_in sc_lv 32 signal 1 } 
	{ w_ih sc_in sc_lv 8 signal 2 } 
	{ w_hh sc_in sc_lv 8 signal 3 } 
	{ b_ih sc_in sc_lv 32 signal 4 } 
	{ b_hh sc_in sc_lv 32 signal 5 } 
	{ mult_gx sc_in sc_lv 32 signal 6 } 
	{ shift_gx sc_in sc_lv 32 signal 7 } 
	{ mult_gh sc_in sc_lv 32 signal 8 } 
	{ shift_gh sc_in sc_lv 32 signal 9 } 
	{ h_out sc_out sc_lv 32 signal 10 } 
	{ h_out_ap_vld sc_out sc_logic 1 outvld 10 } 
	{ h_size sc_in sc_lv 32 signal 11 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "x", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "x", "role": "default" }} , 
 	{ "name": "h_prev", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "h_prev", "role": "default" }} , 
 	{ "name": "w_ih", "direction": "in", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "w_ih", "role": "default" }} , 
 	{ "name": "w_hh", "direction": "in", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "w_hh", "role": "default" }} , 
 	{ "name": "b_ih", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "b_ih", "role": "default" }} , 
 	{ "name": "b_hh", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "b_hh", "role": "default" }} , 
 	{ "name": "mult_gx", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "mult_gx", "role": "default" }} , 
 	{ "name": "shift_gx", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "shift_gx", "role": "default" }} , 
 	{ "name": "mult_gh", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "mult_gh", "role": "default" }} , 
 	{ "name": "shift_gh", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "shift_gh", "role": "default" }} , 
 	{ "name": "h_out", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "h_out", "role": "default" }} , 
 	{ "name": "h_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "h_out", "role": "ap_vld" }} , 
 	{ "name": "h_size", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "h_size", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "15", "23", "24", "25"],
		"CDFG" : "gru_step",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "3", "EstimateLatencyMax" : "-1",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"IsBlackBox" : "0",
		"Port" : [
			{"Name" : "x", "Type" : "None", "Direction" : "I"},
			{"Name" : "h_prev", "Type" : "None", "Direction" : "I"},
			{"Name" : "w_ih", "Type" : "None", "Direction" : "I"},
			{"Name" : "w_hh", "Type" : "None", "Direction" : "I"},
			{"Name" : "b_ih", "Type" : "None", "Direction" : "I"},
			{"Name" : "b_hh", "Type" : "None", "Direction" : "I"},
			{"Name" : "mult_gx", "Type" : "None", "Direction" : "I"},
			{"Name" : "shift_gx", "Type" : "None", "Direction" : "I"},
			{"Name" : "mult_gh", "Type" : "None", "Direction" : "I"},
			{"Name" : "shift_gh", "Type" : "None", "Direction" : "I"},
			{"Name" : "h_out", "Type" : "Vld", "Direction" : "O"},
			{"Name" : "h_size", "Type" : "None", "Direction" : "I"},
			{"Name" : "MGR1_SIGMOID_LUT", "Type" : "Memory", "Direction" : "I",
				"SubConnect" : [
					{"ID" : "7", "SubInstance" : "grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177", "Port" : "MGR1_SIGMOID_LUT", "Inst_start_state" : "5", "Inst_end_state" : "6"}]},
			{"Name" : "MGR1_TANH_LUT", "Type" : "Memory", "Direction" : "I",
				"SubConnect" : [
					{"ID" : "7", "SubInstance" : "grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177", "Port" : "MGR1_TANH_LUT", "Inst_start_state" : "5", "Inst_end_state" : "6"}]}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.a_ar_U", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.u_ar_U", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.z_U", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.n_U", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Outline_VITIS_LOOP_43_1_fu_163", "Parent" : "0",
		"CDFG" : "gru_step_Outline_VITIS_LOOP_43_1",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "2", "EstimateLatencyMax" : "-1",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"IsBlackBox" : "0",
		"Port" : [
			{"Name" : "empty", "Type" : "None", "Direction" : "I"},
			{"Name" : "a_ar", "Type" : "Memory", "Direction" : "O"},
			{"Name" : "add_ln43", "Type" : "None", "Direction" : "I"}],
		"Loop" : [
			{"Name" : "VITIS_LOOP_43_1", "PipelineType" : "no",
				"LoopDec" : {"FSMBitwidth" : "2", "FirstState" : "ap_ST_fsm_state2", "LastState" : ["ap_ST_fsm_state2"], "QuitState" : ["ap_ST_fsm_state2"], "PreState" : ["ap_ST_fsm_state1"], "PostState" : ["ap_ST_fsm_state1"], "OneDepthLoop" : "1", "OneStateBlock": "ap_ST_fsm_state2_blk"}}]},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Outline_VITIS_LOOP_52_3_fu_170", "Parent" : "0",
		"CDFG" : "gru_step_Outline_VITIS_LOOP_52_3",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1", "real_start" : "0",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "2", "EstimateLatencyMax" : "512",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"IsBlackBox" : "0",
		"Port" : [
			{"Name" : "empty", "Type" : "None", "Direction" : "I"},
			{"Name" : "u_ar", "Type" : "Memory", "Direction" : "O"},
			{"Name" : "add_ln58", "Type" : "None", "Direction" : "I"}],
		"Loop" : [
			{"Name" : "VITIS_LOOP_52_3", "PipelineType" : "no",
				"LoopDec" : {"FSMBitwidth" : "2", "FirstState" : "ap_ST_fsm_state2", "LastState" : ["ap_ST_fsm_state2"], "QuitState" : ["ap_ST_fsm_state2"], "PreState" : ["ap_ST_fsm_state1"], "PostState" : ["ap_ST_fsm_state1"], "OneDepthLoop" : "1", "OneStateBlock": "ap_ST_fsm_state2_blk"}}]},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177", "Parent" : "0", "Child" : ["8", "9", "10", "11", "12", "13", "14"],
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
	{"ID" : "8", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.MGR1_SIGMOID_LUT_U", "Parent" : "7"},
	{"ID" : "9", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.MGR1_TANH_LUT_U", "Parent" : "7"},
	{"ID" : "10", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.mul_33s_32s_64_1_1_U7", "Parent" : "7"},
	{"ID" : "11", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.mul_33s_32s_64_1_1_U8", "Parent" : "7"},
	{"ID" : "12", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.srem_64ns_64ns_64_68_1_U9", "Parent" : "7"},
	{"ID" : "13", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.srem_64ns_64ns_64_68_1_U10", "Parent" : "7"},
	{"ID" : "14", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_61_5_fu_177.flow_control_loop_pipe_sequential_init_U", "Parent" : "7"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197", "Parent" : "0", "Child" : ["16", "17", "18", "19", "20", "21", "22"],
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
	{"ID" : "16", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.mul_15ns_32s_47_1_1_U27", "Parent" : "15"},
	{"ID" : "17", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.mul_31s_33ns_63_1_1_U28", "Parent" : "15"},
	{"ID" : "18", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.mul_47s_49ns_95_1_1_U29", "Parent" : "15"},
	{"ID" : "19", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.srem_47s_16ns_47_51_1_U30", "Parent" : "15"},
	{"ID" : "20", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.mul_16s_15ns_31_1_1_U31", "Parent" : "15"},
	{"ID" : "21", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.srem_31s_16ns_31_35_1_U32", "Parent" : "15"},
	{"ID" : "22", "Level" : "2", "Path" : "`AUTOTB_DUT_INST.grp_gru_step_Pipeline_VITIS_LOOP_76_6_fu_197.flow_control_loop_pipe_sequential_init_U", "Parent" : "15"},
	{"ID" : "23", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_19s_32s_32_1_1_U44", "Parent" : "0"},
	{"ID" : "24", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_31ns_8s_32_1_1_U45", "Parent" : "0"},
	{"ID" : "25", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.mul_32s_32s_32_1_1_U46", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	gru_step {
		x {Type I LastRead 2 FirstWrite -1}
		h_prev {Type I LastRead 1 FirstWrite -1}
		w_ih {Type I LastRead 1 FirstWrite -1}
		w_hh {Type I LastRead 1 FirstWrite -1}
		b_ih {Type I LastRead 2 FirstWrite -1}
		b_hh {Type I LastRead 2 FirstWrite -1}
		mult_gx {Type I LastRead 1 FirstWrite -1}
		shift_gx {Type I LastRead 1 FirstWrite -1}
		mult_gh {Type I LastRead -1 FirstWrite -1}
		shift_gh {Type I LastRead -1 FirstWrite -1}
		h_out {Type O LastRead -1 FirstWrite 8}
		h_size {Type I LastRead 0 FirstWrite -1}
		MGR1_SIGMOID_LUT {Type I LastRead -1 FirstWrite -1}
		MGR1_TANH_LUT {Type I LastRead -1 FirstWrite -1}}
	gru_step_Outline_VITIS_LOOP_43_1 {
		empty {Type I LastRead 0 FirstWrite -1}
		a_ar {Type O LastRead -1 FirstWrite 1}
		add_ln43 {Type I LastRead 0 FirstWrite -1}}
	gru_step_Outline_VITIS_LOOP_52_3 {
		empty {Type I LastRead 0 FirstWrite -1}
		u_ar {Type O LastRead -1 FirstWrite 1}
		add_ln58 {Type I LastRead 0 FirstWrite -1}}
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
		MGR1_TANH_LUT {Type I LastRead -1 FirstWrite -1}}
	gru_step_Pipeline_VITIS_LOOP_76_6 {
		empty {Type I LastRead 0 FirstWrite -1}
		z {Type I LastRead 0 FirstWrite -1}
		sext_ln76 {Type I LastRead 0 FirstWrite -1}
		n {Type I LastRead 16 FirstWrite -1}
		retval_0_i_phi_out {Type O LastRead -1 FirstWrite 52}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "3", "Max" : "-1"}
	, {"Name" : "Interval", "Min" : "4", "Max" : "0"}
]}

set PipelineEnableSignalInfo {[
]}

set Spec2ImplPortList { 
	x { ap_none {  { x in_data 0 32 } } }
	h_prev { ap_none {  { h_prev in_data 0 32 } } }
	w_ih { ap_none {  { w_ih in_data 0 8 } } }
	w_hh { ap_none {  { w_hh in_data 0 8 } } }
	b_ih { ap_none {  { b_ih in_data 0 32 } } }
	b_hh { ap_none {  { b_hh in_data 0 32 } } }
	mult_gx { ap_none {  { mult_gx in_data 0 32 } } }
	shift_gx { ap_none {  { shift_gx in_data 0 32 } } }
	mult_gh { ap_none {  { mult_gh in_data 0 32 } } }
	shift_gh { ap_none {  { shift_gh in_data 0 32 } } }
	h_out { ap_vld {  { h_out out_data 1 32 }  { h_out_ap_vld out_vld 1 1 } } }
	h_size { ap_none {  { h_size in_data 0 32 } } }
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
