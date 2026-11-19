# PWM Design Specification

## 1. Introduction

`PWM` is a 16-bit programmable pulse-width modulation and timer core with a WISHBONE slave control interface. The core can run from either the WISHBONE clock or an external clock input, apply programmable down-clocking, and generate either a PWM waveform or timer interrupt indication on `o_pwm`.

The module provides runtime-programmable control for:
- mode selection (PWM mode or timer mode),
- counter start/stop,
- one-shot or continuous timer operation,
- duty-cycle source selection (internal register or external input),
- clock source and divider selection.

## 2. Module Diagram



## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_wb_clk` | Input | 1 | WISHBONE interface clock. Also available as internal working-clock source. |
| `i_wb_rst` | Input | 1 | Active-high reset for register/control logic; also participates in main counter reset. |
| `i_wb_cyc` | Input | 1 | WISHBONE cycle qualifier for writes. |
| `i_wb_stb` | Input | 1 | WISHBONE strobe; used as transaction acknowledge source. |
| `i_wb_we` | Input | 1 | WISHBONE write enable. |
| `i_wb_adr` | Input | 16 | Register address. |
| `i_wb_data` | Input | 16 | WISHBONE write data. |
| `o_wb_data` | Output | 16 | WISHBONE read data from addressed register. |
| `o_wb_ack` | Output | 1 | WISHBONE acknowledge output (`i_wb_stb` mirrored). |
| `i_extclk` | Input | 1 | External working-clock source option. |
| `i_DC` | Input | 16 | External duty-cycle value input. |
| `i_valid_DC` | Input | 1 | Capture enable for `i_DC` into internal external-duty register. |
| `o_pwm` | Output | 1 | PWM waveform output (PWM mode) or timer interrupt indication (timer mode), gated by output-enable control bit. |

### 3.2 Register Map

| Register | Address | Width | Access | Description |
| --- | --- | --- | --- | --- |
| `Ctrl` | `0x0000` | 8 (read as low byte of 16-bit bus word) | R/W | Core operating control and timer interrupt status/clear bits. |
| `Divisor` | `0x0002` | 16 | R/W | Divider setting for working-clock down-clocking. |
| `Period` | `0x0004` | 16 | R/W | PWM period count or timer target count. |
| `DC` | `0x0006` | 16 | R/W | Internal duty-cycle register. |

Readback behavior:
- Reads from undefined addresses return `16'h0000`.
- `Ctrl` readback is `{8'h00, ctrl[7:0]}`.

### 3.3 `Ctrl` Register Definition

| Bit | Name | Access | Description |
| --- | --- | --- | --- |
| `0` | `clk_sel` | R/W | `0`: use `i_wb_clk`; `1`: use `i_extclk` as working-clock source. |
| `1` | `mode_pwm` | R/W | `1`: PWM mode; `0`: timer mode. |
| `2` | `run_en` | R/W | Main counter enable. `0` stops counting; `1` enables counting behavior according to selected mode. |
| `3` | `timer_cont` | R/W | Timer-mode run style. `0`: one-shot; `1`: continuous restart after terminal count. |
| `4` | `out_en` | R/W | Output gate for `o_pwm`. When `0`, `o_pwm` is forced low. |
| `5` | `timer_irq` | R/W (status/clear behavior) | Timer interrupt status indication. In timer mode this reflects timer event state. Writing `0` requests interrupt clear. |
| `6` | `dc_src_ext` | R/W | `0`: duty cycle from `DC` register; `1`: duty cycle from captured external `i_DC`. |
| `7` | `ctr_rst` | R/W | Main counter reset control. Assertion resets main counter path and clears timer output/event state. Deassert to resume normal operation. |

## 4. Function Description

### 4.1 Operation Overview

The core forms a programmable working clock, counts working-clock cycles, and drives `o_pwm` from mode-specific event logic:
- In PWM mode, the counter repeats over the programmed period and compares count position to duty cycle.
- In timer mode, the counter runs toward a target (`Period`) and raises a timer event when the target is reached.

`Period`, `DC`, `Divisor`, and `Ctrl` are software-programmable through WISHBONE writes.

### 4.2 Clock Selection and Down-Clocking

The working-clock source is selected by `Ctrl[0]`:
- `0`: `i_wb_clk`
- `1`: `i_extclk`

The selected source is optionally down-clocked using `Divisor`:
- `Divisor = 0` or `Divisor = 1`: bypass (no frequency reduction).
- `Divisor > 1`: divider output frequency tracks selected source frequency divided by divisor value.

Odd and even divisors are handled by separate divider submodules; `Divisor[0]` selects odd/even path.

### 4.3 PWM Mode (`Ctrl[1]=1`)

When PWM mode is selected and `run_en=1`:
- Main counter increments on each working clock.
- Counter resets to zero when terminal count is reached.
- `o_pwm` source signal (`pts`) is high while counter value is below selected duty-cycle value, and low otherwise.

Duty-cycle source is selected by `Ctrl[6]`:
- `0`: internal `DC` register.
- `1`: externally captured duty-cycle register (`extDC`), updated when `i_valid_DC=1`.

If `run_en=0`, PWM counter progression halts; output transitions stop unless reset/control changes modify state.

### 4.4 Timer Mode (`Ctrl[1]=0`)

When timer mode is selected and `run_en=1`:
- Counter increments toward terminal count derived from `Period`.
- When terminal count is reached, timer event state is asserted (`timer_irq` path), and `o_pwm` can indicate this event when output is enabled.

Timer run style is controlled by `Ctrl[3]`:
- One-shot (`0`): after terminal count, event remains asserted until cleared.
- Continuous (`1`): counter restarts after terminal count and continues counting while event state remains software-clearable.

Timer interrupt clear uses `Ctrl[5]` write-low semantics. Clear request is handshaked into the counter/event path and deasserts timer event indication after completion.

### 4.5 Output Behavior and Gating

`o_pwm` is always gated by `Ctrl[4]`:
- `out_en=0`: `o_pwm=0`.
- `out_en=1`: `o_pwm` reflects internal mode-dependent signal (`pts`).

As a result, timer interrupt indication on `o_pwm` is visible only when `out_en=1`.

### 4.6 Reset and Counter-Reinitialization Effects

Main counter path reset is asserted by either:
- global reset `i_wb_rst`, or
- control reset request `Ctrl[7]`.

This reset clears main counting/event state used for PWM/timer output generation. For mode transitions that require clean timer startup, assert/deassert `Ctrl[7]` to reinitialize counter/event state before restarting.

## 5. Implementation Details

### 5.1 Functional Block Structure

The design is organized into four major behavior blocks:
- WISHBONE register/control block (`Ctrl`, `Divisor`, `Period`, `DC`, read mux, write decode).
- Timer interrupt control block (status latch and clear-request handshake).
- Clock conditioning block (source select plus odd/even divider selection).
- Main counter/event block (counter progression, PWM compare logic, timer event logic, output source `pts`).

### 5.2 Register and Control Path

- Write enable condition is `i_wb_cyc & i_wb_stb & i_wb_we`.
- Addressed writes update control/data registers at `0x0/0x2/0x4/0x6`.
- `Ctrl[5]` is not a free-running software bit; it is managed by timer-event logic and clear sequencing.
- Read data is combinationally selected by `i_wb_adr`.
- `o_wb_ack` is combinationally driven from `i_wb_stb`.

### 5.3 Clocking Path

- `Ctrl[0]` selects `i_wb_clk` or `i_extclk`.
- Divider path selection uses `Divisor[0]`:
  - even-path module for even divisors,
  - odd-path module for odd divisors.
- Divider bypass occurs for divisor values corresponding to no down-clocking behavior.

### 5.4 Counter/Event Path

- Main counter state (`ct`) and output source (`pts`) operate in the selected working-clock domain.
- `Period` is interpreted as terminal count target with internal terminal handling for zero/non-zero period values.
- External duty-cycle input is sampled into `extDC` when `i_valid_DC` is asserted.
- Timer clear request/acknowledge logic coordinates interrupt clear across control and event logic.

## 6. Submodule List

### 6.1 `down_clocking_even`

Role: divide input clock by an even-number ratio path; bypass input clock when divider is disabled.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | Divider input clock. |
| `i_rst` | Input | 1 | Active-low reset. |
| `i_divisor` | Input | 16 | Divider setting used by even-divider path. |
| `o_clk` | Output | 1 | Even-divider output clock or bypassed clock. |

### 6.2 `down_clocking_odd`

Role: divide input clock by an odd-number ratio path; bypass input clock when divider is disabled.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | Divider input clock. |
| `i_rst` | Input | 1 | Active-low reset. |
| `i_divisor` | Input | 16 | Divider setting used by odd-divider path. |
| `o_clk` | Output | 1 | Odd-divider output clock or bypassed clock. |

### 6.3 `minus_one`

Role: combinational helper used inside divider submodules to derive decrement-based terminal compare values.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_operand` | Input | 16 | Input value. |
| `o_result` | Output | 16 | Input value minus one. |
| `o_borrow` | Output | 1 | Borrow output for zero-underflow indication. |

## 7. Clock and Reset

- `i_wb_clk` clocks the WISHBONE/control path.
- Main counter/event logic runs on a selected working clock (`i_wb_clk` or `i_extclk`) after optional down-clocking.
- `i_wb_rst` resets register/control logic and also resets main counter/event logic.
- `Ctrl[7]` provides software-controlled reset for the main counter/event path.

## 8. Constraints

- Software should use aligned register addresses `0x0000`, `0x0002`, `0x0004`, `0x0006`.
- `o_wb_ack` follows `i_wb_stb`; bus integration should account for this acknowledge behavior.
- For deterministic reconfiguration, clear `run_en` before changing `Divisor`, `Period`, duty-cycle source, or duty-cycle values.
- In external duty-cycle mode (`Ctrl[6]=1`), assert `i_valid_DC` with stable `i_DC` in the active working-clock domain.
- After asserting `Ctrl[7]` for counter reset, deassert `Ctrl[7]` before restarting (`run_en=1`).
