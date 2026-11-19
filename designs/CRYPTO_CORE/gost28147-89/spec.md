# gost89_cfb Design Specification

## 1. Introduction

`gost89_cfb` is a 64-bit cipher-feedback (CFB) cryptographic module based on GOST 28147-89 block encryption. The module supports both encryption and decryption data flow under a single interface and processes one 64-bit block per transaction.

The design uses a 256-bit key and a programmable 512-bit S-box table. A 64-bit internal feedback register (`gamma`) is used as the CFB state across blocks.

## 2. Module Diagram

## 3. Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock. |
| `reset` | Input | 1 | Synchronous active-high control reset for the CFB wrapper transaction state. When asserted with `load_data=0`, it clears `busy` and loads feedback state (`gamma`) from `in`. |
| `mode` | Input | 1 | Operation mode selector. `0`: encryption path. `1`: decryption path. |
| `load_data` | Input | 1 | Start signal for a block transaction. Latches input block and launches internal ECB encryption of current feedback state. |
| `sbox` | Input | 512 | S-box table input (8 substitution tables, 64 bits each). |
| `key` | Input | 256 | GOST key input (8 words, 32 bits each). |
| `in` | Input | 64 | Data input block. During initialization, also provides initial feedback value when `reset=1` and `load_data=0`. |
| `out` | Output | 64 | Data output block. Ciphertext in encryption mode, plaintext in decryption mode. |
| `busy` | Output | 1 | Transaction status. Asserted while a block is in progress, deasserted when output block and next feedback state are committed. |

### 3.1 Interface Semantics

- A block operation is started by asserting `load_data` while `reset=0`.
- `busy` is asserted after block start and remains asserted until the internal ECB operation completes and output is committed.
- The module has no separate output-valid signal; `busy` deassertion marks completion of the current block operation.
- `reset` behavior is defined for `reset=1` with `load_data=0`; this condition initializes feedback state from `in` and clears active transaction state.

## 4. Function Description

### 4.1 CFB Block Operation

For each accepted block:

1. The current feedback state (`gamma`) is encrypted by the internal GOST ECB encryption core.
2. The resulting keystream block is combined with latched input data using bitwise XOR.
3. The XOR result is presented on `out` at transaction completion.
4. The feedback state is updated based on mode:
   - Encryption mode (`mode=0`): feedback updates with the newly produced output block.
   - Decryption mode (`mode=1`): feedback updates with the input ciphertext block.

### 4.2 Encryption and Decryption Interpretation

- In encryption mode, input data is plaintext and output data is ciphertext.
- In decryption mode, input data is ciphertext and output data is plaintext.
- In both modes, the internal ECB primitive is used only in encryption direction, consistent with CFB operation.

### 4.3 Initialization and Sequencing

- Initial feedback value is loaded from `in` by asserting `reset` while `load_data` is deasserted.
- Each subsequent data block uses the feedback value produced by the previous completed transaction.
- External control logic is responsible for correct block ordering and for initialization before the first block of a stream.

## 5. Implementation Details

### 5.1 Top-Level Control and Data Path

Top-level state elements:

- `gamma`: current 64-bit feedback register.
- `in_value`: latched 64-bit input block for current transaction.
- `busy`: top-level activity indicator.

Control relationships:

- `load_ecb` is asserted when `load_data=1` and `reset=0`.
- Internal ECB launch and internal ECB reset are both driven by `load_ecb`.
- Transaction completion occurs when the top-level block is active (`busy=1`) and the internal ECB core indicates completion (`busy_ecb=0`).

At completion, the module updates:

- `out` with keystream XOR latched input,
- `gamma` based on `mode`,
- `busy` to `0`.

### 5.2 Internal ECB Encryption Core Behavior

The instantiated core `gost89_ecb_encrypt` processes a 64-bit block as two 32-bit halves over 32 rounds. It performs:

- round counter sequencing from 0 to 32,
- Feistel round updates through `gost89_round`,
- final half swap and output assembly at completion.

The key schedule in this encryption core uses eight 32-bit key words in forward order for rounds 0 to 23, followed by reverse order for rounds 24 to 31.

### 5.3 Round Function Structure

`gost89_round` performs the GOST round transform at 32-bit half-word granularity:

- modular addition of the left half and round key,
- nibble-wise substitution through 8 S-box slices,
- 11-bit cyclic rotation of the substituted value,
- XOR with the right half to produce next left half,
- Feistel swap behavior by forwarding prior left half as next right half.

### 5.4 S-box Selection

`gost89_sbox` maps a 4-bit input nibble through a 64-bit S-box slice. The full 512-bit `sbox` input supplies eight such slices, one per nibble position in a 32-bit word.

## 6. Submodule List

### 6.1 `gost89_ecb_encrypt`

Role:

- Encrypts one 64-bit block with GOST 28147-89 round processing.
- Provides the keystream block used by CFB wrapper logic.

Interface summary:

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | Clock. |
| `reset` | Input | 1 | Core control reset. |
| `load_data` | Input | 1 | Starts a new block encryption. |
| `sbox` | Input | 512 | S-box table input. |
| `key` | Input | 256 | Encryption key input. |
| `in` | Input | 64 | Block input to be encrypted. |
| `out` | Output | 64 | Encrypted output block. |
| `busy` | Output | 1 | Core busy indicator. |

### 6.2 `gost89_round`

Role:

- Implements one Feistel round transformation used by `gost89_ecb_encrypt`.

### 6.3 `gost89_sbox`

Role:

- Implements nibble substitution for one S-box slice used within the round function.

## 7. Clock and Reset

- Single clock domain (`clk`).
- `reset` is sampled synchronously.
- For deterministic initialization of feedback state, assert `reset` with `load_data=0` and provide initialization vector value on `in`.

## 8. Constraints

- Block size is 64 bits.
- Key size is 256 bits.
- S-box table width is 512 bits.
- `load_data` is expected to be asserted only when the module is not busy, to avoid interrupting an in-progress transaction.
- Output data should be consumed when `busy` deasserts after a started transaction.
