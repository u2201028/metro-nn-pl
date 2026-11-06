set SynModuleInfo {
  {SRCNAME gru_step_Outline_VITIS_LOOP_43_1 MODELNAME gru_step_Outline_VITIS_LOOP_43_1 RTLNAME gru_step_gru_step_Outline_VITIS_LOOP_43_1}
  {SRCNAME gru_step_Outline_VITIS_LOOP_52_3 MODELNAME gru_step_Outline_VITIS_LOOP_52_3 RTLNAME gru_step_gru_step_Outline_VITIS_LOOP_52_3}
  {SRCNAME gru_step_Pipeline_VITIS_LOOP_61_5 MODELNAME gru_step_Pipeline_VITIS_LOOP_61_5 RTLNAME gru_step_gru_step_Pipeline_VITIS_LOOP_61_5
    SUBMODULES {
      {MODELNAME gru_step_mul_33s_32s_64_1_1 RTLNAME gru_step_mul_33s_32s_64_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_srem_64ns_64ns_64_68_1 RTLNAME gru_step_srem_64ns_64ns_64_68_1 BINDTYPE op TYPE srem IMPL auto LATENCY 67 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_gru_step_Pipeline_VITIS_LOOP_61_5_MGR1_SIGMOID_LUT_ROM_AUTO_1R RTLNAME gru_step_gru_step_Pipeline_VITIS_LOOP_61_5_MGR1_SIGMOID_LUT_ROM_AUTO_1R BINDTYPE storage TYPE rom IMPL auto LATENCY 2 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_gru_step_Pipeline_VITIS_LOOP_61_5_MGR1_TANH_LUT_ROM_AUTO_1R RTLNAME gru_step_gru_step_Pipeline_VITIS_LOOP_61_5_MGR1_TANH_LUT_ROM_AUTO_1R BINDTYPE storage TYPE rom IMPL auto LATENCY 2 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_flow_control_loop_pipe_sequential_init RTLNAME gru_step_flow_control_loop_pipe_sequential_init BINDTYPE interface TYPE internal_upc_flow_control INSTNAME gru_step_flow_control_loop_pipe_sequential_init_U}
    }
  }
  {SRCNAME gru_step_Pipeline_VITIS_LOOP_76_6 MODELNAME gru_step_Pipeline_VITIS_LOOP_76_6 RTLNAME gru_step_gru_step_Pipeline_VITIS_LOOP_76_6
    SUBMODULES {
      {MODELNAME gru_step_mul_15ns_32s_47_1_1 RTLNAME gru_step_mul_15ns_32s_47_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_mul_31s_33ns_63_1_1 RTLNAME gru_step_mul_31s_33ns_63_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_mul_47s_49ns_95_1_1 RTLNAME gru_step_mul_47s_49ns_95_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_srem_47s_16ns_47_51_1 RTLNAME gru_step_srem_47s_16ns_47_51_1 BINDTYPE op TYPE srem IMPL auto LATENCY 50 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_mul_16s_15ns_31_1_1 RTLNAME gru_step_mul_16s_15ns_31_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_srem_31s_16ns_31_35_1 RTLNAME gru_step_srem_31s_16ns_31_35_1 BINDTYPE op TYPE srem IMPL auto LATENCY 34 ALLOW_PRAGMA 1}
    }
  }
  {SRCNAME gru_step MODELNAME gru_step RTLNAME gru_step IS_TOP 1
    SUBMODULES {
      {MODELNAME gru_step_mul_19s_32s_32_1_1 RTLNAME gru_step_mul_19s_32s_32_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_mul_31ns_8s_32_1_1 RTLNAME gru_step_mul_31ns_8s_32_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_mul_32s_32s_32_1_1 RTLNAME gru_step_mul_32s_32s_32_1_1 BINDTYPE op TYPE mul IMPL auto LATENCY 0 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_a_ar_RAM_AUTO_1R1W RTLNAME gru_step_a_ar_RAM_AUTO_1R1W BINDTYPE storage TYPE ram IMPL auto LATENCY 2 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_z_RAM_AUTO_1R1W RTLNAME gru_step_z_RAM_AUTO_1R1W BINDTYPE storage TYPE ram IMPL auto LATENCY 2 ALLOW_PRAGMA 1}
      {MODELNAME gru_step_n_RAM_AUTO_1R1W RTLNAME gru_step_n_RAM_AUTO_1R1W BINDTYPE storage TYPE ram IMPL auto LATENCY 2 ALLOW_PRAGMA 1}
    }
  }
}
