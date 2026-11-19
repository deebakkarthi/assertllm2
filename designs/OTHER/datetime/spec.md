# Datetime Design Specification

## 1. Introduction

`Datetime` is a date-and-time keeping core with a 64-bit BCD register model and a WISHBONE-compatible slave interface. The module maintains time/date using an external time-of-day pulse input and supports alarm generation based on programmable match masks.

Key capabilities include:
- 64-bit BCD time/date representation,
- programmable time-of-day input frequency selection,
- optional Mars timekeeping mode,
- snapshot-based coherent time readout,
- programmable alarm comparison granularity.

## 2. Module Diagram

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `rst_i` | Input | 1 | Active-high reset. |
| `clk_i` | Input | 1 | Bus/control clock. |
| `cyc_i` | Input | 1 | Bus cycle valid qualifier. |
| `stb_i` | Input | 1 | Bus transfer strobe. |
| `ack_o` | Output | 1 | Bus transfer acknowledge. |
| `we_i` | Input | 1 | Write enable (`1` = write, `0` = read). |
| `sel_i` | Input | `[7:0]` | Byte-lane write enables for 64-bit register fields. |
| `adr_i` | Input | `[23:0]` | Address input; high bits select core, low bits select register. |
| `dat_i` | Input | `[63:0]` | Write data bus. |
| `dat_o` | Output | `[63:0]` | Read data bus. |
| `tod` | Input | 1 | External time-of-day pulse input (50/60/100 Hz selectable). |
| `alarm` | Output | 1 | Alarm match indication output. |

### 3.2 Bus Selection and Register Decode

The core is selected when:
- `cyc_i=1`,
- `stb_i=1`,
- `adr_i[23:5]` matches the configured base (`pIOAddress[23:5]`).

Internal register decode uses `adr_i[4:3]`:
- `2'b00`: Date-time register,
- `2'b01`: Alarm register,
- `2'b10`: Control register,
- `2'b11`: Snapshot trigger register.

### 3.3 Acknowledge Behavior

- Write accesses acknowledge immediately when selected.
- Read accesses acknowledge with a one-cycle delayed path while the transfer remains selected.

## 4. Register Map and Semantics

### 4.1 Register 0: Date-Time (`DC0400`)

Format (BCD): `YYYYMMDDHHMMSSss`.

This register is writable for time/date updates. Readback returns the snapshot output register contents, not the live running counters.

### 4.2 Register 1: Alarm (`DC0408`)

Format matches the date-time register (`YYYYMMDDHHMMSSss`, BCD). The stored alarm value is compared against current time/date using mask bits from the control register.

Reading register 1 clears the active alarm output.

### 4.3 Register 2: Control (`DC0410`)

- Bits `[7:0]`: alarm care/mask bytes (which date-time bytes participate in alarm match).
- Bit `[8]`: TOD tracking enable (`1` enable, `0` hold counters).
- Bits `[10:9]`: TOD frequency mode:
  - `00`: 100 Hz,
  - `01`: 60 Hz,
  - `10`: 50 Hz.
- Bit `[16]`: Mars mode select (`1` Mars calendar/time rules, `0` Earth rules).

### 4.4 Register 3: Snapshot (`DC0418`)

Any write triggers a snapshot pulse. On snapshot, the current live counters are copied to output latch registers. Register 0 reads then return this coherent captured value.

## 5. Function Description

### 5.1 Clocking Model

The core uses independent clocks/signals for bus access and time advancement:
- `clk_i` drives bus/control/register logic.
- `tod` is asynchronous to `clk_i` and is synchronized by a two-stage synchronizer (`sync2s`) followed by an edge detector (`edge_det`).

Only detected `tod` rising edges advance the time counters when TOD tracking is enabled.

### 5.2 Timekeeping Data Path

Live time/date state is maintained as BCD digit registers:
- jiffies, seconds, minutes, hours,
- day, month,
- year (four BCD digits).

On each qualified TOD edge, increment cascades through BCD fields with carry propagation. Day/month/year rollover logic depends on selected Earth or Mars mode.

### 5.3 Earth and Mars Calendar Handling

Earth mode:
- Day limits follow month lengths with leap-year handling for February.

Mars mode:
- Uses alternate day-length and month rollover rules for Martian timekeeping.

### 5.4 Alarm Operation

Alarm match compares alarm register bytes against current live date-time bytes with mask expansion from `alarm_care` bits.

When a new match is detected, `alarm` is asserted. Reading register 1 clears `alarm`.

### 5.5 Snapshot Read Sequence

To read a coherent date-time value:
1. Write to register 3 to trigger snapshot.
2. Read register 0.

This avoids partial-update observations while counters are advancing.

## 6. Implementation Details

### 6.1 Internal State Organization

The design separates:
- live counters (`jiffy*`, `sec*`, `min*`, `hour*`, `day*`, `month*`, `year*`),
- snapshot/output latches (`*o` versions),
- alarm compare registers (`alm_*`),
- control state (`tod_en`, `tod_freq`, `mars`, `alarm_care`).

This organization supports coherent readback and independent alarm programming.

### 6.2 Bus Read/Write Control

Writes update selected register fields according to decoded register and active `sel_i` lanes. Snapshot write is pulse-based.

Reads multiplex register views onto `dat_o`:
- snapshot date-time,
- alarm settings,
- control view,
- zero for snapshot register read path.

### 6.3 Synchronization and Edge Detection

`sync2s` provides two-flop synchronization of `tod` into `clk_i` domain.

`edge_det` generates pulse-qualified edge indicators; the positive edge drives time update enable.

### 6.4 Leap-Year and Special-Year Logic

The implementation includes dedicated logic to evaluate:
- Earth leap-year validity from BCD year digits,
- Mars-mode year class behavior used by month/day rollover.

## 7. Submodule List

### 7.1 `sync2s`

Role: synchronize asynchronous `tod` input into `clk_i` domain.

| Signal | Direction | Description |
| --- | --- | --- |
| `rst` | Input | Reset input. |
| `clk` | Input | Destination clock (`clk_i`). |
| `i` | Input | Asynchronous input (`tod`). |
| `o` | Output | Synchronized output. |

### 7.2 `edge_det`

Role: detect edges on synchronized TOD signal.

| Signal | Direction | Description |
| --- | --- | --- |
| `rst` | Input | Reset input. |
| `clk` | Input | Clock input. |
| `ce` | Input | Detector enable. |
| `i` | Input | Signal under test. |
| `pe` | Output | Positive-edge pulse. |
| `ne` | Output | Negative-edge pulse. |
| `ee` | Output | Either-edge pulse. |

## 8. Clock and Reset

- `clk_i` is the core bus/control clock.
- `tod` is an external pulse source and is treated as asynchronous to `clk_i`.
- `rst_i` resets control and state registers to initial values.

## 9. Constraints

- External `tod` source is required for time/date progression.
- Date/time and alarm values are expected in valid BCD digit format.
- For coherent time reads, software should snapshot (register 3 write) before reading register 0.
- During partial date-time writes, TOD updates may be temporarily disabled to avoid mixed-field updates.
- Alarm compare granularity is controlled exclusively by `alarm_care` mask bits.
