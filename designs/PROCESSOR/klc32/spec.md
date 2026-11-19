# KLC32 Design Specification

## 1. Introduction

`KLC32` is a 32-bit multicycle processor core with a Wishbone-compatible master interface and a 68000-style interrupt/vector model. The core is optimized for high clock-rate operation with multi-cycle instruction execution, rather than minimum cycles-per-instruction.

The design integrates:
- a finite-state control engine for fetch, decode/operand read, execute, memory, and writeback phases,
- a 32-entry general-purpose register file,
- condition-code and status state for conditional flow and privilege control,
- trap/interrupt entry and return sequencing,
- bus-master request generation for instruction, data, stack, and vector accesses.

## 2. Module Diagram

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `RST` | Input | 1 | Active-high external reset. |
| `clk_i` | Input | 1 | External reference clock. |
| `ipl_i` | Input | 3 | Interrupt priority level input. |
| `vpa_i` | Input | 1 | Vector pull acknowledge input used for autovector interrupt acknowledge completion. |
| `halt_i` | Input | 1 | Halt request; prevents new instruction issue while asserted. |
| `inta_o` | Output | 1 | Interrupt acknowledge cycle indicator. |
| `fc_o` | Output | 3 | Bus function code indicating cycle type and privilege context. |
| `rst_o` | Output | 1 | Processor-generated reset output pulse sequence. |
| `cyc_o` | Output | 1 | Bus cycle valid. |
| `stb_o` | Output | 1 | Bus strobe (request valid). |
| `ack_i` | Input | 1 | Bus acknowledge input; completes active bus transfer. |
| `err_i` | Input | 1 | Bus error input; aborts active transfer and invokes bus-error trap flow. |
| `sel_o` | Output | 4 | Byte-lane strobes for transfers. |
| `we_o` | Output | 1 | Write enable (`1`=write, `0`=read). |
| `adr_o` | Output | 32 | Address bus output. |
| `dat_i` | Input | 32 | Read-data bus input. |
| `dat_o` | Output | 32 | Write-data bus output. |

### 3.2 Bus and Control Semantics

- `cyc_o` and `stb_o` assert a bus request; transfer completion is indicated by `ack_i`.
- `err_i` terminates an active cycle and transfers control to the bus-error trap sequence.
- `we_o`, `sel_o`, `adr_o`, and `dat_o` are valid during write cycles.
- `sel_o` encodes byte-lane usage for byte/halfword/word operations.

### 3.3 Function-Code Conventions

`fc_o` indicates transfer intent. The control logic uses:
- `{sf,2'b10}` for instruction fetch cycles,
- `{sf,2'b01}` for normal data/stack cycles,
- `3'b111` for interrupt-acknowledge cycles,
- `3'b101` for supervisor exception/vector-stack related cycles.

`sf` is the supervisor-mode flag in processor status state.

## 4. Function Description

### 4.1 Execution Model and Architectural State

`KLC32` is a multi-cycle, state-machine-controlled processor. Instruction processing is sequenced through states such as instruction fetch, register fetch, execute, memory access, and writeback.

Key architectural state includes:
- 32 general-purpose 32-bit registers,
- eight 4-bit condition-code registers (`CR0`..`CR7`),
- status fields (`sf` supervisor mode, `tf` trace enable, `im` interrupt mask level),
- user and supervisor stack pointers (`usp`, `ssp`),
- a free-running 32-bit tick counter.

Register semantics:
- register `R0` reads as zero,
- register `R31` aliases the active stack pointer (`ssp` when `sf=1`, else `usp`).

### 4.2 Reset and Initial Vector Fetch

On external reset assertion:
- control state enters reset sequencing,
- supervisor mode is selected,
- trace is disabled,
- interrupt mask is set to the highest level.

Startup vector flow:
1. load initial stack pointer from address `0x00000000`,
2. load initial program counter from address `0x00000004`,
3. enter normal instruction fetch.

`rst_o` is generated from an internal shift register and remains asserted for a finite multi-cycle pulse window after reset sequencing is initiated.

### 4.3 Instruction Fetch and Operand Acquisition

Instruction fetch:
- bus read is issued at `pc`,
- on acknowledge, instruction register (`ir`) is loaded,
- `pc` advances by 4 bytes for the next sequential instruction.

Operand/register fetch:
- control states fetch up to three register operands over multiple cycles,
- immediate values are sign- or zero-extended by opcode class,
- an extended immediate path fetches an additional 32-bit immediate word when required.

This multi-cycle operand acquisition supports a single-ported internal register-file access style while preserving functional correctness.

### 4.4 ALU, Condition, and Compare Behavior

Arithmetic/logic classes include add/subtract/compare, bitwise logic, shifts/rotates, min/max, BCD add/subtract, multiply/divide/modulo variants, and immediate forms.

Condition handling:
- compare instructions target a selected condition register,
- many register-register operations optionally update `CR0` when the instruction Rc bit is set,
- immediate arithmetic/logic and load-like result paths update condition flags according to instruction class.

Status flags (`N/Z/V/C`) are derived from result and operation type, including dedicated carry/overflow support logic and divide-by-zero indication in divide/modulo paths.

### 4.5 Memory Access Behavior

Effective address generation supports:
- register + displacement addressing,
- indexed register + register addressing.

Load/store support:
- byte, halfword, and word accesses,
- sign-extended and zero-extended load variants,
- byte-lane-qualified writes through `sel_o`.

Atomic test-and-set (`TAS`) behavior:
- read target word,
- if lock bit is clear, perform writeback setting the lock bit,
- return previous word value for condition/result handling.

### 4.6 Flow Control, Stack, and Procedure Support

Control-flow operations include:
- conditional branches over condition-register predicates,
- absolute and register-indirect jumps,
- subroutine calls (`JSR`) with return-address stack push,
- subroutine return (`RTS`) with optional stack adjustment,
- stack frame creation/removal (`LINK`/`UNLK`),
- register list push/pop and effective-address push.

Stack operations are mode-sensitive and use `ssp` or `usp` according to `sf`.

### 4.7 Trap and Interrupt Processing

Interrupt entry conditions are checked before issuing a new fetch cycle:
- non-maskable edge event path via interrupt level 7 edge detection,
- maskable interrupt when `ipl_i > im`.

Interrupt acknowledge flow:
- assert `inta_o` and issue acknowledge cycle,
- select vector number from either external acknowledge data or autovector completion (`vpa_i`),
- fetch vector entry and enter trap stack-save sequence.

Trap entry sequence saves context on supervisor stack in ordered words:
1. program counter,
2. condition-register aggregate,
3. saved status.

Return-from-interrupt (`RTI`) restores status, condition registers, and program counter from stack, then resumes instruction fetch.

### 4.8 Clock-Enable and Halt/Stop Behavior

The processor core clock is generated through a clock-enable buffer.

- `halt_i`: blocks new instruction processing at fetch boundaries while preserving clock operation.
- `STOP` instruction: disables internal clock enable and updates selected status fields.
- clock re-enable occurs on reset or non-maskable interrupt-level event.

## 5. Implementation Details

### 5.1 Control Organization

The processor is implemented as a finite-state machine with explicit states for:
- reset/vector bootstrap,
- fetch/decode/operand read,
- execute,
- memory access and acknowledge,
- writeback and flag write,
- subroutine and stack primitives,
- trap/interrupt entry and return,
- multiply/divide iterative sequencing.

This organization decouples bus phases from internal data-path phases and naturally supports variable-cycle instructions.

### 5.2 Datapath and Register Structures

Major internal datapath elements include:
- instruction register and program counter,
- operand/result registers (`a`, `b`, `c`, `imm`, `res`, `ea`),
- condition/status registers and tick counter,
- stack-pointer pair with mode-dependent selection,
- multiplier/divider staging registers for multi-step arithmetic.

Multiplication and division operations use dedicated iterative states; completion returns through normal writeback/flag paths.

### 5.3 Bus Integration and Exception Coupling

Bus sequencing is coupled to state transitions:
- request launch (`cyc_o/stb_o`),
- acknowledge-driven completion (`ack_i`),
- byte-lane selection by operation size/address,
- write-data formation for store and stack pushes.

Bus-error coupling:
- any active-cycle `err_i` forces cycle termination,
- faulting address is captured,
- processor enters bus-error trap vector path.

### 5.4 Privilege and System Register Behavior

Supervisor-only operations (for example interrupt mask control, return-from-interrupt, reset/stop control, selected special-register accesses) are privilege-checked.

On privilege violation:
- control redirects to the privilege-violation trap vector sequence,
- trap context save/restore flow remains consistent with other exception classes.

## 6. Submodule List

### 6.1 `BUFGCE`

Role: Generates the internal processor clock from `clk_i` under enable control, supporting stop/restart behavior.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `I` | Input | 1 | Source clock input (`clk_i`). |
| `CE` | Input | 1 | Clock-enable control from processor control logic. |
| `O` | Output | 1 | Gated core clock driving sequential processor state. |

### 6.2 `carry`

Role: Computes carry-out for add/subtract class operations used in flag generation.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `op` | Input | 1 | Operation type (`0` add, `1` subtract). |
| `a`, `b`, `s` | Input | 1 each | Operand sign bits and result sign bit. |
| `c` | Output | 1 | Derived carry/borrow-related flag result. |

### 6.3 `overflow`

Role: Computes signed overflow flag for add/subtract class operations.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `op` | Input | 1 | Operation type (`0` add, `1` subtract). |
| `a`, `b`, `s` | Input | 1 each | Operand sign bits and result sign bit. |
| `v` | Output | 1 | Signed overflow indication. |

### 6.4 `BCDAdd` / `BCDSub`

Role: 8-bit BCD add/subtract datapath helpers for BCD arithmetic instructions.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `ci` | Input | 1 | Carry/borrow input. |
| `a`, `b` | Input | 8 each | BCD operands. |
| `o` | Output | 8 | BCD result. |
| `c` | Output | 1 | Carry/borrow output. |

## 7. Clock and Reset

- Primary external clock: `clk_i`.
- Core state updates on internally gated clock derived from `clk_i`.
- External reset `RST` is active high and initializes control/status state.
- `rst_o` is a processor-generated reset indicator pulse derived from internal reset-shift sequencing.

## 8. Constraints

- The external bus target must complete cycles with `ack_i` or `err_i`; otherwise the processor remains in the active transfer state.
- `vpa_i` is meaningful during interrupt acknowledge sequencing and selects autovector completion behavior.
- Interrupt level comparison uses `ipl_i` against internal mask `im`; level 7 edge is treated as the non-maskable entry trigger.
- Program-counter control flow assumes 32-bit instruction word stepping (`pc + 4`) and vector entries aligned to word boundaries.
- Byte/halfword accesses use `sel_o` lane qualification; system integration should ensure memory/peripheral behavior matches these lane semantics.
- STOP mode halts processor internal clock progression until reset or non-maskable interrupt-level wake condition.
