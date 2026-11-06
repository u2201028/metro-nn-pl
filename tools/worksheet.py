"""Workload, memory and cycle worksheets for MobileNetV2 + GRU on Kria KV260.

Counting rules (roadmap Section 2): a MAC is one multiply-accumulate; only
convolution and dense matrix products are counted.  MAC counts omit pooling,
gates, bias adds, rescaling, loop overhead, data movement and stalls.

Architecture: torchvision MobileNetV2 at 224 x 224 RGB input, width
multiplier 1.0, ImageNet classifier removed.  Stem 3x3 s2 3->32, bottleneck
groups (t, c, n, s) with the first block at the group stride, final 1x1
320 -> 1280, then global average pooling to 1,280 features.

Device model: Kria KV260 / K26 SOM - 144 x 36 KiB BRAM36, 64 x 288 KiB
UltraRAM, 1,248 DSP slices, 117,120 LUTs.
"""

from __future__ import annotations

KIB = 1024
MIB = KIB * KIB

# ---------------------------------------------------------------------------
# Device model (Kria KV260 / K26 SOM)
# ---------------------------------------------------------------------------

KV260 = dict(
    bram36_count=144,
    uram_count=64,
    dsp_count=1248,
    lut_count=117_120,
    bram36_kibit=36,
    uram_kibit=288,
)


def device_budget() -> dict:
    bram_bytes = KV260["bram36_count"] * KV260["bram36_kibit"] * KIB // 8
    uram_bytes = KV260["uram_count"] * KV260["uram_kibit"] * KIB // 8
    return dict(
        bram36_count=KV260["bram36_count"],
        uram_count=KV260["uram_count"],
        dsp_count=KV260["dsp_count"],
        lut_count=KV260["lut_count"],
        bram36_bytes=bram_bytes,
        uram_bytes=uram_bytes,
        total_onchip_bytes=bram_bytes + uram_bytes,
    )


# ---------------------------------------------------------------------------
# MobileNetV2 backbone, ImageNet classifier removed.
# ---------------------------------------------------------------------------

STEM = ("stem", 3, 32, 3, 2, "conv3x3")
BOTTLENECKS = [
    ("c16", 1, 16, 1, 1),
    ("c24", 6, 24, 2, 2),
    ("c32", 6, 32, 3, 2),
    ("c64", 6, 64, 4, 2),
    ("c96", 6, 96, 3, 1),
    ("c160", 6, 160, 3, 2),
    ("c320", 6, 320, 1, 1),
]
HEAD = ("final_1x1", 320, 1280, 1, 1, "conv1x1")


def _out_size(h: int, w: int, stride: int) -> tuple[int, int]:
    if stride == 2:
        return (h + 1) // 2, (w + 1) // 2
    return h, w


def conv_layers() -> list[dict]:
    """Every convolution layer of the exported reference graph."""
    layers: list[dict] = []
    name, cin, cout, k, s, kind = STEM
    h = w = 224
    hout, wout = _out_size(h, w, s)
    layers.append(
        dict(
            name=name,
            kind=kind,
            cin=cin,
            cout=cout,
            k=k,
            stride=s,
            hin=h,
            win=w,
            hout=hout,
            wout=wout,
            weights=k * k * cin * cout,
            macs=hout * wout * k * k * cin * cout,
        )
    )
    h, w = hout, wout
    cin = STEM[2]
    for name, t, c, n, s in BOTTLENECKS:
        for i in range(n):
            stride = s if i == 0 else 1
            hidden = cin * t
            hout, wout = _out_size(h, w, stride)
            if t != 1:
                layers.append(
                    dict(
                        name=f"{name}_{i}_expand",
                        kind="conv1x1",
                        cin=cin,
                        cout=hidden,
                        k=1,
                        stride=1,
                        hin=h,
                        win=w,
                        hout=h,
                        wout=w,
                        weights=cin * hidden,
                        macs=h * w * cin * hidden,
                    )
                )
            layers.append(
                dict(
                    name=f"{name}_{i}_depthwise",
                    kind="dw3x3",
                    cin=hidden,
                    cout=hidden,
                    k=3,
                    stride=stride,
                    hin=h,
                    win=w,
                    hout=hout,
                    wout=wout,
                    weights=9 * hidden,
                    macs=hout * wout * 9 * hidden,
                )
            )
            layers.append(
                dict(
                    name=f"{name}_{i}_project",
                    kind="conv1x1",
                    cin=hidden,
                    cout=c,
                    k=1,
                    stride=1,
                    hin=hout,
                    win=wout,
                    hout=hout,
                    wout=wout,
                    weights=hidden * c,
                    macs=hout * wout * hidden * c,
                )
            )
            cin, h, w = c, hout, wout
    name, cin, cout, k, s, kind = HEAD
    layers.append(
        dict(
            name=name,
            kind=kind,
            cin=cin,
            cout=cout,
            k=k,
            stride=s,
            hin=h,
            win=w,
            hout=h,
            wout=w,
            weights=cin * cout,
            macs=h * w * cin * cout,
        )
    )
    return layers


# ---------------------------------------------------------------------------
# GRU temporal head.  PyTorch gate order: reset, update, new.
#   a = W_ih x + b_ih ;  u = W_hh h_prev + b_hh
#   r = sigmoid(a_r + u_r) ;  z = sigmoid(a_z + u_z)
#   n = tanh(a_n + r * u_n)
#   h = (1 - z) * n + z * h_prev
# ---------------------------------------------------------------------------

I = 1280  # pooled features per frame
H = 128  # hidden size
T = 32  # frames per window


def gru_weights_bytes() -> int:
    return 3 * H * (I + H)


def gru_step_macs() -> int:
    return 3 * H * (I + H)


def gru_dense_window_macs() -> int:
    return T * gru_step_macs()


def gru_cached_window_macs() -> int:
    """Steady-state cost with the input projection cached per frame."""
    return 3 * H * I + T * 3 * H * H


# ---------------------------------------------------------------------------
# Worksheets
# ---------------------------------------------------------------------------


def memory_worksheet() -> dict:
    layers = conv_layers()
    total_weights = sum(l["weights"] for l in layers)
    total_macs = sum(l["macs"] for l in layers)
    early = next(l for l in layers if l["name"] == "c24_0_expand")
    early_tensor = early["cout"] * early["hout"] * early["wout"]
    return dict(
        layers=layers,
        total_weights=total_weights,
        total_macs=total_macs,
        early_expansion_tensor_bytes=early_tensor,
    )


def device_worksheet(ws: dict) -> dict:
    dev = device_budget()
    weights = ws["total_weights"]
    return dict(
        bram36_bytes=dev["bram36_bytes"],
        uram_bytes=dev["uram_bytes"],
        total_onchip_bytes=dev["total_onchip_bytes"],
        weight_bytes=weights,
        weight_share_pct=100.0 * weights / dev["total_onchip_bytes"],
        remaining_bytes=dev["total_onchip_bytes"] - weights,
        early_expansion_bytes=ws["early_expansion_tensor_bytes"],
    )


def traffic_worksheet(ws: dict, fps: float = 25.0) -> dict:
    e = ws["early_expansion_tensor_bytes"]
    return dict(
        early_expansion_one_way_bytes=e,
        early_expansion_rw_bytes=2 * e,
        early_expansion_mbps=fps * 2 * e / MIB,
        last_1x1_weight_bytes=next(
            l["weights"] for l in ws["layers"] if l["name"] == "final_1x1"
        ),
        last_1x1_mbps=fps
        * next(l["weights"] for l in ws["layers"] if l["name"] == "final_1x1")
        / MIB,
    )


def budget_worksheet(ws: dict, mhz: float = 150.0) -> dict:
    macs = ws["total_macs"]
    gru_dense = gru_dense_window_macs()
    gru_cached = gru_cached_window_macs()
    cycles_per_frame = mhz * 1e6 / 25.0
    return dict(
        steady_macs_per_frame=macs,
        steady_gmacs_per_s=macs * 25.0 / 1e9,
        macs_per_cycle_at_150mhz=macs / cycles_per_frame,
        gru_dense_window_macs=gru_dense,
        gru_cached_window_macs=gru_cached,
        gru_dense_reduction_pct=100.0 * (1.0 - gru_cached / gru_dense),
        gru_dense_model_wide_reduction_pct=100.0
        * (1.0 - gru_cached / (gru_dense + macs)),
    )


def full_worksheet() -> dict:
    ws = memory_worksheet()
    return dict(
        memory=ws,
        device=device_worksheet(ws),
        traffic=traffic_worksheet(ws),
        budget=budget_worksheet(ws),
    )


def format_bytes(n: int) -> str:
    if n >= MIB:
        return f"{n / MIB:.2f} MiB"
    if n >= KIB:
        return f"{n / KIB:.1f} KiB"
    return f"{n} B"


def markdown_tables(ws: dict) -> str:
    mem = ws.get("memory", ws) if isinstance(ws, dict) else ws
    dev = device_worksheet(mem)
    bud = budget_worksheet(mem)
    layers = mem["layers"]
    out = ["| Layer | Weights B | MACs/frame |", "| :---- | ----: | ----: |"]
    for l in layers:
        out.append(f"| {l['name']} | {l['weights']:,} | {l['macs']:,} |")
    out.append(
        f"| **total** | **{sum(l['weights'] for l in layers):,}** |"
        f" **{sum(l['macs'] for l in layers):,}** |"
    )
    out += [
        "",
        f"BRAM36: {format_bytes(dev['bram36_bytes'])}"
        f" ({dev['weight_share_pct']:.1f}% used by weights)",
        f"UltraRAM: {format_bytes(dev['uram_bytes'])}",
        f"On-chip total: {format_bytes(dev['total_onchip_bytes'])};"
        f" after weights {format_bytes(dev['remaining_bytes'])} remain",
        f"Early expansion tensor: {format_bytes(dev['early_expansion_bytes'])}"
        f" ({format_bytes(2 * dev['early_expansion_bytes'])} per frame write+read)",
        f"Steady state: {bud['steady_macs_per_frame']:,} MACs/frame"
        f" = {bud['steady_gmacs_per_s']:.2f} GMAC/s at 25 FPS",
        f"Required useful MACs/cycle at 150 MHz:"
        f" {bud['macs_per_cycle_at_150mhz']:.2f}"
        " (a 128-lane design needs 39.3% sustained utilization)",
    ]
    return "\n".join(out)


if __name__ == "__main__":
    ws = full_worksheet()
    print(markdown_tables(ws))
