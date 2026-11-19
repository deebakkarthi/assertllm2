# SSP_UART Functional Specification

## 1. Introduction

`SSP_UART` is a synchronous-serial-hosted UART that combines register access, transmit/receive FIFOs, UART framing control, timeout detection, and interrupt generation behind an SSP/SPI-like 16-bit control/data interface.

The module is intended to reduce host polling overhead by returning status together with data-path register accesses, and by providing FIFO- and timeout-based interrupt sources. It supports RS-232 and RS-485 operating modes with mode-dependent handling of RTS/CTS and RS-485 driver enable behavior.

## 2. Module Diagram

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `Rst` | Input | 1 | Module reset. Resets control/status registers, FIFOs, UART state machines, timeout, and interrupt state. |
| `Clk` | Input | 1 | Main UART operating clock domain. |
| `SSP_SSEL` | Input | 1 | SSP slave-select for this peripheral. Gates effective SSP accesses and output data driving. |
| `SSP_SCK` | Input | 1 | SSP serial clock domain used for host-side register transfer sequencing. |
| `SSP_RA` | Input | 3 | SSP register address select. |
| `SSP_WnR` | Input | 1 | SSP command direction (`1` write, `0` read). |
| `SSP_En` | Input | 1 | SSP data-phase indicator used by register-transfer control and interrupt-clear detection. |
| `SSP_EOC` | Input | 1 | SSP end-of-cycle indicator used to qualify read/write strobes. |
| `SSP_DI[11:0]` | Input | 12 | SSP write payload and command/control bits for addressed register. |
| `SSP_DO[11:0]` | Output | 12 | SSP readback data for addressed register/status window; zero when `SSP_SSEL=0`. |
| `TxD_232` | Output | 1 | UART TX output in RS-232 modes. Forced to mark level in RS-485 modes. |
| `RxD_232` | Input | 1 | UART RX input source in RS-232 modes. |
| `xRTS` | Output | 1 | RS-232 request-to-send output. Mode-dependent manual/automatic behavior. |
| `xCTS` | Input | 1 | RS-232 clear-to-send input used for flow control in Mode 1. |
| `TxD_485` | Output | 1 | UART TX output in RS-485 modes. Forced to mark level in RS-232 modes. |
| `RxD_485` | Input | 1 | UART RX input source in RS-485 modes. |
| `xDE` | Output | 1 | RS-485 transceiver drive-enable control. Asserted while transmitter is active in RS-485 modes. |
| `IRQ` | Output | 1 | Latched interrupt request output derived from enabled UART interrupt flags. |
| `TxIdle` | Output | 1 | Transmit state-machine idle indication. |
| `RxIdle` | Output | 1 | Receive state-machine idle indication. |

### 3.2 SSP Access Semantics

- Effective SSP write strobe: `SSP_SSEL & SSP_WnR & SSP_EOC`.
- Effective SSP read strobe: `SSP_SSEL & ~SSP_WnR & SSP_EOC`.
- `SSP_DO` returns the currently selected register/window value while selected (`SSP_SSEL=1`), otherwise `0`.
- Address `SSP_RA=3'b001` is multiplexed: read accesses return `USR`; write accesses program `BRR` (`PS` and `Div`).

## 4. Register Model

### 4.1 Address Map (`SSP_RA`)

| `SSP_RA` | Name | Access | Description |
| --- | --- | --- | --- |
| `3'b000` | `UCR` | R/W | UART control: operating mode, RTS override (Mode 0), interrupt enable, frame format. |
| `3'b001` | `USR` / `BRR` | R / W | Read: UART status and interrupt flags (`USR`). Write: baud generator prescaler/divider (`BRR`). |
| `3'b010` | `TDR` | R/W | Transmit data/control register. Writes enqueue TX data (when ready) and can request FIFO clears / hold behavior. |
| `3'b011` | `RDR` | R | Receive data/status register snapshot (`TRDY`, `RRDY`, `RTO`, `RERR`, `RD[7:0]`). |
| `3'b100` | `SPR` | R/W | Scratch-pad register and window selector for auxiliary status registers. |

### 4.2 `UCR` (UART Control Register, `RA=0`)

| Bit(s) | Field | Description |
| --- | --- | --- |
| `[11:10]` | `MD` | Operating mode select (Mode 0..3). |
| `[9]` | `RTSo` | Manual RTS output control in Mode 0. |
| `[8]` | `IE` | Interrupt enable for external `IRQ`. |
| `[7:4]` | `FMT` | UART frame format selector (data length/parity/stop configuration). |
| `[3:0]` | Reserved | Not used for baud selection in this revision. |

### 4.3 `USR` (UART Status Register, `RA=1` read)

| Bit(s) | Field | Description |
| --- | --- | --- |
| `[11:10]` | `MD` | Current mode reflection. |
| `[9]` | `RTSi` | Reflected RTS-related status (mode-dependent: `xRTS` in RS-232 modes, `xDE` in RS-485 modes). |
| `[8]` | `CTSi` | Reflected CTS status (`xCTS` in Mode 1; logical `1` in other modes). |
| `[7:6]` | `RS` | Receive status encoding (`00` empty, `01` below half-full, `10` at/above half-full, `11` full). |
| `[5:4]` | `TS` | Transmit status encoding (`00` empty/idle, `01` below half-full, `10` at/above half-full, `11` full). |
| `[3]` | `iRTO` | Receive-timeout interrupt flag. |
| `[2]` | `iRHF` | Receive half-full interrupt flag. |
| `[1]` | `iTHE` | Transmit half-empty interrupt flag. |
| `[0]` | `iTFE` | Transmit empty interrupt flag. |

### 4.4 `BRR` (Baud Rate Register, `RA=1` write)

| Bit(s) | Field | Description |
| --- | --- | --- |
| `[11:8]` | `PS` | Prescaler load value. |
| `[7:0]` | `Div` | Divider load value. |

Baud generation follows:

`Baud = (Clk / 16) / ((PS + 1) * (Div + 1))`

### 4.5 `TDR` (Transmit Data Register, `RA=2`)

| Bit(s) | Field | Description |
| --- | --- | --- |
| `[11]` | `TFC` | Request clear/reset of transmit FIFO. |
| `[10]` | `RFC` | Request clear/reset of receive FIFO. |
| `[9]` | `HLD` | Transmit-hold control: when set on write, TX start can be deferred until hold is released. |
| `[8]` | Reserved | Reserved in this revision. |
| `[7:0]` | `TD` | Transmit payload data written into TX FIFO when write is accepted. |

Write acceptance is gated by `TRDY`; if TX FIFO is full (`TRDY=0`), write side effects are not accepted.

### 4.6 `RDR` (Receive Data Register, `RA=3` read)

| Bit(s) | Field | Description |
| --- | --- | --- |
| `[11]` | `TRDY` | TX FIFO can accept data (`1` when not full). |
| `[10]` | `RRDY` | RX FIFO contains at least one entry. |
| `[9]` | `RTO` | Receive-timeout status. |
| `[8]` | `RERR` | Error tag associated with current `RD[7:0]` entry. |
| `[7:0]` | `RD` | Receive payload data from RX FIFO output. |

`RDR` is captured in the SSP clock domain when `SSP_En` is low; host polling reads this snapshot.

### 4.7 `SPR` Window (`RA=4`)

`SPR[11:9]` selects auxiliary readback window contents.

| `SPR[11:9]` | Window | Access | Returned/Stored Data |
| --- | --- | --- | --- |
| `0` | Scratch Pad | R/W | Raw `SPR` storage value. |
| `1` | `REV` | RO | Revision code (`pVersion`). |
| `2` | `LEN` | RO | FIFO depth parameters (`RFLen`, `TFLen`). |
| `3` | `RTFThr` | R/W | RX/TX threshold register image (`RFThr`, `TFThr`) with write-enable qualifier `SPR[8]=1`. |
| `4` | `THR` peek | RO | Current TX FIFO output word without advancing FIFO. |
| `5` | `RHR` peek | RO | Current RX FIFO output word (includes error bit) without advancing FIFO. |
| `6` | `TFCnt` | RO | TX FIFO count. |
| `7` | `RFCnt` | RO | RX FIFO count. |

## 5. Function Description

### 5.1 Operational Overview

`SSP_UART` bridges an SSP host interface to an internal UART datapath:

1. Host writes transmit data/control via `TDR`.
2. Accepted TX data is queued in a transmit FIFO (`THR`).
3. A baud-rate generator produces `CE_16x`; transmit and receive state machines consume this enable to serialize/deserialize according to `FMT`.
4. Received characters (with per-character error tag) are queued into receive FIFO (`RHR`).
5. Host reads `RDR`/`USR`/`SPR` windows for payload and status.
6. Timeout/threshold-empty/threshold-full conditions produce interrupt flags; enabled flags assert `IRQ`.

### 5.2 Transmit Path Behavior

- `TDR` write is accepted only when `TRDY=1`.
- Accepted payload (`TD[7:0]`) is transferred to TX FIFO in `Clk` domain.
- UART transmitter reads FIFO data, sends start bit, data bits (7/8), optional parity, and 1 or 2 stop bits per `FMT` decode.
- In Mode 1, external `xCTS` can pause between characters; a character already in progress completes before pause takes effect.
- `TxIdle` indicates no active transmission state.
- `HLD` allows delaying transmission launch behavior by holding the effective TX-empty condition until hold is released.

### 5.3 Receive Path Behavior

- Receiver samples asynchronous input selected by operating mode.
- Start-bit qualification and bit-center sampling are driven by `CE_16x`.
- Data is assembled into `RD[7:0]`; parity/stop violations map to `RD[8]` (`RERR` for that character).
- Each completed character is pushed to RX FIFO (`RHR`) with its error tag.
- Host reads `RDR` to obtain `RRDY`, timeout/error status, and current receive byte snapshot.
- RX FIFO pop (`RE_RHR`) is generated on valid `RDR` read request only when captured `RDR[10]` indicates data availability.

### 5.4 Operating Modes (`UCR.MD`)

- `Mode 0` (RS-232, no automatic flow control):
  - `TxD_232` active, `TxD_485` inactive.
  - `xRTS` driven by `RTSo`.
  - TX path not gated by `xCTS`.
- `Mode 1` (RS-232 with automatic flow control):
  - `xRTS` asserted while RX FIFO is below half-full (`~RF_HF`).
  - `xCTS` is used as transmitter enable gating between characters.
- `Mode 2` (RS-485 without loopback):
  - `TxD_485` active, `xDE` asserted while transmitter is active (`~TxIdle`).
  - RX input is forced to mark (`1`) during local transmit activity, otherwise follows `RxD_485`.
- `Mode 3` (RS-485 with loopback):
  - Same RS-485 drive behavior as Mode 2.
  - RX input follows `RxD_485` continuously (including during local transmit).

### 5.5 Interrupt and Timeout Behavior

Interrupt-source flags (`iTFE`, `iTHE`, `iRHF`, `iRTO`) are generated from FIFO and timeout events:

- `iTFE`: set when TX FIFO transitions to empty.
- `iTHE`: set when TX FIFO crosses below half-full.
- `iRHF`: set when RX FIFO reaches half-full.
- `iRTO`: set when receive-timeout condition asserts.

`IRQ` is a latched request asserted when `IE=1` and any interrupt flag is set. `IRQ` remains asserted until reset or interrupt-clear event (`Clr_Int`) generated from `USR` access path.

Receive-timeout logic arms on RX FIFO write, tracks elapsed character intervals using `CE_16x`, and clears on RX FIFO read or reset.

## 6. Implementation Details

### 6.1 Clock-Domain Partitioning

- SSP control/register-transfer capture uses `SSP_SCK`.
- UART datapath (FIFOs, BRG, TX/RX state machines, timeout, interrupt logic, `IRQ`) runs on `Clk`.
- `re1ce` synchronizer/pulse generators transfer SCK-domain events into single-cycle pulses in `Clk` domain (`WE_THR`, `RE_RHR`, `ClrTHR`, `ClrRHR`, `Clr_Int`).

### 6.2 Datapath and Control Blocks

- TX datapath: `TDR` -> `THR` FIFO -> `UART_TXSM` -> mode mux -> `TxD_232/TxD_485`.
- RX datapath: mode-selected serial input -> `UART_RXSM` -> `RHR` FIFO -> `RDR` snapshot/host read.
- BRG: programmable prescaler/divider produces `CE_16x` timing enable.
- Timeout: `UART_RTO` counts character intervals from RX activity and asserts `RcvTimeout`/`RTO`.
- Interrupt aggregation:
  - `UART_INT` generates sticky event flags in UART clock domain.
  - Top-level OR-gates enabled flags into latched external `IRQ`.

### 6.3 FIFO Organization and Status Derivation

- TX FIFO depth: `2**(pTF_Depth+4)`, width 8.
- RX FIFO depth: `2**(pRF_Depth+4)`, width 9 (error bit + data).
- `TRDY = ~TF_FF`.
- `RRDY = ~RF_EF`.
- `RERR = RHR[8]`.
- `TS`/`RS` status fields are derived from FIFO full/half/empty indicators with idle-state consideration.

### 6.4 Auxiliary Window and Threshold Register Note

`SPR` sub-address `3` (`RTFThr`) is implemented as a readable/writable register image and requires `SPR[8]=1` to update. In this RTL revision, interrupt generation uses FIFO half-full indicators from the FIFO block; threshold reprogramming behavior should be confirmed against the intended integration build if variable threshold triggering is required.

## 7. Submodule List

### 7.1 `DPSFnmCE`

Role: Parameterized synchronous FIFO used for both TX (`THR`) and RX (`RHR`) queues.

| Signal | Dir | Description |
| --- | --- | --- |
| `Rst`, `Clk` | In | FIFO reset/clock. |
| `WE`, `RE` | In | Write/read enables. |
| `DI`, `DO` | In/Out | FIFO data input/output. |
| `FF`, `HF`, `EF` | Out | Full/half-full/empty flags. |
| `Cnt` | Out | FIFO occupancy count. |

### 7.2 `UART_BRG`

Role: Generates `CE_16x` enable from programmable `PS` and `Div` values.

| Signal | Dir | Description |
| --- | --- | --- |
| `PS[3:0]`, `Div[7:0]` | In | Prescaler/divider programming. |
| `CE_16x` | Out | 16x baud timing enable pulse. |

### 7.3 `UART_TXSM`

Role: Transmit state machine and serializer with format-dependent frame generation.

| Signal | Dir | Description |
| --- | --- | --- |
| `Len`, `NumStop`, `ParEn`, `Par` | In | Frame format controls. |
| `TF_EF`, `THR`, `TF_RE` | In/In/Out | TX FIFO status, data input, and FIFO pop control. |
| `CTSi` | In | Flow-control gate (Mode 1). |
| `TxD` | Out | Serialized UART transmit output. |
| `TxIdle` | Out | Idle indication used by mode mux/de-enable logic. |

### 7.4 `UART_RXSM`

Role: Receive state machine with start validation, bit sampling, parity/stop checking, and error tagging.

| Signal | Dir | Description |
| --- | --- | --- |
| `Len`, `NumStop`, `ParEn`, `Par` | In | Frame format controls. |
| `RxD` | In | Selected serial receive input. |
| `RD[8:0]` | Out | Received character plus error flag. |
| `WE_RHR` | Out | RX FIFO write strobe per completed character/error event. |
| `RxIdle` | Out | Receiver idle indication. |

### 7.5 `UART_RTO`

Role: Receive timeout detection based on character-frame duration and configured timeout character count.

| Signal | Dir | Description |
| --- | --- | --- |
| `WE_RHR`, `RE_RHR` | In | Arms timer on receive write; clears on receive read. |
| `CCntVal`, `RTOVal` | In | Character-length and timeout-delay counts. |
| `RcvTimeout` | Out | Timeout status pulse/latch input to status/interrupt logic. |

### 7.6 `UART_INT`

Role: Generates interrupt flags (`iTFE`, `iTHE`, `iRHF`, `iRTO`) from FIFO and timeout transitions, with clear handling.

| Signal | Dir | Description |
| --- | --- | --- |
| `TF_HF`, `TF_EF`, `RF_HF`, `RF_EF` | In | FIFO condition inputs. |
| `RTO` | In | Receive-timeout status input. |
| `Clr_Int` | In | Clear pulse from USR access path. |
| `USR[3:0]` | In | Captured interrupt bits used for clear qualification. |
| `iTFE`, `iTHE`, `iRHF`, `iRTO` | Out | Interrupt source flags. |

### 7.7 `re1ce`

Role: Event capture and synchronization helper that converts SCK-domain events into `Clk`-domain pulses.

| Signal | Dir | Description |
| --- | --- | --- |
| `den`, `din` | In | Event detect enable and source-domain trigger. |
| `clk`, `rst` | In | Destination domain clock/reset. |
| `pls` | Out | Synchronized pulse in destination domain. |

## 8. Clock and Reset

- `Clk` is the primary UART processing clock.
- `SSP_SCK` is used for SSP-side register transfer sequencing.
- `Rst` initializes control/status state, FIFOs, timeout logic, TX/RX state machines, and interrupt outputs.
- Cross-domain operations between `SSP_SCK` and `Clk` rely on explicit event-synchronization modules; SSP software access should follow the defined transaction sequencing (`SSP_SSEL`, `SSP_En`, `SSP_EOC`) to avoid ambiguous register interaction.

## 9. Constraints

- Host software should use `TRDY` before enqueuing TX data and `RRDY` before consuming RX data.
- In Mode 1, sustained transmit throughput depends on external `xCTS` assertion.
- Mode 2 intentionally suppresses RX sampling during local transmission by forcing the RX path to mark state.
- `IRQ` deassertion is tied to interrupt-clear/reset behavior, not only to immediate source-condition deassertion.
- If programmable FIFO interrupt thresholds are required by system-level software, validate the integration build behavior of `RTFThr` against the deployed RTL configuration.
