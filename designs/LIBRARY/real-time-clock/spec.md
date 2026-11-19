# rtcclock Design Specification

## 1. Introduction

`rtcclock` is a Wishbone-controlled real-time clock peripheral that provides:

- 24-hour wall-clock timekeeping,
- a countdown timer,
- a stopwatch,
- a daily alarm,
- programmable clock-speed calibration,
- time-hack capture registers,
- seven-segment and LED status outputs,
- an interrupt pulse output for timer/alarm events.

The design represents time fields in BCD for hours, minutes, and seconds. It is intended for software configuration and status readback through a simple register-mapped bus interface.

## 2. Module Diagram


## 3. Interface

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | System clock. All logic is synchronous to the positive edge of `i_clk`. |
| `i_wb_cyc` | Input | 1 | Bus cycle qualifier. |
| `i_wb_stb` | Input | 1 | Bus strobe qualifier. |
| `i_wb_we` | Input | 1 | Bus write enable. |
| `i_wb_addr` | Input | 3 | Register address select. |
| `i_wb_data` | Input | 32 | Bus write data. |
| `o_data` | Output | 32 | Register read data for the selected `i_wb_addr`. |
| `o_sseg` | Output | 32 | Encoded 4-digit seven-segment output payload (8 bits per digit, including decimal-point control bit). |
| `o_led` | Output | 16 | LED status output pattern. |
| `o_interrupt` | Output | 1 | Interrupt pulse, asserted on countdown expiration or alarm trip event. |
| `i_hack` | Input | 1 | Time-hack capture strobe input. |

### 3.1 Bus Access Semantics

- A write is accepted when `i_wb_cyc`, `i_wb_stb`, and `i_wb_we` are asserted and `i_wb_addr` matches the target register.
- The module does not expose explicit `ack`/`stall` outputs.
- `o_data` is a registered mux of the addressed register bank and is updated on `i_clk`.
- Register map uses word addressing (`i_wb_addr[2:0]`) with 32-bit data accesses.

## 4. Function Description

### 4.1 Time Base and Clock Advancement

The core uses a programmable fractional time base:

- `ckspeed` defines the increment added each `i_clk` cycle into a 40-bit accumulator (`ck_counter`).
- For one-second calibration, `ckspeed` is programmed to the integer ratio of 2^48 to the input clock frequency.
- When this addition carries out, a subsecond step (`ck_sub`) advances.
- A second pulse (`ck_pps`) is generated after 256 subsecond steps and advances the wall clock by one second.

Wall-clock fields (`clock`) are BCD-encoded:

- Seconds: `00` to `59`
- Minutes: `00` to `59`
- Hours: `00` to `23`

### 4.2 Wall Clock Register Behavior

Software may write wall-clock fields with masked update semantics:

- Writing `8'hFF` to seconds or minutes leaves that field unchanged.
- Writing `6'h3F` to hours leaves hours unchanged.
- Writing seconds as `8'h00` also clears `ck_sub`.

Upper bits of the clock register include display-mode control used by the seven-segment formatting logic.

### 4.3 Countdown Timer

The countdown timer is represented by `timer[25:0]`:

- `timer[24]`: run/stop state.
- `timer[25]`: timer alarm/trip status.
- `timer[23:0]`: BCD countdown value (HH:MM:SS).

Behavior:

- While running, timer decrements once per second.
- When countdown reaches zero, alarm status is set, running is cleared, and an interrupt pulse is generated.
- Writes while running can control run/stop only.
- Writes while stopped can load a new value and clear alarm status.
- If timer value is zero and a zero value is written while stopped, the timer reloads from the saved start value (`tm_start`).

### 4.4 Stopwatch

The stopwatch uses `stopwatch[31:0]` with:

- `stopwatch[0]`: run/stop control.
- `stopwatch[1]` (write control bit): clear request.
- Remaining bits: elapsed time representation (BCD for seconds/minutes/hours plus subsecond bits).

Behavior:

- When running, subsecond and BCD time fields advance from the same base carry mechanism.
- Writing bit0 controls run/stop.
- Clear action occurs only when stopped, or when write data stops the stopwatch in that transaction.

### 4.5 Alarm

Alarm configuration uses `alarm_time[21:0]` with control bits:

- `al_enabled`: alarm enable.
- `al_tripped`: latched trip indication.

Behavior:

- Alarm compares wall-clock time against alarm time and trips on time match transition.
- When tripped, `al_tripped` latches until cleared by software or by disabling alarm.
- A match event generates a one-cycle interrupt pulse (`al_int`).
- Alarm register supports masked field updates using `8'hFF` / `6'h3F` sentinel values.

### 4.6 Time Hack Capture

`i_hack` captures a precise timestamp snapshot:

- `hack_time` captures `{clock[21:0], ck_sub}`.
- `hack_counter` captures the 40-bit fractional accumulator.
- If a carry is active at hack capture time, a follow-up update aligns captured time on the next cycle.

This supports fine-grain cross-timestamping against external timing references.

### 4.7 Display and LED Outputs

Seven-segment output (`o_sseg`) supports multiple display modes selected by clock register mode bits:

- Mode `0`: wall-clock hours/minutes view.
- Mode `1`: timer-centric view.
- Mode `2`: stopwatch-centric view.
- Mode `3`: wall-clock minutes/seconds view.

`o_sseg` is blanked in a blink pattern when timer alarm or alarm trip is active.

`o_led` behavior:

- Normal mode: derived from an internal running pattern synchronized to the clock progression.
- Alarm mode: all LEDs flash together.

### 4.8 Interrupt Behavior

`o_interrupt` is the logical OR of:

- countdown timer expiration pulse (`tm_int`), and
- alarm trip pulse (`al_int`).

Both events are pulse-style event indications rather than level-held interrupt requests.

## 5. Register Map

| Address (`i_wb_addr`) | Name | Access | Description |
| --- | --- | --- | --- |
| `3'b000` | Clock/Display | R/W | Wall clock and display mode register. Read returns `{clock[31:22], ck_last_clock[21:0]}`. |
| `3'b001` | Timer | R/W | Countdown timer register `{6'h00, timer[25:0]}`. |
| `3'b010` | Stopwatch | R/W | Stopwatch control/value register. |
| `3'b011` | Alarm | R/W | Alarm control/value register `{6'h00, al_tripped, al_enabled, 2'b00, alarm_time}`. |
| `3'b100` | Clock Speed | R/W | `ckspeed` calibration value. |
| `3'b101` | Hack Time | R | `{2'b00, hack_time}`. |
| `3'b110` | Hack Counter High | R | `hack_counter[39:8]`. |
| `3'b111` | Hack Counter Low | R | `{hack_counter[7:0], 24'h00}`. |

### 5.1 Key Bitfield Semantics

#### Clock Register (`3'b000`)

- `[31:22]`: control/status upper fields (includes display mode in `[27:24]`).
- `[21:16]`: BCD hours (masked write: `6'h3F` means unchanged).
- `[15:8]`: BCD minutes (masked write: `8'hFF` means unchanged).
- `[7:0]`: BCD seconds (masked write: `8'hFF` means unchanged; `8'h00` clears `ck_sub`).

#### Timer Register (`3'b001`)

- `[25]`: timer alarm/tripped.
- `[24]`: timer running.
- `[23:0]`: BCD countdown value.

#### Stopwatch Register (`3'b010`)

- `[0]`: running control.
- `[1]`: write-command bit for clear control (effective only if stopped before/after write); on reads, this bit is part of stopwatch time state.
- Remaining bits: stopwatch elapsed-time fields.

#### Alarm Register (`3'b011`)

- `[25]`: alarm tripped (write `1` to clear).
- `[24]`: alarm enable.
- `[23:22]`: reserved zero.
- `[21:16]`: BCD hours (masked update by `6'h3F`).
- `[15:8]`: BCD minutes (masked update by `8'hFF`).
- `[7:0]`: BCD seconds (masked update by `8'hFF`).

## 6. Implementation Details

### 6.1 Core Timekeeping Structure

- A 40-bit accumulator (`ck_counter`) is incremented by `ckspeed` every cycle.
- Carry from this addition provides the base timing event used across clock, timer, and stopwatch logic.
- Separate 8-bit subsecond trackers (`ck_sub`, `tm_sub`, `sw_sub`) derive feature-specific one-second events.

### 6.2 Stable Comparison and Readout

- `ck_last_clock` captures a stable copy of current wall time for alarm comparison and readback.
- Alarm match logic compares `clock[21:0]` against `alarm_time` and uses transition detection (`ck_last_clock != alarm_time`) to avoid repeated same-level trigger assertion.

### 6.3 Control and Status Coupling

- Timer and alarm status directly influence user outputs (`o_sseg`, `o_led`) through blink behavior.
- Interrupt output is event-oriented and produced from timer/alarm pulse sources.

### 6.4 Read Data Multiplexing

`o_data` is produced by an address-based registered multiplexer and includes both primary control registers and auxiliary time-hack capture registers.

## 7. Submodule List

### 7.1 `hexmap`

Role: Converts a 4-bit hexadecimal nibble to a 7-segment pattern (`o_map[7:1]`).

The top-level instantiates four `hexmap` units to generate segment patterns for four display digits.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `i_clk` | Input | 1 | Clock for registered output mapping. |
| `i_hex` | Input | 4 | Nibble value to display. |
| `o_map` | Output | 7 (`[7:1]`) | Segment enable pattern (decimal point handled outside `hexmap`). |

## 8. Clock and Reset

- Clock domain: single domain on `i_clk` (posedge).
- Reset: no dedicated reset input port is defined for this module.
- Power-up/default state is established via register initializations in RTL.
- Software is expected to initialize operational registers after startup according to system requirements.

## 9. Constraints

- Time fields should be written in valid BCD format for defined behavior.
- Bus transactions are 32-bit word-oriented; there are no byte-enable controls.
- Software should keep `i_wb_addr`, `i_wb_cyc`, `i_wb_stb`, and `i_wb_we` stable for the target access cycle.
- `i_hack` should be strobed for at least one `i_clk` cycle per capture event.
- Time-hack registers should be read before the next hack event if previous capture data must be preserved.
