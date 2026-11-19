# FT816Float Design Specification

## 1. Introduction
`FT816Float` is a memory-mapped floating-point accelerator intended for byte-oriented CPUs. The core contains two 96-bit accumulators (`FAC1`, `FAC2`) and executes arithmetic, conversion, and data-manipulation commands on accumulator contents.

The arithmetic format is a non-IEEE custom representation documented for this design: a 16-bit exponent and an 80-bit mantissa (mantissa in two's-complement form, with one binary digit before the radix point). The core also supports fixed-point command variants using the same accumulator storage interface.

## 2. Module Diagram


## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `rst` | Input | 1 | Synchronous active-high reset for control and interface registers. |
| `clk` | Input | 1 | Rising-edge system clock used for both bus interface and computation sequencing. |
| `vda` | Input | 1 | Valid data address qualifier for bus access decode. |
| `rw` | Input | 1 | Bus direction (`1`: read, `0`: write). |
| `ad` | Input | 24 | Byte address bus. |
| `db` | Inout | 8 | Bidirectional data bus. Driven during selected read cycles; high impedance otherwise. |
| `rdy` | Output | 1 | Bus ready / wait-state control output. |

### 3.1 Interface Semantics

- Device select (`cs`) is generated when `vda=1` and `ad[23:8]` matches `pIOAddress[23:8]`.
- `db` is only driven when the core is selected and `rw=1`; otherwise `db` is tri-stated.
- Write transfers are accepted when selected and `rw=0`.
- Read data is returned through an internal output register (`dbo`) and exposed on `db` when selected and `rw=1`.
- `rdy` behavior:
  - if not selected, `rdy` outputs `pRdyStyle`;
  - if selected and writing, `rdy` is asserted in the current cycle;
  - if selected and reading, `rdy` is produced through an internal delayed handshake path (`rdy1`/`rdy2`) to insert read latency.

## 4. Register Model

Registers are byte-addressed within the selected 256-byte window (`ad[7:0]` offset).

### 4.1 Accumulator Storage

| Offset | Access | Description |
| --- | --- | --- |
| `0x00`..`0x09` | RW | `FAC1` mantissa bytes, least-significant to most-significant. |
| `0x0A`..`0x0B` | RW | `FAC1` exponent bytes, least-significant to most-significant. |
| `0x10`..`0x19` | RW | `FAC2` mantissa bytes, least-significant to most-significant. |
| `0x1A`..`0x1B` | RW | `FAC2` exponent bytes, least-significant to most-significant. |

### 4.2 Command / Status Register

| Offset | Access | Description |
| --- | --- | --- |
| `0x0E` | W | Command register in current RTL implementation. |
| `0x0E` | R | Status register in current RTL implementation. |

Status register format (`db[7:0]`):

| Bit | Name | Meaning |
| --- | --- | --- |
| 7 | `Busy` | `1` while an operation is in progress. |
| 6:5 | Reserved | Read as zero. |
| 4 | `LT` | `FAC1 < FAC2` comparator flag. |
| 3 | `EQ` | `FAC1 == FAC2` comparator flag. |
| 2 | `GT` | `FAC1 > FAC2` comparator flag. |
| 1 | `ZF` | `FAC1` equals zero. |
| 0 | `VF` | Overflow flag. |

### 4.3 Address Note (Source Discrepancy)

The source PDF documents command/status at `$...20F`, while the provided RTL decodes command/status at offset `0x0E` (default absolute address `$FEA20E`). This requires confirmation at integration time.

## 5. Functional Description

### 5.1 Programming Model

A software transaction sequence is:

1. Write operand bytes into `FAC1` and/or `FAC2`.
2. Write an opcode to the command register.
3. Poll the status register until `Busy=0`.
4. Read result bytes (typically from `FAC1`) and status flags.

If a new command is written while the accelerator is not in the idle state, it is not latched as an operation start command in the current implementation.

### 5.2 Supported Commands (Normative)

The documented command set is:

| Operation | Opcode | Functional Effect |
| --- | --- | --- |
| `ADD` | `0x01` | `FAC1 = FAC2 + FAC1` |
| `SUB` | `0x02` | `FAC1 = FAC2 - FAC1` |
| `MUL` | `0x03` | `FAC1 = FAC2 * FAC1` |
| `DIV` | `0x04` | `FAC1 = FAC2 / FAC1` |
| `FIX2FLT` | `0x05` | Convert fixed-point value in `FAC1` to floating format. |
| `FLT2FIX` | `0x06` | Convert floating value in `FAC1` to fixed-point format. |
| `ABS` | `0x07` | `FAC1 = abs(FAC1)` |
| `NEG` | `0x10` | `FAC1 = -FAC1` |
| `SWAP` | `0x11` | Exchange `FAC1` and `FAC2`. |
| `FIXED_ADD` | `0x81` | Fixed-point add path using accumulator operands. |
| `FIXED_SUB` | `0x82` | Fixed-point subtract path using accumulator operands. |
| `FIXED_MUL` | `0x83` | Fixed-point multiply path using accumulator operands. |
| `FIXED_DIV` | `0x84` | Fixed-point divide path using accumulator operands. |
| `FIXED_ABS` | `0x87` | Fixed-point absolute-value path. |

### 5.3 Completion and Flag Behavior

- `Busy` is asserted when a valid command is accepted in idle state and cleared on return to idle state.
- `VF` is asserted by overflow paths and conversion saturation paths.
- `LT`, `EQ`, `GT`, and `ZF` are derived from current accumulator contents and can be used for software-side comparisons and result checks.

## 6. Implementation Details

### 6.1 Internal Data Organization

- `FAC1` and `FAC2` are 96-bit registers partitioned as:
  - exponent: bits `[95:80]` (16 bits),
  - mantissa: bits `[79:0]` (80 bits).
- Arithmetic sequencing is controlled by an internal state machine (`state`) with a small return-state stack for multi-step operation flows.

### 6.2 Operation Sequencing Architecture

- `ADD` / `SUB` path:
  - compares exponents,
  - aligns mantissas via iterative right-shift sequencing,
  - performs add/subtract on mantissas,
  - applies normalization for floating-point mode.
- `MUL` path:
  - computes exponent combination,
  - performs iterative mantissa processing under counter control,
  - applies sign handling and normalization.
- `DIV` path:
  - computes exponent difference,
  - executes iterative quotient/remainder update over mantissa bits,
  - applies post-processing and normalization.
- `FIX2FLT` / `FLT2FIX` conversions:
  - use exponent rebasing and shift/normalize loops,
  - include guard behavior for under-range and over-range conversion cases.

### 6.3 Normalization and Overflow Handling

- Floating-point normalization shifts mantissa left while adjusting exponent until sign/leading-bit conditions are satisfied.
- A multi-bit shift path is used when upper mantissa slices indicate that a larger shift can be applied.
- Overflow conditions drive `VF` and terminate the active operation to idle.

### 6.4 Bus-Visible Timing Model

- The computation engine and bus interface share the same clock.
- Command writes are sampled synchronously.
- Read data is register-based and exposed through tri-state `db` during selected read cycles.

## 7. Submodule List

The provided RTL is implemented as a single top-level module (`FT816Float`) and does not instantiate architectural submodules.

## 8. Clock and Reset

- Clock: single rising-edge clock `clk`.
- Reset: synchronous active-high `rst`.
- On reset:
  - interface handshake registers are reinitialized,
  - control state is forced to reset/idle sequencing,
  - simulation-only code initializes accumulators to zero when `SIMULATION` is enabled.

## 9. Constraints and Integration Notes

- `pIOAddress` controls register window placement, but current decode uses `ad[23:8]` equality; software integration should treat the interface as a 256-byte region selected by upper address bytes.
- The PDF and RTL differ on command/status byte offset (`0x0F` vs `0x0E`); system integration must choose one mapping and verify software accordingly.
- Operation latency is data-dependent and command-dependent; software should rely on `Busy` polling rather than fixed-cycle assumptions.
- Interface and arithmetic format are custom and not IEEE-754 compliant.
