# s1_top Design Specification

## 1. Introduction

`s1_top` is the top-level integration of the Simply RISC S1 core. The design combines a single OpenSPARC T1 SPARC core instance with three wrapper blocks: a SPARC-to-Wishbone master bridge, a reset controller, and an interrupt controller.

The module exposes a Wishbone master interface to external memory/peripheral interconnect and a 64-bit external interrupt request vector. The CPU execution model is SPARC v9 64-bit, with memory and I/O transactions translated from the SPARC PCX/CPX packet interface to Wishbone signaling.

## 2. Module Diagram

## 3. Top-Level Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `sys_clock_i` | Input | 1 | System clock for the S1 wrapper logic and top-level control path. |
| `sys_reset_i` | Input | 1 | Active-high system reset request. Drives reset sequencing through `rst_ctrl`. |
| `sys_irq_i` | Input | 64 | External interrupt request vector. Encoded by `int_ctrl` and forwarded through the bridge interrupt path. |
| `wbm_ack_i` | Input | 1 | Wishbone acknowledge from interconnect/target; completes the active bus phase. |
| `wbm_data_i` | Input | `[`WB_DATA_WIDTH-1:0]` | Wishbone read data returned on acknowledged read transfers. |
| `wbm_cycle_o` | Output | 1 | Wishbone cycle qualifier from bridge. Asserted during active bus ownership. |
| `wbm_strobe_o` | Output | 1 | Wishbone strobe indicating an active transfer request. |
| `wbm_we_o` | Output | 1 | Wishbone write-enable (`1` write, `0` read). |
| `wbm_addr_o` | Output | `[`WB_ADDR_WIDTH-1:0]` | Wishbone byte address (64-bit width in this design configuration). |
| `wbm_data_o` | Output | `[`WB_DATA_WIDTH-1:0]` | Wishbone write data payload. |
| `wbm_sel_o` | Output | `[`WB_DATA_WIDTH/8-1:0]` | Wishbone byte-lane select. Encodes subword access granularity and lane position. |

### 3.1 Interface Semantics

- The Wishbone interface is a master interface aligned with Wishbone B.3 style signaling and supports single read/write transaction phases.
- `wbm_ack_i` is the completion indication used by the bridge FSM to retire a transfer phase.
- `wbm_err_i` and `wbm_rty_i` are not present; error/retry signaling is not supported at this top-level interface.
- Address/data buses are 64-bit wide. Access sizes of 8, 16, 32, and 64 bits are represented through `wbm_sel_o`; larger SPARC-side fetch/load transfers are decomposed into multiple 64-bit Wishbone reads by the bridge.
- Wishbone request outputs are driven from bridge state and are clocked/registered behavior at `sys_clock_i`.

## 4. Functional Description

### 4.1 Architectural Function

The S1 core provides a single SPARC execution core with external memory/peripheral access through Wishbone. Top-level operation consists of:

1. Reset sequencing to release the SPARC core and wrapper logic in staged order.
2. Request capture from the SPARC PCX side.
3. Translation of request type, address, size, and data into Wishbone transfer(s).
4. Collection of Wishbone response data.
5. Generation of CPX return packets toward the SPARC core.
6. Injection of encoded interrupt notifications through the CPX return path.

### 4.2 Address Model and S1 Region Mapping

The S1 external address model is 64-bit:

- Bits `[63:59]`: one-hot target region encoding.
- Bits `[58:40]`: zero-filled in bridge-generated Wishbone addresses.
- Bits `[39:0]`: physical address payload from SPARC-side request packet fields.

For S1 integration, the region for physical address byte `[39:32]` is:

| Address `[39:32]` | Region |
| --- | --- |
| `0x00`-`0x7F` | RAM |
| `0x80`-`0x95` | Reserved |
| `0x96` | Real Time Clock |
| `0x97` | RAM Controller |
| `0x98` | Wishbone Interconnect Arbiter |
| `0x99` | DMA Controller |
| `0x9A`-`0x9D` | Reserved |
| `0x9E` | General Purpose I/O |
| `0x9F` | Interrupt Controller |
| `0xA0`-`0xFE` | Reserved |
| `0xFF` | Boot ROM |

The bridge issues 64-bit aligned Wishbone addresses (`[2:0] = 0`), and subword targeting is encoded on `wbm_sel_o`.
For example, an interrupt-controller access in the I/O bridge region is addressed from base `0x8000_009F_0000_0000`.

### 4.3 SPARC Request to Wishbone Transaction Flow

At runtime, the bridge serializes SPARC-originated PCX requests into Wishbone operations:

1. In idle state, the bridge waits for a nonzero SPARC request vector.
2. On request detect, it stalls further SPARC requests, latches target-region and atomic attributes, then latches the outgoing packet contents.
3. It decodes request class and size, drives `wbm_cycle_o/strobe_o`, forms `wbm_addr_o`, sets `wbm_we_o`, and computes `wbm_sel_o`.
4. It waits for `wbm_ack_i`; on acknowledge it captures read data (for read classes), clears/stages bus controls, and prepares a CPX return packet.
5. It asserts SPARC return-ready/packet signals and resumes SPARC request acceptance.

Primary translated request classes are instruction-miss read, data load, and data store. Return packet type is selected accordingly (instruction-fill return, load return, or store acknowledge).

### 4.4 Multi-Access and Width Handling

The bridge decomposes wider SPARC-side read needs into multiple 64-bit Wishbone reads:

- Standard load/store size handling uses `wbm_sel_o` for byte/halfword/word/doubleword granularity.
- 16-byte load requests require multiple 64-bit read phases before final packet completion.
- RAM-targeted instruction-miss handling performs additional read phases to assemble the required instruction-fill payload.
- During multi-phase operations, the bridge maintains internal sequencing and emits CPX return packet(s) when assembled data is ready.

### 4.5 Interrupt Handling Path

`sys_irq_i[63:0]` is priority-encoded by `int_ctrl` into a 6-bit source ID (highest active bit wins, IRQ 63 highest priority). IRQ 0 is reserved in the architecture; effective external peripheral sources are IRQ 1 through IRQ 63.

The encoded source is provided to the bridge, which uses CPX interrupt-return packet formatting for SPARC-side interrupt notification.

### 4.6 SPARC Core Context (Concise)

The integrated `sparc` instance is an OpenSPARC T1-derived single core implementing SPARC v9 64-bit execution semantics. At wrapper level, the relevant architectural roles are:

- IFU: instruction fetch and miss generation.
- EXU: integer execution and control-flow operations.
- LSU: load/store request generation toward memory system.
- TLU: trap/interrupt and thread-level control interaction.

This specification focuses on top-level wrapper and bus/packet integration semantics, not full SPARC internal microarchitecture specification.

## 5. Implementation Details

### 5.1 Top-Level Block Roles

- `sparc`: produces PCX requests and consumes CPX return packets.
- `spc2wbm`: central control/datapath adapter between SPARC packet protocol and Wishbone master protocol.
- `rst_ctrl`: staged reset/clock-enable generation for SPARC bring-up and wrapper reset release.
- `int_ctrl`: synchronous priority encoder from 64 interrupt request lines to 6-bit source code.

### 5.2 Bridge Control and Datapath Organization

`spc2wbm` contains:

- Latched request context (target region, atomic attribute, packet fields).
- Packet decode logic for request type/size/address/data extraction.
- Wishbone command generation logic (`cycle/strobe/we/addr/data/sel`).
- CPX return-packet assembly registers (type, thread, non-cacheable flag, atomic indication, returned data).
- A sequenced FSM (wake-up, idle, request latch/decode, request grant, optional extra access phases, packet return).

The bridge enforces one active request flow at a time via stall/resume signaling to the SPARC side.

### 5.3 Reset Sequencing Behavior

`rst_ctrl` uses a cycle counter to release internal controls in phases. The sequence is staged over programmable thresholds (`RESET_CYCLES_1` through `RESET_CYCLES_4`), then deasserts `sys_reset_final_o` to release downstream wrapper blocks.

Key behaviors:

- On `sys_reset_i=1`, internal enables/resets are driven to boot-hold values and `sys_reset_final_o` is asserted.
- As the counter advances, SPARC-facing control/reset/debug-init signals transition in phases.
- `gclk_o` is generated as a gated version of `sys_clock_i` after the configured cycle threshold (`GCLK_CYCLES`).

### 5.4 Interrupt Encoder Behavior

`int_ctrl` updates on `sys_clock_i` and emits the encoded highest-priority asserted interrupt index on each cycle. If no eligible interrupt request is active, output is `0`.

## 6. Submodules

### 6.1 `sparc`

Functional role: SPARC v9 CPU core instance providing instruction execution and memory request generation via PCX/CPX packet interfaces.

Top-level relevant interface groups:

| Signal Group | Direction (relative to `s1_top`) | Description |
| --- | --- | --- |
| `spc_pcx_req_pq`, `spc_pcx_atom_pq`, `spc_pcx_data_pa` | Internal from `sparc` to `spc2wbm` | Outgoing SPARC request qualifiers and packet payload. |
| `pcx_spc_grant_px`, `cpx_spc_data_rdy_cx2`, `cpx_spc_data_cx2`, `wbm_spc_stall`, `wbm_spc_resume` | Internal from `spc2wbm` to `sparc` | Request grant, return packet readiness/data, and flow-control handshake. |
| `cluster_cken`, `gclk`, `cmp_grst_l`, `cmp_arst_l`, `ctu_tst_pre_grst_l`, `adbginit_l`, `gdbginit_l` | Internal from `rst_ctrl` to `sparc` | Bring-up/reset and clock-enable controls for SPARC operation. |

### 6.2 `spc2wbm`

Functional role: protocol and datapath bridge from SPARC PCX/CPX packet signaling to Wishbone master signaling.

| Port | Dir. | Width | Description |
| --- | --- | --- | --- |
| `sys_clock_i` | In | 1 | Bridge clock. |
| `sys_reset_i` | In | 1 | Bridge reset (`sys_reset_final` from reset controller). |
| `sys_interrupt_source_i` | In | 6 | Encoded interrupt source from interrupt controller. |
| `spc_req_i` | In | 5 | SPARC request region vector. |
| `spc_atom_i` | In | 1 | SPARC atomic attribute. |
| `spc_packetout_i` | In | `[`PCX_WIDTH-1:0]` | Outgoing PCX packet from SPARC. |
| `spc_grant_o` | Out | 5 | Grant back to SPARC for request acceptance. |
| `spc_ready_o` | Out | 1 | CPX return packet valid qualifier. |
| `spc_packetin_o` | Out | `[`CPX_WIDTH-1:0]` | CPX return packet to SPARC. |
| `spc_stall_o` | Out | 1 | Stall SPARC request issue while bridge is busy. |
| `spc_resume_o` | Out | 1 | Resume SPARC request issue after packet return. |
| `wbm_ack_i` | In | 1 | Wishbone acknowledge. |
| `wbm_data_i` | In | `[`WB_DATA_WIDTH-1:0]` | Wishbone read data. |
| `wbm_cycle_o` | Out | 1 | Wishbone cycle. |
| `wbm_strobe_o` | Out | 1 | Wishbone strobe. |
| `wbm_we_o` | Out | 1 | Wishbone write enable. |
| `wbm_addr_o` | Out | `[`WB_ADDR_WIDTH-1:0]` | Wishbone address. |
| `wbm_data_o` | Out | `[`WB_DATA_WIDTH-1:0]` | Wishbone write data. |
| `wbm_sel_o` | Out | `[`WB_DATA_WIDTH/8-1:0]` | Wishbone byte select. |

### 6.3 `rst_ctrl`

Functional role: staged reset/clock bring-up controller for SPARC-side internal controls and wrapper reset-release signal.

| Port | Dir. | Width | Description |
| --- | --- | --- | --- |
| `sys_clock_i` | In | 1 | Reset-sequencer clock. |
| `sys_reset_i` | In | 1 | Active-high reset request for sequencer restart. |
| `cluster_cken_o` | Out | 1 | Cluster clock-enable control to SPARC. |
| `gclk_o` | Out | 1 | Gated clock output used by SPARC wrapper path. |
| `cmp_grst_o`, `cmp_arst_o`, `ctu_tst_pre_grst_o` | Out | 1 each | Staged reset controls to SPARC. |
| `adbginit_o`, `gdbginit_o` | Out | 1 each | Debug/init-related staged controls. |
| `sys_reset_final_o` | Out | 1 | Wrapper reset output used by bridge and interrupt controller. |

### 6.4 `int_ctrl`

Functional role: synchronous priority encoder for external interrupt requests.

| Port | Dir. | Width | Description |
| --- | --- | --- | --- |
| `sys_clock_i` | In | 1 | Interrupt encoder clock. |
| `sys_reset_i` | In | 1 | Active-high reset; clears encoded source to zero. |
| `sys_irq_i` | In | 64 | External interrupt request vector. |
| `sys_interrupt_source_o` | Out | 6 | Encoded highest-priority active source index. |

## 7. Clock and Reset

- Primary clock domain: `sys_clock_i`.
- Top-level reset input: `sys_reset_i` (active high).
- Wrapper reset sequencing is generated by `rst_ctrl`; `sys_reset_final_o` remains asserted during bring-up and is deasserted after staged release.
- `spc2wbm` and `int_ctrl` consume `sys_reset_final_o` as their reset input.
- Reset and control sequencing behavior is synchronous to `sys_clock_i`.

## 8. Constraints and Integration Notes

- Wishbone completion depends on `wbm_ack_i`; no built-in timeout is provided in `s1_top`.
- Wishbone error/retry channels are not implemented at this interface level.
- Data ordering is big-endian; subword selection is controlled by `wbm_sel_o`.
- Addresses presented on Wishbone are 64-bit aligned; subword semantics are lane-qualified via `wbm_sel_o`.
- The interrupt path is intentionally basic and should be validated in system integration when enabling external interrupt-driven software flows.
