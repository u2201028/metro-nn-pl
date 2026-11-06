# 9a. Per-layer unroll plan (latency-first, generated)

Source of truth: `tools/worksheet.py conv_layers()` + the DSP budget
(2496 packed INT8 MACs/cycle). Pixels-in-flight U caps each
engine near 20% of the array so several engines co-reside; the
row-token dataflow of docs/09 section 3 consumes this table.

| node | cin | cout | kxk | s | U | MACs/cycle at U |
| :---- | ----: | ----: | ----: | ----: | ----: | ----: |
| stem | 3 | 32 | 3x3 | 2 | 8 | 216 |
| c16_0_depthwise | 32 | 32 | 3x3 | 1 | 8 | 2,304 |
| c16_0_project | 32 | 16 | 1x1 | 1 | 8 | 256 |
| c24_0_expand | 16 | 96 | 1x1 | 1 | 8 | 128 |
| c24_0_depthwise | 96 | 96 | 3x3 | 2 | 2 | 1,728 |
| c24_0_project | 96 | 24 | 1x1 | 1 | 8 | 768 |
| c24_1_expand | 24 | 144 | 1x1 | 1 | 8 | 192 |
| c24_1_depthwise | 144 | 144 | 3x3 | 1 | 1 | 1,296 |
| c24_1_project | 144 | 24 | 1x1 | 1 | 8 | 1,152 |
| c32_0_expand | 24 | 144 | 1x1 | 1 | 8 | 192 |
| c32_0_depthwise | 144 | 144 | 3x3 | 2 | 1 | 1,296 |
| c32_0_project | 144 | 32 | 1x1 | 1 | 8 | 1,152 |
| c32_1_expand | 32 | 192 | 1x1 | 1 | 8 | 256 |
| c32_1_depthwise | 192 | 192 | 3x3 | 1 | 1 | 1,728 |
| c32_1_project | 192 | 32 | 1x1 | 1 | 8 | 1,536 |
| c32_2_expand | 32 | 192 | 1x1 | 1 | 8 | 256 |
| c32_2_depthwise | 192 | 192 | 3x3 | 1 | 1 | 1,728 |
| c32_2_project | 192 | 32 | 1x1 | 1 | 8 | 1,536 |
| c64_0_expand | 32 | 192 | 1x1 | 1 | 8 | 256 |
| c64_0_depthwise | 192 | 192 | 3x3 | 2 | 1 | 1,728 |
| c64_0_project | 192 | 64 | 1x1 | 1 | 8 | 1,536 |
| c64_1_expand | 64 | 384 | 1x1 | 1 | 8 | 512 |
| c64_1_depthwise | 384 | 384 | 3x3 | 1 | 1 | 3,456 |
| c64_1_project | 384 | 64 | 1x1 | 1 | 6 | 2,304 |
| c64_2_expand | 64 | 384 | 1x1 | 1 | 8 | 512 |
| c64_2_depthwise | 384 | 384 | 3x3 | 1 | 1 | 3,456 |
| c64_2_project | 384 | 64 | 1x1 | 1 | 6 | 2,304 |
| c64_3_expand | 64 | 384 | 1x1 | 1 | 8 | 512 |
| c64_3_depthwise | 384 | 384 | 3x3 | 1 | 1 | 3,456 |
| c64_3_project | 384 | 64 | 1x1 | 1 | 6 | 2,304 |
| c96_0_expand | 64 | 384 | 1x1 | 1 | 8 | 512 |
| c96_0_depthwise | 384 | 384 | 3x3 | 1 | 1 | 3,456 |
| c96_0_project | 384 | 96 | 1x1 | 1 | 6 | 2,304 |
| c96_1_expand | 96 | 576 | 1x1 | 1 | 8 | 768 |
| c96_1_depthwise | 576 | 576 | 3x3 | 1 | 1 | 5,184 |
| c96_1_project | 576 | 96 | 1x1 | 1 | 4 | 2,304 |
| c96_2_expand | 96 | 576 | 1x1 | 1 | 8 | 768 |
| c96_2_depthwise | 576 | 576 | 3x3 | 1 | 1 | 5,184 |
| c96_2_project | 576 | 96 | 1x1 | 1 | 4 | 2,304 |
| c160_0_expand | 96 | 576 | 1x1 | 1 | 8 | 768 |
| c160_0_depthwise | 576 | 576 | 3x3 | 2 | 1 | 5,184 |
| c160_0_project | 576 | 160 | 1x1 | 1 | 4 | 2,304 |
| c160_1_expand | 160 | 960 | 1x1 | 1 | 8 | 1,280 |
| c160_1_depthwise | 960 | 960 | 3x3 | 1 | 1 | 8,640 |
| c160_1_project | 960 | 160 | 1x1 | 1 | 2 | 1,920 |
| c160_2_expand | 160 | 960 | 1x1 | 1 | 8 | 1,280 |
| c160_2_depthwise | 960 | 960 | 3x3 | 1 | 1 | 8,640 |
| c160_2_project | 960 | 160 | 1x1 | 1 | 2 | 1,920 |
| c320_0_expand | 160 | 960 | 1x1 | 1 | 8 | 1,280 |
| c320_0_depthwise | 960 | 960 | 3x3 | 1 | 1 | 8,640 |
| c320_0_project | 960 | 320 | 1x1 | 1 | 2 | 1,920 |
| final_1x1 | 320 | 1280 | 1x1 | 1 | 7 | 2,240 |

Regenerate: `python3 tools/gen_unroll_plan.py` (never hand-edit).
