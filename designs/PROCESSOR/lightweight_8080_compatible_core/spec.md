# light8080 Design Specification

## 1. Introduction

`light8080` is a lightweight Intel 8080 binary-compatible CPU core implemented as a microcoded two-stage machine. The core provides an 8-bit data path, a synchronous memory/I/O interface, and interrupt, halt, and interrupt-enable status outputs suitable for SoC integration.

The architecture is organized around:
- a microcode sequencer,
- an operand stage that loads ALU operand registers,
- an ALU stage that writes results and updates flags,
- a register bank that holds programmer-visible and internal working registers.

The design is multicycle by construction and prioritizes compact control over single-cycle instruction execution.

## 2. Module Diagram

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock. All external interface signals are synchronous to this clock. |
| `reset` | Input | 1 | Active-high synchronous reset. |
| `addr_out` | Output | 16 | External address bus for memory or I/O access. |
| `vma` | Output | 1 | Valid memory/I/O access indicator (master cycle enable). |
| `io` | Output | 1 | Access type qualifier: `1` for I/O access, `0` for memory access. |
| `rd` | Output | 1 | Read-cycle qualifier when `vma` is asserted. |
| `wr` | Output | 1 | Write-cycle qualifier when `vma` is asserted. |
| `fetch` | Output | 1 | Opcode fetch-cycle indication. |
| `data_in` | Input | 8 | Read data from external memory/I/O. |
| `data_out` | Output | 8 | Write data to external memory/I/O. |
| `inta` | Output | 1 | Interrupt acknowledge status. |
| `inte` | Output | 1 | Interrupt-enable status (`1` means interrupts enabled). |
| `halt` | Output | 1 | Halt status (`1` while CPU is in halt loop). |
| `intr` | Input | 1 | External interrupt request input. |

### 3.2 Interface Semantics

- `vma` is the master transaction-valid signal for external accesses.
- `io`, `rd`, and `wr` are only meaningful when `vma=1`.
- `addr_out` and `data_out` are valid during active external access cycles.
- `data_in` is sampled synchronously during the read completion phase defined by the microcode-controlled access sequence.
- The high byte of `addr_out` is driven from register-bank data; low byte is driven by an internal low-address latch.

### 3.3 Reset and Visibility

- `reset` is sampled on a rising edge of `clk`.
- After reset release, the first opcode fetch at address `0x0000` occurs after the internal startup microcode sequence.
- `inte`, `inta`, and `halt` are direct architectural status indicators for system integration and verification.

## 4. Function Description

### 4.1 Microcoded Two-Stage Operation

Each microinstruction spans two consecutive cycles:
1. Operand stage: loads `T1`/`T2` from register bank or `data_in`.
2. ALU stage: computes result, writes destination (register bank or output register), and conditionally updates flags.

Microinstructions overlap in a two-stage pipeline. Control bits for the ALU stage are pipelined internally to guarantee that once a microinstruction starts, its second stage completes unless reset intervenes.

### 4.2 Microcode Sequencing and Decode Flow

The microcode engine uses a 9-bit microcode address source with these flow paths:
- sequential increment,
- micro-subroutine jump (`JSR`/conditional jump),
- one-level return address,
- opcode decode path using fetched opcode value,
- fixed entry points for reset/fetch/halt routines.

Instruction decode is table-driven. Fetched opcode data is used to dispatch into a decode jump table region that redirects execution to the corresponding instruction micro-routine.

### 4.3 Register and Flag Model

Internal storage includes:
- register bank with 8080 programmer-visible state and internal temporary registers,
- dedicated ALU operand registers `T1` and `T2`,
- output data register used to drive `data_out`,
- dedicated PSW/flag register with controlled flag update patterns.

Flag update behavior is microinstruction-controlled, including separate control over carry and non-carry flag groups. ALU operations include arithmetic, logic, rotate/shift, and BCD-adjust support.

### 4.4 External Memory/I/O Access Behavior

External access is synchronous and microcode-controlled:
- `vma` indicates an active cycle,
- `io` selects I/O versus memory,
- `rd` or `wr` qualify read/write direction,
- byte data transfers occur on `data_in`/`data_out`.

The core currently executes external accesses without programmable wait-state insertion; each access follows the fixed microcoded cycle sequence.

### 4.5 Fetch, PC Update, and INTA Behavior

Normal fetch flow places PC on `addr_out`, performs a read, and advances PC through microcoded register updates.

During interrupt acknowledge execution (`inta=1`):
- a fetch-like sequence occurs for vector opcode retrieval,
- PC auto-increment is inhibited for the interrupt-acknowledge instruction flow,
- explicit control-flow instructions can still modify PC.

### 4.6 Interrupt, INTE, and Halt Behavior

Interrupt handling is instruction-boundary based:
- interrupt requests are sampled synchronously,
- service entry occurs at instruction end when interrupt service conditions are met,
- `inta` remains asserted for the duration of the acknowledged interrupt instruction flow,
- interrupts are disabled on interrupt service entry and remain disabled until re-enabled by instruction flow.

Halt behavior:
- `halt` is asserted when the halt microcode loop is entered,
- exit from halt occurs on reset or interrupt service conditions.

### 4.7 Compatibility Notes

The core is intended for 8080 binary compatibility with multicycle execution timing.

Known behavioral compatibility note:
- auxiliary-carry behavior for logical AND-class operations follows the implemented core rules (consistent with 8085-style AC handling), which can differ from strict original 8080 AC semantics for ANI/ANA-class behavior.

## 5. Implementation Details

### 5.1 Control Path Structure

The control path is microcode-ROM driven and centered on a microcode-address sequencer. It supports:
- one-level micro-subroutine calls and returns,
- conditional micro-branches for condition-code based instruction classes,
- dedicated restart points for reset/fetch/halt flows,
- decode-table dispatch for opcode-to-routine mapping.

### 5.2 Datapath Structure

Datapath elements include:
- asynchronous-read/synchronous-write register bank,
- operand latches `T1`/`T2`,
- ALU result path and output register `DO`,
- low-address register combined with register-bank high byte for `addr_out`,
- flag register with patterned update control and auxiliary-carry support.

### 5.3 ALU and Flag Update Organization

ALU function classes include:
- arithmetic operations with carry-in/carry-out handling,
- logic operations,
- rotate/shift operations,
- dedicated decimal-adjust (DAA) path.

Flag generation is not monolithic; microinstruction flag-pattern fields select which flag groups are updated on each operation.

### 5.4 Interrupt and PC Control Coupling

Interrupt servicing is coupled to instruction-end control, not asynchronous preemption mid-microinstruction. INTA state and PC increment inhibition are coordinated in microcode and writeback gating to preserve interrupt-vector instruction semantics.

## 6. Submodule List

### 6.1 `micro_rom`

Role: stores and outputs 32-bit microinstructions addressed by the 9-bit microcode sequencer.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clock` | Input | 1 | Clock for registered microinstruction output. |
| `uc_addr` | Input | 9 | Microcode address. |
| `uc_dout` | Output | 32 | Registered microinstruction word. |

Usage in top-level core:
- `light8080` computes `next_uc_addr`,
- `micro_rom` returns the corresponding microinstruction,
- control fields are decoded and partially pipelined for operand/ALU stage execution.

## 7. Clock and Reset

- Single clock domain: `clk`.
- `reset` is synchronous and initializes microcode control state, visible status outputs, flags, and address-related state.
- Reset startup includes internal microcode sequencing before normal fetch flow resumes.

## 8. Constraints

- External memory/I/O logic must be synchronous to `clk` and meet timing for `vma`-qualified transfers.
- `data_in` must be valid for sampling in the read phase of the microcoded transfer sequence.
- The current core does not provide wait-state insertion; integration with slower memory requires external adaptation or design modification.
- `io`, `rd`, and `wr` should be interpreted only when `vma=1`.
- For interrupt integration, treat `inta` as a multi-cycle status covering the interrupt-acknowledge instruction flow.
- Interrupt request persistence while interrupts are disabled should be treated as integration-sensitive and confirmed in the target build before relying on queued masked-interrupt behavior.
