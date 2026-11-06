# Integer numerical contract (generated)

Source of truth: `model/integer_oracle/oracle.py`.  Regenerate with
`python3 tools/gen_docs.py`.  Every boundary below is executed, not
transcribed.

## Frozen formats

| Tensor | Format | Scale | Rounding |
| :---- | :---- | :---- | :---- |
| Weights | INT8 symmetric | per-output-channel | n/a (exact) |
| Activations | INT8, zero point = real zero | per-tensor | exact |
| Accumulators | INT32 | n/a | exact |
| Gate inputs | Q7.10 INT16 | 2^-10 | round-half-to-even |
| Gate LUT outputs / in-flight hidden | Q1.15 INT16 | 2^-15 | table lookup |
| Committed hidden | Q7.8 INT8 | 2^-7 | round-half-to-even, saturate |

## Boundary witnesses (executed against the oracle)

| Boundary | Expression | Value |
| :---- | :---- | :---- |
| Requantization tie (positive) | `requantize(1000000, 18226, 21, 0)` | 127 |
| Requantization tie (negative) | `requantize(-1000001, 18226, 21, 0)` | -128 |
| Most-negative accumulator | `requantize(-2147483648, 18226, 21, 0)` | -128 |
| Sigmoid at zero | `sigmoid_q15(0)` | 16384 |
| Sigmoid at Q7.10 saturation | `sigmoid_q15(32767)` | 32767 |
| Tanh at zero | `tanh_q15(0)` | 0 |
| Tanh at Q7.10 saturation | `tanh_q15(32767)` | 32767 |
| Round-half-even(5, 2) | `round_half_even(5, 2)` | 2 |
| Round-half-even(-5, 2) | `round_half_even(-5, 2)` | -2 |

## GRU update rule (PyTorch gate order r, z, n)

```
a = W_ih x + b_ih ;  u = W_hh h_prev + b_hh
r = sigmoid(a_r + u_r) ;  z = sigmoid(a_z + u_z)
n = tanh(a_n + r * u_n)   # reset gate multiplies the candidate
                          # affine result including its recurrent bias
h = (1 - z) * n + z * h_prev
```

The reset gate multiplies the candidate affine result including its
recurrent bias; the committed state is `h >> 8` with round-half-to-even
and saturation, and the next step re-expands it with an exact `<< 8`.

## Executed operator checks

The oracle self-check below runs the full operator set on the zero
state; the printed digest must be reproduced by the HLS C++ testbench
and by the RTL scoreboard.

```
gru_sequence self-check digest (2 steps, zero input): 0
gru_score(zero state) = 0
```
