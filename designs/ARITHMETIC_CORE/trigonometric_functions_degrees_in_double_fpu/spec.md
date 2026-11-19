# top Design Specification

## 1. Introduction

`top` is a degree-domain trigonometric function module that outputs IEEE-754 double-precision (`64-bit`) results. The module accepts an unsigned angle input, selects one trigonometric function through `actv`, normalizes the angle into a first-quadrant lookup domain, applies quadrant-dependent sign rules, and produces the selected function result on `data1`.

Supported functions are sine, cosine, tangent, cosecant, secant, and cotangent.

## 2. Module Diagram

## 3. Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock; internal control and data-path updates occur on rising edges. |
| `rst` | Input | 1 | Reset input for top-level control and divider path. |
| `enable` | Input | 1 | Operation enable. Used with `actv` to activate one trigonometric function path. |
| `actv` | Input | 3 | Function select code. |
| `degrees` | Input | 32 | Unsigned degree input angle. |
| `data1` | Output | 64 | Selected trigonometric result in IEEE-754 double-precision format. |

### 3.1 Function Select (`actv`) Encoding

| `actv` | Selected Function |
| --- | --- |
| `3'b000` | Sine |
| `3'b001` | Cosine |
| `3'b010` | Tangent |
| `3'b011` | Cosecant |
| `3'b100` | Secant |
| `3'b101` | Cotangent |
| `3'b110`, `3'b111` | Output defaults to zero |

### 3.2 Interface Semantics

- `data1` is a clocked output register updated from the currently selected function path.
- Function path activation is gated by `enable` and decoded from `actv`.
- The design does not expose a dedicated `valid/done` handshake; output validity is determined by control sequencing (`enable`, `actv`) and internal update timing.

## 4. Function Description

### 4.1 Operational Flow

1. Decode `actv` and generate one active function-enable signal (sin/cos/tan/csc/sec/cot) when `enable=1`.
2. Normalize input angle into a first-quadrant equivalent angle (`0..90`) and determine the quadrant code (`quad`).
3. Perform LUT lookup in the selected trigonometric module using normalized angle.
4. Apply function-specific sign according to `quad`.
5. Register selected function output onto `data1`.

### 4.2 Angle Normalization and Quadrant Identification

The datapath maps arbitrary unsigned degree input to a reduced first-quadrant angle with an associated quadrant code.

- For `0..90`: `quad=00`, reduced angle is unchanged.
- For `91..180`: `quad=01`, reduced angle is mirrored around `180`.
- For `181..360`: reduced around `180`, then classified into third/fourth-quadrant behavior (`quad=10` or `11`) with first-quadrant mirroring when needed.
- For values greater than `360`: modulo-`360` reduction is applied first, then the same quadrant/mirroring rules are used.

This approach uses LUT contents for first-quadrant magnitudes and derives remaining quadrants through sign and mirroring.

### 4.3 Quadrant Sign Rules by Function Family

- Sine and cosecant: positive in quadrants I and II, negative in III and IV.
- Cosine and secant: positive in quadrants I and IV, negative in II and III.
- Tangent and cotangent: positive in quadrants I and III, negative in II and IV.

These sign rules are applied by the function modules through sign-bit control while magnitude is obtained from LUT data.

### 4.4 Boundary and Special-Value Behavior

The LUTs include encoded IEEE-754 boundary values for important angles:

- `sin(0)=0`, `sin(90)=1`
- `cos(0)=1`, `cos(90)=0`
- `tan(0)=0`, `tan(90)=+Inf`
- `csc(0)=+Inf`, `csc(90)=1`
- `sec(0)=1`, `sec(90)=+Inf`
- `cot(0)=+Inf`, `cot(90)=0`

Quadrant sign control may convert these to signed variants where applicable.

### 4.5 Output Selection

`data1` is selected by a function mux keyed by `actv` and updated on clock edges. Unsupported `actv` codes map `data1` to zero.

## 5. Implementation Details

### 5.1 Major Internal Functional Blocks

- **Function decode and enable gating**: decodes `actv` and drives a one-hot-like enable set for six function paths.
- **Angle reduction block**: reduces `degrees` to `degrees mod 360` for out-of-range inputs.
- **Quadrant/mirroring block**: computes `quad` and reduced angle for LUT addressing.
- **Function LUT blocks**: six independent lookup engines (`sin/cos/tan/csc/sec/cot`) generating 64-bit IEEE-754 outputs.
- **Output select register**: chooses one LUT output according to `actv` and registers `data1`.

### 5.2 Control and Datapath Relationship

- Control decode (`actv`, `enable`) determines which LUT path is active for a cycle.
- Datapath preprocessing (`degrees` normalization + quadrant computation) provides common inputs (`quad`, reduced angle) to all LUT blocks.
- LUT results feed a shared output-selection stage, which transfers the selected function result to `data1`.

### 5.3 Sequencing Behavior

- Function enable signals are updated on clock edges and reset to inactive under `rst`.
- The modulo reducer is a clocked stage; reduced-angle behavior for `degrees > 360` depends on this sequential update path.
- Output selection is clocked; `data1` changes only on `clk` rising edges.

### 5.4 Trigger Conditions and Internal State Updates

- `rst=1` clears top-level function-enable controls and resets divider output path.
- `enable=1` with supported `actv` activates the corresponding function path.
- Any change in `degrees` affects reduced-angle/quadrant state through the clocked preprocessing path.
- `actv` drives which function result is committed to `data1` on each clock.

## 6. Submodule List

### 6.1 Function LUT Modules

| Submodule | Role | Interface Summary |
| --- | --- | --- |
| `sine_lut` | Sine magnitude lookup and quadrant sign application. | Inputs: `quad[1:0]`, `enable`, `degrees[31:0]`, `rst`, `clk`; Output: `data[63:0]`. |
| `cosine_lut` | Cosine magnitude lookup and quadrant sign application. | Inputs: `quad[1:0]`, `enable`, `degrees[31:0]`, `rst`, `clk`; Output: `data[63:0]`. |
| `tangent_lut` | Tangent magnitude lookup and quadrant sign application, including asymptotic entries. | Inputs: `quad[1:0]`, `enable`, `degrees[31:0]`, `rst`, `clk`; Output: `data[63:0]`. |
| `cosecant_lut` | Cosecant magnitude lookup and quadrant sign application, including singular-angle entries. | Inputs: `quad[1:0]`, `enable`, `degrees[31:0]`, `rst`, `clk`; Output: `data[63:0]`. |
| `secant_lut` | Secant magnitude lookup and quadrant sign application, including singular-angle entries. | Inputs: `quad[1:0]`, `enable`, `degrees[31:0]`, `rst`, `clk`; Output: `data[63:0]`. |
| `cotangent_lut` | Cotangent magnitude lookup and quadrant sign application, including singular-angle entries. | Inputs: `quad[1:0]`, `enable`, `degrees[31:0]`, `rst`, `clk`; Output: `data[63:0]`. |

### 6.2 Angle Reduction Module

| Submodule | Role | Interface Summary |
| --- | --- | --- |
| `dividor` | Computes modulo-`360` reduction for degree inputs above one full revolution. | Inputs: `clk`, `inp[31:0]`, `rst`; Output: `out[31:0]`. |

## 7. Clock and Reset

- Clocking is single-domain (`clk`).
- Top-level control decode and divider path include reset handling via `rst`.
- Function LUT/output behavior is clock-driven; no explicit top-level output-valid flag is provided.

## 8. Constraints and Confirmation Items

- Degree input is treated as unsigned integer degrees.
- The module uses first-quadrant LUT data plus mirroring/sign logic for full-circle coverage.
- The PDF IO table lists `ACTV` as 4 bits, while top-level RTL uses 3 bits; interface definition follows top-level module.
- PDF text states reset clears all values; in current design, reset coverage is not uniform across all internal datapath registers and should be confirmed for integration assumptions.
- When a function path is not enabled, LUT outputs are not specified as stable results; downstream consumers should use `enable`/sequencing discipline when interpreting `data1`.
