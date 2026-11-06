"""Bit-accurate integer reference for the frozen numerical contract.

This module is the independent software oracle (roadmap Phase 4).  Every
integer boundary declared here must be reproduced exactly by the HLS C++
sources and by the RTL.

Frozen formats
--------------
INT8 weights, symmetric, per-output-channel scales.
INT8 activations, per-tensor scale, zero point representing real zero.
INT32 accumulators for every dot product and bias add.
Gate-domain inputs: Q7.10 (INT16, scale 2^-10), round-half-to-even.
Gate LUT outputs and the in-flight hidden state: Q1.15 (INT16, scale 2^-15).
Committed hidden state: INT8, Q7.8 (scale 2^-7).  Committing is an exact
arithmetic shift by 8 with round-half-to-even and saturation; the next step
re-expands the committed state with an exact left shift by 8, so the
recurrence operates on the state actually stored in hardware.

GRU gate order is the exported PyTorch order (reset, update, new):
    a = W_ih x + b_ih ;  u = W_hh h_prev + b_hh
    r = sigmoid(a_r + u_r) ;  z = sigmoid(a_z + u_z)
    n = tanh(a_n + r * u_n)
    h = (1 - z) * n + z * h_prev
The reset gate multiplies the candidate recurrent affine result, including
its recurrent bias.
"""

from __future__ import annotations

from dataclasses import dataclass, field

Int = int

Q15_ONE = 32767  # Q1.15 representation of 1.0 (positive full scale)
Q15_MIN = -32768
GATE_FRAC = 10  # Q7.10 gate-domain inputs
HIDDEN_SHIFT = 8  # Q1.15 -> Q7.8 committed hidden state


def sat(lo: int, hi: int, v: int) -> int:
    return max(lo, min(hi, v))


def round_half_even(num: int, den: int) -> int:
    """Exact round-half-to-even of num/den for den > 0."""
    q, r = divmod(num, den)
    r2 = 2 * r
    if r2 > den or (r2 == den and (q & 1)):
        q += 1
    elif r2 < -den or (r2 == -den and (q & 1)):
        q -= 1
    return q


def requantize(
    acc: int,
    multiplier: int,
    shift: int,
    zero_point: int = 0,
    lo: int = -128,
    hi: int = 127,
) -> int:
    """Frozen requantization record (roadmap Section 12).

    The accumulator is multiplied by a fixed-point multiplier and shifted
    right by `shift`, with round-half-to-even applied to the exact product
    before the shift, then the output zero point is added and the result
    saturates to the output type.
    """
    product = acc * multiplier
    rounded = round_half_even(product, 1 << shift) if shift > 0 else product
    return sat(lo, hi, rounded + zero_point)


# ---------------------------------------------------------------------------
# Activation LUTs.  Domain: Q7.10 signed input, Q1.15 signed output.
# ---------------------------------------------------------------------------


def _build_sigmoid() -> list[int]:
    return [
        round(32767.0 / (1.0 + pow(2.718281828459045, -i / 1024.0)))
        for i in range(-32768, 32768)
    ]


def _build_tanh() -> list[int]:
    e = 2.718281828459045
    return [
        round(32767.0 * (pow(e, 2 * i / 1024.0) - 1) / (pow(e, 2 * i / 1024.0) + 1))
        for i in range(-32768, 32768)
    ]


_SIGMOID_LUT: list[int] = []
_TANH_LUT: list[int] = []


def _ensure_luts() -> None:
    global _SIGMOID_LUT, _TANH_LUT
    if not _SIGMOID_LUT:
        _SIGMOID_LUT = _build_sigmoid()
        _TANH_LUT = _build_tanh()


def sigmoid_q15(i: int) -> int:
    """Saturating sigmoid of a Q7.10 input, returned in Q1.15."""
    _ensure_luts()
    return _SIGMOID_LUT[sat(-32768, 32767, i) + 32768]


def tanh_q15(i: int) -> int:
    """Saturating tanh of a Q7.10 input, returned in Q1.15."""
    _ensure_luts()
    return _TANH_LUT[sat(-32768, 32767, i) + 32768]


# ---------------------------------------------------------------------------
# Convolution operators at the frozen boundaries.
# ---------------------------------------------------------------------------


def conv2d_int8(
    x: list[list[list[int]]],
    w: list[list[list[list[int]]]],
    b: list[int],
    zx: int,
    mult: list[int],
    shift: list[int],
    zout: int,
    stride: int,
    pad: int,
    act_lo: int = -128,
    act_hi: int = 127,
) -> list[list[list[int]]]:
    """Signed INT8 convolution with INT32 accumulation.

    Padding represents real zero: the pad value is the input zero point
    `zx`.  Reduction order is input-channel outermost, then kernel rows and
    columns; the bias is added once after the full reduction.
    """
    hin, win, cin = len(x), len(x[0]), len(x[0][0])
    cout = len(w)
    kh, kw = len(w[0][0]), len(w[0][0][0])
    hout = (hin + 2 * pad - kh) // stride + 1
    wout = (win + 2 * pad - kw) // stride + 1
    out = [[[0 for _ in range(wout)] for _ in range(hout)] for _ in range(cout)]
    for oc in range(cout):
        for oy in range(hout):
            for ox in range(wout):
                acc: Int = b[oc]
                for ic in range(cin):
                    for ky in range(kh):
                        for kx in range(kw):
                            iy = oy * stride + ky - pad
                            ix = ox * stride + kx - pad
                            if 0 <= iy < hin and 0 <= ix < win:
                                acc += (x[iy][ix][ic] - zx) * w[oc][ic][ky][kx]
                out[oc][oy][ox] = sat(
                    act_lo, act_hi, requantize(acc, mult[oc], shift[oc], zout)
                )
    return out


def depthwise_conv2d_int8(
    x: list[list[list[int]]],
    w: list[list[int]],
    b: list[int],
    zx: int,
    mult: list[int],
    shift: list[int],
    zout: int,
    stride: int,
    pad: int,
    act_lo: int = -128,
    act_hi: int = 127,
) -> list[list[list[int]]]:
    """Channel-wise depthwise convolution, one filter per channel."""
    hin, win, cin = len(x), len(x[0]), len(x[0][0])
    kh, kw = len(w[0]), len(w[0][0])
    hout = (hin + 2 * pad - kh) // stride + 1
    wout = (win + 2 * pad - kw) // stride + 1
    out = [[[0 for _ in range(wout)] for _ in range(hout)] for _ in range(cin)]
    for c in range(cin):
        for oy in range(hout):
            for ox in range(wout):
                acc: Int = b[c]
                for ky in range(kh):
                    for kx in range(kw):
                        iy = oy * stride + ky - pad
                        ix = ox * stride + kx - pad
                        if 0 <= iy < hin and 0 <= ix < win:
                            acc += (x[iy][ix][c] - zx) * w[c][ky][kx]
                out[c][oy][ox] = sat(
                    act_lo, act_hi, requantize(acc, mult[c], shift[c], zout)
                )
    return out


def relu6(x: list[list[list[int]]], zx: int, scale_shift: int = 0) -> list[list[list[int]]]:
    """Clamp to the quantized representation of the [0, 6] range."""
    lo = zx
    hi = zx + (6 << scale_shift)
    return [
        [[sat(lo, hi, v) for v in plane] for plane in channel]
        for channel in x
    ]


# ---------------------------------------------------------------------------
# GRU.  Gate order is (reset, update, new) as exported by PyTorch.
# ---------------------------------------------------------------------------


def _matvec(m: list[list[int]], v: list[int]) -> list[int]:
    return [sum(row[i] * v[i] for i in range(len(v))) for row in m]


@dataclass
class GruWeights:
    """INT8 GRU weights with the frozen requantization records.

    mult_gx/shift_gx requantize the input affine a to Q7.10; mult_gh and
    shift_gh requantize the recurrent affine u to Q7.10.  Both must be
    applied before the gate sum so that branch scales are aligned before
    addition.
    """

    w_ih: list[list[int]]  # [3H, I]
    w_hh: list[list[int]]  # [3H, H]
    b_ih: list[int]  # [3H]
    b_hh: list[int]  # [3H]
    mult_gx: int
    shift_gx: int
    mult_gh: int
    shift_gh: int
    s_x: float = 1.0 / 128.0
    s_h: float = 1.0 / 128.0
    s_wih: float = 1.0 / 128.0
    s_whh: float = 1.0 / 128.0
    head_w: list[int] = field(default_factory=list)  # [H] classifier weights
    head_b: int = 0


def affine_input(x: list[int], w: GruWeights) -> list[int]:
    """a = W_ih x + b_ih in INT32 (the cacheable input projection)."""
    a = _matvec(w.w_ih, x)
    return [a[i] + w.b_ih[i] for i in range(len(a))]


def affine_recurrent(h: list[int], w: GruWeights) -> list[int]:
    """u = W_hh h + b_hh in INT32."""
    u = _matvec(w.w_hh, h)
    return [u[i] + w.b_hh[i] for i in range(len(u))]


def gru_cell_int8(
    x: list[int],
    h_prev: list[int],
    w: GruWeights,
    a: list[int] | None = None,
    lut_sigmoid=sigmoid_q15,
    lut_tanh=tanh_q15,
) -> list[int]:
    """One GRU step at the frozen integer boundaries.

    `h_prev` is the committed Q7.8 hidden state; the recurrence operates on
    the state actually stored in hardware, re-expanded to Q1.15 by an exact
    left shift.  `a` may be supplied precomputed (the cached input
    projection); it must be the identical INT32 intermediate, at the same
    precision and rounding location, that the uncached path consumes.
    """
    h_size = len(h_prev)
    if a is None:
        a = affine_input(x, w)
    u = affine_recurrent(h_prev, w)
    h_prev_q15 = [h << HIDDEN_SHIFT for h in h_prev]
    out = []
    for i in range(h_size):
        gi = requantize(a[i] + u[i], w.mult_gx, w.shift_gx, 0,
                        lo=Q15_MIN, hi=Q15_ONE)
        zi = requantize(a[h_size + i] + u[h_size + i], w.mult_gx, w.shift_gx,
                        0, lo=Q15_MIN, hi=Q15_ONE)
        ni = requantize(a[2 * h_size + i] + u[2 * h_size + i], w.mult_gx,
                        w.shift_gx, 0, lo=Q15_MIN, hi=Q15_ONE)
        r = lut_sigmoid(gi)
        z = lut_sigmoid(zi)
        n = lut_tanh(ni)
        # h = (1 - z) * n + z * h_prev, all in Q1.15.  The reset gate
        # multiplies the candidate affine result including its recurrent
        # bias.  Each product is rounded half-to-even back to Q1.15 before
        # the saturating sum.
        rn = round_half_even(n * r, Q15_ONE)
        zh = round_half_even(z * h_prev_q15[i], Q15_ONE)
        keep = round_half_even((Q15_ONE - z) * n, Q15_ONE)
        h_q15 = sat(Q15_MIN, Q15_ONE, keep + zh)
        out.append(sat(-128, 127, round_half_even(h_q15, 1 << HIDDEN_SHIFT)))
    return out


def gru_sequence_int8(
    xs: list[list[int]],
    w: GruWeights,
    window: int = 32,
) -> list[list[int]]:
    """Dense replay of one window from zero initial state.

    Returns the committed INT8 hidden state after every step.
    """
    h_size = len(w.w_hh) // 3
    h = [0] * h_size
    states = []
    for t in range(window):
        x = xs[t] if t < len(xs) else xs[-1]
        h = gru_cell_int8(x, h, w)
        states.append(h[:])
    return states


def gate_order_witness(w: GruWeights, x, h) -> bool:
    """Witness that the reset gate multiplies the candidate affine result
    including its recurrent bias: perturbing b_hh of the candidate section
    must be able to change the output when r < 1."""
    w2 = GruWeights(
        w_ih=[row[:] for row in w.w_ih],
        w_hh=[row[:] for row in w.w_hh],
        b_ih=w.b_ih[:],
        b_hh=w.b_hh[:],
        mult_gx=w.mult_gx, shift_gx=w.shift_gx,
        mult_gh=w.mult_gh, shift_gh=w.shift_gh,
    )
    w2.b_hh[2 * len(h)] += 4096
    h_perturbed = gru_cell_int8(x, h, w2)
    h_base = gru_cell_int8(x, h, w)
    return h_perturbed != h_base


def gru_score_int8(h: list[int], w: GruWeights) -> int:
    """Single-logit classifier: 128 weights, one bias, 128 MACs."""
    return sum(h[i] * w.head_w[i] for i in range(len(h))) + w.head_b
