# sd_scoreboard Design Specification

## 1. Introduction

`sd_scoreboard` is a parameterized srdy/drdy utility component that maintains per-item state in an internal memory and serves read or write requests through a single request/response pipeline.

The module supports:

- Read requests that return stored item data.
- Write requests that replace item data.
- Optional masked writes for read-modify-write updates.
- Optional transaction ID tagging on read responses.

The design is intended to act as a centralized repository for multiple logical requestors after request serialization by upstream arbitration logic.

## 2. Module Diagram


## 3. Interface

### 3.1 Parameters

| Parameter | Description |
| --- | --- |
| `width` | Data width of each scoreboard entry. |
| `items` | Number of scoreboard entries. |
| `use_txid` | Enables transaction ID transport when non-zero. |
| `use_mask` | Enables masked write/read-modify-write when non-zero. |
| `txid_sz` | Width of transaction ID field. |
| `asz` | Address width for item index (`c_itemid`). |

### 3.2 Top-Level Ports

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | Clock input. |
| `reset` | Input | 1 | Asynchronous active-high reset. |
| `c_srdy` | Input | 1 | Request-channel source-ready. |
| `c_drdy` | Output | 1 | Request-channel destination-ready. |
| `c_req_type` | Input | 1 | Request type: `0` read, `1` write. |
| `c_txid` | Input | `txid_sz` | Request transaction ID (used when `use_txid != 0`). |
| `c_mask` | Input | `width` | Write mask (used when `use_mask != 0`). |
| `c_data` | Input | `width` | Write data payload. |
| `c_itemid` | Input | `asz` | Target item address/index. |
| `p_srdy` | Output | 1 | Response-channel source-ready. |
| `p_drdy` | Input | 1 | Response-channel destination-ready. |
| `p_txid` | Output | `txid_sz` | Response transaction ID (zero when `use_txid == 0`). |
| `p_data` | Output | `width` | Response data payload for read responses. |

### 3.3 Handshake Semantics

- A transfer occurs on a cycle where `srdy` and `drdy` are both asserted.
- Request channel uses `c_srdy/c_drdy`; response channel uses `p_srdy/p_drdy`.
- Backpressure propagates through input/output timing-closure wrappers (`sd_input`, `sd_output`).

## 4. Function Description

### 4.1 Request Packing and Input Staging

Incoming request fields are packed into an internal payload whose composition depends on parameters:

- `use_txid` controls whether `txid` bits are carried internally.
- `use_mask` controls whether `mask` bits are carried internally.

`sd_input` captures this packed request and provides one-word buffering while driving internal request signals (`ip_*`) toward the scoreboard FSM.

### 4.2 Scoreboard Memory Model

The scoreboard data store is implemented with a single-port behavioral memory (`behave1p_mem`) addressed by `c_itemid`.

- Write path uses `wr_en`, `addr`, and `d_in`.
- Read path uses `rd_en` and registered read address (`r_addr` in memory model), with data returned as `d_out`.

### 4.3 Read Transactions

For `c_req_type = 0`:

1. FSM accepts request (`ip_drdy` asserted), captures request `txid` when enabled, and issues memory read (`rd_en`).
2. FSM enters read-response state and drives `ic_srdy` with `ic_data = d_out`.
3. `sd_output` holds response stable until `p_drdy` handshake occurs.
4. If `use_txid == 0`, response `p_txid` is driven as zero.

### 4.4 Write Transactions

For `c_req_type = 1`:

- Full write case:
  - If masking is disabled (`use_mask == 0`) or mask is all ones, FSM accepts request and writes `ip_data` directly to memory.
- Masked write case:
  - If masking is enabled and mask is not all ones, FSM performs read-modify-write.
  - First cycle issues memory read and transitions to modify state.
  - Next cycle computes merged data as:
    - preserved bits from existing data where mask bit is `0`,
    - new bits from request data where mask bit is `1`.
  - FSM writes merged result and returns to idle.

Write operations do not generate response-channel traffic.

### 4.5 Flow Control Behavior

- Reads can be stalled in response phase if downstream `p_drdy` is low.
- Request acceptance is paused while FSM is in non-idle phases that cannot accept a new request.
- `sd_input` and `sd_output` wrappers provide timing-closure buffering on the external interfaces.

## 5. Implementation Details

### 5.1 Top-Level Datapath Structure

`sd_scoreboard` composes four subfunctions:

1. `sd_input` for request-channel timing closure and buffering.
2. `sd_scoreboard_fsm` for request decode, memory control, and response control.
3. `behave1p_mem` for per-item storage.
4. `sd_output` for response-channel timing closure and buffering.

### 5.2 FSM Control States

The scoreboard control FSM uses three state bits/functions:

- `s_idle`: request decode and acceptance.
- `s_read`: response production for reads.
- `s_rdmod`: masked-write modify/commit phase.

Transitions are determined by request type, mask qualification, and response-channel readiness.

### 5.3 Optional Feature Handling

- `use_txid` controls inclusion/forwarding of transaction ID fields.
- `use_mask` controls activation of masked-write behavior.
- When features are disabled, related internal fields are forced to zero where applicable.

### 5.4 Clocking and Macro Controls

Clock/reset style and nonblocking assignment delay can be overridden with:

- ``SDLIB_CLOCKING`` (default: `posedge clk or posedge reset`)
- ``SDLIB_DELAY`` (default: `#1`)

These controls affect implementation style but do not change interface semantics.

## 6. Submodule List

### 6.1 `sd_input`

Role: Request-side timing closure and one-word buffer from external consumer interface to internal pipeline.

| Signal Group | Description |
| --- | --- |
| `c_srdy/c_drdy/c_data` | External request handshake and payload input. |
| `ip_srdy/ip_drdy/ip_data` | Internal request handshake and payload output. |

### 6.2 `sd_scoreboard_fsm`

Role: Core transaction controller for read, write, and masked read-modify-write operation.

| Signal Group | Description |
| --- | --- |
| `ip_*` | Internal request decode inputs and request backpressure output. |
| `ic_*` | Internal response handshake/data toward output wrapper. |
| `wr_en/rd_en/d_in/addr` | Memory control and write-data/address generation. |
| `d_out` | Memory read-data input. |

### 6.3 `behave1p_mem`

Role: Single-port storage array for scoreboard entries.

| Signal | Direction | Description |
| --- | --- | --- |
| `wr_en` | Input | Write enable. |
| `rd_en` | Input | Read enable. |
| `clk` | Input | Clock. |
| `d_in` | Input | Write data. |
| `addr` | Input | Read/write address. |
| `d_out` | Output | Read data from registered read address. |

### 6.4 `sd_output`

Role: Response-side timing closure and output holding from internal pipeline to external producer interface.

| Signal Group | Description |
| --- | --- |
| `ic_srdy/ic_drdy/ic_data` | Internal response handshake and payload input. |
| `p_srdy/p_drdy/p_data` | External response handshake and payload output. |

## 7. Clock and Reset

- Clock domain: single clock `clk`.
- Reset polarity: active-high asynchronous reset (`reset`).
- Reset clears wrapper state and FSM state to idle behavior, and clears response-valid state in output staging.

## 8. Constraints

- `asz` must be sufficient to address `items` entries.
- `c_itemid` must be valid for configured memory depth.
- Upstream logic should provide request serialization if multiple sources share the scoreboard.
- For deterministic masked writes, `use_mask` must be enabled and `c_mask` must reflect bit-level update intent.
- `p_drdy` backpressure is supported; downstream must complete response handshakes to avoid read-response stalling.
