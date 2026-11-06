set SynModuleInfo {
  {SRCNAME conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6 MODELNAME conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6 RTLNAME conv2d_int8_conv2d_int8_Pipeline_VITIS_LOOP_36_4_VITIS_LOOP_37_5_VITIS_LOOP_38_6
    SUBMODULES {
      {MODELNAME conv2d_int8_mul_33s_8s_41_1_1 RTLNAME conv2d_int8_mul_33s_8s_41_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME conv2d_int8_flow_control_loop_pipe_sequential_init RTLNAME conv2d_int8_flow_control_loop_pipe_sequential_init BINDTYPE interface TYPE internal_upc_flow_control INSTNAME conv2d_int8_flow_control_loop_pipe_sequential_init_U}
    }
  }
  {SRCNAME conv2d_int8 MODELNAME conv2d_int8 RTLNAME conv2d_int8 IS_TOP 1
    SUBMODULES {
      {MODELNAME conv2d_int8_mul_31ns_31ns_62_1_1 RTLNAME conv2d_int8_mul_31ns_31ns_62_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME conv2d_int8_mul_31ns_62ns_93_1_1 RTLNAME conv2d_int8_mul_31ns_62ns_93_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME conv2d_int8_mul_64s_32s_64_1_1 RTLNAME conv2d_int8_mul_64s_32s_64_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME conv2d_int8_sdiv_32ns_32s_32_36_seq_1 RTLNAME conv2d_int8_sdiv_32ns_32s_32_36_seq_1 BINDTYPE op TYPE sdiv IMPL auto_seq LATENCY 35 ALLOW_PRAGMA 1}
      {MODELNAME conv2d_int8_srem_64ns_64ns_64_68_seq_1 RTLNAME conv2d_int8_srem_64ns_64ns_64_68_seq_1 BINDTYPE op TYPE srem IMPL auto_seq LATENCY 67 ALLOW_PRAGMA 1}
    }
  }
}
