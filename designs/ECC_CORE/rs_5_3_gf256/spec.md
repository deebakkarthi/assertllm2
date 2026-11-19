# RS_5_3_GF256 Design Specification

## 1. Introduction

`RS_5_3_GF256` is an 8-bit-symbol Reed-Solomon codec implementing RS(5,3) behavior over GF(256).

The module supports two operating modes selected by `E_D`:
- Encoding mode (`E_D=1`): converts a 3-symbol message into a 5-symbol systematic codeword.
- Decoding mode (`E_D=0`): receives a 5-symbol codeword and performs single-symbol error correction.

The coding rate is 3/5, and the decoder is intended for one-symbol error correction per codeword.

## 2. Module Diagram

## 3. Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `CLK` | Input | 1 | Positive-edge clock. |
| `rst_n` | Input | 1 | Asynchronous active-low reset. |
| `DATA_VALID_IN` | Input | 1 | Active-low input qualifier. `DATA_IN` and `E_D` are sampled when this signal is low. |
| `E_D` | Input | 1 | Mode select: `1` for encoding, `0` for decoding. |
| `DATA_IN` | Input | 8 | Input symbol stream (message symbols in encode mode, codeword symbols in decode mode). |
| `DATA_VALID_OUT` | Output | 1 | Active-low output qualifier. `DATA_OUT` is valid when this signal is low. |
| `DATA_OUT` | Output | 8 | Output symbol stream (systematic+parity symbols in encode mode, corrected symbols in decode mode). |

### 3.1 Interface Semantics

- Input transactions are driven by asserting `DATA_VALID_IN` low on clock edges where input symbols are valid.
- `E_D` is sampled only when `DATA_VALID_IN` is low; it shall remain constant for a transaction.
- Output symbols shall be sampled only when `DATA_VALID_OUT` is low.
- Reset (`rst_n=0`) asynchronously returns internal control, syndrome, FIFO, and output registers to their reset state.

## 4. Function Description

### 4.1 Operational Modes

The module operates as a combined encoder/decoder with shared syndrome-generation and output alignment logic:

- Encode path generates two parity symbols from three message symbols and emits a 5-symbol codeword.
- Decode path computes syndromes from the received codeword, determines a candidate error location/value, and emits a corrected 5-symbol stream.

### 4.2 Encoding Operation (`E_D=1`)

1. Three message symbols are accepted while `DATA_VALID_IN` is low.
2. During these cycles, `DATA_OUT` forwards the message symbols (systematic portion).
3. Internal syndrome/parity state is updated from incoming message symbols.
4. After message intake, the module emits two parity symbols on the next parity phase cycles.
5. During parity output cycles, `DATA_VALID_OUT` is asserted low and `DATA_OUT` carries computed parity symbols.

The parity-generation datapath is based on two running syndrome-like states (`SYND1_`, `SYND2_`) and a GF(256) multiply-by-constant path (`MULT_BY_ALPHA51`).

### 4.3 Decoding Operation (`E_D=0`)

1. A 5-symbol received codeword is provided on `DATA_IN` with `DATA_VALID_IN` low.
2. Syndrome state (`SYND1_`, `SYND2_`) is accumulated from the received symbols.
3. At decode intake completion, the module captures:
   - `VAL` (error magnitude candidate) from `SYND1_`.
   - `LOC2_` (error location candidate) from `SYN2ERR`.
4. A 5-cycle decode-output phase emits symbols from the internal FIFO alignment path.
5. On the cycle matching the selected error location, the emitted symbol is corrected by XOR with the captured error value; other positions pass through unchanged.

The decoder is intended to correct a single symbol error per codeword.

### 4.4 Validity and Sequencing Behavior

- `DATA_VALID_OUT` is active low during output-bearing encode and decode phases.
- In encode mode, output-low-valid covers message pass-through cycles and parity emission cycles.
- In decode mode, output-low-valid is asserted during the correction/output window controlled by `cntr2_en` and `cntr2_`.

## 5. Implementation Details

### 5.1 Control Path

Two internal counters organize sequencing:

- `cntr1_` controls transaction phase selection:
  - Encode phases: intake and parity emission.
  - Decode phases: codeword intake and transition to correction output.
- `cntr2_` controls decode output position (five output positions).
- `cntr2_en` is a one-cycle trigger that captures correction parameters (`VAL`, `LOC2_`) and starts the decode output window.

### 5.2 Shared Syndrome and Parity Datapath

- `SYND2_` is multiplied by a constant field element (`alpha^51`) via `MULT_BY_ALPHA51`, producing `MULT2_`.
- `ADD3_` selects mode-dependent feedback:
  - Encode mode: combines `SYND1_` with `MULT2_`.
  - Decode mode: uses `MULT2_` path.
- `SYND1_` and `SYND2_` are updated during valid input cycles and parity-update cycles.

This shared structure supports both parity generation and syndrome evaluation without separate top-level datapaths.

### 5.3 Error Location/Value Determination

- `SYN2ERR` computes the error-location indicator from the syndrome pair (`SYND1_`, `SYND2_`).
- Inside `SYN2ERR`, the second syndrome is inverted in GF(256), multiplied by the first syndrome, and mapped to a 3-bit location code.
- Top-level registers `VAL` and `LOC2_` hold captured correction parameters for the decode-output phase.

### 5.4 FIFO Alignment and Output Substitution

- Five internal byte registers (`FIFO0_` to `FIFO4_`) provide symbol alignment for decode output.
- Decode output is taken from `FIFO4_` each decode-output cycle.
- Correction is applied by XOR substitution at the selected location index:
  - Immediate correction case for location zero during trigger cycle.
  - Indexed correction case when `cntr2_` equals `LOC2_`.

## 6. Submodule List

### 6.1 `MULT_BY_ALPHA51`

Functional role: GF(256) constant multiplier used in syndrome/parity feedback.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `b` | Input | 8 | GF(256) input operand. |
| `z` | Output | 8 | Product of `b` with fixed field constant (`alpha^51`). |

### 6.2 `SYN2ERR`

Functional role: derives decode error location code from the syndrome pair.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `SYND1_` | Input | 8 | First syndrome term. |
| `SYND2_` | Input | 8 | Second syndrome term. |
| `LOC` | Output | 3 | Encoded location used by top-level correction selection. |

Key interaction:
- Uses GF inverse and GF multiply helper blocks to form a syndrome ratio used for location mapping.

### 6.3 `inv_gf256`

Functional role: combinational GF(256) multiplicative inverse lookup.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `x` | Input | 8 | GF(256) element to invert. |
| `y` | Output | 8 | Multiplicative inverse result (`0` maps to `0`). |

### 6.4 `gf256mult`

Functional role: combinational GF(256) multiplier.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `a` | Input | 8 | First GF(256) operand. |
| `b` | Input | 8 | Second GF(256) operand. |
| `z` | Output | 8 | GF(256) multiplication result. |

## 7. Clock and Reset

- Clocking is on the positive edge of `CLK`.
- `rst_n` is asynchronous and active low.
- Reset initializes:
  - phase and decode counters (`cntr1_`, `cntr2_`, `cntr2_en`),
  - syndrome/correction registers (`SYND1_`, `SYND2_`, `VAL`, `LOC2_`),
  - FIFO registers (`FIFO0_`..`FIFO4_`),
  - outputs (`DATA_OUT`, `DATA_VALID_OUT`).

## 8. Constraints

- `DATA_VALID_IN` must be driven low only on cycles where `DATA_IN` and `E_D` are valid.
- `E_D` shall remain constant while `DATA_VALID_IN` is low for a transaction.
- Encoding transaction rule: after three message symbols are provided, keep `DATA_VALID_IN` high for the next two cycles to complete parity emission.
- Decoding transaction rule: provide a full 5-symbol codeword with `DATA_VALID_IN` low for symbol intake.
- `DATA_OUT` shall be sampled only when `DATA_VALID_OUT` is low.
- Decoder correction capability is limited to one symbol error per codeword.
