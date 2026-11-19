# wbicapetwo Design Specification

## 1. Introduction

`wbicapetwo` provides a WISHBONE slave interface to the Xilinx 7-series ICAPE2 configuration register access path. It allows software-visible 32-bit read and write operations to configuration-register addresses through a simple memory-mapped bus interface.

This interface supports use cases such as:
- reading configuration/status registers,
- programming warm-boot start address registers,
- issuing configuration commands such as reconfiguration trigger commands.

The core is intended to hide ICAPE2 command-stream ordering and timing details behind the WISHBONE transaction model.

## 2. Module Diagram

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | System clock for the bus interface and internal transaction sequencer. |
| `i_wb_cyc` | Input | 1 | WISHBONE cycle qualifier. |
| `i_wb_stb` | Input | 1 | WISHBONE strobe qualifier. |
| `i_wb_we` | Input | 1 | WISHBONE direction: `1` write, `0` read. |
| `i_wb_addr` | Input | 5 | ICAPE2 configuration register address field. |
| `i_wb_data` | Input | 32 | WISHBONE write payload. |
| `o_wb_ack` | Output | 1 | WISHBONE transaction completion pulse. |
| `o_wb_stall` | Output | 1 | WISHBONE backpressure indicator while internal ICAPE2 sequence is active. |
| `o_wb_data` | Output | 32 | WISHBONE read data, valid with read completion acknowledge. |

### 3.2 WISHBONE Access Semantics

- The core operates as a WISHBONE B4 slave with 32-bit port size and 32-bit granularity.
- A request is accepted when `i_wb_cyc` and `i_wb_stb` are asserted while the core is idle (`o_wb_stall=0`).
- Only one request is processed at a time.
- During an active ICAPE2 transaction sequence, `o_wb_stall` is asserted.
- Completion is indicated by a pulse on `o_wb_ack`.
- For read requests, `o_wb_data` is returned with the read completion acknowledge.
- Completion and ready-for-next-request are separate events; `o_wb_ack` may assert before `o_wb_stall` deasserts.

### 3.3 Address/Data Mapping

- `i_wb_addr[4:0]` is used as the target ICAPE2 register address field.
- `i_wb_data[31:0]` is the write value for write transactions.
- Read transactions return the selected ICAPE2 register value on `o_wb_data`.

## 4. Function Description

### 4.1 Overview

For each accepted WISHBONE transaction, the core executes a fixed ICAPE2 command sequence that includes synchronization, address-specific read/write command emission, and a DESYNC termination sequence. This sequencing is required to access the configuration interface safely from user logic.

### 4.2 Write Operation Flow

For a write request (`i_wb_we=1`), the sequencer performs:
1. Transaction start from idle and request latching (`address`, `data`, direction).
2. Synchronization preamble using dummy/NOOP/sync words.
3. Write header generation for the requested address.
4. Write data transfer (`i_wb_data` value).
5. DESYNC postamble sequence.
6. WISHBONE completion acknowledge and return to idle.

A complete write access spans multiple clock cycles due to the required ICAPE2 framing.

### 4.3 Read Operation Flow

For a read request (`i_wb_we=0`), the sequencer performs:
1. Transaction start from idle and request latching (`address`, direction).
2. Synchronization preamble using dummy/NOOP/sync words.
3. Read header generation for the requested address.
4. Additional wait/read turnaround cycles for configuration readback.
5. Capture of returned ICAPE2 data into `o_wb_data` with completion acknowledge.
6. DESYNC postamble sequence before returning fully to idle.

Read accesses use a longer sequence than writes because of read turnaround/wait phases.

### 4.4 Warm-Boot/Reconfiguration Use Pattern

A common control pattern is:
1. Write the desired warm-boot start address to the warm-boot start register address (`5'h10`).
2. Write the IPROG command to the command register address (`5'h04`).

This causes the FPGA configuration engine to restart from the programmed warm-boot address.

### 4.5 Bit Ordering

The ICAPE2 data path requires per-byte bit reversal relative to normal WISHBONE bit ordering. The core applies this bit remapping internally for both transmitted and received configuration words, while preserving standard `bit[31:0]` ordering at the WISHBONE interface.

## 5. Implementation Details

### 5.1 Internal Control Structure

The core is implemented around a single clocked transaction sequencer with internal state values for:
- idle/start,
- read command and read wait phases,
- write command/data phases,
- desynchronization and completion.

Key internal latched request context:
- `r_addr` (latched register address),
- `r_data` (latched write data),
- `r_we` (latched direction),
- `wb_req` (active request tracking).

### 5.2 ICAPE2 Control Signals

The sequencer drives internal ICAPE2-side control/data signals:
- `cfg_cs_n` (chip-select control),
- `cfg_rdwrn` (read/write mode control),
- `cfg_in` (configuration command/data word stream).

Read data is accepted through internal `cfg_out` and forwarded to `o_wb_data` at read completion.

### 5.3 Handshake and Completion Behavior

- `o_wb_stall` is deasserted in idle and asserted during active sequencing.
- `o_wb_ack` is pulsed at defined completion points.
- A read completion acknowledge can occur before the sequencer fully returns to idle; therefore, `o_wb_ack` and `o_wb_stall` are not mutually exclusive.

### 5.4 Timing Characteristics

Because of required ICAPE2 command framing:
- write operations require a multi-cycle sequence (nominally on the order of the documented write path length),
- read operations require a longer multi-cycle sequence than writes (nominally on the order of the documented read path length).

These transaction lengths are protocol-sequence dependent rather than single-cycle register access timing.

## 6. Submodule List

No RTL child-module instantiations are present in this top-level module file. ICAPE2 interface signaling is encapsulated internally in the module behavior.

## 7. Clock and Reset

- Clock: `i_clk` is the only external clock.
- External reset: no top-level reset input is provided.
- Initialization: internal state/control signals are initialized to idle-safe startup values in the RTL (`state` idle, interface deselected).

## 8. Constraints

- Master logic should issue a new request only when `o_wb_stall=0`.
- `i_wb_cyc` should remain asserted through transaction completion so that internal request tracking and completion acknowledge remain coherent.
- Accesses are 32-bit; address decoding is limited to `i_wb_addr[4:0]`.
- Since no explicit external reset is provided, system integration should ensure startup clock stability and proper bus-idle conditions at power-up.
