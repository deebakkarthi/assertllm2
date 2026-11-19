# rtfSpriteController Design Specification

## 1. Introduction

`rtfSpriteController` is a hardware sprite (cursor) controller that overlays programmable sprite images onto an incoming video stream. It supports a parameterized number of sprites and per-sprite image caches that can be updated by either programmed I/O or an internal DMA path.

The module provides:
- a memory-mapped slave interface for sprite control registers and image-cache access,
- a memory-master interface used by the internal DMA loader,
- a video-side pixel overlay, priority, and collision-reporting path.

## 2. Module Diagram

## 3. Interface

### 3.1 Top-Level Ports

| Signal | Dir | Width | Description |
| --- | --- | --- | --- |
| `rst_i` | Input | 1 | Active-high reset input. |
| `clk_i` | Input | 1 | Slave register/programmed-access clock domain. |
| `s_cyc_i` | Input | 1 | Slave transaction cycle qualifier. |
| `s_stb_i` | Input | 1 | Slave transfer strobe. |
| `s_ack_o` | Output | 1 | Slave transfer acknowledge for register/image-cache region accesses. |
| `s_we_i` | Input | 1 | Slave write qualifier. |
| `s_sel_i` | Input | 4 | Slave byte enables for 32-bit register/cache accesses. |
| `s_adr_i` | Input | 32 | Slave address for register block and sprite cache windows. |
| `s_dat_i` | Input | 32 | Slave write data. |
| `s_dat_o` | Output | 32 | Slave read data. |
| `vol_o` | Output | 1 | Indicates access to volatile global-status register page within the register region. |
| `m_clk_i` | Input | 1 | DMA master clock domain. |
| `m_bte_o` | Output | 2 | DMA burst-type output (fixed value). |
| `m_cti_o` | Output | 3 | DMA cycle-type output (fixed value). |
| `m_cyc_o` | Output | 1 | DMA bus cycle active indicator. |
| `m_stb_o` | Output | 1 | DMA transfer strobe (asserted while DMA interface is active). |
| `m_ack_i` | Input | 1 | DMA data acknowledge from system memory. |
| `m_err_i` | Input | 1 | DMA transfer error indication; treated as transfer completion for sequencing. |
| `m_we_o` | Output | 1 | DMA write enable (fixed low; DMA performs reads only). |
| `m_adr_o` | Output | 32 | DMA read address. |
| `m_dat_i` | Input | 32 | DMA read data input. |
| `m_dat_o` | Output | 32 | DMA write data output (unused, fixed zero). |
| `vclk` | Input | 1 | Video pixel clock domain. |
| `hSync` | Input | 1 | Horizontal sync reference input. |
| `vSync` | Input | 1 | Vertical sync reference input. |
| `blank` | Input | 1 | Pixel blanking input; forces black output when asserted. |
| `rgbPriority` | Input | 2 | Input-video priority classification used in overlay/collision decisions. |
| `rgbIn` | Input | 24 | Background/input pixel stream (`R:G:B`, 8 bits each). |
| `rgbOut` | Output | 24 | Composited output pixel stream (`R:G:B`, 8 bits each). |
| `irq` | Output | 1 | OR of sprite-sprite and sprite-background collision interrupt requests. |

### 3.2 Address Regions

- Register block: `0xFFDAD000`-`0xFFDADFFF` (decoded by `s_adr_i[31:12] == 20'hFFDAD`).
- Sprite image cache window: `0xFFD80000`-`0xFFD9FFFF` (decoded by `s_adr_i[31:16] == 16'hFFD8` or `16'hFFD9`).

Within the image-cache window, `s_adr_i[16:12]` selects the sprite cache bank (4 KB per sprite cache, up to 32 banks).

### 3.3 Slave Interface Semantics

- Writes to decoded register/cache regions are acknowledged in the access cycle.
- Reads are acknowledged after the internal ready stage for the decoded region.
- `s_dat_o` returns either cache data (`cs_ram`) or register data (`cs_regs`) based on address decoding.
- `vol_o` is asserted for global register-page accesses (`0x3C0` and above in the local register map).

## 4. Register Map

All registers are 32-bit wide. The per-sprite register block repeats every `0x10` bytes.

### 4.1 Per-Sprite Registers (`sprite n` base + offsets)

| Offset | Name | Bits | Description |
| --- | --- | --- | --- |
| `0x00` | Position | `[11:0]` | Horizontal sprite position (relative to `hSync` reference counter). |
| `0x00` | Position | `[27:16]` | Vertical sprite position (relative to `vSync` reference counter). |
| `0x04` | Size | `[7:0]` | Sprite width in pixels minus 1. |
| `0x04` | Size | `[15:8]` | Sprite height in pixels minus 1. |
| `0x04` | Size | `[19:16]` | Horizontal pixel expansion factor minus 1 (1 to 16 video clocks per sprite pixel). |
| `0x04` | Size | `[23:20]` | Vertical pixel expansion factor minus 1 (1 to 16 scan lines per sprite pixel). |
| `0x08` | Image/DMA Addr | `[11:0]` | Image offset within the selected sprite cache. |
| `0x08` | Image/DMA Addr | `[31:12]` | Per-sprite DMA source address upper portion (low 12 bits are DMA-generated during transfer). |
| `0x0C` | Transparent Color | `[15:0]` | Transparent color key (8-bit or 16-bit mode dependent). |

### 4.2 Global Registers

| Offset | Name | Bits | Description |
| --- | --- | --- | --- |
| `0x3C0` | Sprite Enable (`EN`) | `[31:0]` | Per-sprite display enable mask. |
| `0x3C4` | Interrupt Enable/Status (`IE`) | `[0]` | Enable interrupt generation for sprite-sprite collision events. |
| `0x3C4` | Interrupt Enable/Status (`IE`) | `[1]` | Enable interrupt generation for sprite-background collision events. |
| `0x3C8` | Sprite Collision Record (`SCOL`) | `[31:0]` | Accumulated sprite-sprite collision bitmap. |
| `0x3CC` | Background Collision Record (`BCOL`) | `[31:0]` | Accumulated sprite-background collision bitmap. |
| `0x3D0` | DMA Trigger On (`DT_ON`) | `[31:0]` | Bitwise set of DMA trigger bits. |
| `0x3D4` | DMA Trigger Off (`DT_OFF`) | `[31:0]` | Bitwise clear of DMA trigger bits. |
| `0x3E8` | Background Transparent Color (`BTC`) | `[23:0]` | Background transparency reference color used by overlay policy. |
| `0x3EC` | Background Color (`BC`) | `[23:0]` | Programmed background color classification reference. |
| `0x3FC` | DMA High Address | `[31:0]` | High address extension field for DMA addressing (architecturally defined; implementation support requires confirmation). |

### 4.3 Collision Register Clearing

- Collision records accumulate sprite-bit information across collision events.
- Access to `SCOL`/`BCOL` locations clears the corresponding accumulated record and pending interrupt state in the implementation.

## 5. Function Description

### 5.1 Overall Operation

The controller receives an input pixel stream (`rgbIn`) and outputs a composited stream (`rgbOut`) with optional sprite overlay. Each sprite is defined by programmable position, dimensions, pixel scaling, transparent color, and image-cache offset. Sprite image data comes from per-sprite cache RAM. Caches are written either by programmed writes through the slave interface or by the internal DMA loader.

### 5.2 Sprite Coordinate and Scan Flow

- Horizontal and vertical reference counters are driven in the `vclk` domain.
- `hSync` positive edges reset the horizontal counter.
- `vSync` positive edges reset the vertical counter.
- Per sprite, when the current reference counter equals the programmed position, the sprite scan enters its active region.
- Horizontal and vertical pixel expansion controls allow each sprite source pixel to be repeated for multiple video clocks/scanlines.
- Sprite address generation supports both scanline progression and line rescan when vertical expansion requires repeating lines.

This scan flow allows a sprite image to be read as a 2-D object while honoring programmable size and scaling controls.

### 5.3 Sprite Pixel Activity and Priority

For each pixel time:
- a sprite contributes only if:
  - the sprite is enabled,
  - the current point is within its active display region,
  - the fetched sprite pixel is not equal to the sprite transparent-color key.
- multiple active sprites are resolved with fixed priority (lower sprite index has higher priority).

### 5.4 Color Handling

Supported sprite pixel formats are parameterized by `pColorBits`:
- `8`-bit mode: color interpreted as `R3:G3:B2` and expanded to 24-bit output.
- `16`-bit mode: color interpreted as `A1:R5:G5:B5`.

In 16-bit mode:
- if `A` bit is clear, sprite color is directly expanded to 24-bit.
- if `A` bit is set, the lower 8 bits act as a blend factor and the output is blended against `rgbIn` components.

### 5.5 Overlay Decision with Input Video

- If `blank` is asserted, output is forced to black.
- Otherwise, the controller decides whether the background/input pixel (`rgbIn`) or the sprite pixel appears at `rgbOut` based on:
  - sprite activity,
  - `rgbPriority`,
  - background transparency policy (`bgTc`/background classification context).

### 5.6 Collision and Interrupt Behavior

The controller tracks two collision classes:
- Sprite-sprite collision: more than one sprite active at the same pixel time.
- Sprite-background collision: active sprite overlapping a region classified as background-object/foreground by the input-priority context.

For each collision class:
- a bitmap records which sprites are involved,
- a pending flag is set on first collision after clear,
- `irq` is asserted when an enabled collision class is pending.

### 5.7 DMA Loading of Sprite Caches

DMA is requested per sprite through trigger bits:
- setting a bit in `DT_ON` requests cache loading for that sprite,
- setting a bit in `DT_OFF` clears a pending trigger bit.

For a triggered sprite, DMA reads 32-bit words from system memory and writes the selected sprite cache until one full 4 KB cache image is transferred. DMA source addressing combines per-sprite address fields with an internally generated low-order offset sequence.

## 6. Implementation Details

### 6.1 Clock-Domain Partitioning

- `clk_i` domain: slave register file updates, programmed cache access path, status readback.
- `m_clk_i` domain: DMA master sequencing and address generation.
- `vclk` domain: timing counters, sprite scan/address generation, compositing, and collision detection.

Collision status/interrupt state generated in `vclk` is transferred into the `clk_i` domain for register visibility and top-level `irq` generation.

### 6.2 DMA Sequencer

The DMA path performs memory reads only (`m_we_o = 0`) and uses fixed cycle-type outputs (`m_bte_o = 2'b00`, `m_cti_o = 3'b000`).

Sequencing behavior:
- selects one pending sprite trigger at a time,
- starts from the sprite-programmed source base,
- transfers one cache image worth of data (4 KB) using 32-bit accesses,
- treats either `m_ack_i` or `m_err_i` as transfer completion for the current beat,
- clears the corresponding trigger bit when the request is accepted.

### 6.3 Dual-Port Sprite Cache Organization

Each sprite has a dedicated cache RAM instance:
- Port A (`vclk`) is the read port for display fetches.
- Port B (`clk_i`/DMA side) is used for programmed writes/reads and DMA writes.

RAM depth/width depends on color mode:
- 8-bit mode cache organization supports 4096 byte-addressed pixels per sprite.
- 16-bit mode cache organization supports 2048 halfword pixels per sprite.

### 6.4 Video Datapath and Control Coupling

The video datapath combines:
- per-sprite display-enable timing (`hSprDe`, `vSprDe`),
- pixel-scaling counters (`hSprPt`, `vSprPt`),
- sprite address generators (`sprAddr`, `sprAddrB`),
- active-sprite resolve (`sproact`),
- color conversion/blending,
- final mux to `rgbOut`.

Control-path decisions (enable bits, transparent color compare, priority classification, collision enables) directly govern when sprite pixels are visible and when collision states are latched.

## 7. Submodule List

### 7.1 `edge_det`

Role: edge detector used to derive one-cycle `hSync`/`vSync` positive-edge events for timing-counter resets.

| Port | Dir | Width | Description |
| --- | --- | --- | --- |
| `rst` | Input | 1 | Reset. |
| `clk` | Input | 1 | Sampling clock (`vclk` in this design). |
| `ce` | Input | 1 | Clock enable. |
| `i` | Input | 1 | Input signal to monitor. |
| `pe` | Output | 1 | Positive-edge pulse. |
| `ne` | Output | 1 | Negative-edge pulse. |
| `ee` | Output | 1 | Either-edge pulse. |

### 7.2 `rtfSpriteRam8`

Role: per-sprite dual-port cache RAM used when `pColorBits = 8`.

| Port | Dir | Width | Description |
| --- | --- | --- | --- |
| `clka` | Input | 1 | Display-side clock (`vclk`). |
| `adra` | Input | 12 | Display-side read address. |
| `doa` | Output | 8 | Display-side pixel data output. |
| `cea` | Input | 1 | Display-side enable. |
| `clkb` | Input | 1 | System-side clock (`~clk_i`). |
| `adrb` | Input | 10 | System-side word address. |
| `dib` | Input | 32 | System-side write data (programmed/DMA). |
| `dob` | Output | 32 | System-side read data. |
| `ceb` | Input | 1 | System-side enable. |
| `web` | Input | 1 | System-side write enable. |
| `rstb` | Input | 1 | System-side read/reset control. |

### 7.3 `rtfSpriteRam16`

Role: per-sprite dual-port cache RAM used when `pColorBits = 16`.

| Port | Dir | Width | Description |
| --- | --- | --- | --- |
| `clka` | Input | 1 | Display-side clock (`vclk`). |
| `adra` | Input | 11 | Display-side read address. |
| `doa` | Output | 16 | Display-side pixel data output. |
| `cea` | Input | 1 | Display-side enable. |
| `clkb` | Input | 1 | System-side clock (`~clk_i`). |
| `adrb` | Input | 10 | System-side word address. |
| `dib` | Input | 32 | System-side write data (programmed/DMA). |
| `dob` | Output | 32 | System-side read data. |
| `ceb` | Input | 1 | System-side enable. |
| `web` | Input | 1 | System-side write enable. |
| `rstb` | Input | 1 | System-side read/reset control. |

## 8. Clock and Reset

- Reset input: `rst_i` (active high).
- Functional clock domains:
  - `clk_i`: slave register/programmed-access domain,
  - `m_clk_i`: DMA master domain,
  - `vclk`: video processing and collision domain.

`hSync` and `vSync` are sampled in the `vclk` domain and define sprite coordinate references.

## 9. Constraints

- `pnSpr` supported values: `1, 2, 4, 6, 8, 14, 32`.
- `pColorBits` supported values: `8` or `16`.
- Per-sprite cache capacity constraints:
  - 8-bit mode: up to 4096 pixels per sprite image,
  - 16-bit mode: up to 2048 pixels per sprite image.
- To avoid cache wrap/repetition, configure sprite width-height products to fit the selected color mode cache capacity.
- DMA cache loading assumes 4 KB sprite-image alignment for each sprite source block.

Items requiring integration confirmation:
- The global high DMA address register (`0x3FC`) is architecturally defined but implementation support is not fully realized.
- Background-collision qualification policy must be aligned with system-level meaning of `rgbPriority` and background-color classification.
