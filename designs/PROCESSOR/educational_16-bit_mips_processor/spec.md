# mips_16_core_top Design Specification

## 1. Introduction

`mips_16_core_top` is a compact educational 16-bit processor core with a classic five-stage pipeline (`IF`, `ID`, `EX`, `MEM`, `WB`). The core implements a small MIPS-like instruction subset, an 8-entry general-purpose register file, internal instruction/data memories, and a hazard-detection mechanism for read-after-write dependencies.

The design target is architectural clarity and verification-friendly behavior, including explicit pipeline stall handling and branch control without operand forwarding.

## 2. Module Diagram

Reference figure: [architecture.pdf](figures/architecture.pdf)

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock for all pipeline stages and storage elements. |
| `rst` | Input | 1 | Active-high reset input. |
| `pc` | Output | `PC_WIDTH` (default 8) | Program counter value driven by the fetch stage. |

### 3.2 Interface Semantics

- `pc` is a registered fetch address output.
- On each rising edge of `clk`, `pc` either increments, redirects by branch offset, or holds, depending on internal fetch enable and branch decision.
- `rst` initializes processor state, including PC and pipeline/register-file state.
- Instruction and data memory interfaces are internal to this top-level module; no external instruction/data bus is exposed at `mips_16_core_top`.

### 3.3 Architectural Constants (Compile-Time Definitions)

| Definition | Default | Meaning |
| --- | --- | --- |
| `PC_WIDTH` | 8 | Width of program counter and instruction address space index. |
| `INSTR_MEM_ADDR_WIDTH` | 8 | Instruction memory address width (indexing by low bits of `pc`). |
| `DATA_MEM_ADDR_WIDTH` | 8 | Data memory address width (indexing by low address bits). |

## 4. Function Description

### 4.1 Execution Model

- Data path width is 16 bits.
- The pipeline is organized as `IF -> ID -> EX -> MEM -> WB`.
- The register file has 8 general-purpose registers (`3-bit` register index).
- Register `R0` is architecturally constant zero for read operations.
- No forwarding path is implemented; RAW hazards are resolved by stalling.

### 4.2 Supported Instruction Set

The core supports the following 13 operations:

- `NOP`
- `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SL`, `SR`, `SRU`
- `ADDI`
- `LD`, `ST`
- `BZ`

Instruction fields are interpreted as opcode, destination/condition field, source register fields, and a 6-bit immediate/offset field. For immediate-based operations, the 6-bit immediate is sign-extended to 16 bits.

### 4.3 Fetch and Program Counter Behavior

The IF stage reads instruction memory using the current `pc`.

On rising `clk`:
- If `rst` is asserted, `pc` resets to zero.
- Else if fetch is enabled (`pipeline_stall_n = 1`), the next PC is selected as:
  - branch target when `branch_taken = 1`
  - sequential `pc + 1` when `branch_taken = 0`
- Else (`pipeline_stall_n = 0`), `pc` holds its value.

For a taken branch, the target is formed by adding the sign-extended 6-bit branch offset to the current PC update point. The control flow model includes one branch delay slot.

### 4.4 Decode, Operand Read, and Branch Decision

The ID stage:
- latches the fetched instruction when decode is enabled,
- decodes ALU command and writeback/memory control,
- reads two operands from the register file,
- generates branch offset and branch-taken decision,
- packages control/data fields for EX stage.

Branch operation:
- `BZ` uses a condition selector in the destination/condition field.
- Implemented branch condition code is zero-test (`BRANCH_Z`).
- `branch_taken` is asserted when the selected source operand equals zero.

Store operation:
- store data source comes from the register indicated by the instruction destination field (`rd` used as source for `ST`).

### 4.5 Execute, Memory Access, and Writeback

EX stage:
- executes ALU operation selected by decode (`ADD`, `SUB`, logic ops, shifts, etc.),
- forwards ALU result and control signals to MEM stage.

MEM stage:
- uses ALU result as data memory access address,
- performs synchronous writes when store enable is asserted,
- reads memory data and forwards both ALU result and memory read data toward WB.

WB stage:
- selects writeback source by instruction class:
  - ALU result for arithmetic/logic/immediate operations,
  - memory read data for `LD`.
- outputs register write enable, destination register, and write data.

### 4.6 Hazard Detection and Stall Behavior

The hazard detection unit compares decode-stage source registers against destination register identifiers of in-flight instructions in EX, MEM, and WB tracking paths.

- When a nonzero source register matches any tracked destination register, `pipeline_stall_n` is deasserted (active-low stall).
- Stall action freezes IF and ID stage advancement.
- During decode freeze, ID stage drives a bubble (`NOP`-equivalent control) into downstream pipeline control fields to prevent unsafe execution.

### 4.7 Reset and Startup Behavior

With `rst` asserted:
- `pc` is cleared,
- instruction register and pipeline registers are cleared,
- register file entries are initialized,
- subsequent execution restarts from instruction address zero after reset release.

## 5. Implementation Details

### 5.1 Top-Level Composition

`mips_16_core_top` instantiates:
- `IF_stage`
- `ID_stage`
- `EX_stage`
- `MEM_stage`
- `WB_stage`
- `register_file`
- `hazard_detection_unit`

Instruction memory is instantiated inside `IF_stage`. Data memory is instantiated inside `MEM_stage`.

### 5.2 Pipeline Register Payload Organization

The pipeline interfaces carry structured control and data fields:

| Path | Width | Content Summary |
| --- | --- | --- |
| `ID -> EX` | 57 | ALU command, two ALU operands, memory write control/data, writeback control (enable, destination, source select). |
| `EX -> MEM` | 38 | ALU result plus memory/writeback control payload. |
| `MEM -> WB` | 37 | ALU result, memory read data, and writeback control payload. |

This field-level partition is stable and is the basis for stage-to-stage control/data alignment.

### 5.3 Control/Data Coupling

- Decode control determines ALU mode, immediate/register operand selection, memory write enable, and writeback source select.
- EX computes effective addresses for `LD`/`ST` using base register plus sign-extended offset.
- MEM returns both pass-through ALU results and memory-read data for final WB selection.
- Hazard control (`pipeline_stall_n`) directly gates IF/ID progression and bubble behavior.

### 5.4 Internal Memory Models

- Instruction memory and data memory are local modules in this integration.
- Addressing into memory arrays uses low-order address bits according to configured address-width macros.
- Data memory writes are clocked; read data is provided from the addressed location for WB capture.

## 6. Submodule List

### 6.1 `IF_stage`

Role: Program-counter update and instruction fetch.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `clk`, `rst` | In | 1 | Clock and active-high reset. |
| `instruction_fetch_en` | In | 1 | Fetch advance enable from hazard logic. |
| `branch_offset_imm` | In | 6 | Signed branch offset from ID stage. |
| `branch_taken` | In | 1 | Branch decision from ID stage. |
| `pc` | Out | `PC_WIDTH` | Current fetch address register. |
| `instruction` | Out | 16 | Instruction word read from instruction memory. |

### 6.2 `ID_stage`

Role: Instruction latch/decode, register read, branch decision, and ID/EX packaging.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `instruction_decode_en` | In | 1 | Decode advance enable from hazard logic. |
| `instruction` | In | 16 | Fetched instruction from IF stage. |
| `pipeline_reg_out` | Out | 57 | Packed control/data payload to EX stage. |
| `branch_offset_imm`, `branch_taken` | Out | 6,1 | Branch control feedback to IF stage. |
| `reg_read_addr_1/2` | Out | 3/3 | Register file read addresses. |
| `reg_read_data_1/2` | In | 16/16 | Register file read data. |
| `decoding_op_src1/2` | Out | 3/3 | Source register identifiers for hazard detection. |

### 6.3 `EX_stage`

Role: ALU execution and EX/MEM register generation.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `pipeline_reg_in` | In | 57 | Decoded operands and control from ID stage. |
| `pipeline_reg_out` | Out | 38 | ALU result plus forwarded control to MEM stage. |
| `ex_op_dest` | Out | 3 | Destination register identifier for hazard tracking. |

### 6.4 `MEM_stage`

Role: Data-memory access and MEM/WB register generation.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `pipeline_reg_in` | In | 38 | EX-stage result and memory/writeback controls. |
| `pipeline_reg_out` | Out | 37 | ALU result + memory read data + WB controls. |
| `mem_op_dest` | Out | 3 | Destination register identifier for hazard tracking. |

### 6.5 `WB_stage`

Role: Final result selection and register-file write interface.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `pipeline_reg_in` | In | 37 | MEM-stage payload. |
| `reg_write_en` | Out | 1 | Register write enable. |
| `reg_write_dest` | Out | 3 | Register write destination. |
| `reg_write_data` | Out | 16 | Register write data (ALU or load result). |
| `wb_op_dest` | Out | 3 | Destination register identifier for hazard tracking. |

### 6.6 `register_file`

Role: 8x16 register storage with one write port and two read ports.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `reg_write_en` | In | 1 | Write enable. |
| `reg_write_dest` | In | 3 | Write destination register index. |
| `reg_write_data` | In | 16 | Write data. |
| `reg_read_addr_1/2` | In | 3/3 | Read register indexes. |
| `reg_read_data_1/2` | Out | 16/16 | Read data outputs (`R0` reads as zero). |

### 6.7 `hazard_detection_unit`

Role: RAW-hazard detection and IF/ID stall control.

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `decoding_op_src1/2` | In | 3/3 | Source registers for instruction in ID stage. |
| `ex_op_dest`, `mem_op_dest`, `wb_op_dest` | In | 3/3/3 | In-flight destination identifiers. |
| `pipeline_stall_n` | Out | 1 | Active-low stall enable for IF/ID progression. |

## 7. Clock and Reset

- Single clock domain driven by `clk`.
- Reset input `rst` is active high.
- Reset clears architectural and pipeline state needed for deterministic restart from `pc = 0`.

## 8. Constraints

- Immediate/offset field width is 6 bits; immediate-based operations use sign extension from this field.
- Branch condition support is limited to zero-condition branch (`BZ` with zero-test selector).
- Hazard resolution is stall-based; no bypass/forwarding path is provided.
- Register index `0` is reserved as architectural zero on reads.
- Internal memory indexing uses low-order address bits defined by `INSTR_MEM_ADDR_WIDTH` and `DATA_MEM_ADDR_WIDTH`; address aliasing follows those configured widths.
- This top module does not expose external instruction/data bus protocols; system-level external memory integration requires replacing or adapting internal memory stage modules.
