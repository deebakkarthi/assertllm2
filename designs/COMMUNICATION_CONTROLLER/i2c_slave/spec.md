# i2cSlaveTop Design Specification

## 1. Introduction

`i2cSlaveTop` is a minimalist I2C slave wrapper that instantiates the reusable `i2cSlave` core and exposes a single user-visible register output (`myReg0`) at the top level. The core implements a byte-oriented register access protocol over I2C, including device-address recognition, register-address pointer handling, and multi-byte read/write streaming.

The delivered configuration is intended as a template integration: the serial protocol engine and register interface are implemented inside the core, while system-specific control/status exposure is defined by how top-level ports are mapped.

## 2. Module Diagram


## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock used for all internal sequential logic. |
| `rst` | Input | 1 | Active-high reset input, synchronized internally to `clk`. |
| `sda` | Inout | 1 | I2C serial data line. Implemented as open-drain behavior (`0` driven low, `1` released to high-Z). |
| `scl` | Input | 1 | I2C serial clock line input. |
| `myReg0` | Output | 8 | User register output reflecting writable register address `0x00` in the internal register map. |

### 3.1 Interface Semantics

- `sda` is bidirectional and is driven low only when the core transmits `0`; otherwise the line is released.
- `scl` is sampled by the core and used for I2C bit timing/state progression.
- The top-level module exports only `myReg0`; additional internal template registers are not top-level ports in this delivered wrapper.

## 4. Function Description

### 4.1 Protocol-Level Behavior

The core behaves as an I2C slave with compile-time device address `I2C_ADDRESS` (default `7'h3c`).

- Slave address match is performed on the first received byte after START.
- If address does not match, the core returns NAK and remains idle for data transfer.
- If address matches:
  - `R/W=0`: enter write sequence.
  - `R/W=1`: enter read sequence.

### 4.2 Register Access Model

The internal protocol uses an 8-bit register-address pointer (`regAddr`), supporting address values `0x00` to `0xFF`.

- The second byte of a write transaction is interpreted as register-address pointer setup.
- Subsequent write data bytes are written to the current pointer address, then pointer auto-increments.
- Read transactions source data from the current pointer address, then pointer auto-increments per transmitted byte.
- Pointer increment wraps from `0xFF` to `0x00`.

Per source specification intent, the register pointer is not explicitly initialized by reset and must be set by I2C command sequencing before deterministic register access.

### 4.3 Write Transaction Flow

A write transfer follows this operational sequence:

1. START + device address with write bit.
2. Register pointer byte.
3. One or more data bytes.
4. STOP (or START for mode change).

During the write-data phase, accepted bytes are forwarded to the register interface using `writeEn` and `dataOut`. In the delivered register interface implementation, only addresses `0x00` to `0x03` are writable.

### 4.4 Read Transaction Flow

A read transfer uses the current register pointer and streams bytes until the master terminates:

1. Pointer setup typically performed by prior write transaction.
2. START/Repeated START + device address with read bit.
3. Slave transmits data bytes from current pointer and increments pointer.
4. Master ACK continues streaming; master NAK terminates read stream.

### 4.5 START/STOP Handling and Stream Control

- START and STOP are detected from SDA transitions while SCL is high, using delayed/debounced signals.
- A detected START edge resets the serial-interface FSM to restart byte framing at address phase.
- STOP or explicit stream termination conditions return stream mode to idle.

## 5. Implementation Details

### 5.1 Top-Level Composition (`i2cSlaveTop`)

`i2cSlaveTop` is a thin wrapper around `i2cSlave`:

- Connects `clk`, `rst`, `sda`, and `scl` directly.
- Exposes only `myReg0` from the internal register bank.
- Leaves `myReg1..myReg3` unconnected at top level.
- Ties read-only template register inputs `myReg4..myReg7` to constants `8'h12`, `8'h34`, `8'h56`, `8'h78`.

### 5.2 Front-End Signal Conditioning (`i2cSlave`)

`i2cSlave` implements protocol front-end conditioning before serial decode:

- Synchronizes reset to clock (`rstSyncToClk`) through a short pipeline.
- Debounces SDA and SCL inputs with configurable filter lengths.
- Delays SCL for internal sampling and delays SDA for robust START/STOP detection.
- Produces start/stop detection state (`NULL_DET`, `START_DET`, `STOP_DET`) and a START edge pulse used to restart serial transaction parsing.

### 5.3 Serial Protocol Engine (`serialInterface`)

`serialInterface` performs byte-level transaction control:

- Receives and shifts serial bits using SCL-driven state transitions.
- Implements stream modes:
  - `STREAM_IDLE`
  - `STREAM_WRITE_ADDR` (pointer load)
  - `STREAM_WRITE_DATA` (data write)
  - `STREAM_READ` (data transmit)
- Handles address match, ACK/NAK generation, pointer update, and read/write continuation or termination.
- Asserts `writeEn` when a write-data byte is committed to the register interface.

### 5.4 Register Bank Template (`registerInterface`)

Delivered register mapping behavior:

- Read decode:
  - `0x00..0x03` -> `myReg0..myReg3` (writable bank)
  - `0x04..0x07` -> `myReg4..myReg7` (input/read-only bank from wrapper connections)
  - other addresses -> `8'h00`
- Write decode:
  - only `0x00..0x03` update `myReg0..myReg3`

This module is the intended customization point for application-specific register maps.

## 6. Submodule List

### 6.1 `i2cSlave`

Role: Main slave core integrating input conditioning, START/STOP detection, serial protocol control, and register interface binding.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock |
| `rst` | Input | 1 | Active-high reset input |
| `sda` | Inout | 1 | I2C SDA line |
| `scl` | Input | 1 | I2C SCL input |
| `myReg0..myReg3` | Output | 8 each | Writable register outputs |
| `myReg4..myReg7` | Input | 8 each | Readback register inputs |

### 6.2 `serialInterface`

Role: I2C byte transaction state machine. Converts serial data to/from parallel register bytes, controls ACK/NAK and read/write stream progression.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock |
| `rst` | Input | 1 | Active-high reset for serial FSM |
| `scl` | Input | 1 | Delayed SCL sampling input |
| `sdaIn` | Input | 1 | Debounced SDA sample |
| `sdaOut` | Output | 1 | SDA drive control (`0` drive low, `1` release) |
| `startStopDetState` | Input | 2 | START/STOP detection state |
| `clearStartStopDet` | Output | 1 | Handshake to clear start/stop detector state |
| `regAddr` | Output | 8 | Current register-address pointer |
| `dataOut` | Output | 8 | Write-data byte to register interface |
| `writeEn` | Output | 1 | Register write strobe |
| `dataIn` | Input | 8 | Read-data byte from register interface |

### 6.3 `registerInterface`

Role: Register read/write decode for application-visible register bytes.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock |
| `addr` | Input | 8 | Register address pointer |
| `dataIn` | Input | 8 | Data for register write |
| `writeEn` | Input | 1 | Write enable |
| `dataOut` | Output | 8 | Readback data to serial engine |
| `myReg0..myReg3` | Output | 8 each | Writable register outputs |
| `myReg4..myReg7` | Input | 8 each | Readback-only inputs |

## 7. Clock and Reset

| Signal | Type | Description |
| --- | --- | --- |
| `clk` | Clock | Primary clock domain for all logic. |
| `rst` | Reset | Active-high reset input, synchronized in `i2cSlave` and used to reset protocol/control state. |

Reset behavior:

- Protocol-control state (debounce/delay pipelines, start/stop state, serial FSM control signals) is reset to idle defaults.
- `registerInterface` does not define explicit reset assignments for `myReg0..myReg3`; their post-reset values are implementation-dependent until written.

## 8. Constraints and Integration Notes

- Compile-time constants in `i2cSlave_define.v` define key behavior:
  - `I2C_ADDRESS` (default `7'h3c`)
  - `CLK_FREQ` (default `48` MHz)
  - debounce and delay lengths derived from `CLK_FREQ`.
- Source comments indicate that low `CLK_FREQ` values may require manual adjustment of `SDA_DEL_LEN` macro expressions.
- `sda` must be integrated as an open-drain line with external pull-up.
- This wrapper is a template instance; extending externally visible register/control ports requires coordinated changes in `i2cSlaveTop`, `i2cSlave`, and `registerInterface`.
