# rtfSimpleUart Design Specification

## 1. Introduction

`rtfSimpleUart` is the inferred top-level module for `COMMUNICATION CONTROLLER/rtfsimpleuart`. This specification is generated from local documentation artifacts and RTL sources.
Primary documentation inputs: rtfSimpleUart.pdf, rtfSimpleUart.doc.

## 2. Module Diagram

## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `rst_i` | Input | 1 | Reset signal |
| `clk_i` | Input | 1 | Clock input signal |
| `cyc_i` | Input | 1 | Input signal |
| `stb_i` | Input | 1 | Input signal |
| `we_i` | Input | 1 | Input signal |
| `adr_i` | Input | 32 | Input signal |
| `dat_i` | Input | 8 | Input signal |
| `dat_o` | Output | 8 | Output signal |
| `ack_o` | Output | 1 | Output signal |
| `vol_o` | Output | 1 | Output signal |
| `irq_o` | Output | 1 | Output signal |
| `cts_ni` | Input | 1 | Input signal |
| `rts_no` | Output | 1 | Output signal |
| `dsr_ni` | Input | 1 | Input signal |
| `dcd_ni` | Input | 1 | Input signal |
| `dtr_no` | Output | 1 | Output signal |
| `rxd_i` | Input | 1 | Input signal |
| `txd_o` | Output | 1 | Output signal |
| `data_present_o` | Output | 1 | Output signal |

### 3.1 Interface Semantics

- Clock-domain reference signals: `clk_i`.
- Reset reference signals: `rst_i`.

## 4. Functional Description

1. Register Description............................................................................................................ 4
2. clock signal during transmission or reception.
3. only a single transmission / reception format which is 1 start bit, 1 stop bit, 8 data bits
4. Register Description
5. - write to transmit buffer
6. - read from receive buffer
7. 1 LS RO Line Status register
8. 3 Framing error, this bit is set if there was a framing
9. error with the current byte in the receiver
10. 2 MS RO Modem Status register
11. Writing to the modem status register clears the change indicators
12. and also clears a modem status interrupt
13. 3 IS RO Interrupt Status register
14. 2-4 Encoded interrupt level

## 5. Implementation Details

- Top module source: `rtfSimpleUart.v`.
- Parsed reachable RTL files from the top: 4.
- Numeric Verilog macros detected: `CNT`, `IDLE`.

## 6. Submodules

### 6.1 `edge_det`

- VERILOG module with 7 ports and 0 child instantiations.
- Representative interface signals:
  - `rst` (Input, 1)
  - `clk` (Input, 1)
  - `ce` (Input, 1)
  - `i` (Input, 1)
  - `pe` (Output, 1)
  - `ne` (Output, 1)
  - `ee` (Output, 1)

### 6.2 `rtfSimpleUartRx`

- VERILOG module with 14 ports and 0 child instantiations.
- Representative interface signals:
  - `rst_i` (Input, 1)
  - `clk_i` (Input, 1)
  - `cyc_i` (Input, 1)
  - `stb_i` (Input, 1)
  - `ack_o` (Output, 1)
  - `we_i` (Input, 1)
  - `dat_o` (Output, 8)
  - `cs_i` (Input, 1)

### 6.3 `rtfSimpleUartTx`

- VERILOG module with 13 ports and 0 child instantiations.
- Representative interface signals:
  - `rst_i` (Input, 1)
  - `clk_i` (Input, 1)
  - `cyc_i` (Input, 1)
  - `stb_i` (Input, 1)
  - `ack_o` (Output, 1)
  - `we_i` (Input, 1)
  - `dat_i` (Input, 8)
  - `cs_i` (Input, 1)

## 7. Clock and Reset

- Clocks:
  - `clk_i`
- Resets:
  - `rst_i`

## 8. Constraints and Integration Notes

- Top-level interface truth source is parsed RTL, not inferred prose.
- Module diagram section is intentionally a placeholder for manual insertion.
- Validate protocol-level timing and software-visible sequencing against original source docs.
