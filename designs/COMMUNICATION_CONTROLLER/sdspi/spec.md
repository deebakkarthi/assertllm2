# sdspi Design Specification

## 1. Introduction

`sdspi` is an SD-card controller that provides SPI-mode SD access through a 32-bit Wishbone slave interface. The design is intended for systems that do not use the full SD native interface and therefore access the card through the SD SPI pins.

The controller exposes command, argument/response, and FIFO data movement through memory-mapped registers. It supports single-block data transactions via command plus FIFO usage, and it provides a completion interrupt pulse for software or DMA orchestration.

## 2. Module Diagram

[Placeholder: Insert module/block diagram manually.]

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | Controller clock. Also serves as the timing reference for Wishbone interaction and internal SPI clock generation. |
| `i_wb_cyc` | Input | 1 | Wishbone cycle indication (present for bus compatibility). |
| `i_wb_stb` | Input | 1 | Wishbone strobe. |
| `i_wb_we` | Input | 1 | Wishbone write enable. |
| `i_wb_addr` | Input | 2 | Wishbone register address selector. |
| `i_wb_data` | Input | 32 | Wishbone write data. |
| `o_wb_ack` | Output | 1 | Wishbone acknowledge. |
| `o_wb_stall` | Output | 1 | Wishbone stall indication. |
| `o_wb_data` | Output | 32 | Wishbone read data. |
| `o_cs_n` | Output | 1 | Active-low SD chip-select request/output. |
| `o_sck` | Output | 1 | SPI serial clock to SD card. |
| `o_mosi` | Output | 1 | SPI MOSI output to SD card. |
| `i_miso` | Input | 1 | SPI MISO input from SD card. |
| `o_int` | Output | 1 | One-cycle completion interrupt pulse at command completion. |
| `i_bus_grant` | Input | 1 | SPI bus grant indication for shared-bus environments. |
| `o_debug` | Output | 32 | Debug/status observation bus (implementation visibility aid). |

### 3.2 Wishbone Address Map

| `i_wb_addr` | Register | Width | Access | Description |
| --- | --- | --- | --- | --- |
| `2'b00` | `CMD` | 32 | R/W | Command/status control register. |
| `2'b01` | `DATA` | 32 | R/W | Command argument / returned response / config transfer register. |
| `2'b10` | `FIFO[0]` | 32 | R/W | Primary FIFO data window. |
| `2'b11` | `FIFO[1]` | 32 | R/W | Alternate FIFO data window. |

### 3.3 Interface Semantics

- `o_wb_stall` is not asserted by this design; accesses are accepted without wait-state backpressure.
- `o_wb_ack` acknowledges accepted Wishbone strobes.
- Command execution is initiated by writes to `CMD` that encode a valid command format.
- SPI ownership is coordinated by `o_cs_n` (request/select) and `i_bus_grant` (permission to drive shared SPI bus).

## 4. Register Description

### 4.1 `CMD` Register

The `CMD` register is used both to launch transactions and to read transaction status.

#### Command launch behavior

- If the interface is busy, `CMD` writes are ignored for transaction launch.
- A write is interpreted as an SD command when `CMD[7:6] == 2'b01`.
- For command writes, `CMD[7:0]` forms the SD command byte; `DATA` provides the 32-bit argument.
- Internal command CRC generation is appended automatically.

#### Status/Control fields

| Bits | Name | Description |
| --- | --- | --- |
| `[7:0]` | `R1/CMD` | During write, SD command byte. After completion, R1 response byte. |
| `[9:8]` | `R` | Expected response type selector: R1 / R1b / R2-R3-R7(32-bit). |
| `[10]` | `W` | FIFO direction qualifier when FIFO is used (`1` for card write from FIFO, `0` for card read into FIFO). |
| `[11]` | `F` | FIFO usage enable for data-transfer commands. |
| `[12]` | `I` | FIFO select (`0` for `FIFO[0]`, `1` for `FIFO[1]`). |
| `[14]` | `B` | Busy indicator while command/transaction is active. |
| `[15]` | `E` | Latched command/transaction error indicator (timeout/CRC-related error classes). Write `1` to clear. |
| `[16]` | `C` | Implementation status/control extension associated with FIFO/token error tracking and clear behavior during command writes. |

Note: The implementation reports additional FIFO/token error context in upper CMD status bits beyond the core PDF narrative; software may use these for diagnostics.

### 4.2 `DATA` Register

- On command issue, `DATA` supplies the 32-bit command argument.
- On command completion, `DATA` returns response payload data when applicable:
  - R2 response in the upper byte,
  - R3/R7 response across full 32 bits.
- `DATA` is also the transfer register for `CONFIG` read/write helper commands.

### 4.3 `FIFO[0]` and `FIFO[1]`

- Two 32-bit FIFO windows support ping-pong buffering.
- Command bit `I` selects which FIFO participates in SD data movement.
- Any write to `CMD` resets the FIFO access pointer to the start.
- Wishbone-side FIFO accesses share one internal address pointer; interleaving accesses across both FIFO windows in one stream advances the same pointer and therefore requires software care.

### 4.4 Internal `CONFIG` Register

`CONFIG` is transferred through `DATA` using helper commands written to `CMD`:

- Read config: write `0x0bf` to `CMD`, then read `DATA`.
- Set config: write desired config fields to `DATA`, then write `0x0ff` to `CMD`.

CONFIG fields:

| Bits | Field | Description |
| --- | --- | --- |
| `[6:0]` | `CLKDIV` | SPI clock divider control (`f_spi = f_clk / (2*(CLKDIV+1))`, with implementation ignoring zero writes for update). |
| `[11:8]` | `LgFIFO` | Log2 FIFO length in 32-bit words used for transfer packet sizing. |
| `[15:12]` | `Max LgFIFO` | Maximum supported `LgFIFO` value reported by implementation. |

## 5. Function Description

### 5.1 Command and Response Operation

1. Software writes argument to `DATA`.
2. Software writes command/control to `CMD`.
3. Controller serializes command + CRC over SPI and waits for selected response class.
4. Response status/data are captured in `CMD`/`DATA`.
5. Busy deasserts when the transaction completes, and `o_int` pulses for one cycle.

Supported response handling modes include:

- R1-only response,
- R1b with additional busy-wait phase,
- 32-bit response collection for R2/R3/R7-style flows.

### 5.2 FIFO-Based Data Transfers

When `F=1` in `CMD`:

- `W=0`: controller reads a data block from card into selected FIFO.
- `W=1`: controller writes a data block from selected FIFO to card.

The design supports single-block transfers through this command path. FIFO usage is coordinated with SD data tokens and CRC checks, with completion/error reflected in `CMD` status and interrupt behavior.

### 5.3 Shared SPI Bus Arbitration

The controller is designed for shared SPI wiring:

- It asserts `o_cs_n` low to request/select card transaction scope.
- It waits for `i_bus_grant` before active SPI clock/data progression.
- If no external arbitration is required, `i_bus_grant` may be tied high.

### 5.4 Error and Completion Behavior

The controller tracks command/data-path error conditions including timeout and CRC-related faults. Error status is latched until explicitly cleared via command register clear semantics.

Completion is indicated by:

- Busy bit deassertion in `CMD`, and
- one-cycle `o_int` pulse when leaving busy state.

## 6. Implementation Details

### 6.1 Architectural Composition

The top-level `sdspi` module contains:

- Wishbone command/data/FIFO register interface logic,
- command transmit and response-parse control sequencing,
- dual FIFO storage arrays with a shared Wishbone-side pointer,
- CRC generation/check logic for command and FIFO data paths,
- watchdog timeout logic,
- low-level byte-to-SPI engine (`llsdspi`).

### 6.2 Control Sequencing

Two coupled control flows are used:

- command transmit progression (command byte stream and optional FIFO packet transfer),
- response progression (R1/R1b/word response phases, FIFO token and completion phases).

This structure allows command-only and data-bearing commands to share one launch/status model while preserving distinct receive-phase behavior.

### 6.3 Low-Level SPI Engine Role (`llsdspi`)

`llsdspi` converts byte strobe requests into SPI bit-level activity and handles bus-grant-aware start behavior. It provides:

- configurable SPI clock pacing from `i_speed`,
- per-byte request/accept and returned-byte strobe interface,
- CS/SCK/MOSI drive and MISO sampling,
- idle signaling back to top-level control.

### 6.4 FIFO and CRC Handling

- Each FIFO is implemented as byte-wide banks grouped into 32-bit Wishbone words.
- FIFO transfer sizing is bounded by configured `LgFIFO`.
- FIFO read/write packetization includes data plus CRC bytes.
- CRC fault tracking contributes to command error status and completion qualification.

### 6.5 Watchdog

A transaction watchdog bounds command wait time. Expiration forces termination of the active sequence and latches error status.

## 7. Submodule List

### 7.1 `llsdspi`

Functional role: low-level SPI byte engine and shared-bus gatekeeper.

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | Byte-engine clock input. |
| `i_speed` | Input | `SPDBITS` | SPI clock divider input. |
| `i_cs` | Input | 1 | Active transaction request from top-level. |
| `i_stb` | Input | 1 | Byte transmit strobe from top-level. |
| `i_byte` | Input | 8 | Byte to transmit. |
| `o_cs_n` | Output | 1 | Active-low chip select output. |
| `o_sclk` | Output | 1 | SPI serial clock output. |
| `o_mosi` | Output | 1 | SPI MOSI output. |
| `i_miso` | Input | 1 | SPI MISO input. |
| `o_stb` | Output | 1 | Received-byte valid strobe. |
| `o_byte` | Output | 8 | Received byte. |
| `o_idle` | Output | 1 | Engine ready-for-next-byte indication. |
| `i_bus_grant` | Input | 1 | Bus grant qualifier for shared SPI environments. |

## 8. Clock and Reset

### 8.1 Clock

- Single explicit clock input: `i_clk`.
- SPI clock is derived internally from `i_clk` via programmable divider logic.

### 8.2 Reset/Initialization

- No top-level reset port is exposed.
- Internal startup behavior relies on initialized state/register defaults and software command sequencing (including configuration and error-clear commands) after power-up.

## 9. Constraints and Integration Notes

- The core is a Wishbone slave only; data movement orchestration is expected from CPU/DMA software control.
- Multi-block SD transactions are not provided in this controller flow; operation is organized around single-block command usage.
- SPI clock must be configured within card-supported limits (commonly 25 MHz class for standard operation, subject to card capability).
- For best FIFO behavior on Wishbone side, avoid interleaving FIFO[0]/FIFO[1] accesses within one pointer sequence.
- `o_debug` is implementation-observability output and may remain unconnected in production integration.
