# cpu Design Specification

## 1. Introduction

`cpu` is the top-level AltOR32 processor core for the alternative lightweight OpenRISC-compatible design. It provides:
- a 32-bit instruction memory interface,
- a 32-bit data memory interface,
- external interrupt and break/NMI-class event inputs,
- fault and break status outputs.

The core integrates fetch, execute, and writeback functions with configurable instruction cache, data cache, and register-file implementations.

## 2. Module Diagram

## 3. Interface

### 3.1 Configuration Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `BOOT_VECTOR` | `32'h00000000` | Base address used for reset entry vector generation. |
| `ISR_VECTOR` | `32'h00000000` | Base address used for exception/interrupt vector generation. |
| `REGISTER_FILE_TYPE` | `"SIMULATION"` | Register file implementation selection (`SIMULATION`, `XILINX`, `ALTERA`). |
| `ENABLE_ICACHE` | `"ENABLED"` | Instruction path selection (`altor32_icache` vs `altor32_noicache`). |
| `ENABLE_DCACHE` | `"DISABLED"` | Data path selection (`altor32_dcache` vs direct memory pass-through). |
| `SUPPORT_32REGS` | `"ENABLED"` | Register file depth option. |
| `PIPELINED_FETCH` | `"ENABLED"` | Fetch-stage output retiming option in `altor32_fetch`. |

### 3.2 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk_i` | Input | 1 | Core clock. |
| `rst_i` | Input | 1 | Active-high reset. |
| `intr_i` | Input | 1 | External interrupt request input. |
| `nmi_i` | Input | 1 | Break/NMI-class event input to execute-stage break path. |
| `fault_o` | Output | 1 | Fault indication output for exception-class fault events. |
| `break_o` | Output | 1 | Break/trap indication output. |
| `imem_addr_o` | Output | 32 | Instruction memory address. |
| `imem_dat_i` | Input | 32 | Instruction memory read data. |
| `imem_cti_o` | Output | 3 | Instruction bus cycle type indicator. |
| `imem_cyc_o` | Output | 1 | Instruction bus cycle valid. |
| `imem_stb_o` | Output | 1 | Instruction bus strobe/request. |
| `imem_stall_i` | Input | 1 | Instruction bus backpressure input. |
| `imem_ack_i` | Input | 1 | Instruction bus acknowledge input. |
| `dmem_addr_o` | Output | 32 | Data memory address. |
| `dmem_dat_o` | Output | 32 | Data memory write data. |
| `dmem_dat_i` | Input | 32 | Data memory read data. |
| `dmem_sel_o` | Output | 4 | Data memory byte-lane enables. |
| `dmem_cti_o` | Output | 3 | Data bus cycle type indicator. |
| `dmem_cyc_o` | Output | 1 | Data bus cycle valid. |
| `dmem_we_o` | Output | 1 | Data bus write enable. |
| `dmem_stb_o` | Output | 1 | Data bus strobe/request. |
| `dmem_stall_i` | Input | 1 | Data bus backpressure input. |
| `dmem_ack_i` | Input | 1 | Data bus acknowledge input. |

### 3.3 Interface Semantics

- `imem_*` and `dmem_*` are independent request/response channels.
- `*_stb_o` and `*_cyc_o` mark active requests; `*_ack_i` and `*_stall_i` govern completion and backpressure.
- Data stores use `dmem_sel_o` for byte-lane qualification.
- Output timing and throughput depend on cache settings and external memory response behavior.

## 4. Function Description

### 4.1 Core Execution Flow

The processor is organized as a three-stage flow:
1. Fetch (`altor32_fetch`) requests instruction words and tracks program counter progression.
2. Execute (`altor32_exec`) decodes and executes operations, resolves branches/exceptions, and issues data-memory accesses.
3. Writeback (`altor32_writeback`) commits ALU/load results to the register file.

Forwarding and hazard/stall control are used to preserve correctness when dependencies or outstanding memory operations are present.

### 4.2 Instruction Fetch and Branch Redirection

The fetch stage drives `pc_o` and `fetch_o`, accepts instruction data/valid response, and handles branch redirection from execute-stage `branch_o/branch_pc_o`.

When branch, stall, or read-valid conditions require it, fetch controls hold or redirect PC sequencing to maintain correct instruction issue ordering.

### 4.3 Execute Stage and Datapath Control

The execute stage performs:
- ALU arithmetic/logical/compare operations,
- branch/jump target resolution,
- load/store request generation,
- system-register read/write handling,
- exception and interrupt entry sequencing.

Operand forwarding resolves register dependencies using writeback and in-flight execution results where available. Pipeline stalling is asserted when operands or load results are not yet ready.

### 4.4 Load/Store Behavior

Load/store operations are generated from effective address calculations based on register and immediate operands. Byte/halfword/word transfer size and alignment handling are applied through byte-lane select and write-data packing.

Load results are sign/zero-extended according to load opcode class before writeback.

### 4.5 Writeback Behavior

Writeback selects between ALU-path and memory-load-path results. For load instructions, register write enable is qualified by memory-ready completion. Register zero write suppression is implemented by destination-register checks.

### 4.6 Cache and Non-Cache Modes

Instruction path:
- `ENABLE_ICACHE="ENABLED"`: uses `altor32_icache`.
- Otherwise: uses `altor32_noicache` direct fetch front-end.

Data path:
- `ENABLE_DCACHE="ENABLED"`: uses `altor32_dcache`.
- Otherwise: data requests are passed directly to external memory interface with cache-side handshake mapped to `dmem_*`.

Cache flush requests are driven from status-control writes and propagated to cache blocks.

### 4.7 Status and SPR Behavior

The core supports key special-purpose registers including:
- version register (`SPR_REG_VR`),
- status register (`SPR_REG_SR`),
- exception PC (`SPR_REG_EPCR`),
- exception status (`SPR_REG_ESR`).

Status bits include interrupt enable, flag/carry state, and cache flush control bits. Execute-stage control updates status fields during arithmetic, compare, exception entry, return-from-exception, and SPR write operations.

### 4.8 Reset, Exceptions, and Interrupts

On reset:
- internal control/status state is initialized,
- exception-related state is cleared,
- execution begins at reset vector offset relative to `BOOT_VECTOR`.

Exception/interrupt vectors are generated relative to `ISR_VECTOR` (except reset relative to `BOOT_VECTOR`). Supported vectors include reset, illegal instruction, external interrupt, syscall, trap, and bus/address error; vector offsets align with the design vector table definitions.

Interrupt entry captures return-state information (EPC/ESR), clears active status for handler entry, and redirects fetch to the selected vector target.

## 5. Implementation Details

### 5.1 Top-Level Composition

`cpu` instantiates and connects:
- instruction frontend (`altor32_fetch` + icache/no-icache wrapper),
- register file (one of simulation/Xilinx/Altera variants),
- execute stage (`altor32_exec`),
- writeback stage (`altor32_writeback`),
- optional data cache or direct data-memory path.

### 5.2 Pipeline Coupling and Stall Sources

Execute-stage `stall_o` feeds fetch-stage stall control. Stall conditions include unresolved forwarded operands, pending load-result dependencies, and memory-side completion dependencies.

Branch and exception events drive a common redirect path (`branch_o` / `branch_pc_o`) to fetch.

### 5.3 Data-Memory Integration

When dcache is enabled, CPU load/store requests are translated through cache control/tag/data state machines and then emitted to memory interface.

When dcache is disabled, top-level wiring directly maps execute-stage memory request/control signals to `dmem_*` outputs, with input `dmem_ack_i`/`dmem_stall_i` reflected back into execute-stage flow control.

### 5.4 Exception/Break Control Path

Execute-stage exception control updates EPC/ESR/SR, asserts redirect, and drives `fault_o` or `break_o` according to event class. Break input is latched and handled through break/trap control sequencing.

### 5.5 Register File Selection

Register file implementation is chosen by `REGISTER_FILE_TYPE` generate logic. All variants expose equivalent tri-port logical behavior (two read ports and one writeback port) to the pipeline.

## 6. Submodule List

### 6.1 `altor32_fetch`

Role: program-counter sequencing, instruction request generation, branch redirect handling, and decoded register-index extraction.

| Signal Group | Purpose |
| --- | --- |
| `pc_o/fetch_o/data_i/data_valid_i` | Instruction request and response flow. |
| `branch_i/branch_pc_i/stall_i` | Redirect and fetch hold control. |
| `opcode_o/opcode_pc_o/opcode_valid_o` | Decoded-stage instruction payload and validity. |

### 6.2 `altor32_exec`

Role: instruction decode/execute, hazard resolution, data-memory operation issuance, status/SPR updates, and exception/interrupt handling.

| Signal Group | Purpose |
| --- | --- |
| operand + opcode inputs | Execution and control decode. |
| `dmem_*` interface | Load/store command generation and response handling. |
| `branch_o/branch_pc_o/stall_o` | Pipeline control feedback to fetch. |
| `fault_o/break_o` | Exception and break reporting outputs. |

### 6.3 `altor32_writeback`

Role: register writeback arbitration between ALU and load-result paths.

| Signal Group | Purpose |
| --- | --- |
| opcode/rd/alu/mem inputs | Source selection and destination targeting. |
| `write_enable_o/write_addr_o/write_data_o` | Register file commit interface. |

### 6.4 Cache Front-End Options

| Module | Role |
| --- | --- |
| `altor32_icache` | Instruction-cache frontend with invalidate support and memory-fetch sequencing. |
| `altor32_noicache` | Instruction-fetch frontend without cached line storage. |
| `altor32_dcache` | Data cache with load/store request buffering, line-state control, and flush support. |

### 6.5 Register File Options

| Module | Role |
| --- | --- |
| `altor32_regfile_sim` | Simulation-oriented register file implementation. |
| `altor32_regfile_xil` | Xilinx-targeted register file implementation. |
| `altor32_regfile_alt` | Altera-targeted register file implementation. |

## 7. Clock and Reset

- `clk_i` is the single core clock.
- `rst_i` is an active-high reset used by fetch, execute, writeback, cache front-end, and register-file blocks.
- Reset reinitializes control state, status state, and startup PC sequencing.

## 8. Constraints

- External instruction/data memory agents must honor `stb/cyc` requests and provide coherent `ack/stall` responses.
- Word alignment is required for normal instruction fetch and word data operations; misaligned control-path conditions may enter bus/error exception handling.
- Cache-related status bits and flush controls should be software-managed in coordination with memory system behavior.
- The break/NMI input path is implementation-coupled to break/trap handling; system integration should apply pulse/level behavior consistent with the configured debug/exception model.
