# MobileNetV2 \+ GRU on Kria KV260

## Mixed SystemVerilog and Vitis HLS IP engineering roadmap • KV260 / Vivado / PYNQ • revised 5 November 2026

# 1\. What the first release must do

A KV260 receives one live camera stream, runs the complete neural network in programmable logic (PL), and emits a timestamped fight score and an alert suitable for operator review. The processing system (PS) owns capture, decoding, preprocessing, device control, logging and the alert policy. Start with repeatable recorded footage, then USB, then RTSP with independent capture timestamps. Keep the same inference API for all three.

Build a fresh ImageNet-pretrained MobileNetV2 teacher, a one-layer unidirectional GRU and a binary classifier. No existing checkpoint or ZCU104 result is assumed authoritative. The first hardware target is the same trained graph after validated quantization. Explore smaller students only after the reference is frozen. Keep public benchmark results separate from performance on held-out metro footage.

Use the following explicit working point to make the engineering decisions reproducible. It is a proposed baseline, open to revision before freezing the model: 224 × 224 RGB, width multiplier 1.0, 1,280 pooled features per frame, hidden size 128, one output logit, batch 1, 32 uniformly sampled frames per window, stride 1, zero initial hidden state per window. Start the feasibility study at 25 analyzed frames/s for one stream. Negotiate an actual source mode and train at the selected sampling rate.

Accept three deliverables independently. First qualify the reusable CNN and GRU packages against their arithmetic and interface contracts in clean consumer designs. Then qualify a complete integrated KV260 overlay and headless pilot. Production deployment requires a production K26 SOM and carrier, application-specific system qualification and representative field evidence. AMD documents the starter kit’s intended evaluation use \[1, 2\].

## How to use this roadmap

Start with Phases 0–5 and the workload worksheet before fixing lane counts or RTL boundaries. Use the IP catalogue and diagrams in Section 4 to assign ownership. Freeze the interface and numerical contracts in Sections 11–12 before the public packages diverge. Use the verification matrix in Section 13 and the two release checklists in Section 14 when deciding whether a build may ship.

A successful first demonstration has three independently inspectable results: one real frame produces the expected embedding, an independent embedding trace produces the expected sequence scores, and the combined overlay reproduces those scores after cold boot. A throughput claim additionally requires a physical board run with the complete capture-to-publication path active.

## Research decisions and time budget

Evidence cut-off for this revision is 5 November 2026\. The reference workload is still the trained MobileNetV2, exact zero-initialized 32-frame windows and one KV260 camera stream. Sort proposals into three tracks. The release track contains transformations that are bit-equivalent at every public integer boundary. The model track contains changes requiring a new trained or calibrated profile. The watchlist contains ideas whose workload or device differs too much to spend a full implementation run on them yet.

Apply research in dependency order. In weeks 5–8 freeze the cost model and quality budgets. In weeks 9–18 reproduce one fused bottleneck and one temporal microbenchmark. In weeks 19–23 route both public and integrated configurations. In weeks 24–27 compare viable builds on the physical board. Track experimental time separately within those bands. Fund one model-changing experiment at a time from the optimization allowance. If it needs a new dataset, overhaul of the ABI or extra board weeks, record a separate estimate before promoting it.

For every paper-derived claim keep a record of source, publication status, measured device, graph and input size, arithmetic, batch/window policy, measured or simulated boundary, and the decision it informs. Retain blanks for undisclosed details and record which assumptions invalidate transfer to K26. A paper can establish feasibility of an isolated block. Report a KV260 speedup only from a matched KV260 measurement.

# 2\. The workload and memory worksheet

The following counts are derived for the working point. Count a multiply–accumulate as one MAC. Count only convolution and dense matrix products unless stated. Regenerate the ledger from the final graph and report all excluded operations. MAC counts omit pooling, gates, bias adds, rescaling, loop overhead, data movement and stalls.

Standard MobileNetV2 has a stride-2 stem followed by bottleneck groups with expansion, output channels, repeats and first-block stride (t,c,n,s) of (1,16,1,1), (6,24,2,2), (6,32,3,2), (6,64,4,2), (6,96,3,1), (6,160,3,2), (6,320,1,1). The last 1 × 1 convolution maps 320 to 1,280 channels. Global average pooling yields one embedding. Freeze the padding convention, the no-expansion first block, the locations of ReLU6, the linear projections and the permitted identity additions in the exported reference \[3, 4\].

Derive convolution weight count as K² × Cin × Cout / groups and MACs as Hout × Wout × weight count. With the ImageNet classifier removed, the convolution kernels occupy 2,189,760 bytes at INT8 and cost 299,494,272 MACs per frame. The GRU matrices add 3H(I+H) \= 540,672 INT8 bytes for I=1,280 and H=128. The combined 2,730,432 bytes exclude every bias, scale, classifier weight and buffer. The single-logit classifier adds 128 weights, one bias and 128 MACs per score.

The K26 has 144 × 36 Kibit BRAM, 64 × 288 Kibit UltraRAM, 1,248 DSP slices and 117,120 LUTs. Nominal combined BRAM \+ UltraRAM capacity is 3,022,848 bytes. This calculation includes physical parity-width bits and assumes ideal packing. The convolution and GRU matrices already occupy 90.3% of that ideal capacity. The remaining 292,416 bytes must compete with bias and rescale tables, ports, bank replication, temporal state, FIFOs, activation tiles and the platform. BRAM and URAM have different ports and shapes. Account for each separately \[1\].

For scale, one early 112 × 112 × 96 INT8 expanded feature map occupies 1,204,224 bytes. A plan retaining all baseline weights and materializing that whole tensor in BRAM/URAM fails the capacity test. Fusing expansion, depthwise and projection across a spatial tile or a stream is therefore worth testing immediately. Keep its external tensor and rounding behavior identical. Report the physically allocated blocks as well as the logical bytes.

An exact 32-frame classifier predicts from the most recent 32 sampled frames. At 25 Hz their first-to-last timestamp span is 31/25 \= 1.24 s. This is a startup context requirement. The deadline between completed steady-state predictions at stride 1 is 40 ms. One can meet the update interval while still delivering late scores from a growing capture queue. Timestamp ingress, preprocessing, dispatch, PL completion, score publication and alert publication separately.

## Stage-level sizing worksheet

Each repeat group below includes its first block at the group’s configured stride. Counts cover convolution weights and matrix MACs only. Tensors are listed height × width × channels. Recompute them from the exported trained graph before design freeze. Use the rows to choose a high-compute case, a high-storage case and a tail case for synthesis.

**Worksheet 1 · MobileNetV2 convolution groups at 224 × 224**

| Group | Output tensor | INT8 weights, B | MACs/frame |
| :---- | :---- | :---- | :---- |
| Stem | 112×112×32 | 864 | 10,838,016 |
| c16 × 1 | 112×112×16 | 800 | 10,035,200 |
| c24 × 2 | 56×56×24 | 12,912 | 54,942,720 |
| c32 × 3 | 28×28×32 | 37,392 | 37,443,840 |
| c64 × 4 | 14×14×64 | 177,984 | 38,497,536 |
| c96 × 3 | 14×14×96 | 296,448 | 58,103,808 |
| c160 × 3 | 7×7×160 | 784,320 | 46,560,192 |
| c320 × 1 | 7×7×320 | 469,440 | 23,002,560 |
| Final 1×1 | 7×7×1280 | 409,600 | 20,070,400 |
| All convolution groups | Pooled to 1,280 | 2,189,760 | 299,494,272 |

The c24 and c96 groups have similar arithmetic demand despite different resolution and channel counts. A PE organization that performs well on one can stall or waste lanes on the other. The c160 group stores 784,320 weight bytes, more than the first four bottleneck groups together. Give the memory planner separate objectives for physical capacity, bytes transferred per frame and ports consumed per cycle.

## Worked mapping experiment for the first stride-2 bottleneck

Consider the first c24 block alone. It expands 112×112×16 to 112×112×96, applies stride-2 3×3 depthwise convolution, then projects 56×56×96 to 56×56×24. The matrix MAC counts are 19,267,584 for expansion, 2,709,504 for depthwise and 7,225,344 for projection, or 29,202,432 total. The early expansion is about 66% of these MACs. This is a good test of a shared pointwise engine as well as a three-stage pipeline. The next c24 block has a residual and a different traffic pattern; test both \[3, 4, 6, 40\].

At INT8 two materialized intermediate tensors occupy 1,204,224 and 301,056 bytes. Writing and rereading both once costs 3,010,560 bytes/frame, about 75.26 MB/s at 25 FPS, for this one block. This is the intermediate traffic a fully streaming schedule can potentially remove. Keep input and output transfers, weight fetches, halo rereads and any partial-sum traffic in the full budget. If the baseline already holds one tensor on chip, reduce the saving accordingly.

First reproduce the unfused result with explicit stage outputs. Then stream expansion to depthwise while leaving projection unchanged. Finally stream into projection and compare the integer result after each natural quantization point. Keep the same input, clock target, weight residence, finite FIFO limits and arithmetic in all three runs. Attribute any change in traffic or cycles to the edge that was removed. A folded implementation may need local storage to reconcile channel-tile order even when it eliminates the full feature map.

Use Roofline and Timeloop-style mapping analysis to price spatial tiling, temporal reuse, reduction order and memory levels. For each candidate report a useful-compute ceiling, a measured DDR ceiling and a bank-port ceiling. If a core needs 16 distinct weights from a bank per cycle and the selected legal layout delivers four, DDR bandwidth alone cannot predict its throughput. Replace nominal bandwidth with traces from simultaneous reads and writes. Fit parameters on one set of layers, predict a different layer and compare to its measured cycles before trusting the model \[21, 22\].

Eyeriss v2 is an ASIC reference for adapting data delivery to layer reuse. Borrow the choice between broadcast, local reuse and point-to-point delivery. On K26, test a registered broadcast of one activation tile across output-channel lanes and separate channel-local windows for depthwise. Record fanout, inserted registers, useful transfers per cycle and routing slack. Include the cost of the multicast network in the routed candidate. ASIC energy per access and frequency do not transfer directly \[23\].

# 3\. An exact temporal optimization worth building

Start with a deliberately simple reference. Compute and store one CNN embedding per accepted frame. For each full window, reset h to zero, read the embeddings oldest to newest, run all 32 GRU steps and score the last state. Adjacent windows share 31 embeddings. They generally have different hidden histories, even over the frames they share.

For a PyTorch-style GRU, write a \= W\_ih x \+ b\_ih and u \= W\_hh h\_prev \+ b\_hh. In gate order reset, update, new: r \= sigmoid(a\_r \+ u\_r), z \= sigmoid(a\_z \+ u\_z), n \= tanh(a\_n \+ r ⊙ u\_n), h \= (1−z) ⊙ n \+ z ⊙ h\_prev. The reset gate multiplies the candidate recurrent affine result, including its recurrent bias. Export the actual gate order, framework variant and bias placement. Preserve the specified arithmetic order at rounding boundaries \[5\].

A second exact schedule computes the three input-side affine projections once when a new frame arrives. Store them in a 32-slot chronological ring. Whenever a window is due, start from zero and replay the recurrent side for the 32 cached entries. Use the same fixed input scale, bias convention and intermediate width as the uncached reference. Verify equality at every timestep, on ring wrap and after reset. If a quantizer derives its scale from the current window, reusing projections requires a new equivalence analysis.

At I=1,280 and H=128, one input projection costs 491,520 MACs and one recurrent projection 49,152. Replaying both sides over 32 frames costs 17,301,504 matrix MACs per score. With the input contribution cached at stride 1, the steady-state cost per update becomes 491,520 \+ 32 × 49,152 \= 2,064,384. A ring of 32 × 384 INT32 values needs 49,152 bytes, or 48 KiB. An alternative INT8 embedding ring is 40 KiB. The release can keep one or the other once equivalence and diagnostic needs are resolved.

This reduces the GRU matrix work by about 8.38×. The model-wide reduction is about 4.8% of convolution-plus-GRU matrix MACs against the embedding-only baseline. Measure any speed benefit. If the CNN, video decode or DDR owns the critical path, the end-to-end difference may be smaller. Invalidation keys include camera identity, stream epoch, model hash, preprocessing version and the specified gap policy.

Add CNN and optimized GRU costs to get 301,558,656 MACs per steady frame before the tiny classifier. At 25 frames/s the arithmetic demand is about 7.54 GMAC/s. At an illustrative 150 MHz this requires just over 50 useful MACs per clock sustained across the whole design. A 128-lane design would need about 39.3% sustained useful utilization under this simplified model. Lane count is a design variable and is independent of how many DSPs HLS ultimately uses.

## Sequence replay, freshness and stream policy

Use an accepted-sample counter and a camera epoch. A slot is readable only when its tag matches the expected sequence, epoch and model generation. Publish the new slot atomically after all three gate projections have arrived. If replay and input preparation overlap, reserve the slot until the oldest outstanding reader releases it, or serialize the next input. Start with serialization and demonstrate that it meets the deadline before adding a second context.

A queue drop at 25 Hz changes the temporal sampling of a model trained at 25 Hz. Define a tolerance in time units from the training protocol. Preserve ordinary timestamp jitter within that tolerance and flag a discontinuity outside it. Start a new epoch on a large gap, device reconnect, source switch or model commit. Keep separate counters for intentionally unsampled frames, dropped required samples, invalid windows and accepted samples. When the source only supplies 20 FPS, report its observed rate and run an independently paced 25 Hz replay to isolate accelerator capacity.

Projection cache storage scales with independent streams. Four active 32-slot INT32 rings consume 192 KiB, eight use 384 KiB, before metadata or scratch. Eight rings already exceed the 292,416 bytes of nominal BRAM/URAM left after the baseline matrices. Revisit placement, the accepted precision or sharing of time-limited contexts before promising a camera count. Carry sequence state separately even when camera jobs share the same arithmetic lanes.

## Temporal engine experiments with exact and approximate boundaries

Exact alternative A removes the redundant first recurrent matrix product of each zero-initialized window. At H=128 this saves 3×128² \= 49,152 matrix MACs per score against a dense schedule that actually computes the first product. Preserve the recurrent biases, including the candidate bias inside the reset multiplication. Apply the shortcut to quantized real zero only when the oracle proves equivalence after zero-point compensation. Test nonzero biases, asymmetric zero points and start-of-window saturation. If the existing scheduler already suppresses these cycles, record zero incremental benefit.

Exact alternative B interleaves independent windows or camera contexts to fill otherwise idle affine lanes. Tag every partial sum with its context and timestep. Publish contexts in the permitted order and bound their waiting time. At stride one a newly started window has no precomputed final hidden state. Interleaving can change utilization and latency but does not remove its recurrent dependencies. Benchmark a single camera first; extra delayed contexts can improve aggregate throughput while violating the first stream’s p99 deadline.

Approximate alternative C uses EdgeDRNN-style thresholded changes. Instrument per-coordinate differences in quantized embeddings and hidden states across real quiet scenes, busy platforms, camera cuts and fights. Count sparse indices, emitted values and weight traffic along with saved multiplications. Delta updates with a positive threshold change the function. Start each window and epoch from the declared reference state; train or calibrate a distinct profile, validate rapid motion and measure worst-case dense activity. Exit early if sparse dispatch saves less time than its index traffic, or if onset sensitivity falls outside the validation gate \[25\].

Approximate alternative D constrains recurrent or input-affine weights to signed powers of two. The February 2026 2QGRU work offers an FPGA precedent for shift-based GRU weights; its phoneme task differs from this camera application. Compare dense INT8, recurrent-only power-of-two and all-affine power-of-two variants. Define zero code, sign/exponent range, alignment, accumulation and saturation. Route the shifters and reduction tree. Report DSPs released, added LUT/routing cost, cycles per window and camera-level quality. A multiplier saving only matters if it unlocks a constrained system resource \[26\].

# 4\. Architecture to prototype

Build two public IPs, mnv2\_features and gru\_sequence, plus a reference block design and an optimized integrated build called metro\_accel. Each public IP has its own control wrapper, package, tests, model slice and integration example. The CNN exports an embedding tensor. The GRU accepts compatible embeddings independently of their origin. Use SystemVerilog for predictable control and stream behavior and Vitis HLS C++ for arithmetic where it wins the measured trade-off. Keep PS submissions at frame granularity.

The spatial engine should support signed quantized data, 3 × 3 standard stem, grouped depthwise convolution, stride 1 or 2, exact padding, channel tails and border masks. A line-buffered depthwise engine consumes channel vectors and forms spatial windows. The pointwise engine tiles input channels, output channels and pixels, keeps partial sums across input tiles and requantizes only after the full reduction. Keep a bounded residual path with token alignment for equal shapes and stride 1\. The final projection inside a bottleneck stays linear.

Evaluate three implementations on identical vectors. A reusable tiled design shares engines and is easiest to fit, at the cost of additional tensor traffic. A hybrid design streams selected expansion–depthwise–projection groups and reuses engines elsewhere. A deeply streamed representative prefix provides a throughput and resource comparison before anyone attempts a whole-network pipeline. Use the same graph, precision, clock constraints, shell and traffic definition in comparisons. Hybrid FPGA work such as FiBHA provides a relevant architectural comparison \[6\].

For the first complete prototype, preserve the full model and allow explicitly listed weight tiles to be fetched from DDR when banked on-chip allocation fails. Keep the temporal ring and small recurrent state local where feasible, and stream or tile the largest expansions. If activation spills are necessary, record each tensor, byte count and lifetime. In parallel on paper, price a strict on-chip version with smaller hidden size, width multiplier or a trained projection/student. A smaller input image reduces activation and MAC costs but usually leaves convolution weight sizes unchanged. Re-extract all actual shapes for each candidate.

Budget concurrency explicitly. Double-buffer only data whose transfer can cover useful compute. The per-tile lower bound with overlap is max(compute time, transfer time), plus fill/drain and uncovered dependencies. Without overlap the terms add. Count repeated reads induced by the schedule, partial-sum spills, halos, bursts and padding. Measure effective DDR bandwidth under simultaneous camera and CPU traffic. Use the measured result to select ports, burst widths and tile sizes.

## Public IP catalogue and implementation ownership

**IP catalogue · Public packages and internal implementation units**

| Unit / delivery | Owns | Initial implementation and acceptance |
| :---- | :---- | :---- |
| mnv2\_features / public | Packed INT8 frame → pooled embedding; weights, dimensions, quantization profile | HLS stem, depthwise, pointwise and pooling; SV packet/control shell. Standalone replay checks all features. |
| gru\_sequence / public | Embedding → exact-window state, binary head and status; per-stream context | HLS affine and gate arithmetic; SV ring, tags and job control. Isolated replay checks each state and score. |
| metro\_accel / integrated | Frame → tagged completion; admission, arbitration, shared resource scheduling | SV shell around reusable datapaths. Exact cross-build match before comparing performance. |
| tile\_mac / internal | P×Q dot products, partial sums and finalization | HLS baseline. SV variant for the measured limit. Check tails, widened arithmetic and equal output. |
| dw\_window and residual / internal | Stride, halo, spatial taps, skip alignment and backpressure | HLS line-buffer baseline; SV window or elastic join if a measured port/scheduling limit justifies it. |
| quant\_ops / internal | Scale conversion, saturation, gate functions and output encode | One numeric spec, independent software oracle, generated constants. Verify every rounding seam. |
| stream\_ctrl / internal | AXI-Lite, packet parser, watchdog, queues and counters | Hand-written SV with reusable simulation agents. Test stalls, invalid lengths, reset and terminal status. |
| Platform IP / vendor | AXI DMA, SmartConnect, clock/reset and optional debug | Use supported platform IP with pinned configurations; measure overhead in both whole designs. |

Publish three parameter classes. Build-time limits include stream beat width, MAC lanes, tile shape, bank layout, maximum I/H/T and maximum live streams. Model-load settings include layer descriptors, actual supported I/H, tensor scales, weights and classifier labels. Per-stream settings include epoch/reset, a supported sampling and window profile, and diagnostics. Qualify the first model at I=1,280, H=128 and T=32. Advertise shorter windows or different channel counts only when both the engine and the loaded trained profile support them. Include boundary tests at 1, maximum, maximum \+ 1 and an incompatible but in-range value.

Each standalone package owns its own legal configuration checks and works when the other IP is absent. A reference block design connects them with the public embedding packet. The optimized metro\_accel build can keep an internal vector channel, use private quantization metadata and share an affine engine. It must produce identical public results at the declared integer boundaries and model configuration. Use a build-time switch to export the embedding for diagnostics and quantify that switch’s resource and timing cost.

**Diagram 1 · Data ownership and the two hardware routes**

| Boundary | Modular reference route | Optimized integrated route |
| :---- | :---- | :---- |
| PS → PL | Camera / replay → PYNQ → DMA frame | Same frame, timestamp map and ABI |
| CNN stage ↓ | Frame shell → MobileNetV2 → public embedding | Ingress → tiled or fused bottlenecks → pooled vector |
| Feature boundary ↓ | Framed AXI stream → independent GRU port | Private local channel → GRU input projection |
| Temporal stage ↓ | Window replay → head → completion | Local ring → replay → head → completion |
| PL → PS | DMA result → driver → alert policy | Same tagged result → same service |
| Memory branch ↔ | Separate placement and counters per package | Optional shared MAC / weight buffers; meter every DDR master |

Diagram 1 reads from top to bottom. Each lane is an ownership boundary. The reference traversal proves portability; the integrated traversal measures the benefit of fusion. In both cases the DDR accounting includes the PS frame buffer, model preload and any explicitly permitted inference-time traffic as separate totals.

## CNN datapath design

Derive the HLS loop structure from memory ports. Start with output-stationary tiles of P output channels × Q input channels for a pointwise convolution. A P=8, Q=16 tile consumes 128 INT8 weights per issue and 16 activation values broadcast across those eight outputs, before any spatial reuse. Specify the bank-to-lane mapping and registered read latency before applying unroll directives. At 150 MHz, supplying 128 fresh bytes every cycle would require 19.2 GB/s locally. Reuse weight tiles over pixels and compare the local requirement with measured external traffic.

For the early c24 block, run the expansion at the original spatial resolution, retain enough previous rows to produce the required depthwise neighborhood, then project at the reduced resolution. Model line startup, right/bottom padding, stride phase, tile halos and tail lanes. Skip data may need its own buffer if consumer ordering changes during fusion. Define the tile contract in global coordinates, then run an impulse at each image corner and on each internal tile edge. Neighboring output tiles must agree bit-for-bit with the full-image integer reference.

For later wide layers, evaluate weight-stationary scheduling over multiple output pixels against output-stationary accumulation. Count a partial-sum spill at its true width. Spilling a 32-bit accumulator and rereading it moves eight bytes per element, which can dominate the INT8 output. Emit rescaled INT8 only once the channel reduction is complete. Place a registered join at the skip connection and verify that both branches carry the same tile, pixel and channel identity.

## A cycle schedule for the first stride-2 c24 block

Use this worked schedule as the first design-review fixture. Its purpose is to expose port conflicts and rate mismatches before committing to HLS pragmas or RTL pipeline stages. It covers one block, unit batch, fixed row-major scan, INT8 working data, no dilation, symmetric one-pixel zero padding, preloaded local weights and no downstream stalls. Time starts at the first expansion issue. The expansion and projection have separate 8-output × 16-input MAC arrays. The depthwise unit evaluates nine taps for eight channels per valid window. Pipeline delays below are design assumptions that must be replaced by measured values.

For input coordinate (y,x) issue expansion group g at edge 12×(112y+x)+g, for g=0…11. Each issue broadcasts the 16 input channels and computes eight expanded channels. Reuse the same input pixel across its 12 issues. Admit a new input pixel only with adequate downstream credit. Expansion emits the group four edges later. On that edge issue the row-store read; on the next edge combine the returned rows with delayed current data and the horizontal taps. Assume a further four edges to produce the depthwise dot product, rounding and clamp, giving a nominal depthwise output at issue+9 for a valid window.

Output coordinate (v,u) is centered on input (2v,2u). Its final physical sample is (2v+1,2u+1). Supply the upper/left pad via masks at the first edges. At 112 input pixels with this stride and padding, the last required lower-right sample is (111,111). Check global coordinates on edge tiles because locally restarting the stride phase shifts the output while preserving its shape. Twelve 8-channel depthwise groups form one 96-channel pixel. Pack adjacent groups into six 16-channel input words for projection.

**Cycle worksheet · First output pixel and successive projection issues**

Allocate two local depthwise-output pixel slots. While projection drains one, the next valid pixel can fill the other. For input fold k=0…5 issue output group u=0…2 at local cycle 3k+u. Keep three 8-wide partial accumulators. Read the next input word once per three issues and broadcast it across output groups. This schedule needs a safe accumulator feedback distance of three issues. A longer adder association requires forwarding, interleaved pixel contexts or a slower issue rate; prove identical integer arithmetic and price added storage. Final-group output latency here is four edges from issue. This permits a shorter internal feedback path with a separate final requantization stage.

The expansion requires 150,528 issue cycles per block, depthwise produces 37,632 eight-channel valid windows, and projection requires 56,448 issues. A shared pointwise array requires at least 206,976 expansion-plus-projection issues before stalls or context changes. With independent engines the last nominal result appears at edge 150,558 in the worked trace. Record that as a calculated single-block schedule. Full camera performance also pays for other blocks, refill, control, backpressure and all clock-domain boundaries. Use this pair of schedules to decide whether another pointwise array earns its DSP and routing cost.

Extend the fixture to the following stride-1 residual block separately. Tag the identity branch with pixel and channel-group indices at the fork. Measure the lead over the projected branch through fill, steady state and drain. At the join consume both arms atomically, in matching order. For each stall regression include the first valid output, an interior output, the last output in a row and the final packet beat. Reject a schedule that can duplicate a skip token when just one fork output is ready.

## Choosing an RTL boundary

Keep the first depthwise or pointwise candidate functionally identical in two implementations. The HLS version owns loops, fixed widths, banking directives and FIFO interfaces; the SystemVerilog candidate owns the valid pipeline, lane enables and ready/valid stalls explicitly. The test harness sends the same packed tiles with the same memory latency, bus widths, clock constraint and backpressure. Record latency to first output, cycles per full tile, achieved II, Fmax evidence at the chosen constraint, DSP/BRAM/URAM/LUT/FF and validation effort.

Repeat the winner inside the routed system. A faster OOC kernel may consume an extra RAM port, create a high-fanout enable or force a width converter on the actual path. Retain a hand-written datapath only if it passes numerical, transport and maintainability gates and improves an active system bottleneck. Use a versioned package or generated constants for shared numeric metadata. Keep behavioral code in SystemVerilog; UG1118 2025.2 requires a thin Verilog or VHDL top-level wrapper when packaging an SV top \[14\].

## What to transfer from recent FPGA research

Use the 2025 MobileNetV2 bottleneck study to scope a block-level replication, and the October 2026 IEEE sparse MobileNetV1 work to test whether depthwise/pointwise load imbalance is worth addressing. The latter reports a ZCU104 implementation that couples chaining and computation-aware pruning. KV260 has a different resource envelope, and MobileNetV2 adds an expansion, linear projection and optional skip. Reproduce the dense schedule first and preserve ReLU6, branch summation and rescale locations. A fused schedule with those semantics can qualify for the exact track. Algebraic reordering across an activation or a changed pruning mask enters model qualification \[24, 40\].

Collect per-stage active, empty-input, full-output and arbitration-wait cycles. For a pipeline with concurrent independent stages the slowest steady stage can bound the interval. For a shared pointwise engine, expansion and projection consume cycles from the same budget. Charge both. Rebalance parallelism using valid outputs per cycle, then measure the next bottleneck. Verify a speedup persists for both stride-2 and residual stride-1 blocks. A stage-specific utilization gain with unchanged tile interval gives little reason to expand the design.

Keep learned logic on the watchlist. The September 2026 DiffLUT-Net preprint trains FPGA-native truth tables and connectivity from scratch. Its mapping assumptions differ from a reloadable MobileNetV2+GRU. The narrow trial is a distilled, replaceable head if measured head cost warrants it. Charge retraining, model-update granularity and any bitstream rebuild. Do not promote it to the baseline from an isolated logic or latency figure \[30\].

# 5\. Execution plan and exit criteria

Each phase ends in evidence another engineer can reproduce. The effort bands in Section 9 assume one developer and overlap only where dependencies permit.

## Phase 0 • Freeze the product contract and evidence policy

Write a one-page acceptance record defining the classes, analyzed rate, score stride, latency boundaries, drop policy, model scope and who reviews alerts. Distinguish clip classification, event detection and a human-confirmed incident. Specify how to handle buffering after a camera reconnect, a large time gap and an interrupted model load. Use one camera for the required milestone and 4–8 feeds as a separate capacity experiment.

Create one result row per configuration, tool version, clock, model hash, workload, evidence level and run ID. Evidence levels are calculated, C simulation, RTL co-simulation, routed timing, physical-board replay, live camera and field evaluation. Exit when the team can classify every target and every future claim against this record.

## Phase 1 • Qualify the host, board and PYNQ path

Select a single installed Vivado/Vitis HLS release family and exact patches. Use 2025.2.x as the initial candidate if that is what is available. Record the HLS compiler build, Vivado build, XSim, OS, board files, KV260 board preset, resolved device part, board revision and clock constraints. Read the device part from a validated KV260 project and reuse that exact value for HLS. Keep Windows FPGA-tool scripts and WSL training scripts reproducible independently.

On the board, inventory boot firmware, Ubuntu image, kernel, Python, PYNQ package and the Kria overlay-loading path. The Xilinx Kria-PYNQ repository documents installation on a supported Ubuntu image and notes firmware compatibility. Pin a tested combination. Run the board’s reference overlay, then a custom register scratchpad and a DMA loopback with odd packet sizes and one full input frame. Record the metadata and device-tree or firmware requirements of the selected loading mechanism \[7\].

Exit with a clean-build-to-board smoke test, repeatable after cold boot. If no physical board is available, proceed on host phases and mark board qualification pending. Reserve board access before the first end-to-end HLS build.

## Phase 2 • Build the data and event evaluation protocol

Define visible fighting and relevant normal activities before labeling. Include difficult negatives such as crowd surges, running, hugging, boarding and camera shake. Record source, camera or proxy, scene, original file, time span, FPS/timebase, label and rights to use the footage. Deduplicate before sampling. Assign original videos, related clips and cameras to groups before making training and evaluation windows. Keep uncertain camera provenance in a separate evaluation stratum.

Use real videos for accuracy and event evaluation. Use artificial data only for deterministic arithmetic and interface verification. Maintain independent training, validation, calibration and locked-test roles. For source overlap or very similar viewpoints, document the resulting generalization limit. Include long background recordings and continuous sessions with annotated event onset/offset. Short trimmed action clips alone do not establish false alarms per camera-hour or realistic event latency.

Specify alert matching, onset tolerance, duplicate-alert suppression and handling of overlapping incidents before the final run. Report precision, recall and F1 at clip level, event recall, false alerts per negative camera-hour, event delay, sample counts and camera/site breakdowns. Fix operating thresholds on validation data. Exit with versioned split manifests, duplication checks and independently reviewable event annotations.

## Phase 3 • Train and freeze the floating-point teacher

Reuse an ImageNet-pretrained MobileNetV2. Remove the ImageNet classifier, retain the last convolution and global pooling, and apply the backbone separately to each sampled frame. Initialize the GRU and binary head unless a compatible validated checkpoint is supplied. Train the temporal head on frozen features first. Then fine-tune selected backbone stages and temporal layers together using the real sequence protocol. Invalidate saved embeddings whenever preprocessing or backbone weights change.

Use the same crop policy, color order, normalization, uniform temporal sampling and gap behavior in training and deployment. Apply spatial augmentation consistently across frames where required. Log seeds, exact dependencies, data split hash, optimizer schedule, early stopping, threshold selection and calibration. On limited GPU memory use cached embeddings for head-only training and short microbatches with accumulation for fine-tuning. Evaluate one-frame and shuffled-time controls to see whether the GRU contributes temporal information.

Exit with an immutable checkpoint, frozen preprocessing, graph and tensor manifest, held-out accuracy, example score timelines, and a small real-video replay set with expected vectors. Record explicitly whether the network consumes real-time sampled windows or clips resampled over their full duration. Fix any discrepancy before generating hardware vectors.

## Phase 4 • Establish the integer contract

Build an independent bit-accurate software reference before using HLS fast paths. Fold inference-mode batch normalization into convolution weights and biases. Start with symmetric INT8 weights per output channel and a calibrated per-tensor activation format. Document zero points, bias scale, intermediate widths, multiplier and shift order, rounding ties, saturation, padding value and residual branch scale alignment. Padding that represents real zero must use the corresponding quantized zero point. Use widened intermediates for requantization and residual addition \[8\].

For every dot product bound the worst-case sum by reduction length × maximum centered activation × maximum weight, plus bias. Check the selected accumulator at every stage, including the requantization product and global-average division. Keep an INT32 accumulator where the bound permits. Start GRU weights at INT8 and evaluate INT8 versus wider hidden and gate formats, including the effect on the recurrent multiplier width; use separate budgets for gate accuracy and downstream alert behavior. Check fixed-point representations of zero, one and the gate limits.

Sweep sigmoid/tanh implementation against a high-precision reference, including saturation tails, symmetry, zero and threshold-sensitive sequences. For recurrent paths measure step-wise hidden error, full-window logits, label flips and event metrics. Try better calibration, targeted higher precision or quantization-aware fine-tuning before shrinking the model. Require hardware and the frozen integer oracle to match exactly at declared integer boundaries. Use separately agreed tolerances between float and integer models. Exit with approved vectors for every operator, numerical format tables and an accuracy comparison.

## Phase 5 • Size the memory and run two decisive microbenchmarks

Generate one row per tensor with shape, element size, lifetime, physical banks, ports, replication, tile extent, halo and DDR read/write multiplicity. Generate a per-layer ledger for MACs, shape tails, achievable issue rate, bytes moved, required bandwidth and cycles. Compute BRAM36 and URAM occupancy using bank width/depth, then compare against inferred primitives. Check the peak simultaneously live allocation at a specific point in the schedule.

Synthesize one high-resolution stride-2 expansion/depthwise/projection path and one later high-channel residual path. Exercise realistic shapes, scales, skips and traffic in both. In parallel with model work, derive the GRU replay versus cached projection comparison using the same sequence. Select the design based on timed results, useful MACs/clock, bank conflicts, memory use and output equality. Exit with a concrete memory map, on-chip fit verdict and explicit DDR policy.

## Phase 5B • Research replication before architecture freeze

Select a common stride-2 c24 block, a stride-1 block with a skip and the dense temporal reference. For each, deliver a golden trace, one measured or simulated baseline, a predicted bottleneck and the single parameter to vary next. Reproduce one paper-derived idea at matched precision with a self-checking harness. At the review, either authorize a routed experiment or record why the predicted system effect is too small. Preserve all required original phase gates.

## Phase 5C • Trace reference implementations to an executable comparison

Freeze a commit before opening the source, and keep the full SHA, path and file-specific notices with the experiment. The four examples below were inspected at the linked revisions. Their test and build behavior is source evidence. Running their vendor toolchains, reproducing their results and qualifying our KV260 designs are subsequent project milestones. Treat examples as independent comparison fixtures so a common error in imported code and its test cannot silently become the project oracle.

FINN HLS library · folded CNN arithmetic. In the pinned Xilinx tree, [convlayer.h](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/convlayer.h) connects window generation to a matrix/vector operator, and [mvau.hpp](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/mvau.hpp) buffers input folds for reuse across output folds. The depthwise example in [tb/conv\_dws\_top.cpp](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/tb/conv_dws_top.cpp) converts channel packing before window generation and invokes the vector/vector unit in [vvau.hpp](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/vvau.hpp). Follow the tensor order into [tb/conv\_dws\_tb.cpp](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/tb/conv_dws_tb.cpp), where the test unpacks and checks channels. The build recipe [tb/test\_conv\_dws.tcl](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/tb/test_conv_dws.tcl) selects xczu3eg-sbva484-1-i and a 5 ns constraint, then runs C simulation, synthesis and co-simulation. Treat that constraint as a requested clock on a different device. Use this chain to compare PE/SIMD folding, input reuse and explicit adapters; rederive padding, stride and saturation for MobileNetV2. The root [LICENSE](https://github.com/Xilinx/finn-hlslib/blob/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a/LICENSE) gives BSD three-clause terms \[41\].

EdgeDRNN · sparse recurrent control and exact transport testing. In the August 2026 revision, trace a changed input through [hdl/ieu.sv](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/hdl/ieu.sv), its memory/update interfaces in [hdl/edgedrnn.sv](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/hdl/edgedrnn.sv), the controller [hdl/hpc.sv](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/hdl/hpc.sv) and the arithmetic lane [hdl/hpe.sv](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/hdl/hpe.sv). A nonzero change causes weight-column work; a count of skipped scalar values is insufficient to predict bandwidth. The repository documents a MiniZed integration. [verification/rtl/tb/edgedrnn\_tb.sv](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/verification/rtl/tb/edgedrnn_tb.sv) compares responses and packet ends under controlled stalls. [verification/rtl/scripts/run\_xsim.sh](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/verification/rtl/scripts/run_xsim.sh) provides an XSim entry point, and [verification/rtl/README.md](https://github.com/SensorsINI/EdgeDRNN/blob/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c/verification/rtl/README.md) documents the pass marker and fixtures. Use its stimulus → scoreboard pattern to exercise the dense exact baseline before testing a delta variant. GitHub reported no detected repository license; no root license file was present in the pinned tree. Keep this a design-study reference and implement the project RTL independently \[42\].

hls4ml · dense GRU comparator. In release v1.2.0, [hls4ml/templates/vivado/nnet\_utils/nnet\_recurrent.h](https://github.com/fastmachinelearning/hls4ml/blob/b493ea7fd282ed969e250a94a0738f29f144ac7e/hls4ml/templates/vivado/nnet_utils/nnet_recurrent.h) computes input and recurrent dense transforms and selects gate indexing using its configuration. Follow the generated weights and recurrent bias into the candidate gate before assuming framework equivalence. [test/pytest/test\_recurrent\_pytorch.py](https://github.com/fastmachinelearning/hls4ml/blob/b493ea7fd282ed969e250a94a0738f29f144ac7e/test/pytest/test_recurrent_pytorch.py) includes parallel and streamed conversion tests and compares predictions with a tolerance. [hls4ml/templates/vitis/build\_prj.tcl](https://github.com/fastmachinelearning/hls4ml/blob/b493ea7fd282ed969e250a94a0738f29f144ac7e/hls4ml/templates/vitis/build_prj.tcl) gets the part from the generated configuration and controls vendor flow stages. The repository covers multiple backends and its root [LICENSE](https://github.com/fastmachinelearning/hls4ml/blob/b493ea7fd282ed969e250a94a0738f29f144ac7e/LICENSE) is Apache-2.0. Use this as an independent floating/fixed-point comparator on small shapes. Require exact gate, hidden-state and completion vectors against our own integer model for release. Log the actual selected device, precision, tools and conversion warnings for any reproduction \[43\].

verilog-axis · the cost of registering READY. [rtl/axis\_register.v](https://github.com/alexforencich/verilog-axis/blob/48ff7a7e2ef782cf778d47910cf85835c64b1bce/rtl/axis_register.v) offers bypass, simple-register and skid-buffer choices. In the skid path identify the normal output register and temporary register. Trace the cycle that retains a beat after downstream READY falls. [tb/axis\_register/test\_axis\_register.py](https://github.com/alexforencich/verilog-axis/blob/48ff7a7e2ef782cf778d47910cf85835c64b1bce/tb/axis_register/test_axis_register.py) exercises separate source-idle and sink-backpressure generators; the test recipe is [tb/axis\_register/Makefile](https://github.com/alexforencich/verilog-axis/blob/48ff7a7e2ef782cf778d47910cf85835c64b1bce/tb/axis_register/Makefile). This is portable RTL, with no KV260 timing result implied by the example. The repository is deprecated at this pin and the root [COPYING](https://github.com/alexforencich/verilog-axis/blob/48ff7a7e2ef782cf778d47910cf85835c64b1bce/COPYING) gives MIT terms. Use it as a fixed comparison for elastic behavior; write the production checks as SV assertions and XSim scoreboards in the supported project flow \[44\].

Exit with a four-row ledger that records read, reproduced, retargeted and board-measured as distinct evidence levels. A clean-room implementation should identify the architectural property being compared, its own code owner, and a test that distinguishes an incorrectly functioning implementation. A dependency proposed for redistribution also needs the actual file list and license/notice review.

## Phase 6 • Build the HLS arithmetic kernels and SystemVerilog transport

Implement small bit-accurate operators first: unpack/pack, dot-product reduction, requantization, clamp/ReLU6, identity addition, pooling and gate arithmetic. Use fixed-width ap\_int/ap\_uint and an explicit overflow contract. Keep a scalar reference outside the optimized HLS kernel. Ensure division by the actual pooling area and consistent round/saturate conventions.

Implement the stem, depthwise, pointwise expansion/projection, residual path and final pooling. Use a banked local weight tile and lanes selected jointly with memory ports. Pipeline the active compute loop and unroll only what the banks can feed. Test stride-2 boundary alignment; a one-pixel shift can survive shape checks and still ruin accuracy. Use tagged diagnostic tensors to identify the first mismatching op.

Implement GRU affine kernels and vector nonlinearities; then add chronological buffering, replay and input-projection caching. Include cold start, first full window, wrap, repeated frames, large gaps, camera switches and model reload. Exit when C simulation matches the integer oracle for full real frames and complete windows. Save one small deterministic failing vector automatically for any mismatch.

## Phase 6A • Sign off the transport RTL independently

Develop a one-clock ready/valid pipeline register or skid buffer, packet framing/checking, control/status registers and completion accounting. Build a queue reference model in the SV testbench. Randomize gaps in VALID, READY stalls at the first/middle/final beat, reset after header acceptance and repeated packets without bubbles. Record the seed and smallest failing trace. Advance counters only on accepted transfers. Hold the entire outgoing payload and qualifiers stable until accepted.

Review reset scope separately for fabric control, model validity, per-camera history and performance counters. Reset small validity and pointer state directly. Invalidate uninitialized RAM contents using valid bits, tags or a bounded initialization sequence. Check that no invalid RAM word can influence an output after reset. If a second clock is needed, explicitly declare the clock relationship, use a verified crossing primitive or handshake, release reset in each destination domain, and examine the CDC report and constraints.

Exit with a portable synthesizable shell, a list of allowed resets and a measured maximum throughput in the no-stall case. HLS arithmetic can be replaced by a traffic generator while this milestone is tested.

## Phase 6B • Schedule the dense temporal transaction

Freeze a second, independently executable cycle model for gru\_sequence. Use H=128, I=1,280, T=32 and an illustrative shared P=8, Q=16 affine engine. Use row order \[r,z,n\] after exporter normalization. The three gates span 384 rows or 48 output groups. Issue input-channel tile k outermost and output group u=0…47 innermost; a partial sum for the same output group is revisited after 48 issues. On the last input tile, add the correct affine bias once and write each output-group result into its gate bank. Expose the rounding boundary of this store in the numeric manifest.

For each new embedding the input projection needs 80×48 \= 3,840 issues once. Allow four edges of terminal drain before using the newly filled ring slot. For each replay step the recurrent projection requires eight input tiles and 48 output groups, or 384 issues. Old h and new h occupy separate banks until an entire step commits. A gate vector contains eight hidden channels. Read the input and recurrent contributions for r,z,n for that vector together, calculate the gates, apply reset to the recurrent candidate including its bias, then compute the new state using the old h. Keep the classifier outside this cycle budget.

**Cycle worksheet · One GRU timestep, relative to its first recurrent issue**

Let the next timestep begin only after all 16 hidden vectors commit. With the table assumptions a timestep consumes 412 cycles and the dense sequence of 32 steps consumes 13,184 cycles. The fresh input projection and its drain bring the total to 17,028 cycles per steady-state update, or 113.52 μs at an assumed 150 MHz. This is a local scheduling example with resident weights and a ready sink. It is neither a routed latency result nor an end-to-end inference time. Keep the dense first step for the baseline; the exact zero-state shortcut described earlier must be timed and equivalence-checked separately.

Add explicit wait states for an occupied ring slot, a shared MAC owner, a missing weight tile and a stalled completion. Each wait owns a counter and changes measured latency. Stalls freeze every associated tag, valid bit and write enable consistently. A model reload drains or explicitly fails outstanding requests and invalidates incompatible cached projections. A reset during the final hidden write must not produce a valid score from partially committed state.

Exit with a per-edge trace for a tiny model (for example I=4,H=2,T=3, padded to legal lane widths), a full-size analytical trace and an XSim scoreboard for issued group IDs, RAM accesses, hidden bank swaps and published status. Check threshold-sensitive real sequences independently of the cycle model; arithmetic or data shared between predictor and DUT can conceal a common defect.

## Phase 7 • Integrate two public IPs and a frame-level accelerator

Use a versioned AXI4-Lite shell with a frame-level command and AXI4-Stream packets. The reference overlay instantiates both public IPs. The optimized integrated variant can fuse internal interfaces and arbitrate a shared array while retaining externally observable semantics. Emit one completion per accepted request in normal operation, including a warm-up completion when appropriate. For permitted DDR reads or spills, use a bounded AXI master and an explicit manifest. Direct memory input is a measured variant.

Define a versioned model package with magic, ABI, model ID/hash, dimensions, layer descriptors, quantization tables, bounds, packed offsets and integrity check. At load time validate opcode, length, alignment, tensor dimensions, offset+length overflow and each region’s capacity. Load a candidate only while idle, mark valid after the last successful check, and keep failed/incomplete loads unlaunchable. A single-bank design can recover by reloading the previous verified model.

Group commands into discovery, model load/commit, stream configuration, submit, status, reset and diagnostics. Carry model generation, stream epoch and sequence through each completion. Define busy writes, interrupt acknowledgement, reset scope, sticky errors, watchdog behavior and atomic multiword counters. Generate public CSR definitions for RTL, C and Python from a single schema and check the Vivado HWH metadata. Treat generated HLS control maps as private to the wrapper. Let the loaded model and advertised capability limits jointly determine legal shapes.

Exit with a frozen protocol, byte-exact packet examples and negative tests. Include a supported malformed-packet recovery path: a missing terminal beat may require an external watchdog and reset of both DMA and IP. A software timeout alone cannot release a stalled PL dataflow pipeline.

## Phase 7A • Prove the two packages can be consumed independently

Create a clean Vivado example containing the CNN package, a playback source and an embedding sink; no GRU dependency may be required. Run a real frame through 224×224×3 ingress and compare all 1,280 output values to the model export. Repeat with backpressure and a model reload. Resolve all include files, relative XDC scopes, file groups, generated products and versioned dependencies from the package itself.

Create a second clean example containing the GRU and a saved embedding producer. Test 31 warm-up completions, the first valid score at sample 32, a wrap, a rejected numeric profile and a discontinuity. For a different CNN, first verify embedding dimension, channel order, scale and semantic compatibility with its trained temporal head. Matching wire formats allow integration; quality with a different feature extractor requires matched training and evaluation.

Exit when a second developer can instantiate each public IP using only its package, integration note and vectors, and when a compatible CNN/GRU model pair passes an independent composition test.

## Phase 8 • Qualify HLS and RTL through their respective tool flows

Create a version-controlled HLS configuration with target Vivado IP flow, exact part, clock and uncertainty, top function, source files and testbench vectors. Run the requested gates: C simulation; C synthesis; C/RTL co-simulation with XSim; out-of-context implementation; package the release IP for the Vivado IP catalog. Let the installed tool generate any intermediate package its implementation step needs. Freeze the final IP revision after the candidate passes its gates \[9, 10\].

In synthesis, record achieved initiation interval (II), latency range, loop-carried dependencies, memory port conflicts, inferred RAM type, DSP binding and latency-sensitive interfaces. II=1 for one inner loop does not predict frame FPS. In co-simulation exercise consecutive transactions and downstream stalls; use dataflow profiling and FIFO occupancy where supported. Check insufficient FIFO depth, cyclic blocking on a residual fork/join, final stream beat, reset behavior and variable-latency transfers \[10\].

Compare builds on identical vectors and constraints. Archive HLS C/RTL and OOC reports for arithmetic cores, plus lint, elaboration, simulation, constraints and OOC reports for hand RTL. Import each public package independently in a fresh Vivado project and run its example. Require an additional mixed RTL/HLS XSim regression before releasing the integrated subsystem.

## Phase 8A • Package and integrate mixed-language IP

For each public IP, set a stable vendor/library/name/version (VLNV), display name, supported family, address block, parameters, reset polarity and associated clock for each bus. Ship simulation and synthesis file groups and scoped constraints. Include the generated HLS component as a locked dependency or reproducibly resolve it during packaging. Instantiate it in a small SV adapter and simulate its actual generated handshake after every regeneration. Never splice custom logic into generated HDL.

Choose a single owner for start/done/interrupt signals. For an HLS block with ap\_ctrl\_hs, latch a job, assert start according to the generated contract, capture its completion once and guard against accidental retrigger. For a continuously operating stream stage, implement framing, quiescence and model switching at the enclosing boundary. Verify the initial and final beats under stalls, across model reload, and after a reset of one side. Record tool version and control protocol in the IP release manifest.

Build recipes must distinguish HLS co-simulation from a mixed behavioral bench. C/RTL co-simulation verifies each exported HLS kernel against its C testbench. A separate XSim bench compiles the packaged RTL, generated HLS HDL, vendor simulation libraries, monitors and AXI agents. The integration scoreboard follows accepted transactions through backpressure and checks the top-level contract \[9, 10, 14, 15\].

Size elastic buffers using a generous reference configuration and measured high-water marks on realistic producer/consumer schedules. Then reduce one depth at a time with stalls and repeated frames. FINN documents a related RTL-simulation-based FIFO sizing approach \[20\]. A finite trace supplies a candidate depth; bounded worst-case analysis and recovery tests cover unseen stalls.

## Phase 9 • Build the Vivado IP Integrator system

Recreate both block designs from Tcl with the verified KV260 preset, Zynq UltraScale+ MPSoC, resets, SmartConnect, DMA and the selected standalone pair or optimized subsystem. Connect PS control to AXI4-Lite and the permitted DMA/memory masters to enabled high-performance ports. Start with one PL clock domain and synchronized reset release. Add a clock converter or asynchronous FIFO only at an identified crossing.

Allocate addresses without overlap, agree on address width and verify upper address bits in software. Check data widths, bursts, outstanding transactions and alignment. One packed 224 × 224 × 3 INT8 image is 150,528 bytes. With a single transfer the DMA length field needs at least 18 bits; a 14-bit configuration will fail. Choose the field for the largest actual transaction including model loads if DMA is used for them. Define one packet per tensor with TLAST on the last beat and TKEEP for valid bytes. Video-style end-of-line signaling requires an adapter before packet DMA \[11\].

Use validate\_bd\_design, generate output products, create the wrapper, synthesize and inspect inferred clocks, timing exceptions, latch/width warnings and DRC. Add a behavioral XSim bench with AXI stimulus or a PS transaction model. Drive reads, writes, packet transfers, reset and backpressure. Exercise an integrated PL shell with AXI BFMs where hardened PS simulation cannot exercise a Linux boot or board peripheral.

Perform post-synthesis functional simulation with selected real data plus protocol corner cases. Implement the complete block design through optimization, placement and routing. Inspect setup and hold slack, total negative slack, pulse-width checks, unconstrained paths, CDC, clocks, routing congestion, high fanout, DRC and utilization per hierarchy. Investigate negative slack or an unexplained exception at its cause. A clean timing report requires valid constraints.

Run post-implementation functional simulation and targeted SDF timing simulation in XSim where supported, checking clocks, reset release, memory interaction and representative packet boundaries. Use scoped PL netlists and record coverage/exclusions if the hardened blocks or vendor IP restrict a full timing simulation. Keep static timing analysis as the full-path timing gate. Generate the bitstream only for the accepted routed build. Export the matched HWH, optional XSA and image-specific overlay assets. Exit with a reproducible bitstream and a replay trace linked to its exact build \[12\].

## Phase 9A • Compare the two routed block designs

Create modular.bd and integrated.bd from source Tcl with the same board preset, DMA, clock and XDC. Lock IP versions and record which run includes ILA, bus monitors or debug tensor taps. Build a minimal instrumentation release as well as a diagnostic build when observation changes timing. Keep OOC numbers, routed PL utilization and physical evidence in distinct columns.

Sign off every generated clock, reset tree, declared false or multicycle path and externally visible AXI interface. Hold a timing review of the worst paths at high fanout, the channel-reduction adder, large RAM outputs, stream backpressure chains and address decoding. Place a register slice where a measured READY fanout limits timing, then rerun both protocol and performance tests. Require a documented endpoint rationale for every exception and review the effect of resets on RAM primitive inference.

Exit with two comparable build manifests and enough evidence to choose a release overlay. If the integrated build misses timing or offers no meaningful board benefit, the modular build remains a valid pilot candidate.

## Phase 10 • Bring up the PYNQ driver and recorded-video runner

Load a known-good base image, verify device identity, load the approved overlay, match its HWH and optional image-specific metadata, and check the expected IP identities. Use pynq.allocate for device-accessible buffers. For noncoherent transfers, synchronize owned input data before device reads and invalidate/synchronize output before CPU reads. Account for synchronization already done by the installed driver. Preallocate buffers, set explicit ownership, arm the result channel before sending input, and bound every wait. Confirm the chosen DMA mode is supported by the installed PYNQ driver \[7, 11, 13\].

Bring up in this order: ID register and self-test, DMA loopback, known single operation, one real frame to embedding, one complete window, two windows across wrap, long recorded replay. Return a status packet for warm-up and errors so a pending receive does not hang. Compare raw int outputs, sequence numbers, status, first/last timestamp and score against the host oracle. Test consecutive starts/stops and verify resources are released after an exception.

Make the headless command and the notebook call the same driver and pipeline. The notebook displays counters and diagnostic traces. The service owns the camera, buffers, queue, model and device lock. Exit when a cold machine can replay a checked-in reference trace using one documented command and a checksum-verified release bundle.

## Phase 11 • Measure live video, capacity and bottlenecks

Start with one locally attached camera and confirm negotiated format, dimensions and FPS from the device. Repeat with RTSP, recording the decoder, transport, jitter buffer and timebase. Implement bounded queues and an explicit overload policy. Track source frames, decoded frames, sampled frames, submitted frames, warm-up results, valid scores, stale frames and drops by reason. Keep per-camera epoch, timestamps, queue, ring and alert state isolated.

Measure sustained analyzed FPS, result cadence, timestamp age and p50/p95/p99/max latency with stage spans. Report service latency from frame receipt separately from sensor-to-score latency; true sensor timestamps require synchronized clocks or an external measurement. Include startup, steady state, backlog recovery and event onset. Drive the exact same frame tensors through reference and PL; for live capture record replayable test segments when permitted.

Collect PL busy/stall cycles, bytes read/written, DMA wait, CPU decode/preprocess, CPU utilization, memory, thermal sensors and clocks. State the power measurement boundary (wall input, board rail or device estimate), sampling, idle and active levels. Calculate energy per analyzed frame using measured energy and frame counts. Compare identical preprocessing and sampling in any CPU baseline.

Scale to 2, 4 and 8 independent replay feeds, then to actual live sources if available. Increase load until the first sustained miss, then identify whether decode, DMA, DDR, compute, per-camera state or scheduling caused it. Publish per-stream fairness, p99 age and missed deadlines, including overload behavior. Exit with the highest supported camera count satisfying all selected gates and a repeatable configuration.

## Phase 12 • Optimize with controlled experiments

First eliminate correctness failures and missed data; then measure the largest per-frame time and the largest shared throughput limiter. Sweep e.g. 64/128/256 useful pointwise lanes, tile sizes compatible with feature shapes, single/double buffering and a conservative clock sweep such as 100/150/200 MHz. Keep the same vectors and release precision for hardware-only comparisons. Exclude infeasible memory configurations before expensive place-and-route runs.

Experiment A compares whole-layer DDR materialization with tile fusion on high-resolution bottlenecks. Measure the DDR bytes removed per frame, extra BRAM/URAM, p99 latency and useful throughput. B compares single and double buffers at the same clock. C compares exact GRU replay with the projection cache, including gate widths and cache storage. D compares shared and separate GRU affine compute using actual utilization traces. E compares deeper streaming of the hottest prefix with the reusable baseline.

If memory remains the limiter, trial smaller H, a trained 1,280-to-D projection, width multiplier 0.75/0.5 or a distilled student. For torchvision, inspect the actual last-channel rule at each width multiplier. Do not scale 1,280 blindly. Evaluate one change at a time, then combine surviving candidates. If the accuracy gap persists, apply selective higher precision or QAT. Re-run threshold calibration, class/event metrics and field splits for each altered model.

Maintain Pareto results across accuracy, resources, sustained analyzed FPS, p99 age, measured power and portability. Repeat the leading candidates with the same board, thermal state, input trace and enough independent sessions to expose variability. Exit by freezing the simplest implementation meeting all agreed gates; document the losing experiment that most clearly explains the choice.

## Phase 12B • Cross-platform comparison and model promotion

Freeze the comparator configuration before collecting official project results. Run the A53, modular PL and integrated PL paths on the same timestamped replay. Record FINN/DPU compatibility separately and save any compiler partition evidence. Route one finalist from the exact track. Qualify a model-changing finalist only when it meets the event and resource gates. Archive a report that an independent engineer can reproduce, including failed hypotheses and unavailable comparisons.

## Phase 12C • Decide which microarchitectural changes ship

Prioritize the exact c24 fusion experiment if counters confirm that either intermediate crosses DDR. Compare unfused, one fused edge, and both fused edges with identical weights and camera trace. Record saved read/write bytes, additional memories and any extra cycles from retiming. If the baseline already retains the intermediate, close the DDR-saving hypothesis and test a measured utilization or port bottleneck instead.

Next compare the separately scheduled versus shared pointwise arrays at the same device and supported clock. Use the 150,528 and 206,976 issue counts to explain, rather than forecast, observed runtime. Retain more parallel hardware only if the critical path or supported camera count improves, or if the measured energy per analyzed frame justifies its cost. A throughput gain that creates stale frames at the capture queue fails the live-service requirement.

Compare dense GRU replay against projection caching with the complete memory plan, then consider deeper gate parallelism. If the head is a negligible fraction of the observed critical path and no scarce bank or DSP is freed, stop work there. Promote delta, mixed-precision or shift-based model changes under a new numerical profile with the earlier field-quality gates. Record control build, candidate build, implementation effort, rejected design and the specific future condition that would justify reopening it.

## Phase 13 • Harden the single-board pilot

Package a headless service with a device lock, configuration schema, startup self-test, structured metrics and an alert sink with explicit delivery semantics. Use monotonic time for local elapsed measurements and map to camera/UTC time with recorded uncertainty. Expose model and bitstream identifiers in every run. Use clear states for warming, running, stale stream, recovering and failed. Stop publishing valid scores on a fault.

Exercise camera unplug, RTSP reconnect, truncated packet, FIFO stall, DMA timeout, model mismatch, process crash, full log volume, power cycle and rollback. The recovery path stops submissions, quiesces or resets DMA and PL, invalidates temporal state, starts a new epoch, then warms up. Require a new valid window before emitting alerts. Validate config and model updates offline, stage matched driver/overlay/model artifacts and retain a known-good release.

Set a provisional 24-hour continuous board soak followed by a longer site-pilot soak appropriate to the deployment. Include idle periods, sustained motion, network jitter, changing lighting and repeated reconnects. Track memory growth, dropped/stale outputs, thermal throttling and recovery time. Run shadow-mode review on representative stations and actual background hours. Exit with a signed review of release evidence, known limitations, recovery playbook and an operator workflow.

## Phase 14 • Prepare the production handoff

Deliver both public IP archives, RTL and HLS sources, example designs, mixed-system Vivado scripts and constraints, the model packer, versioned release manifest, golden vectors, PYNQ driver, service package, deployment/rollback instructions and acceptance reports. Have a second engineer integrate each package without the metro application. Rebuild from clean sources and compare input hashes, integer outputs, timing and resource tolerances. Record any nondeterminism in the vendor build artifacts.

For a deployed product, select a production K26 SOM grade and carrier, validate power, cooling, physical I/O, environmental envelope, update and recovery process, and repeat timing and board acceptance on that production hardware. Agree who owns model drift, field alert review and incident response. Exit when a second engineer can build, install, recover and reproduce acceptance from the handoff \[2\].

# 6\. Proposed release gates

Functional — All supported integer reference vectors match exactly across C++, RTL and board output at declared boundaries. Include a real complete window, a wrap and a second independent stream/reset case. Any mismatch is localized to the first divergent integer tensor or hidden state.

Quality — Before touching the final test set, ratify an operational minimum event recall and maximum false alerts per negative camera-hour with the pilot owner. As an initial quantization budget, investigate every loss above one percentage point of validation F1 or event recall relative to FP32 at a comparable false-alert rate. A relative budget cannot make an inadequate FP32 baseline acceptable. Publish the locked operating point, event count, background hours and camera-level uncertainty.

Real time — Example one-camera target is 25 analyzed FPS and 25 valid score opportunities/s after warm-up at stride 1, on a source proven to supply that rate. Proposed initial receipt-to-score p99 is 80 ms with bounded queues; set the sensor-to-alert limit with the operator. Run a fixed-rate replay to isolate hardware capacity from a slower camera. Measure drops separately from intentional sampling. Establish the allowed drop budget explicitly before sign-off.

Timing and memory — Whole-design routed setup/hold and pulse checks pass at the selected clock, constrained paths are accounted for, and serious DRC/CDC issues are resolved. BRAM/URAM, DSP, LUT and FF remain within the approved platform budgets. Measured sustained bandwidth is sufficient under concurrent video traffic. List every DDR-resident tensor and its traffic. The on-chip-only claim requires evidence that NN weights/activations generate zero DDR transactions after preload, while camera I/O is attributed separately.

Operations — The pilot completes its agreed soak with zero silent output corruption or unhandled hangs. Every induced recovery produces a new epoch and a fresh 32-frame warm-up. State the measured recovery times, thermals, power scope and the maximum camera count actually tested. Quantify the field limits if the evaluation contains too few events or negative hours for the target false-alert rate.

## Release evidence for the modular product

For each released public IP, acceptance includes clean import in a second project, a standalone example replay, declared legal parameters, negative configuration tests, OOC constraints and results, a driver-level smoke test and a compatibility decision for the previous ABI. For the integrated release, add bit-exact equivalence against the modular configuration on the same stream, full-system timing closure, board replay and a recoverable update. Record waived configurations and their owners explicitly.

# 7\. Verification and failure localization

Use six comparisons: FP32 versus annotated continuous video; integer versus FP32 on the same windows; C++ versus integer per layer and timestep; RTL versus C++ across transactions; routed design versus selected RTL vectors; physical system versus replay and time-synchronized live input. Use explicit expected values from an independent oracle, not a testbench that calls the implementation to produce its own answers.

For convolutions include impulse, all-zero input, border-only pixels, signed extrema, odd tile tails, stride transitions, skip enabled/disabled and quantized-zero padding. For GRU include gate saturation, reset/update extremes, recurrent candidate bias, repeated identical frames, full window, first wrap, a long stream and reordering/gaps. For interfaces include partial beats, sink stalls, reset between packets, invalid descriptors and repeated start/stop.

When results diverge, locate the first differing stage. Wrong stem outputs suggest preprocessing, padding or weight layout. Correct CNN embeddings with wrong first-step gates suggest quantization, gate order or bias. Correct individual windows with drift on long streams suggest ring indexing or stale state. Correct board values with high latency suggest queues, copies, cache maintenance or decode. Save the smallest failing vector, the exact build and the diagnostic counters.

## Elastic buffers, adversarial stalls and checkable invariants

Define occupancy after edge c as q(c)=q(c−1)+w(c)−r(c), where w and r are handshakes at the boundary with the FIFO. Count simultaneous push/pop once in each direction. For a trace starting empty, enqueue on edges 0…5 and dequeue on 2,3,6,7,8,9. Post-edge occupancy is 1,2,2,2,3,4,3,2,1,0. A four-entry queue suffices for that trace. A three-entry queue must backpressure the sixth write and shift the subsequent issue trace. Check both behaviors in XSim. A finite FIFO cannot sustain an unbounded sink stall at the source’s maximum offered rate \[44, 46\].

Distinguish the buffered occupancy from issued tokens that cannot yet be stopped. If two additional tokens can arrive after upstream stop is asserted, reserve two free places at that boundary or provide two independently accounted skid slots. In a four-entry queue with two unavoidable arrivals, assert upstream stop by occupancy two under the selected timing convention. Do not count the same elastic registers both as FIFO capacity and as separate free slots. Build a credit-conservation monitor covering source registers, arithmetic pipeline, skid register, FIFO and accepted sink output.

For a fork, either transfer to both outputs in lockstep or remember which output already consumed the current token. For a join, pair exact epoch, frame, pixel and channel tags; with asymmetric stalls the earlier side can fill before the later side has emitted its first word. Simulate the worst legal relative startup delay, then apply randomized pauses during steady state and drain. Use Vitis dataflow occupancy reports for candidate FIFO depth and independent RTL checks for hard bounds; report the maximum tested stall and the assumptions on eventual service.

Use the same scoreboard for the unfused block, fused block, public embedding stream and integrated internal channel. On a transfer check payload, qualifiers, logical coordinate and model generation. On a stalled valid cycle assert payload, TKEEP and TLAST stability. On reset invalidate in-flight jobs and reconcile each accepted request with a completion or explicit host-side abort. Test simultaneous reset and final beat according to one documented precedence rule. Keep assertions active in both the minimally buffered and heavily stalled builds.

Acceptance set for mnv2\_features: single center impulse, four corner impulses, signed input at the quantized zero point, last output group of a row stalled, and a real frame across every selected fusion boundary. Check every channel, CRC or hash only as a fast screen, then compare individual tensors for diagnosis. Acceptance set for gru\_sequence: nonzero recurrent candidate bias, reset gate driven near zero and near one, identical embeddings across a wrap, alternating signs near saturation, two streams with different generations, and a model commit arriving while the oldest history slot is still in use. Verify input projection against uncached replay before comparing final logits.

For metro\_accel retain four observations per run: first semantic mismatch if any, first protocol violation if any, earliest cycle where a measured schedule diverges from its assumptions, and end-to-end tail latency with sufficient samples. The first two block release. The third directs optimization; a legal stall is not a correctness failure. Quantify success for the fourth against the agreed live target. Save the original stimulus, seed, configuration hash and exact bitstream for reproducibility.

## Where to probe first

Give the debug build four selectable taps: post-stem activation, pre-add residual projection, final quantized embedding, and GRU input/recurrent affine plus hidden state for one selected step. Capture only a selected window/tile and attach tensor ID, shape, format ID and sequence metadata to each record. Reuse the readback path and mark its DDR traffic separately. Compare values in logical tensor order after undoing packing and padding. A one-bit error found at the first differing boundary is actionable; a final probability alone rarely identifies the faulty block.

# 8\. Repository and ownership

model/ owns training, transforms, calibration, export, tensor manifest and integer oracle. data/ owns manifests and split checks; keep governed source footage in its approved location. vectors/ owns small golden tensors, clip IDs, expected results and a reproducible generator.

rtl/ owns synthesizable SystemVerilog, package wrappers, SVA, XSim benches, CDC declarations and test models. hls/ owns C++ sources, testbenches, directives and pinned configs. ip/ owns package metadata, self-contained examples, dependency locks and interface schemas. vivado/ owns both block designs, constraints, simulation harnesses and report extraction. Rebuild generated products from the tagged sources.

runtime/ owns the packer/loader, driver, capture adapters, replay CLI, service, notebook and observability. bench/ owns fixed workloads, timestamps, board probes and reporting. docs/ owns the model and ABI contracts, memory worksheet, architecture decisions and release runbook. results/ indexes runs by build and model hashes, with one row per configuration and evidence stage.

Expose project wrappers for model export and golden vectors; rtl-lint, rtl-sim and mixed-xsim; per-kernel HLS csim, synth, cosim, impl and package; per-IP package/import acceptance; and Vivado synth, post-synth simulation, implementation, post-implementation simulation and bitstream. Add board replay, live smoke, fault injection and soak as explicit jobs. Pin the actual vendor invocations for the selected release.

# 9\. Solo schedule and the first ten working days

Budget 32 focused solo weeks at 30–35 hours per week for the two reusable IPs and the one-camera pilot, plus 4–8 contingency weeks for data, board access, timing closure or an unsuccessful RTL optimization. Weeks 1–4 establish the board shell, data, reference and interface contracts. Weeks 5–8 freeze FP32 and integer references and size the memory. Weeks 9–13 implement the CNN and temporal arithmetic. Weeks 14–18 qualify the RTL shell and both standalone packages. Weeks 19–23 compare modular and integrated builds and close timing. Weeks 24–27 prove board replay, capture and controlled optimization. Weeks 28–32 cover field metrics, fault injection, soak, reproducible packaging and a handoff rehearsal. Production carrier qualification and site data collection have separate dependencies.

Days 1–2 — Freeze source cadence, input transform, label protocol, 32-frame reset/stride semantics and provisional metrics. Record host/environment versions and create an empty reproducible build. Start collecting long background sessions immediately.

Days 3–4 — Prove the board path with a register scratchpad and a 150,528-byte DMA loopback on the intended PYNQ image. If board access is delayed, run the same interface contract in XSim and preserve the pending hardware gate. Build split manifests and a deterministic frame sampler.

Days 5–6 — Instantiate the pretrained backbone, GRU and head; produce the per-layer shape/MAC/byte ledger. Develop one window oracle and plot an entire real clip’s frame timestamps and score opportunities. Mark output quality untrained until the temporal model is trained.

Days 7–8 — Prototype exact embedding replay and input-affine caching. Compare every hidden state at wrap and after reset. Size representative fusion tiles, physically banked weights and BRAM/URAM fragmentation. Select the two bottleneck microbenchmarks.

Days 9–10 — Run the first C simulation and HLS synthesis for the selected bottleneck. Elaborate its RTL comparison harness. Freeze the CNN-to-GRU packet example and feed an externally generated embedding through the GRU scoreboard. Record the first physical bank budget, proposed DDR traffic and the next observation that could invalidate each choice. Start teacher training once the signed-off sampling and split manifests are ready.

## Critical path and schedule recovery

The model and hardware teams are the same person in this schedule. Alternate short model-training runs with shell development, but do not count simultaneous engineering hours twice. Gate the frozen integer vectors before final datapath sign-off, independent package acceptance before integrated timing, and replay correctness before live performance claims. Reserve board time at the loopback, standalone, first integrated bitstream and thermal/soak milestones.

If time slips, retain the portable CNN and GRU, real-data accuracy, integrated verification and pilot recovery work. Defer an unproven packed DSP kernel, whole-network deep streaming, a second clock domain or a multi-camera performance claim. If board time slips, complete OOC and routed evidence and queue a deterministic hardware acceptance bundle; keep all board and field claims pending.

# 10\. Worked DDR fallback and hardware/software interface

The last 320 × 1,280 convolution contains 409,600 INT8 weight bytes. Moving only that tensor out of permanent on-chip storage would add 10.24 MB/s at 25 frames/s if every weight is fetched exactly once per frame in long bursts. This first-order estimate excludes AXI overhead, duplicate reads, alignment, staging buffers and arbitration. It frees up to 400 KiB of logical storage before staging; verify the actual URAM/BRAM reduction in the report. Compare this option against spilling a 112 × 112 × 96 intermediate; one write and one read of that tensor per frame alone total 60.21 MB/s at 25 FPS. This is a concrete reason to test streaming the early expansion before spilling it.

For each candidate document the PS-to-PL request (model generation, epoch, sequence, sample time and exact frame bytes), completion (same identifiers, validity, fixed-point logit and counters) and error ownership. An example bring-up result is WARMUP for the first 31 sequential frames, followed by VALID on the 32nd and each following accepted frame. On MODEL\_CHANGED or a discontinuity beyond the configured policy, invalidate the ring and start another warm-up. Small score packets may use latched AXI-Lite registers if measurements justify changing the DMA baseline; explicitly specify latching, overrun and interrupt semantics.

For a lossless 25 Hz replay, at 150 MHz the entire pipeline has 6,000,000 clock cycles per 40 ms update period. Allocate estimated and measured cycles to video preparation, descriptor processing, input transfer, CNN, temporal replay, result return and queuing. Compare frame initiation interval with end-to-end latency when work overlaps. An accelerator can accept a frame every 40 ms even if its individual latency is longer, provided there is bounded concurrency and the measured p99 age still passes.

# 11\. Public interfaces, model loading and observability

## Packet ABI v1 proposal

Use a 128-bit AXI4-Stream candidate for external packet data and little-endian scalar fields. Byte lane 0 carries the earliest serialized byte. The first 32 bytes are an in-band header, so the minimal PYNQ DMA path need not preserve custom TUSER fields. The version, kind and numeric profile make an embedding captured from mnv2\_features usable by an independent host or PL producer. The board loopback remains a raw-payload test; also test the fully framed lengths below. The ABI is a proposed project interface to ratify before implementation.

**Packet worksheet · ABI v1, baseline 128-bit stream**

| Transfer | Payload \+ header | Beats / terminal rule |
| :---- | :---- | :---- |
| Raw loopback | 150,528 \+ 0 bytes | 9,408 full beats; validates raw DMA |
| Framed RGB input | 150,528 \+ 32 bytes | 9,410 full beats; one frame per packet |
| Framed embedding | 1,280 \+ 32 bytes | 82 full beats; a signed INT8 vector |
| Framed completion | 16 \+ 32 bytes | 3 full beats for VALID, WARMUP or handled rejection |
| Diagnostic example | 17 \+ 32 bytes | 4 beats; final TKEEP \= 0x0001, TLAST \= 1 |

Use these proposed field allocations for the 32-byte header: bytes 0–3 are literal ASCII MGR1; byte 4 is ABI major, byte 5 packet kind, bytes 6–7 flags, 8–11 model generation, 12–15 stream epoch, 16–23 sequence number, 24–25 stream ID, 26–27 format ID and 28–31 payload length. Baseline kinds 1/2/3 mean frame/embedding/completion. Use unsigned fields except tensors/logits whose signedness is declared by format. Serialize multi-byte integers explicitly. Reject unknown major versions, illegal flags, oversize lengths or mismatched format before writing state. Reserve additional kinds and flag values in the schema.

At 25 FPS, exporting the 1,280-byte embedding is only 32,000 payload bytes/s. Including the proposed header gives 32,800 bytes/s on one stream, or 65,600 bytes/s for one DDR write plus one DDR read if a diagnostic round trip is used. The ordinary modular build can wire the public stream directly on chip. Bypassing this boundary rarely saves enough bandwidth on its own to justify losing independent observability; measure packet setup, synchronization, stalls and possible buffer duplication separately.

The frame payload is interleaved HWC RGB, row-major, no row padding, normalized and quantized as declared in the model manifest. The embedding contains channels 0 to I−1 in reference order. A 16-byte completion payload can store a u32 status, s32 logit, u32 valid-sample count and u32 device-cycle delta. Its logit is meaningful only for VALID and its scale comes from the format ID. Host software timestamps receipt and looks up capture time by stream, epoch and sequence. If clock-domain-correlated timestamps are required, add an explicit ABI extension and qualify clock synchronization.

For a 16-byte beat require a contiguous low-lane TKEEP on a partial final beat, all lanes valid on other beats and exactly one TLAST per packet. Transfer occurs on a rising edge when TVALID and TREADY are both high. A source must hold payload and qualifiers stable while stalled. Constrain interleaving to whole packets for v1. Exercise nonmultiples of 16 through small supported diagnostic tensors even though all three normal baseline packet sizes divide evenly. Framing and error policies are above the AXI transport rules \[16, 17\].

If a complete but invalid packet can be drained safely, issue a rejected completion with an error code and preserve the last good temporal history. On lost framing, missing TLAST or reset, halt admission, expose the sticky fault, and let the supervisor quiesce/reset and invalidate the epoch. Define the host completion as terminally failed for every outstanding request it aborts. Keep a reconciled count of accepted, completed, rejected and explicitly aborted work to prevent silent loss.

## Control plane and model lifecycle

**Register worksheet · Proposed external shell, separate from generated HLS registers**

| Offset(s) | Access / field | Behavior software must verify |
| :---- | :---- | :---- |
| 0x00–0x0C | RO: ID, ABI, CAPS, LIMITS | Read at attach; compact profile/limit descriptor indexes an immutable capability record. |
| 0x10 / 0x14 | WO: COMMAND / RO: STATUS | Write one full command word. States include idle, loading, ready, busy and fault. Reject illegal transitions. |
| 0x18 / 0x1C | RO: ERROR / W1C: IRQ\_STATUS | Sticky cause retains first fault until acknowledged via CLEAR\_FAULT. IRQ clear removes only consumed sources. |
| 0x20–0x2C | RW: DESC\_LO, DESC\_HI, DESC\_LEN, ARG | Shadow registers; atomically capture on command. Validate ownership, alignment, size and address window. |
| 0x30 / 0x34 | RO: MODEL\_GEN / STREAM\_EPOCH | Commit/configuration confirmation; selected stream comes from the accepted configuration descriptor. |
| 0x38 / 0x3C | RW: IRQ\_MASK / RO: SNAP\_SEQ | Snapshot command latches counters and advances snapshot sequence. |
| 0x40–0x7C | RO: eight 64-bit counter snapshots | Pairs low then high: accepted, completed, aborted, rejected, busy cycles, stall cycles, DDR read bytes, DDR write bytes. |

Proposed CSR layout is byte-addressed and 32-bit aligned. Use one authoritative schema to generate register docs, HWH cross-checks, constants, C/Python accessors and SV decode tests. Honor WSTRB for writable bytes, define response to misaligned, partial command, reserved and read-only accesses, and leave read-only state unchanged. Decouple AXI-Lite write-address and write-data capture so either may arrive first. Hold BVALID/RVALID until handshake. A sticky-error clear arriving in the same cycle as a new fault must preserve the new event \[17\].

The v1 driver may allow one outstanding request to simplify recovery. Expand later only with a bounded descriptor FIFO, a monotonic completion sequence and tags that survive every stage. Do not count interrupt pulses as jobs. An IRQ announces pending state; the driver acknowledges only what it has consumed. The packet stream is the source of result data. Use a snapshot command for coherent multiword counter reads, and specify rollover for free-running counters.

A model container has a header, version, target capabilities, section directory, per-section bounds/alignment, correct graph and tensor IDs, quantization facts, expected preprocessing, and independently loadable CNN/GRU slices. Validate every integer addition before using offset \+ count × element size. The combined manifest binds both slice IDs, embedding dimension, scale/zero point, channel order, classifier labels and numerical implementation ID. A matching tensor shape alone cannot establish model interchangeability.

Load model candidates under exclusive configuration ownership. Quiesce launches, drain jobs, validate the host package, stage data and verify its identity before publishing the new generation. Hardware validates range and size for each DMA-accessed region. An integrity checksum detects corruption; authenticate release packages in the trusted deployment layer. With one weight bank, reject launches after a failed partial load, reload the last verified package and only then reopen admission. Clear temporal histories on commit and fail any submission with a stale generation. Test interrupted writes at the header, middle of a weight bank and just before commit.

**Diagram 2 · Model and frame admission state transitions**

| Current state | Trigger and guard | Next state / visible action |
| :---- | :---- | :---- |
| EMPTY or READY | LOAD while quiescent | LOADING → validate sections; block new launches |
| LOADING | All checks pass; COMMIT | READY → publish generation and reset affected histories |
| LOADING | Error or interrupted single-bank load | FAULT → revoke validity; recover with known-good load |
| READY | Valid frame begins and resources available | RUNNING → bind epoch and sequence |
| RUNNING | Frame consumed, completion delivered | READY → emit WARMUP, VALID or classified rejection |
| Any active state | Timeout or lost framing | RECOVERING → abort outstanding jobs and quiesce/reset |
| RECOVERING | DMA idle, verified model and fresh epoch | READY; else EMPTY until a verified model is loaded |

Diagram 2 describes control transitions for one generation. Progress conditions for a complete accepted job assume the source eventually finishes its packet and the sink eventually accepts output. Use watchdog and recovery behavior to cover permanent external stalls.

# 12\. Microarchitecture worksheets and optimization experiments

## Numerical behavior at the RTL/HLS boundary

Specify the requantization function in one language-independent record. For a convolution, accumulate bias plus the sum of centered activation times signed weight, apply the per-output fixed-point multiplier using a widened product, round according to the frozen tie rule, shift as defined, add the output zero point, then saturate to the output type and apply the declared activation clamp. For a residual sum, align branch scales before addition and preserve the reference sequence of rounding. Record whether the training/export oracle fuses a clamp or emits it as a separate tensor boundary.

Construct hand-verifiable sentinel vectors. With weight zero point zero, an input equal to its activation zero point and zero bias should produce the representable output zero of an ordinary linear operator. A center impulse distinguishes CHW/HWC and transposed kernels; a corner impulse reveals asymmetric padding. Examples near ±0.5 requantization units discriminate rounding-tie choices. Test the most negative signed product explicitly because its magnitude may exceed a same-width positive maximum.

For the GRU, start from the PyTorch gate order and reset placement in Section 3\. Preserve separate candidate input and recurrent biases until the reset gate has multiplied the correct term. The cached value must be the same affine intermediate, at exactly the same precision and rounding location, that uncached replay consumes. Compare the first timestep, every state in the first 32-frame window, the first wrap, a high-motion sequence and a long background run. Include values near sigmoid/tanh saturation and alert thresholds.

Choose the sigmoid/tanh hardware by evaluating a lookup table, a piecewise-linear candidate and the reference function on the representable input domain. Report maximum error, mean error and composite error after 32 steps. Bound addressing and out-of-range behavior at both ends, including the most negative input. If one fractional bit is added to the hidden state, update the recurrent product and accumulator bound, RAM width, multiplier mapping and oracle together. A changed numerical contract needs a new model profile and accuracy evaluation.

## Capacity and traffic worksheet

**Allocation worksheet · Example logical sizes before primitive rounding**

| Object | Logical size | Decision to test |
| :---- | :---- | :---- |
| Full CNN weight kernels | 2,189,760 B | Bank by operator and tile. Track preload versus per-frame reads. |
| GRU input / recurrent matrices | 491,520 B / 49,152 B | Consider separate hot recurrent bank. Both assume INT8 weights. |
| One input-projection ring | 49,152 B per stream | INT32, 32 × 384 values; tag storage extra. Validate precision before narrowing. |
| Early expansion | 1,204,224 B whole tensor | Compare a line/tile-fused schedule against 2,408,448 B per frame for a full write/read. |
| Example depthwise line history | 21,504 B | Two 112×96 INT8 rows, excluding current-row shift taps, bank rounding and replication. |
| One pointwise accumulator tile | 8,192 B | Example 8×8 pixels × 32 outputs × 4 B. Double buffering would consume 16,384 B. |
| Last 1×1 weight block | 409,600 B | One load per frame ≈ 10.24 MB/s at 25 FPS. Measure burst efficiency and repeated reads. |

For each RAM bank record logical width/depth, primitive type and legal mode, physical primitive count, ports used by each cycle, read latency, replication for extra ports and reset behavior. Build a live-range ledger by operation boundary to show when two buffers can reuse the same addresses. Separate simultaneous producers and consumers and include every ping-pong copy. Simultaneous ports and width/depth fragmentation can fail even if the byte sum fits \[1, 18\].

For each DDR region record owner, address base and bound, transfer direction, contiguous burst payload, transfers/frame, repeated tile reads, total bytes/frame and measured service time under load. Distinguish decimal MB/s from MiB of capacity. Compute effective intensity as useful MACs divided by inference-time external bytes. Compare sustained throughput against the smaller of measured compute capacity and intensity × measured available bandwidth. Repeat with camera capture and CPU preprocessing running.

For example, with 150 MHz and one stream, a full 40 ms interval supplies six million PL cycles. Dividing the baseline 301.56 million matrix MACs by that budget yields about 50.26 useful MACs/cycle. On a 128-lane candidate, measure the fraction of cycles doing valid work. Attribute losses separately to input tails, weight loads, RAM hazards, dependencies and backpressure. A multi-frame pipeline can meet the initiation interval with a longer individual latency; confirm the independent p99 age limit.

## Physical memory binding for the cycle fixtures

**Bank worksheet · Proposed mappings to test in HLS and RTL**

For each physical candidate, write the address, data width, legal read/write concurrency, latency and expected primitive count into the worksheet. The values below assume 64 payload bits in a 72-bit-wide primitive and a single clock. Small tables may consume substantially fewer resources as LUTRAM or registers. Report actual primitive inference, placement and routed latency before claiming the savings. Charge replication and ping-pong storage once for each real copy \[1, 18, 45\].

For the CNN line history, index a row-store word by 12x+g. Store eight INT8 channels per word. Keep two previous rows in separate banks. In a row, one bank serves both as the oldest input row and the destination for the current row. Complete its read before overwriting the same logical word, with a delayed write stage and matching data/valid tags. Keep the other row read-only for that scan, then rotate roles after all delayed accesses complete. An alternative three-bank implementation assigns the current row its own bank, simplifying hazards at extra cost. Force stalls on row change and compare every addressed sample in both versions.

For the GRU, store weights with lane b selecting row 8u+b and address 48k+u. Each weight-bank read provides 16 signed weights. Broadcast the 16 inputs once per fold. In the projection ring address a gate word at 16×slot+v for v=0…15. Three 256-bit gate words must be available together to the proposed vector unit. Assign separate r,z,n banks or time-multiplex the reads and adjust the 412-cycle model. Recurrent scratch and old-hidden reads also need ports. Sum simultaneous clients on each bank; an aggregate byte count does not establish a legal schedule.

The W\_ih example uses sixteen URAM blocks, one quarter of the K26 total. W\_hh and the three ring gate banks together use 28 candidate RAMB36s before feature buffers and platform logic. Compare this organization against caching just a weight tile. Test repeat reads per update, burst alignment with packed rows, contention with camera traffic, and whether a tiled working set can still make the 40 ms service interval. A smaller buffer that triggers repeated DDR reads inside every recurrent timestep may be slower and less energy-efficient than its BRAM savings suggest.

Record a proof obligation for every read/write collision policy. Include read latency when selecting the delayed token’s tag, verify partial writes or mask them out by construction, and define behavior on model generation changes. Scope CDC separately. A dual-clock design requires a verified crossing and its own latency and reset budget.

## Design-space exploration with stopping rules

**Experiment matrix · Promote a candidate only on the measured workload**

| Candidate | Compare / instrument | Advance or stop |
| :---- | :---- | :---- |
| Fusion and tile shape | Unfused → fused; bytes/frame, skip storage, useful MACs/cycle | Advance if real traffic and critical-path time fall with exact outputs. |
| Pointwise lanes and clock | 64/128/256 candidate lanes; 100/150/200 MHz attempts | Keep only timing-clean candidates that improve the constrained system metric. |
| Buffering and bursts | Single/double buffers; burst alignment, efficiency, stall tails | Remove extra banks if their transfer overlap does not persist under camera load. |
| Projection cache | Embedding replay vs cached affine; hidden states, ring bytes, p99 | Require integer equality, including reset/wrap; retain only if benefit merits memory. |
| Routed RTL vs HLS kernel | Same external traffic and clock; compare useful throughput and routing | Adopt RTL only when the system benefits enough to justify independent maintenance. |
| Shared affine engine | Independent versus shared resources; starvation, context traffic, p99 | Reject sharing if any active stream misses the agreed service bound. |
| Mixed precision / sparse student | Matched false-alert rate; accuracy, real metadata and energy costs | Use a new numerical profile and repeat field-facing quality gates. |
| Packed DSP arithmetic | Scalar baseline vs packed; carries, extrema, extraction and routed Fmax | Exact profile requires equivalence. Treat approximations as separate model experiments. |

Use identical numerical profiles and input traces for hardware comparisons. First sweep estimates to discard impossible memory configurations, then synthesize short-listed kernels, route the viable integrated candidates, and finally measure the best few on one board. At each stage retain observations that could reverse the choice: a new critical path, a port conflict, lower useful utilization, a longer queue or greater runtime variance. Keep baseline seeds and reports so a surprising result can be replayed.

For DSP packing specify signed lane ranges, sign correction, carry spacing, accumulation length and extraction. Test all scalar input codes where affordable, adversarial long dot products and the whole operator on the frozen vectors; prove the chosen packed identities where practical. Published packing techniques have different error behavior \[19\]. Admit an approximate kernel only under an explicitly revised numerical profile, followed by full accuracy and event evaluation. Treat structured pruning similarly: include index/mask storage, wasted lanes, decode cost and regularity before crediting a theoretical MAC reduction.

For a shared pointwise/GRU affine engine, schedule the new-frame input projection once, then replay hidden transforms in chronological order while the CNN for the next frame is ready. Specify who owns the engine, weights, partial sums and output path across context switches. Analyze worst-case starvation and a backpressured score output. If sharing adds an unbounded queue, keep independent engines or enforce a bounded service allocation. Compare power and tail latency as well as DSP count.

## Hardware-aware student and precision search

Use one training recipe and locked validation protocol for candidate selection. Preserve the ImageNet-pretrained backbone and GRU teacher. Create a per-group sensitivity sweep by perturbing only one group at a time: stem, early expansion, depthwise, linear projection, recurrent input matrix, recurrent hidden matrix, nonlinearities, last convolution or head. Log changes in event recall at the operating false-alert rate, onset delay, clipping frequency and threshold crossings by scene. Rank groups against the actual binding resource. Changes to the recurrent matrix deserve a long-sequence drift check even when single-frame activation error is small.

HAWQ-V3 provides a starting point for integer-only dyadic rescaling and constrained mixed precision. Generate only formats the IP and model loader can encode, for example INT8 activations throughout with INT4 weights in selected wide pointwise layers. A first cost table may use observed accuracy sensitivity plus BRAM banks, DSP mapping, cycles and packer overhead. Enumerate the short list or solve a constrained selection problem, then re-evaluate interacting layer choices in the full graph. A half-width tensor need not halve the consumed primitives once port count and packing are fixed \[27\].

As a worked bound, changing just the final 320×1,280 convolution from INT8 to packed INT4 cuts its ideal payload from 409,600 to 204,800 bytes. A once-per-frame DDR fetch would save 5.12 MB/s at 25 FPS. Check high/low nibble order, sign extension, zero code, odd tails, scalar reference equality for the new profile and primitive occupancy after implementation. If weights stay resident after preload, the same change saves storage and reload time; inference DDR savings for that bank are zero. Preserve the original FP32 and INT8 results alongside the new profile.

Use NetAdapt-style direct measurements to select structurally removable channel groups. Prune in groups aligned to physical lanes and update both sides of each dependent operator. Map skip branches consistently, rebuild normalization, recalibrate and fine-tune the student. If the final feature dimension changes, train the matching GRU input projection and issue a new interface capability/profile pair. Compare dense smaller tensors against sparse encodings at equal validation quality. A new sparse format needs enough work per nonzero to cover decoding and load imbalance \[24, 28\].

For distillation, retain hard labels and fit teacher score trajectories on matching timestamped windows. For a single binary logit use a temperature-scaled Bernoulli soft target or explicitly represent both classes. Feature matching can use a trainable projection during training; decide whether inference needs that projection and budget it if so. Keep camera splits fixed. Test straightforward fine-tuning of the same student as a control so the gain attributable to distillation is visible. For a polynomial or segmented-LUT gate, compare its own fixed-point oracle and carry forward the existing event-recall and false-alert gates \[29\].

# 13\. Verification, measurement and failure recovery

**Verification matrix · Minimum evidence by boundary**

| Boundary | Stimulus and observation | Gate / saved evidence |
| :---- | :---- | :---- |
| Float → integer | Same real sequences; hidden/logit drift, event matches and background hours | Locked accuracy/false-alert budget; save score timelines and split IDs. |
| Operator / tensor | Border impulses, extrema, tile tails, scale ties and phase transitions | Exact tensor output; save minimal first divergent tensor and layout. |
| AXI / controller | Independent AW/W, byte strobes, stalled final beat, invalid header, reset | Assertions and scoreboard pass; save reproducible seed and coverage gaps. |
| Standalone CNN | Real frames, two model loads, independent embedding consumer | Every channel and metadata field match the oracle; preserve clean-import recipe. |
| Standalone GRU | External embeddings, wrap, reset, large gap, interleaved stream contexts | Exact per-step outputs for selected traces, complete ordered statuses and scores. |
| Mixed-system XSim | Real generated HLS RTL plus SV shell, bounded stalls and failed loads | No loss/duplication across normal epochs; traced aborts and recovery. |
| Routed / physical | Post-netlist smoke, routed STA, replay, thermal soak, timeout recovery | Link each result to bitstream/model/tool hashes and the exact tested scope. |
| Site pilot | Continuous camera streams, confirmed event labels and reviewed alerts | Report event recall, false alerts/camera-hour and delay with exposure and uncertainty. |

A transaction scoreboard compares ordered (stream, epoch, sequence, kind, numerical payload, status) records. A separate protocol monitor checks every transfer cycle. This lets implementations add internal pipeline stages legally while exposing duplicate results, reordering within a stream and undeclared changes in data. Match inter-stream ordering only where the ABI promises it. Save the seed, model hash, packet bytes, expected/observed traces and the first failing comparison.

Write project assertions for payload stability under stall, accepted/read/write count consistency, FIFO overflow/underflow, one terminal status per accepted request within a completed epoch, no invalid generation launch and no stale result after reset. Add cover points for simultaneous push/pop, a full-to-empty transition, first TLAST following a mid-header stall, ring wrap and a recovery followed by a valid result. Cover the cross of stream switch, buffer ownership and model generation with directed sequences. Use bounded formal checks for small transport blocks if available; record assumptions, explored depth and tool. Liveness requires explicit fairness assumptions.

Use four integration levels to keep XSim time useful. At block level, exhaust corner arithmetic and handshake cases. At package level, use full real dimensions and independent fixtures. At system behavioral level, run several adjacent model windows and negative cases with realistic AXI stalls. At post-synthesis/post-route level, keep short high-value reset, packet and timing-sensitive cases plus supported paths of the real design. Record the exact simulated scope. Full bitstream operation, DDR service, power and sensor timing require physical-board evidence.

For false alarms, publish both total negative camera-hours and counts by camera. As a planning example, under a stationary Poisson count model with zero false alerts, the one-sided 95% upper rate is −ln(0.05)/hours, approximately 3/hours. Thirty negative hours with zero alerts still admit a rate near 0.10/hour; three hours admit about one/hour. Correlated periods or a single view weaken that calculation. Cover several stations, times and conditions and report event counts and camera-level variability. Select the event operating point on validation data before unblinding the test set.

For long runs use fixed thermal conditions where feasible and report ambient temperature, fan policy, input and analyzed rates, clocks, load mix, model hash, power measurement boundary, elapsed time and sample counts. Store board telemetry independently from per-frame completions to catch stalls. Compute interval energy from time-aligned power samples and divide by analyzed frames. Include sensor timing uncertainty, p99 sample count, maximum observed age and time spent in degraded mode. Compare repeated warm and cold sessions with the same replay.

## Driver and recovery playbook

Start with buffer states FREE, CPU\_FILL, READY\_FOR\_DEVICE, DEVICE\_OWNED and CPU\_CONSUME. Associate each buffer with sequence and generation before handoff. Under a noncoherent path, synchronize after CPU writes and before CPU reads as required by the installed driver. Arm receive capacity before issuing input. Keep DMA buffers allocated until the channel is proven idle or a verified reset has completed; never free/reuse memory merely because a user-facing timeout expired.

If a transfer hangs, capture IP state, DMA status, last accepted byte count, last TLAST, FIFO occupancy, active epoch and last sequence before resetting anything. Stop submissions, bound the drain interval, perform the selected hardware reset if draining fails, invalidate affected state and reconcile outstanding requests. Reinitialize DMA, buffers and model validity, start a fresh epoch, then warm up. For a camera-only reconnect use the narrowest verified reset scope. A second process must not seize the same camera or overlay during recovery.

If timestamps grow stale while PL busy time is stable, inspect the source jitter buffer, decoder, Python scheduling and queue depth. If PL utilization drops while AXI read stalls grow, inspect burst geometry and contention before changing MAC lanes. If logits diverge only after a model switch, check generation binding and invalidation tags. Run the recorded failure case through the standalone IP first so the responsible component can be isolated.

## A fair comparison on the actual KV260

Benchmark at three boundaries: preprocessed frame to embedding, embedding trace to score/status, and captured or replayed frame to published score. In each case record checkpoint, arithmetic profile, sample cadence, warm-up, stride, initial state, stream count and host involvement. Compare the same domain of outputs numerically before comparing throughput. A faster CNN-only implementation may support a valid CNN-only speedup claim. When paired with a CPU GRU, include the transfer, synchronization and CPU time in the mixed-system figure.

**Comparator matrix · Baseline, normalization and required evidence**

| Baseline / scope | Control the comparison | Save as evidence |
| :---- | :---- | :---- |
| A53 software · full graph | Run on the KV260 PS. Pin runtime, threads, affinity and CPU governor. Use optimized Arm/NEON kernels where supported \[31\]. Compare FP32 accuracy and the closest deployable quantized path separately. | Per-stage time for CNN, GRU, copies and preprocessing; operator/precision coverage; real score traces. Distinguish portable scalar oracle timing. |
| Modular custom PL · full graph | Wire mnv2\_features directly to gru\_sequence. Use the frozen exact-window profile. Run the same shell, DMA and clock as the integrated build where feasible. | Integer equality, identifiers, stage/cycle counters, DDR bytes, active resources and board-level timing. |
| Fused custom PL · full graph | Same input, arithmetic and output semantics. Change only measured internal boundaries or array sharing. Record instrumentation and any clock differences. | First differing tensor or exact equality; paired measurements against the modular bitstream. |
| FINN · supported partition | Export the compatible graph via QONNX, inspect folding, packing and generated operators \[20, 32\]. Use a board target and runtime that pass bring-up. Log any conversion, re-quantization or host computation. | Subgraph boundary and platform; CNN-only results where appropriate. If conversion fails, publish the unsupported operator and leave the run unmeasured. |
| AMD DPU · installed compatible image | Check the deployed DPU fingerprint, compiler/runtime pair and operator restrictions \[33\]. Inspect the compiled graph by device. Evaluate CNN-only, and separately DPU CNN \+ host GRU when feasible. | Compiler map, host partitions, transfers and exact time boundaries. A fallback or different precision receives a distinct row. |
| Published hardware · contextual | Inspect device, input size, network, batch, window, precision, power boundary and evidence. Keep inaccessible or incomparable numbers in the reading record. | List what transfers and which denominator is missing. Reserve measured project speedup claims for locally matched jobs. |

Use MLPerf Inference rules as design guidance for reproducible scenarios, accuracy checks and latency reporting \[34\]. Our CCTV workload has a custom dataset and a continuous temporal context. Call the result a project benchmark. Use a closed-loop one-at-a-time test to measure isolated service time and a separate externally paced 25 Hz test to expose queue growth. Preserve the scheduled arrival time of each sample, including a missed sample. A test driver that sends the next frame only on completion hides overload.

Run identical recorded clips first and live video second. Exclude Jupyter rendering from the compute measurement and include all deployed service work in end-to-end results. Report both cold-start-to-first-valid-score and steady-state latency at a defined offered rate. Record the arrival, issue, hardware completion and user-visible publication clocks and timebases. Provide throughput, p50/p95/p99/max, drops by cause, board power and per-stream age. If a runner loses a frame, use the declared gap policy and label the resulting invalid window; dropping hard frames can bias both speed and accuracy.

Use paired repeated sessions with the same input order, thermally settled hardware and alternating candidate order. Analyze session-level or camera-level variation; overlapping windows are strongly dependent. Publish numerator/denominator and data quality for every percentage. Preserve energy measurement boundaries: total joules per analyzed frame and, if desired, idle-subtracted energy from a stated idle baseline. Derive speedup using identical boundaries and units. When uncertainty is large relative to the gain, keep the simpler release and repeat the critical comparison.

## Promotion sequence and stop rules

Rank candidate builds first by obligations met: integer identity for exact variants or locked quality criteria for a new model, safe recovery, timing closure, and the one-stream throughput/p99 targets. Then compare the constrained metrics using the agreed priority. For a DDR-limited design favor lower sustained bytes/frame at equal quality; for a routing-limited design favor the kernel that closes timing with realistic fanout. Use a Pareto comparison where one design saves power and another reduces latency. Record the trade-off instead of assigning an arbitrary composite score.

Set an investigation threshold before each run. For instance, if hardware fusion removes the predicted traffic but cannot improve throughput because decode dominates, retain its verified traffic benefit and direct the next experiment to capture/preprocessing. Use the measured stage fraction f in Amdahl’s relation 1 / \[(1−f)+f/s\]. An illustrative twofold speedup for a stage measured at 5% of elapsed serial time improves total latency by about 2.6%. For overlapping stages, use the observed critical path and frame interval instead. End a GRU rewrite that cannot change an agreed system goal unless it frees an otherwise limiting bank or DSP group.

# 14\. Release engineering and production acceptance

## Two deliverables with different owners

The IP release owner publishes a compatibility ledger covering package VLNV, packet ABI, CSR ABI, numeric profile ID, weight package version, supported board family, tool build and driver range. Separate a patch that changes implementation only from a change that alters visible arithmetic or packet interpretation. For additive features expose a discoverable capability bit; reject incompatible majors at initialization. Test old compatible drivers against a new package and a new driver against the oldest advertised device revision.

Each public IP release ships a one-page integration contract, address map, timing diagrams or waveform captures, parameter table, package metadata, reference test vectors, error list, reset table, example design, OOC utilization/timing with constraints and a known-limitations record. Run a clean example on a fresh checkout with documented tool prerequisites. Verify that the user can change one legal parameter and that an illegal parameter fails at elaboration or initialization with the documented error.

The appliance release owner binds the qualified versions into a reproducible board image and deployable bundle. Record model provenance, data split IDs, package integrity, overlay metadata, service configuration and rollback path. Use a least-privilege runtime where the platform permits, restrict update rights, and keep capture ownership separate from notebook diagnostics. Agree with the site on alert access, permitted video retention and the human review process before the pilot. Validate update rollback under loss of power at each persistent-state transition and verify the previously approved package can boot and pass its self-test again.

## Qualification sequence and handoff review

Bench qualification proceeds from raw loopback to framed loopback, standalone CNN and GRU replay, modular overlay replay, integrated replay, single-camera live capture, then repeated sessions under thermal and storage pressure. Site qualification adds camera-specific background hours, shadow-mode alerts and operator review. On production hardware repeat end-to-end timing, power, thermal soak, camera connectivity, boot recovery and update trials on the actual carrier/SOM variant. A peripheral, clock or thermal difference between carriers is grounds to repeat the affected acceptance tests.

Use a release record with a row for each requirement: owner, threshold and units, test ID, build and model hashes, evidence stage, observed result, pass/fail or pending, and review date. Link accepted deviations to an owner and expiry. A simulator estimate cannot fill the board column. A successful lab soak cannot fill the field row. Publish a failed test with its root cause, correction and repeat result so the handoff includes the recovery knowledge as well as the passing run.

Final demonstration for the IP engineer: import each package into a fresh design, query capabilities, load a valid model, reject an incompatible one, run an independent example, apply output backpressure and recover from a fault. Final demonstration for the deployment engineer: cold boot, replay a known clip, start live service, induce a camera disconnect, recover with a clean epoch, switch models, rollback and reproduce the published metrics. Sign off the two demonstrations separately.

## Standards-to-evidence register

**Conformance evidence matrix · Applicable practice, test and deliverable**

| Practice / scope | Executable check | Release evidence |
| :---- | :---- | :---- |
| AMBA AXI-Stream / AXI4-Lite \[16, 17\] | Independent AXI address/data arrival, stable payload under stall, byte strobes, final partial beat, backpressure, error drain and reset with pending completion. | Waveforms and assertions tied to named interface promises; list supported optional signals. |
| IP-XACT and Vivado packaging \[14, 15, 35, 36\] | Schema/namespace check, IP integrity check, isolated import, parameter rejection, address map and driver-to-hardware version check. | component.xml, file-set and VLNV record plus successful standalone CNN and GRU examples. |
| AMD clock/reset methodology \[37\] | Inventory every crossing. Check synchronizers, pulse handshakes, async FIFO and multi-bit snapshots. Exercise independent reset release, report\_cdc, clock interactions and scoped exceptions. | Per-crossing owner, review outcome, tool reports and waiver rationale; simulations augment structural and timing analysis. |
| Build provenance \[38\] | Verify model and artifact hashes at release; rebuild in a clean pinned environment; check that corrupted and cross-generation bundles fail validation. | Signed provenance, source and build IDs, tool/IP lock list, functional comparison and approved differences. |
| Authenticated updates \[39\] | Test new valid bundle, stale signed metadata, altered artifact, mismatched driver and interrupted activation. Rehearse an authorized local recovery. | Update/recovery logs, trust-root/version policy and cold-boot self-test for the selected known-good bundle. |
| Measurement methodology \[34\] | Separate quality and performance runs; tag precision, scenario and offered load. Reproduce one reported result from the frozen workload and run manifest. | Traceable benchmark record, exclusions and measurement boundary; scope labelled custom CCTV. |
| Field release · application-specific | Assign owners to acceptance criteria, collect independent camera exposure, review event misses, exercise failover and a human review workflow. | Pilot acceptance sheet plus production-carrier requalification record and open site obligations. |

Maintain two independent compatibility records. The machine-readable one describes ports, parameters, register addresses, packaging identity and version. The executable one verifies signed quantization, reset, error recovery, temporal state and latency promises. A consumer can instantiate an apparently valid IP and still interpret the numeric output incorrectly. Gate release on both records and hand the integrator a known-good vector for each declared profile.

Verify the native component.xml emitted by the pinned Vivado release against the namespace and conventions it actually uses. Record the schema, supported extensions, file sets, interface-to-clock associations, address units and VLNV. Accellera’s 1685-2022 schema is a reference for portable exchange. If a recipient requires another schema, make the conversion a separate artifact, validate it and repeat a clean consumer import. Do not mark the vendor package 1685-2022 compliant merely because it is IP-XACT-based \[35, 36\].

Plan a reproducible release with a signed provenance statement linking the model, model packer, HLS/RTL sources, constraints, vendor IP versions, tool image and output artifacts. Include the bitstream, HWH, model slices, driver, firmware assets and configuration in the release identity. An independent build must reproduce declared functional outputs; timestamped or nondeterministic vendor outputs require a documented comparison policy. A signed input manifest alone does not establish a SLSA assurance level \[38\].

Exercise both rollback paths. Local recovery may select a previously trusted, compatible image under an explicit recovery policy. Remote update metadata should reject stale, unsigned or mismatched bundles, and must bind the board and model generations to each other. Check interruption before and after activation, expired metadata under the device’s clock policy and return to service after rollback. TUF supplies a threat model and machinery for update authenticity and freshness; a project-specific implementation should claim only the behavior it actually tests \[39\].

## Deliver the research record with the IP

Attach a concise experiment ledger to each release. Every row names a hypothesis, citation, reference build, new build, numeric profile, model and data hashes, input trace, sample count, board/clock, evidence stage, observed delta, quality effect and disposition. Keep OOC estimates, routed utilization, board latency and site false alarms in separate columns. Include the best rejected candidate and the observation that rejected it. This allows a future engineer to revisit the decision when moving to a different device or a larger hidden size.

A field handoff needs an identified operator, authorization for representative source footage, a tested recovery procedure and measured behavior on the production hardware. Record product-specific assurance or certification requirements separately with their owner. These research and interoperability checks support a reusable accelerator and a reviewed pilot; formal railway certification would require a separately scoped application and assessment.

# 15\. References, tool specifications and design reading

[\[1\] AMD K26 programmable logic resources, DS987](https://docs.amd.com/r/en-US/ds987-k26-som/Programmable-Logic)

[\[2\] AMD KV260 reliability and intended use, DS986](https://docs.amd.com/r/en-US/ds986-kv260-starter-kit/Reliability)

[\[3\] Sandler et al., MobileNetV2: Inverted Residuals and Linear Bottlenecks](https://openaccess.thecvf.com/content_cvpr_2018/html/Sandler_MobileNetV2_Inverted_Residuals_CVPR_2018_paper.html)

[\[4\] Torchvision MobileNetV2 implementation](https://docs.pytorch.org/vision/main/_modules/torchvision/models/mobilenetv2.html)

[\[5\] PyTorch GRU equations, gate ordering and framework conventions](https://docs.pytorch.org/docs/main/generated/torch.nn.GRU.html)

[\[6\] Qararyah et al., FiBHA: Fixed Budget Hybrid CNN Accelerator](https://research.chalmers.se/en/publication/534175)

[\[7\] Xilinx Kria-PYNQ setup and supported images](https://github.com/Xilinx/Kria-PYNQ/blob/main/README.md)

[\[8\] Jacob et al., Quantization and Training of Neural Networks for Efficient Integer-Arithmetic-Only Inference](https://openaccess.thecvf.com/content_cvpr_2018/html/Jacob_Quantization_and_Training_CVPR_2018_paper.html)

[\[9\] AMD Vitis HLS configuration and out-of-context implementation, UG1399 (2025.2)](https://docs.amd.com/r/2025.2-English/ug1399-vitis-hls/Running-Implementation)

[\[10\] AMD C/RTL co-simulation controls, UG1399](https://docs.amd.com/r/2025.2-English/ug1399-vitis-hls/cosim_design)

[\[11\] PYNQ DMA packet handling and length configuration](https://pynq.readthedocs.io/en/latest/pynq_libraries/dma.html)

[\[12\] AMD Vivado post-implementation simulation, UG900 (2025.2)](https://docs.amd.com/r/2025.2-English/ug900-vivado-logic-simulation/Post-Implementation-Simulation)

[\[13\] PYNQ device buffers and synchronization](https://pynq.readthedocs.io/en/latest/pynq_libraries/allocate.html)

[\[14\] AMD UG1118 (2025.2) · Top-level HDL requirements and SV packaging wrappers](https://docs.amd.com/r/2025.2-English/ug1118-vivado-creating-packaging-custom-ip/Top-Level-HDL-Requirements)

[\[15\] AMD UG1118 (2025.2) · IP versioning and revision control](https://docs.amd.com/r/2025.2-English/ug1118-vivado-creating-packaging-custom-ip/Versioning-and-Revision-Control)

[\[16\] Arm IHI 0051 · AMBA AXI-Stream protocol specification](https://developer.arm.com/documentation/ihi0051/latest/)

[\[17\] Arm IHI 0022H · AMBA AXI and ACE protocol specification, including AXI4-Lite](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf)

[\[18\] AMD UG573 · UltraRAM features, port organization and timing](https://docs.amd.com/r/en-US/ug573-ultrascale-memory-resources/UltraRAM-Key-Features)

[\[19\] Sommer et al. · DSP-Packing: Squeezing Low-precision Arithmetic into FPGA DSP Blocks](https://arxiv.org/abs/2203.11028)

[\[20\] FINN project · Per-node RTL-simulation and FIFO-sizing transformations](https://finn.readthedocs.io/en/latest/source_code/finn.transformation.fpgadataflow.html)

[\[21\] Williams, Waterman & Patterson · Roofline performance modelling](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2008/EECS-2008-134.html)

[\[22\] Timeloop / Accelergy · Mapping, workload and architecture models](https://timeloop.csail.mit.edu/)

[\[23\] Chen et al. · Eyeriss v2, data delivery for compact and sparse networks](https://arxiv.org/abs/1807.07928)

[\[24\] IEEE TCAS-II, 2026 · Sparse MobileNetV1 FPGA accelerator with chained DSC and computation-aware pruning](https://doi.org/10.1109/TCSII.2026.3726178)

[\[25\] EdgeDRNN · Recurrent neural network accelerator for edge inference](https://arxiv.org/abs/2012.13600)

[\[26\] Molina et al., 2026 · 2QGRU, power-of-two quantization for FPGA GRUs](https://doi.org/10.3390/electronics15040722)

[\[27\] Yao et al. · HAWQ-V3, dyadic quantization and hardware-aware precision assignment](https://proceedings.mlr.press/v139/yao21a.html)

[\[28\] Yang et al. · NetAdapt, direct platform measurements for network adaptation](https://arxiv.org/abs/1804.03230)

[\[29\] Hinton, Vinyals & Dean · Distilling the Knowledge in a Neural Network](https://arxiv.org/abs/1503.02531)

[\[30\] Ye et al., September 2026 · DiffLUT-Net, FPGA-native learned logic (preprint)](https://arxiv.org/abs/2609.09254)

[\[31\] Arm Compute Library · CPU kernels, build support and source releases](https://github.com/ARM-software/ComputeLibrary)

[\[32\] FINN · Brevitas export and QONNX ingestion](https://finn.readthedocs.io/en/latest/brevitas_export.html)

[\[33\] AMD Vitis AI UG1414 · Supported operators and DPU limitations for the 3.5 generation](https://docs.amd.com/r/3.5-English/ug1414-vitis-ai/Supported-Operators-and-DPU-Limitations?contentId=1uHTjWGz8XZYYN4HWvDKxw)

[\[34\] MLCommons · MLPerf Inference benchmark rules and scenarios](https://github.com/mlcommons/inference_policies/blob/master/inference_rules.adoc)

[\[35\] Accellera · IP-XACT standards, schemas, extensions and 1685-2022 examples](https://www.accellera.org/downloads/standards/ip-xact)

[\[36\] AMD UG1118 (2025.2) · Vivado IP Packager output files](https://docs.amd.com/r/2025.2-English/ug1118-vivado-creating-packaging-custom-ip/Outputs-from-IP-Packager)

[\[37\] AMD UG949 (2025.2) · UltraFast guidance on clock-domain crossing](https://docs.amd.com/r/2025.2-English/ug949-vivado-design-methodology/Clock-Domain-Crossing)

[\[38\] SLSA v1.2 · Build provenance specification](https://slsa.dev/spec/v1.2/build-provenance)

[\[39\] The Update Framework · Secure software update specification, consulted November 2026](https://theupdateframework.github.io/specification/latest/)

[\[40\] IEEE MWSCAS, 2025 · FPGA-based hardware accelerator for MobileNetV2 bottleneck residual blocks](https://doi.org/10.1109/MWSCAS53549.2025.11244457)

[\[41\] Xilinx/finn-hlslib · inspected commit cc8db47b59555df8b3993666cf2cfb6b9e57ff5a](https://github.com/Xilinx/finn-hlslib/tree/cc8db47b59555df8b3993666cf2cfb6b9e57ff5a)

[\[42\] SensorsINI/EdgeDRNN · inspected commit 1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c](https://github.com/SensorsINI/EdgeDRNN/tree/1fd8fdd910afbffb6c681d2e42d6d0c187a5df1c)

[\[43\] fastmachinelearning/hls4ml · inspected commit b493ea7fd282ed969e250a94a0738f29f144ac7e](https://github.com/fastmachinelearning/hls4ml/tree/b493ea7fd282ed969e250a94a0738f29f144ac7e)

[\[44\] alexforencich/verilog-axis · inspected commit 48ff7a7e2ef782cf778d47910cf85835c64b1bce](https://github.com/alexforencich/verilog-axis/tree/48ff7a7e2ef782cf778d47910cf85835c64b1bce)

[\[45\] AMD UG573 · UltraScale block RAM organization and supported port modes](https://docs.amd.com/r/en-US/ug573-ultrascale-memory-resources/Block-RAM-Summary)

[\[46\] AMD Vitis tutorial · Manual FIFO sizing in a dataflow design](https://docs.amd.com/r/en-US/Vitis-Tutorials-Vitis-Hardware-Acceleration/Manual-FIFO-Sizing)

