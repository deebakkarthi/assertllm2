# i2c Design Specification

## 1. Introduction
`i2c` is an APB-connected I2C controller wrapper that bridges APB register/FIFO accesses to serial transfers on `SDA` and `SCL`. The top-level integrates an APB front end, separate transmit and receive FIFOs, and an internal I2C control block.

The module is intended to support software-driven write and read operation modes through APB programming of configuration, timeout, and FIFO data paths.

## 2. Module Diagram

## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `PCLK` | Input | 1 | APB and internal logic clock. |
| `PRESETn` | Input | 1 | Active-low reset input for APB control logic, I2C control logic, and FIFOs. |
| `PADDR` | Input | 32 | APB address; decoded for TX FIFO, RX FIFO, configuration, and timeout accesses. |
| `PWDATA` | Input | 32 | APB write data bus. |
| `PWRITE` | Input | 1 | APB transfer direction (`1`: write, `0`: read). |
| `PSELx` | Input | 1 | APB peripheral select for this block. |
| `PENABLE` | Input | 1 | APB enable phase indicator. |
| `PREADY` | Output | 1 | APB ready response for supported accesses. |
| `PSLVERR` | Output | 1 | APB slave error indication, sourced from internal I2C error status. |
| `INT_RX` | Output | 1 | Receive status interrupt output; mirrors internal `RX_EMPTY` status in the current implementation. |
| `INT_TX` | Output | 1 | Transmit status interrupt output; mirrors internal `TX_EMPTY` status in the current implementation. |
| `PRDATA` | Output | 32 | APB read data path from RX FIFO output bus. |
| `SDA_ENABLE` | Output | 1 | I2C-side control output used by the internal core to indicate SDA drive-control phase. |
| `SCL_ENABLE` | Output | 1 | I2C-side control output used by the internal core to indicate SCL drive-control phase. |
| `SDA` | Inout | 1 | I2C serial data line. |
| `SCL` | Inout | 1 | I2C serial clock line. |

### 3.1 Interface Semantics

- APB accesses are accepted when `PSELx=1`, `PENABLE=1`, and `PADDR` selects one of the implemented locations (`0x0`, `0x4`, `0x8`, `0xC`); under these conditions `PREADY` is asserted.
- `0x0` write (`PWRITE=1`) generates TX FIFO write enable (`WR_ENA`) and transfers `PWDATA` to the TX FIFO input path.
- `0x4` read (`PWRITE=0`) generates RX FIFO read enable (`RD_ENA`) and returns RX data on `PRDATA`.
- `0x8` and `0xC` writes update internal configuration and timeout registers, respectively.
- `PSLVERR`, `INT_RX`, and `INT_TX` are combinational status propagations from internal logic.
- `PRDATA` is driven from the RX data path; software should sample it for valid RX FIFO reads (`PADDR=0x4`, read transfer accepted).

## 4. Functional Description

### 4.1 APB Register/Addressed Operation Model

| APB Address | Access | Function |
| --- | --- | --- |
| `0x0000_0000` | Write | Push one 32-bit entry to TX FIFO (`PWDATA`). |
| `0x0000_0004` | Read | Pop/read one 32-bit entry from RX FIFO path. |
| `0x0000_0008` | Write | Program I2C configuration register (`PWDATA[13:0]`). |
| `0x0000_000C` | Write | Program timeout register (`PWDATA[13:0]`). |

`DATA_CONFIG_REG[1:0]` is used by the I2C core for mode selection in the current RTL:
- `2'b10`: transmit operation enabled.
- `2'b01`: receive operation enabled.
- `2'b00`: idle/no transfer start condition.
- `2'b11`: error condition (`ERROR` asserted).

`DATA_CONFIG_REG[13:2]` is used as a programmable timing divisor for serial phase timing.

### 4.2 APB-to-I2C Data Flow

- Software writes 32-bit words into the TX FIFO through APB address `0x0`.
- The internal I2C TX control path consumes TX FIFO entries and serializes each entry across control, address, and data phases.
- Received serial bits are assembled by the RX control path into a 32-bit receive word and are intended to be delivered through the RX FIFO/APB read path.
- APB reads at `0x4` retrieve RX path data via `PRDATA` and issue RX FIFO read enable.

### 4.3 Transmit Operation

When TX mode is selected (`DATA_CONFIG_REG[1:0]=2'b10`), TX FIFO contains data, and timeout gating allows progress, the TX state machine advances from `IDLE` to protocol phases:
- Start condition phase (`START`).
- Control byte phase (`CONTROLIN_*`) followed by acknowledge sampling.
- Address byte phase (`ADDRESS_*`) followed by acknowledge sampling.
- First data byte phase (`DATA0_*`) followed by acknowledge sampling.
- Second data byte phase (`DATA1_*`) followed by acknowledge sampling.
- Stop condition phase (`STOP`).

For each byte phase, acknowledge is sampled through `SDA` in the corresponding response state. On NACK, the controller enters a restart/retry path (`NACK`) and re-attempts transfer progression according to internal phase counters.

After the final response phase completes, the TX FIFO read-enable is asserted to advance to the next TX FIFO entry.

### 4.4 Receive Operation

When RX mode is selected (`DATA_CONFIG_REG[1:0]=2'b01`), the RX state machine samples `SDA`/`SCL` and reconstructs control, address, and two data-byte fields into `fifo_rx_data_in[31:0]` across analogous phase groups (`CONTROLIN_*`, `ADDRESS_*`, `DATA0_*`, `DATA1_*`). Sampling is gated by the configured timing divisor and `SCL` level checks.

RX response phases evaluate acknowledge state and can branch through delay or NACK handling before stop/idle transition.

### 4.5 Status, Interrupt, Timeout, and Error Behavior

- `INT_TX` mirrors `TX_EMPTY`; `INT_RX` mirrors `RX_EMPTY`.
- `ERROR` is asserted in mode `DATA_CONFIG_REG[1:0]=2'b11` and propagates to `PSLVERR`.
- A timeout counter (`count_timeout`) is maintained in TX idle conditions and is compared against `TIMEOUT_TX` as a guard for transfer start progression.
- Transfer completion and throughput are data- and bus-dependent; no fixed-cycle completion latency is specified.

### 4.6 Reset and Sequencing

- `PRESETn=0` resets APB configuration/timeout registers, TX/RX FIFOs, and TX/RX control state.
- After reset deassertion, software programs configuration/timeout first, then performs TX writes or RX reads according to the selected operation mode.

## 5. Implementation Details

### 5.1 Top-Level Organization

The top module instantiates:
- APB interface/control block (`apb`).
- TX FIFO (`fifo`) for APB-to-I2C transmit buffering.
- RX FIFO (`fifo`) for I2C-to-APB receive buffering.
- I2C control block (`module_i2c`) for serial sequencing, mode handling, and status generation.

The APB block decodes bus accesses and exposes FIFO/control strobes. The I2C block consumes TX FIFO data, drives/monitors `SDA` and `SCL`, and produces status/error outputs.

### 5.2 APB Control Path Realization

- `WR_ENA` and `RD_ENA` are combinational decodes of APB address, direction, select, and enable.
- `PREADY` is combinationally asserted for implemented operations (`0x0`, `0x4`, `0x8`, `0xC`) during active APB access.
- Configuration (`INTERNAL_I2C_REGISTER_CONFIG`) and timeout (`INTERNAL_I2C_REGISTER_TIMEOUT`) registers are updated on `PCLK` when corresponding write accesses are accepted.
- `PRDATA` is sourced from `READ_DATA_ON_RX`; `PSLVERR`, `INT_TX`, and `INT_RX` are direct status mappings.

### 5.3 FIFO Datapath Behavior

Each FIFO is a 32-bit-wide, pointer-based buffer with nominal address width 4:
- Independent write/read pointers (`wr_ptr`, `rd_ptr`).
- Occupancy counter (`counter`) updated for write-only and read-only operations.
- `f_empty` asserted at `counter==0`.
- `f_full` asserted at `counter==15` in the current implementation.
- `data_out` reflects memory at the current read pointer.

### 5.4 I2C Control Path Realization

`module_i2c` contains separate TX and RX state machines with shared phase naming. Key control elements:
- Timing counters (`count_send_data`, `count_receive_data`) compared to `DATA_CONFIG_REG[13:2]` for per-phase timing.
- Byte-group progression counters (`count_tx`, `count_rx`) controlling control/address/data sequencing.
- Acknowledge capture (`RESPONSE`) sampled from `SDA` in response states.
- Mode-dependent selection of SDA/SCL drive paths and generation of `ENABLE_SDA`/`ENABLE_SCL` control outputs.
- Timeout counter (`count_timeout`) used as TX start guard with `TIMEOUT_TX`.

## 6. Submodules

### 6.1 `apb`

Role:
- Decodes APB transfers.
- Generates FIFO strobes and configuration/timeout register writes.
- Returns APB read/status/interrupt outputs.

Interface (direction relative to `apb`):

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `PCLK`, `PRESETn` | Input | 1 each | APB clock and active-low reset. |
| `PSELx`, `PWRITE`, `PENABLE` | Input | 1 each | APB transfer control. |
| `PADDR`, `PWDATA` | Input | 32 each | APB address and write data. |
| `READ_DATA_ON_RX` | Input | 32 | RX FIFO data path into APB read channel. |
| `ERROR`, `TX_EMPTY`, `RX_EMPTY` | Input | 1 each | Internal status/error inputs. |
| `PRDATA` | Output | 32 | APB read data output. |
| `WR_ENA`, `WRITE_DATA_ON_TX` | Output | 1, 32 | TX FIFO write strobe and write data. |
| `RD_ENA` | Output | 1 | RX FIFO read strobe. |
| `INTERNAL_I2C_REGISTER_CONFIG` | Output | 14 | I2C mode/timing configuration register. |
| `INTERNAL_I2C_REGISTER_TIMEOUT` | Output | 14 | Timeout configuration register. |
| `PREADY`, `PSLVERR`, `INT_RX`, `INT_TX` | Output | 1 each | APB ready/error and interrupt outputs. |

### 6.2 `fifo`

Role:
- Provides buffered 32-bit storage between APB and I2C control domains (same clock in this integration).

Interface (direction relative to `fifo`):

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clock` | Input | 1 | FIFO clock. |
| `reset` | Input | 1 | Active-high FIFO reset. |
| `wr_en`, `rd_en` | Input | 1 each | Write/read enable controls. |
| `data_in` | Input | 32 (default) | Write data. |
| `f_full`, `f_empty` | Output | 1 each | Full/empty status flags. |
| `data_out` | Output | 32 (default) | Read data at current read pointer. |

### 6.3 `module_i2c`

Role:
- Executes serial protocol phases for TX and RX modes.
- Interfaces with TX/RX FIFO status/data and APB-programmed configuration.
- Produces I2C line controls and status/error outputs.

Interface (direction relative to `module_i2c`):

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `PCLK`, `PRESETn` | Input | 1 each | Core clock and active-low reset. |
| `fifo_tx_f_full`, `fifo_tx_f_empty` | Input | 1 each | TX FIFO status inputs. |
| `fifo_tx_data_out` | Input | 32 | TX FIFO read data input. |
| `fifo_tx_rd_en` | Output | 1 | TX FIFO pop control. |
| `fifo_rx_f_full`, `fifo_rx_f_empty` | Input | 1 each | RX FIFO status inputs. |
| `fifo_rx_data_in` | Output | 32 | Assembled RX word output toward RX FIFO. |
| `fifo_rx_wr_en` | Output | 1 | RX FIFO push control. |
| `DATA_CONFIG_REG`, `TIMEOUT_TX` | Input | 14 each | Mode/timing and timeout controls. |
| `TX_EMPTY`, `RX_EMPTY`, `ERROR` | Output | 1 each | Status and error outputs to APB layer. |
| `ENABLE_SDA`, `ENABLE_SCL` | Output | 1 each | I2C line-control qualifiers. |
| `SDA`, `SCL` | Inout | 1 each | Serial data and serial clock lines. |

## 7. Clock and Reset

- Primary clock: `PCLK`.
- Primary reset: `PRESETn` (active low).
- `apb` and `module_i2c` use `PRESETn` directly in `posedge PCLK` sequential logic.
- FIFO instances use an internal active-high reset derived from `!PRESETn`.
- Integration should ensure reset assertion long enough to clear APB registers, FIFO pointers/counters, and I2C FSM state.

## 8. Constraints and Integration Notes

- APB software should use only implemented addresses (`0x0`, `0x4`, `0x8`, `0xC`) for defined behavior.
- Mode `DATA_CONFIG_REG[1:0]=2'b11` is an error mode in current RTL and drives `PSLVERR` through `ERROR`.
- `INT_TX` and `INT_RX` are level status outputs (empty flags), not edge-qualified event pulses.
- This top-level directly exposes `SDA` and `SCL` as `inout`; external integration is responsible for board-level I2C electrical requirements.
- Needs confirmation: the current RTL contains RX-path behavior where `fifo_rx_data_in` is assembled but `fifo_rx_wr_en` is not asserted in normal receive sequencing.
- Needs confirmation: FIFO full indication is asserted at occupancy count `15` in the current implementation, so effective usable depth should be validated at integration time.
- Needs confirmation: per-byte bit ordering should be validated against intended system-level I2C framing requirements for this core configuration.
