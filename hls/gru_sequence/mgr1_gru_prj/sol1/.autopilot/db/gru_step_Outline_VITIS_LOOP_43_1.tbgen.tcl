set moduleName gru_step_Outline_VITIS_LOOP_43_1
set isTopModule 0
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
set C_modelName {gru_step_Outline_VITIS_LOOP_43_1}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict a_ar { MEM_WIDTH 32 MEM_SIZE 1536 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
set C_modelArgList {
	{ empty int 31 regular  }
	{ a_ar int 32 regular {array 384 { 0 3 } 0 1 }  }
	{ add_ln43 int 32 regular  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "empty", "interface" : "wire", "bitwidth" : 31, "direction" : "READONLY"} , 
 	{ "Name" : "a_ar", "interface" : "memory", "bitwidth" : 32, "direction" : "WRITEONLY"} , 
 	{ "Name" : "add_ln43", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} ]}
# RTL Port declarations: 
set portNum 12
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ empty sc_in sc_lv 31 signal 0 } 
	{ a_ar_address0 sc_out sc_lv 9 signal 1 } 
	{ a_ar_ce0 sc_out sc_logic 1 signal 1 } 
	{ a_ar_we0 sc_out sc_logic 1 signal 1 } 
	{ a_ar_d0 sc_out sc_lv 32 signal 1 } 
	{ add_ln43 sc_in sc_lv 32 signal 2 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "empty", "direction": "in", "datatype": "sc_lv", "bitwidth":31, "type": "signal", "bundle":{"name": "empty", "role": "default" }} , 
 	{ "name": "a_ar_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "a_ar", "role": "address0" }} , 
 	{ "name": "a_ar_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "a_ar", "role": "ce0" }} , 
 	{ "name": "a_ar_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "a_ar", "role": "we0" }} , 
 	{ "name": "a_ar_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "a_ar", "role": "d0" }} , 
 	{ "name": "add_ln43", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "add_ln43", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "",
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
				"LoopDec" : {"FSMBitwidth" : "2", "FirstState" : "ap_ST_fsm_state2", "LastState" : ["ap_ST_fsm_state2"], "QuitState" : ["ap_ST_fsm_state2"], "PreState" : ["ap_ST_fsm_state1"], "PostState" : ["ap_ST_fsm_state1"], "OneDepthLoop" : "1", "OneStateBlock": "ap_ST_fsm_state2_blk"}}]}]}


set ArgLastReadFirstWriteLatency {
	gru_step_Outline_VITIS_LOOP_43_1 {
		empty {Type I LastRead 0 FirstWrite -1}
		a_ar {Type O LastRead -1 FirstWrite 1}
		add_ln43 {Type I LastRead 0 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "2", "Max" : "-1"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "-1"}
]}

set PipelineEnableSignalInfo {[
]}

set Spec2ImplPortList { 
	empty { ap_none {  { empty in_data 0 31 } } }
	a_ar { ap_memory {  { a_ar_address0 mem_address 1 9 }  { a_ar_ce0 mem_ce 1 1 }  { a_ar_we0 mem_we 1 1 }  { a_ar_d0 mem_din 1 32 } } }
	add_ln43 { ap_none {  { add_ln43 in_data 0 32 } } }
}
