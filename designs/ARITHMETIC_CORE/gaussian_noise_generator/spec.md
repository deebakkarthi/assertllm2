# gng Design Specification

## 1. Introduction
`gng` is a Gaussian noise generator IP core that produces white Gaussian noise samples with standard normal distribution. The core combines:

- a 64-bit combined Tausworthe generator (CTG) for uniform random sequence generation, and
- an inverse-CDF approximation datapath (ICDF interpolation) to transform uniform samples into Gaussian-distributed output samples.

The output is a signed 16-bit fixed-point sample in `s<16,11>` format.

## 2. Module Diagram

## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock. Single clock domain for control and datapath. |
| `rstn` | Input | 1 | System synchronous reset, active low. |
| `ce` | Input | 1 | Clock enable for input sample generation/acceptance. |
| `valid_out` | Output | 1 | Output sample valid indicator. |
| `data_out` | Output | 16 | Output Gaussian sample in fixed-point format `s<16,11>`. |

### 3.1 Parameters

| Parameter | Width | Description |
| --- | --- | --- |
| `INIT_Z1` | 64 | Initial CTG state value for generator branch 1. |
| `INIT_Z2` | 64 | Initial CTG state value for generator branch 2. |
| `INIT_Z3` | 64 | Initial CTG state value for generator branch 3. |

### 3.2 Interface Semantics

- `ce` controls advancement of the CTG internal state. When `ce=0`, CTG state does not advance.
- `valid_out` indicates that `data_out` corresponds to a completed interpolation pipeline result.
- The documented timing behavior is that `valid_out` asserts 11 clock cycles after `ce` assertion. With continuous `ce=1`, output samples are produced every cycle after pipeline fill.
- `data_out` is always driven by registered datapath logic; consumers should use `valid_out` as the qualifier for sample validity.

## 4. Functional Description

### 4.1 Operation Overview

The core generates Gaussian-distributed samples by transforming uniformly distributed random values:

1. CTG generates a 64-bit uniform random value.
2. ICDF interpolation maps that value to a Gaussian-domain sample using piecewise second-order polynomial approximation.
3. The mapped value is quantized/rounded to 16-bit signed fixed-point output (`s<16,11>`).

### 4.2 Uniform Random Source (CTG)

The CTG submodule maintains three 64-bit state registers and updates them using Tausworthe recurrences. The three updated branches are XOR-combined to form a 64-bit uniform output word.

The design documentation characterizes the resulting period as approximately `2^176`.

### 4.3 Gaussian Mapping (ICDF Approximation)

The interpolation path implements a segmented approximation of inverse normal CDF behavior:

- The sign bit is extracted from the random input.
- A leading-zero detector on the magnitude-related bits identifies the segment class.
- Segment/address selection drives a coefficient lookup table (`c0`, `c1`, `c2`).
- A masked local variable `x` is formed for interpolation within the selected segment.
- A second-order polynomial is evaluated in pipelined form: `y = (C2*x + C1)*x + C0`.
- Truncation/rounding and sign restoration produce the final 16-bit signed output sample.

### 4.4 Validity and Sequencing

- `gng_ctg` emits `valid_out_ctg` from `ce` through a registered path.
- `gng_interp` pipelines both data and valid through internal registers and asserts top-level `valid_out` after internal latency.
- During reset, valid outputs are cleared; after reset release, valid/data timing follows the normal pipeline fill behavior.

## 5. Implementation Details

### 5.1 Top-Level Structure

Top-level `gng` is a two-stage composition:

- `gng_ctg` (`ce`-driven uniform generator), followed by
- `gng_interp` (ICDF interpolation and output formatting).

Interface connection is direct: `gng_ctg.valid_out/data_out` feed `gng_interp.valid_in/data_in`.

### 5.2 `gng_ctg` Control/Data Realization

- State registers `z1`, `z2`, `z3` are loaded from `INIT_Z1/2/3` on active-low reset.
- On each cycle with `ce=1`, each state register updates to its branch-specific next-state recurrence value.
- CTG output data register captures `z1_next ^ z2_next ^ z3_next`.
- CTG valid register captures `ce`.

This makes CTG a synchronous, enable-controlled uniform generator with registered output and valid signaling.

### 5.3 `gng_interp` Datapath Realization

`gng_interp` is a pipelined interpolation datapath comprising:

- `gng_lzd`: leading-zero detection over `data_in[63:3]`.
- Segment/mask/address logic: derives `num_lzd`, `offset`, `addr`, and masked interpolation variable `x`.
- `gng_coef`: coefficient ROM lookup for the selected segment.
- Multiply/add pipeline:
  - `gng_smul_16_18_sadd_37` computes `C2*x + C1` (pipelined MAC),
  - `gng_smul_16_18` multiplies by delayed `x`,
  - add with delayed `C0` and perform rounding.
- Sign path: delayed sign bit is applied to produce signed two's-complement output.
- Valid path: a register shift chain delays `valid_in` to align with datapath completion.

### 5.4 Numeric Formatting

- Output format is signed fixed-point `s<16,11>`.
- Internal coefficient and arithmetic widths are fixed-point typed in RTL comments and implemented via signed/unsigned bit-width-specific operations.
- Final rounding is implemented before sign composition for output quantization.

## 6. Submodules

### 6.1 `gng_ctg`

Role:
- Generates 64-bit uniform random samples from combined Tausworthe state machines.

Interface:

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock. |
| `rstn` | Input | 1 | Synchronous active-low reset. |
| `ce` | Input | 1 | State update enable. |
| `valid_out` | Output | 1 | Valid pulse aligned with CTG output register update semantics. |
| `data_out` | Output | 64 | Uniform random output word. |

### 6.2 `gng_interp`

Role:
- Converts 64-bit uniform random input into 16-bit Gaussian-distributed output using segmented polynomial ICDF approximation.

Interface:

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock. |
| `rstn` | Input | 1 | Synchronous active-low reset for valid/output and selected state registers. |
| `valid_in` | Input | 1 | Input valid qualifier from CTG. |
| `data_in` | Input | 64 | Uniform random input word. |
| `valid_out` | Output | 1 | Output valid qualifier after interpolation pipeline. |
| `data_out` | Output | 16 | Gaussian sample output (`s<16,11>`). |

### 6.3 Helper Blocks Used by `gng_interp`

- `gng_lzd`: 61-bit leading-zero detector used for segment classification.
- `gng_coef`: coefficient ROM for piecewise polynomial segments.
- `gng_smul_16_18`: pipelined signed multiplier.
- `gng_smul_16_18_sadd_37`: pipelined signed multiply-add unit.

## 7. Clock and Reset

- Single clock domain: `clk`.
- Reset input `rstn` is synchronous active-low in the RTL.
- Reset effects:
  - CTG state registers are loaded with parameterized initial seeds.
  - Valid outputs are cleared.
  - Output registers are cleared to zero where implemented.
- After reset release, outputs become meaningful according to normal pipeline latency and `valid_out` qualification.

## 8. Constraints and Integration Notes

- The design has no backpressure/ready input; downstream logic must accept or buffer valid samples when `valid_out=1`.
- Statistical behavior depends on seed parameterization (`INIT_Z1/2/3`) and continuous operation conditions.
- The implementation is fully synchronous and intended for high-throughput streaming usage.
- Claimed frequency capability in the source document is technology- and implementation-dependent; system integration should use post-synthesis/post-route timing for the target device.
