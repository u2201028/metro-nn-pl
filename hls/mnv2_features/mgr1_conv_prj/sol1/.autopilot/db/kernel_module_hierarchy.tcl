set ModuleHierarchy {[{
"Name" : "conv2d_int8","ID" : "0","Type" : "sequential",
"SubLoops" : [
	{"Name" : "VITIS_LOOP_32_1","ID" : "1","Type" : "no",
	"SubLoops" : [
	{"Name" : "VITIS_LOOP_33_2","ID" : "2","Type" : "no",
		"SubLoops" : [
		{"Name" : "VITIS_LOOP_34_3","ID" : "3","Type" : "no",
			"SubInsts" : [
			{"Name" : "grp_conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6_fu_271","ID" : "4","Type" : "sequential",
					"SubLoops" : [
					{"Name" : "VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6","ID" : "5","Type" : "pipeline"},]},]},]},]},]
}]}