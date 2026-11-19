# wbqspiflash Design Specification

## 1. Introduction

`wbqspiflash` is a WISHBONE-controlled Quad-SPI flash controller. It provides memory-like read/program access to external flash data space and exposes control/status registers for erase, protection, configuration, and device-identification operations.

The design is organized as a high-level WISHBONE transaction/state controller (`wbqspiflash`) and a low-level Quad-SPI transfer engine (`llqspi`). The high-level controller sequences flash commands, tracks write/erase progress, and arbitrates between data accesses and control-register accesses.

## 2. Module Diagram


## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk_100mhz` | Input | 1 | System clock for all controller logic. |
| `i_wb_cyc` | Input | 1 | WISHBONE cycle indicator. |
| `i_wb_data_stb` | Input | 1 | WISHBONE strobe for flash data-space accesses. |
| `i_wb_ctrl_stb` | Input | 1 | WISHBONE strobe for control-register accesses. |
| `i_wb_we` | Input | 1 | WISHBONE write enable. |
| `i_wb_addr` | Input | 20 | WISHBONE word address. Full width is used for data-space accesses; low bits select control register when `i_wb_ctrl_stb=1`. |
| `i_wb_data` | Input | 32 | WISHBONE write data. |
| `o_wb_ack` | Output | 1 | WISHBONE acknowledge pulse for completed access. |
| `o_wb_stall` | Output | 1 | WISHBONE stall; asserted while command/transaction cannot complete immediately. |
| `o_wb_data` | Output | 32 | WISHBONE read data. |
| `o_qspi_sck` | Output | 1 | QSPI clock output. |
| `o_qspi_cs_n` | Output | 1 | Active-low chip select. |
| `o_qspi_mod` | Output | 2 | QSPI mode control to external glue logic. |
| `o_qspi_dat` | Output | 4 | QSPI output data lines. |
| `i_qspi_dat` | Input | 4 | QSPI input data lines. |
| `o_interrupt` | Output | 1 | Completion interrupt pulse for write/erase completion detection. |

### 3.1 Interface Semantics

- The controller uses split strobes by design:
  - `i_wb_data_stb` for flash data window transactions.
  - `i_wb_ctrl_stb` for control-register transactions.
- Data and control strobes are intended to be mutually exclusive for any single request.
- `o_wb_stall` remains asserted whenever the controller is in a non-idle command state or waiting for flash completion.
- `o_wb_ack` is pulsed when a request completes; long-latency operations can acknowledge immediately at command acceptance while later blocking subsequent requests via `o_wb_stall`.
- The QSPI interface is split into explicit output and input buses. External integration must provide any required inout glue between `o_qspi_mod/o_qspi_dat` and physical flash I/O pins.

## 4. Register and Addressing Model

### 4.1 Access Regions

- **Data window**: selected by `i_wb_data_stb`, mapped by `i_wb_addr[19:0]` as flash word address.
- **Control registers**: selected by `i_wb_ctrl_stb`, decoded by `i_wb_addr[1:0]`.

| Control Address (`i_wb_addr[1:0]`) | Register | Width | Access | Description |
| --- | --- | --- | --- | --- |
| `2'b00` | `EREG` | 32 | R/W | Erase/protection/local status register |
| `2'b01` | `CONFIG` | 8 (in `o_wb_data[7:0]`) | R/W | Flash configuration register |
| `2'b10` | `STATUS` | 8 (in `o_wb_data[7:0]`) | R/W | Flash status register |
| `2'b11` | `ID` | 32 | R | Flash JEDEC ID/read-ID response |

### 4.2 `EREG` (Control Address `0`)

Readback layout:

| Bit(s) | Name | Meaning |
| --- | --- | --- |
| 31 | `WIP` | Write/erase in progress (`write_in_progress`). |
| 30 | `DIRTY` | Sector dirty flag (`dirty_sector`). |
| 29 | `SPI_BUSY` | Low-level SPI engine busy indication (`spi_busy`). |
| 28 | `~WP` | Write-protect disable state (`1` means writes are permitted). |
| 27 | `QUAD_EN` | Quad-mode enabled indication (`quad_mode_enabled`). |
| 26:20 | Reserved | Read as `0`. |
| 19:14 | `SECTOR` | Erased/current sector tracking (`erased_sector`). |
| 13:0 | Reserved | Read as `0`. |

Write behavior:

- Bit 28 controls write protection (`write_protect <= ~bit28`).
- Bit 31 requests sector erase when set and protection allows.
- Bits 19:14 provide sector address for erase command.

### 4.3 `CONFIG` Register (Control Address `1`)

- Accessed using flash `RCR`/`WRR` command sequence.
- `o_wb_data[7:0]` returns configuration byte.
- Bit 1 (`QUAD`) drives `quad_mode_enabled` when read/written.
- Writes to this register are flash program operations and therefore induce busy/write-in-progress handling.

### 4.4 `STATUS` Register (Control Address `2`)

- Accessed using flash `RDSR`/`WRR` command sequence.
- `o_wb_data[7:0]` returns status byte.
- `WIP` is bit 0 and is used by controller polling paths.
- Controller updates internal `last_status` from readback.

### 4.5 `ID` Register (Control Address `3`)

- Read issues flash `RDID (0x9f)` sequence.
- In this implementation, returned read-ID value is reported on `o_wb_data[31:0]`.

## 5. Functional Description

### 5.1 Startup Behavior

The module has no external reset input. It initializes internal state via Verilog initial values and enters an internal startup sequence that toggles command/control outputs to force a known flash interface state before normal command servicing. After startup, the controller transitions to idle command handling.

### 5.2 Read Operation

For data-window reads (`i_wb_data_stb=1`, `i_wb_we=0`):

1. Controller issues read command sequence based on `quad_mode_enabled`:
   - serial fast-read path when quad mode is not enabled,
   - quad-I/O read path when quad mode is enabled.
2. Dummy/address phases are emitted as required by selected command path.
3. Read data is returned on `o_wb_data` with byte-lane reordering to match the little-endian WISHBONE contract.
4. Pipelined sequential reads are supported when the next request is for `i_wb_addr == previous+1`.

The controller includes a quad-read idle mode path (`WBQSPI_RDIDLE`) so subsequent read transactions can resume with reduced setup overhead compared to full re-entry.

### 5.3 Program (Write) Operation

For data-window writes (`i_wb_data_stb=1`, `i_wb_we=1`):

1. Write is accepted only when write protection is disabled and no write/erase is in progress.
2. Controller issues `WREN`, then page-program command (`PP` or `QPP` depending on quad mode), then streams write data.
3. Continuous burst writes are accepted while:
   - addresses increment by one word,
   - all words remain within one flash page (`i_wb_addr[19:6]` unchanged),
   - bus cycle remains active.
4. On end-of-burst or out-of-bounds condition, controller releases hold and waits for flash completion via status polling.

### 5.4 Erase Operation

Erase is commanded through `EREG` writes:

1. Disable protection (`EREG[28]=1`) as needed.
2. Write `EREG[31]=1` with target sector in `EREG[19:14]`.
3. Controller issues `WREN`, then sector erase command.
4. Internal status tracks `write_in_progress`, `erased_sector`, and `dirty_sector`.

### 5.5 Completion, Stall, and Interrupt Behavior

- During active write/erase completion windows, the controller repeatedly reads status (`WIP`) until clear.
- While waiting, unrelated accesses are stalled.
- `o_interrupt` is pulsed high for one clock when background status polling observes `WIP` transition from set to clear.
- `o_wb_stall` deasserts when controller returns to an idle command-accepting state.

### 5.6 Control-Register Access Behavior

- Control reads/writes can trigger direct flash commands (`RDSR`, `RCR`, `RDID`, `WRR`, status clear path), not just local register accesses.
- `EREG` read can be satisfied from local tracked state, except when status refresh is required for active write-in-progress cases.

## 6. Implementation Details

### 6.1 High-Level Controller (`wbqspiflash`)

`wbqspiflash` is an FSM-driven transaction manager with explicit states for:

- startup/line-conditioning,
- idle request decode,
- read command setup and pipelined read data,
- write enable/program streaming,
- erase sequence,
- status/config/id register command handling,
- write-in-progress polling and post-completion return to idle.

Key internal control/state elements include:

- `write_in_progress`, `write_protect`, `dirty_sector`, `erased_sector`,
- `quad_mode_enabled`, `last_status`,
- captured request fields `spif_*` for deferred execution while stalled.

### 6.2 Low-Level Transfer Engine Integration (`llqspi`)

`llqspi` performs framed SPI/QSPI word transfers under control of:

- `spi_wr` request pulse,
- `spi_len` (8/16/24/32-bit transaction unit),
- `spi_spd` (single-bit vs quad-bit data phase),
- `spi_dir` (quad output vs quad input mode),
- `spi_hold` (clock/data-frame hold between chained operations).

`wbqspiflash` uses `spi_busy`/`spi_valid` handshakes to sequence command phases and detect valid return words.

### 6.3 QSPI Output Override During Startup

During startup state conditioning, top-level outputs are temporarily driven from internal override controls (`spif_override`) rather than normal `llqspi` outputs. After startup completes, outputs are sourced from `llqspi`.

## 7. Submodules

### 7.1 `llqspi`

Role: Low-level serial transfer block that translates per-word command requests into QSPI clock/chip-select/data signaling, supports chained transactions with hold, and reports returned words/valid pulses.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | Module clock. |
| `i_wr` | Input | 1 | Transfer request strobe. |
| `i_hold` | Input | 1 | Hold active transaction without closing chip-select sequence. |
| `i_word` | Input | 32 | Outgoing command/data word. |
| `i_len` | Input | 2 | Transfer length selector (`00`=8b, `01`=16b, `10`=24b, `11`=32b). |
| `i_spd` | Input | 1 | Transfer width select (serial vs quad). |
| `i_dir` | Input | 1 | Quad direction selector used in mode encoding. |
| `o_word` | Output | 32 | Captured incoming word from SPI/QSPI lines. |
| `o_valid` | Output | 1 | Valid pulse for `o_word`. |
| `o_busy` | Output | 1 | Engine busy indication. |
| `o_sck` | Output | 1 | Serial clock output. |
| `o_cs_n` | Output | 1 | Active-low chip select output. |
| `o_mod` | Output | 2 | Mode encoding (`SPI`, `QOUT`, `QIN`). |
| `o_dat` | Output | 4 | Output data lines to top-level glue logic. |
| `i_dat` | Input | 4 | Input data lines from flash/glue logic. |

## 8. Clock and Reset

| Signal | Type | Description |
| --- | --- | --- |
| `i_clk_100mhz` | Clock | Primary system clock. |

Reset behavior:

- No explicit top-level reset port is present.
- Internal state/power-up behavior is established through initialized registers and startup sequencing.

## 9. Constraints and Integration Notes

- Designed around a 100 MHz system clock and a divided/toggled QSPI clock behavior in the low-level engine.
- Data path is 32-bit word oriented; byte-select controls are not implemented.
- Data strobes and control strobes should not be asserted together for one transaction.
- Programming requires prior erase of target region and write-protect disable.
- Writes that are non-sequential or cross page boundaries are not streamed as one page-program burst and will transition to completion handling.
- Control-register writes to status/config trigger flash write-register commands and can incur write-in-progress latency.
- `o_qspi_mod/o_qspi_dat/i_qspi_dat` require board-level glue to match physical inout flash I/O wiring.
