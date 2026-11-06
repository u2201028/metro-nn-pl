# Memory and budget worksheet (generated)

Source of truth: `tools/worksheet.py`.  Regenerate with
`python3 tools/gen_docs.py`.

## Device budget (K26 / xck26-sfvc784-2LV-c)

| Resource | Available | Notes |
| :---- | :---- | :---- |
| BRAM36 | 144 blocks / 663,552 B | 36 KiB each |
| URAM | 64 blocks / 2,359,296 B | 288 KiB each |
| DSP | 1248 | INT8 MAC capable |
| LUT | 117,120 | |

## Per-layer conv worksheet (reference graph, INT8)

| Layer | Kind | Cin | Cout | K | Stride | Weights B | MACs/frame |
| :---- | :---- | ----: | ----: | ----: | ----: | ----: | ----: |
| stem | conv3x3 | 3 | 32 | 3 | 2 | 864 | 10838016 |
| c16_0_depthwise | dw3x3 | 32 | 32 | 3 | 1 | 288 | 3612672 |
| c16_0_project | conv1x1 | 32 | 16 | 1 | 1 | 512 | 6422528 |
| c24_0_expand | conv1x1 | 16 | 96 | 1 | 1 | 1536 | 19267584 |
| c24_0_depthwise | dw3x3 | 96 | 96 | 3 | 2 | 864 | 2709504 |
| c24_0_project | conv1x1 | 96 | 24 | 1 | 1 | 2304 | 7225344 |
| c24_1_expand | conv1x1 | 24 | 144 | 1 | 1 | 3456 | 10838016 |
| c24_1_depthwise | dw3x3 | 144 | 144 | 3 | 1 | 1296 | 4064256 |
| c24_1_project | conv1x1 | 144 | 24 | 1 | 1 | 3456 | 10838016 |
| c32_0_expand | conv1x1 | 24 | 144 | 1 | 1 | 3456 | 10838016 |
| c32_0_depthwise | dw3x3 | 144 | 144 | 3 | 2 | 1296 | 1016064 |
| c32_0_project | conv1x1 | 144 | 32 | 1 | 1 | 4608 | 3612672 |
| c32_1_expand | conv1x1 | 32 | 192 | 1 | 1 | 6144 | 4816896 |
| c32_1_depthwise | dw3x3 | 192 | 192 | 3 | 1 | 1728 | 1354752 |
| c32_1_project | conv1x1 | 192 | 32 | 1 | 1 | 6144 | 4816896 |
| c32_2_expand | conv1x1 | 32 | 192 | 1 | 1 | 6144 | 4816896 |
| c32_2_depthwise | dw3x3 | 192 | 192 | 3 | 1 | 1728 | 1354752 |
| c32_2_project | conv1x1 | 192 | 32 | 1 | 1 | 6144 | 4816896 |
| c64_0_expand | conv1x1 | 32 | 192 | 1 | 1 | 6144 | 4816896 |
| c64_0_depthwise | dw3x3 | 192 | 192 | 3 | 2 | 1728 | 338688 |
| c64_0_project | conv1x1 | 192 | 64 | 1 | 1 | 12288 | 2408448 |
| c64_1_expand | conv1x1 | 64 | 384 | 1 | 1 | 24576 | 4816896 |
| c64_1_depthwise | dw3x3 | 384 | 384 | 3 | 1 | 3456 | 677376 |
| c64_1_project | conv1x1 | 384 | 64 | 1 | 1 | 24576 | 4816896 |
| c64_2_expand | conv1x1 | 64 | 384 | 1 | 1 | 24576 | 4816896 |
| c64_2_depthwise | dw3x3 | 384 | 384 | 3 | 1 | 3456 | 677376 |
| c64_2_project | conv1x1 | 384 | 64 | 1 | 1 | 24576 | 4816896 |
| c64_3_expand | conv1x1 | 64 | 384 | 1 | 1 | 24576 | 4816896 |
| c64_3_depthwise | dw3x3 | 384 | 384 | 3 | 1 | 3456 | 677376 |
| c64_3_project | conv1x1 | 384 | 64 | 1 | 1 | 24576 | 4816896 |
| c96_0_expand | conv1x1 | 64 | 384 | 1 | 1 | 24576 | 4816896 |
| c96_0_depthwise | dw3x3 | 384 | 384 | 3 | 1 | 3456 | 677376 |
| c96_0_project | conv1x1 | 384 | 96 | 1 | 1 | 36864 | 7225344 |
| c96_1_expand | conv1x1 | 96 | 576 | 1 | 1 | 55296 | 10838016 |
| c96_1_depthwise | dw3x3 | 576 | 576 | 3 | 1 | 5184 | 1016064 |
| c96_1_project | conv1x1 | 576 | 96 | 1 | 1 | 55296 | 10838016 |
| c96_2_expand | conv1x1 | 96 | 576 | 1 | 1 | 55296 | 10838016 |
| c96_2_depthwise | dw3x3 | 576 | 576 | 3 | 1 | 5184 | 1016064 |
| c96_2_project | conv1x1 | 576 | 96 | 1 | 1 | 55296 | 10838016 |
| c160_0_expand | conv1x1 | 96 | 576 | 1 | 1 | 55296 | 10838016 |
| c160_0_depthwise | dw3x3 | 576 | 576 | 3 | 2 | 5184 | 254016 |
| c160_0_project | conv1x1 | 576 | 160 | 1 | 1 | 92160 | 4515840 |
| c160_1_expand | conv1x1 | 160 | 960 | 1 | 1 | 153600 | 7526400 |
| c160_1_depthwise | dw3x3 | 960 | 960 | 3 | 1 | 8640 | 423360 |
| c160_1_project | conv1x1 | 960 | 160 | 1 | 1 | 153600 | 7526400 |
| c160_2_expand | conv1x1 | 160 | 960 | 1 | 1 | 153600 | 7526400 |
| c160_2_depthwise | dw3x3 | 960 | 960 | 3 | 1 | 8640 | 423360 |
| c160_2_project | conv1x1 | 960 | 160 | 1 | 1 | 153600 | 7526400 |
| c320_0_expand | conv1x1 | 160 | 960 | 1 | 1 | 153600 | 7526400 |
| c320_0_depthwise | dw3x3 | 960 | 960 | 3 | 1 | 8640 | 423360 |
| c320_0_project | conv1x1 | 960 | 320 | 1 | 1 | 307200 | 15052800 |
| final_1x1 | conv1x1 | 320 | 1280 | 1 | 1 | 409600 | 20070400 |

Layer totals: 2,189,760 weight bytes,
299,494,272 MACs per frame.

## GRU accounting

| Quantity | Value |
| :---- | ----: |
| GRU weights (3 x 128 x 1408) | 540,672 B |
| Dense 32-frame window | 17,301,504 MACs |
| Cached 32-frame window | 2,064,384 MACs |
| Dense/cached ratio | 8.38x |
| Model-wide MACs (conv + dense GRU) | 316,795,776 |
| Cached share of model | 4.8% |

## Traffic worksheet (25 FPS, one stream)

| Tensor | Bytes/frame | MB/s at 25 FPS |
| :---- | ----: | ----: |
| Input frame 224x224x3 | 150,528 | 3.76 |
| Embedding 1280 INT8 | 1,280 | 0.03 |
| Pooled feature write+read | 2,560 | 0.06 |
