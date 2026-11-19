# pci_bridge32 Design Specification

## 1. Introduction

`pci_bridge32` is a 32-bit PCI-to-WISHBONE bridge that connects a PCI local bus interface to separate WISHBONE slave and WISHBONE master interfaces. The design supports bidirectional bridging with independent operation of both traffic directions:

- WISHBONE-to-PCI path: WISHBONE slave side accepts local requests and issues PCI initiator transactions.
- PCI-to-WISHBONE path: PCI target side accepts PCI requests and issues WISHBONE master transactions.

The bridge implements image-based address mapping, configuration-space controlled behavior, FIFO-based decoupling across independent PCI and WISHBONE clocks, parity/error signaling, and reset/interrupt propagation logic.

The architecture supports both `HOST` and `GUEST` build profiles. In the current checked-in configuration (`pci_user_constants.v`), the default profile is `GUEST`.

## 2. Module Diagram

![PCI IO](figures/PCI%20IO.png)

![PCI Target Unit](figures/PCI%20target%20Unit.png)

![WB Slave Unit and Configuration Space](figures/WB%20slave%20Unit%20and%20Configuration%20space.png)

![SET and DELETE synchronization](figures/SET%20and%20DELETE%20synchronization.png)

## 3. Interface

### 3.1 WISHBONE System Signals

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `wb_clk_i` | Input | 1 | WISHBONE clock domain reference. |
| `wb_rst_i` | Input | 1 | WISHBONE reset input (used as bridge reset source in `HOST` profile). |
| `wb_rst_o` | Output | 1 | Reset output toward WISHBONE side (driven in `GUEST` profile from PCI reset and software-reset control). |
| `wb_int_i` | Input | 1 | Interrupt input from WISHBONE side (used for propagation in `GUEST` profile). |
| `wb_int_o` | Output | 1 | Interrupt output toward WISHBONE side (used for propagation in `HOST` profile). |

### 3.2 WISHBONE Slave Interface (`wbs_*`)

This interface receives local WISHBONE transactions that are bridged toward PCI.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `wbs_adr_i` | Input | 32 | WISHBONE slave address input. |
| `wbs_dat_i` | Input | 32 | WISHBONE slave write data input. |
| `wbs_dat_o` | Output | 32 | WISHBONE slave read data output. |
| `wbs_sel_i` | Input | 4 | Byte select input. |
| `wbs_cyc_i` | Input | 1 | Cycle qualifier input. |
| `wbs_stb_i` | Input | 1 | Strobe qualifier input. |
| `wbs_we_i` | Input | 1 | Write-enable input. |
| `wbs_ack_o` | Output | 1 | Transfer acknowledge output. |
| `wbs_rty_o` | Output | 1 | Retry response output. |
| `wbs_err_o` | Output | 1 | Error termination output. |

#### Cycle-Type Signals (Build-Dependent)

| Signal | Direction | Width | Condition | Description |
| --- | --- | --- | --- | --- |
| `wbs_cti_i` | Input | 3 | Present when `PCI_WB_REV_B3` is defined | WISHBONE B3 cycle type indicator. |
| `wbs_bte_i` | Input | 2 | Present when `PCI_WB_REV_B3` is defined | WISHBONE B3 burst type extension. |
| `wbs_cab_i` | Input | 1 | Present when `PCI_WB_REV_B3` is not defined | Classic/B2 consecutive-address burst indication. |

### 3.3 WISHBONE Master Interface (`wbm_*`)

This interface issues transactions to local WISHBONE targets for accesses originating on PCI.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `wbm_adr_o` | Output | 32 | WISHBONE master address output. |
| `wbm_dat_i` | Input | 32 | WISHBONE master read data input. |
| `wbm_dat_o` | Output | 32 | WISHBONE master write data output. |
| `wbm_sel_o` | Output | 4 | WISHBONE byte select output. |
| `wbm_cyc_o` | Output | 1 | Cycle qualifier output. |
| `wbm_stb_o` | Output | 1 | Strobe qualifier output. |
| `wbm_we_o` | Output | 1 | Write-enable output. |
| `wbm_cti_o` | Output | 3 | Cycle-type output. |
| `wbm_bte_o` | Output | 2 | Burst-type output. |
| `wbm_ack_i` | Input | 1 | Acknowledge input from WISHBONE target. |
| `wbm_rty_i` | Input | 1 | Retry input from WISHBONE target. |
| `wbm_err_i` | Input | 1 | Error input from WISHBONE target. |

### 3.4 PCI System and Arbitration Signals

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `pci_clk_i` | Input | 1 | PCI clock reference. |
| `pci_rst_i` | Input | 1 | PCI reset input (`RST#` semantics in RTL reset block). |
| `pci_rst_o` | Output | 1 | PCI reset drive value (held low when reset output enable is asserted). |
| `pci_rst_oe_o` | Output | 1 | PCI reset output enable control. |
| `pci_inta_i` | Input | 1 | PCI interrupt input (`INTA#`). |
| `pci_inta_o` | Output | 1 | PCI interrupt drive value (held low when output enable is asserted). |
| `pci_inta_oe_o` | Output | 1 | PCI interrupt output enable control. |
| `pci_req_o` | Output | 1 | PCI bus request output for initiator arbitration. |
| `pci_req_oe_o` | Output | 1 | Output enable for request signal drive. |
| `pci_gnt_i` | Input | 1 | PCI grant input from arbiter. |

### 3.5 PCI Protocol, Data, and Error Signals

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `pci_frame_i` | Input | 1 | PCI `FRAME#` input. |
| `pci_frame_o` | Output | 1 | PCI `FRAME#` output value. |
| `pci_frame_oe_o` | Output | 1 | Output enable for `FRAME#`. |
| `pci_irdy_i` | Input | 1 | PCI `IRDY#` input. |
| `pci_irdy_o` | Output | 1 | PCI `IRDY#` output value. |
| `pci_irdy_oe_o` | Output | 1 | Output enable for `IRDY#`. |
| `pci_idsel_i` | Input | 1 | PCI `IDSEL` input for configuration-target decode context. |
| `pci_devsel_i` | Input | 1 | PCI `DEVSEL#` input. |
| `pci_devsel_o` | Output | 1 | PCI `DEVSEL#` output value. |
| `pci_devsel_oe_o` | Output | 1 | Output enable for `DEVSEL#`. |
| `pci_trdy_i` | Input | 1 | PCI `TRDY#` input. |
| `pci_trdy_o` | Output | 1 | PCI `TRDY#` output value. |
| `pci_trdy_oe_o` | Output | 1 | Output enable for `TRDY#`. |
| `pci_stop_i` | Input | 1 | PCI `STOP#` input. |
| `pci_stop_o` | Output | 1 | PCI `STOP#` output value. |
| `pci_stop_oe_o` | Output | 1 | Output enable for `STOP#`. |
| `pci_ad_i` | Input | 32 | PCI multiplexed address/data bus input. |
| `pci_ad_o` | Output | 32 | PCI multiplexed address/data bus output value. |
| `pci_ad_oe_o` | Output | 32 | Per-bit output enable control for `AD` bus. |
| `pci_cbe_i` | Input | 4 | PCI command/byte enable input. |
| `pci_cbe_o` | Output | 4 | PCI command/byte enable output value. |
| `pci_cbe_oe_o` | Output | 4 | Output enable control for `CBE`. |
| `pci_par_i` | Input | 1 | PCI parity input. |
| `pci_par_o` | Output | 1 | PCI parity output value. |
| `pci_par_oe_o` | Output | 1 | Output enable for parity output. |
| `pci_perr_i` | Input | 1 | PCI parity error input (`PERR#`). |
| `pci_perr_o` | Output | 1 | PCI parity error output value. |
| `pci_perr_oe_o` | Output | 1 | Output enable for parity error output. |
| `pci_serr_o` | Output | 1 | PCI system error output value (`SERR#`). |
| `pci_serr_oe_o` | Output | 1 | Output enable for system error output. |

### 3.6 Optional Interface Ports

#### MBIST (present only when `PCI_BIST` is defined)

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `mbist_si_i` | Input | 1 | MBIST scan serial input. |
| `mbist_so_o` | Output | 1 | MBIST scan serial output. |
| `mbist_ctrl_i` | Input | `PCI_MBIST_CTRL_WIDTH` | MBIST chain control bus. |

#### CompactPCI Hot-Swap (present only when `PCI_CPCI_HS_IMPLEMENT` is defined)

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `pci_cpci_hs_enum_o` | Output | 1 | ENUM# output value (open-drain style usage). |
| `pci_cpci_hs_enum_oe_o` | Output | 1 | ENUM# output enable. |
| `pci_cpci_hs_led_o` | Output | 1 | LED output value (open-drain style usage). |
| `pci_cpci_hs_led_oe_o` | Output | 1 | LED output enable. |
| `pci_cpci_hs_es_i` | Input | 1 | Ejector-switch state input. |

#### SPOCI (present only when `PCI_SPOCI` is defined)

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `spoci_scl_o` | Output | 1 | SPOCI clock output value. |
| `spoci_scl_oe_o` | Output | 1 | SPOCI clock output enable. |
| `spoci_sda_i` | Input | 1 | SPOCI data input. |
| `spoci_sda_o` | Output | 1 | SPOCI data output value. |
| `spoci_sda_oe_o` | Output | 1 | SPOCI data output enable. |

## 4. Function Description

### 4.1 High-Level Operation

The core bridges PCI and WISHBONE through two independent transaction engines:

- The **WISHBONE slave unit** accepts requests on `wbs_*`, performs decode and policy checks, and drives PCI master-side request/command generation.
- The **PCI target unit** accepts PCI target traffic, performs image and command checks, and issues WISHBONE master transactions on `wbm_*`.

Both directions can operate concurrently, with coordination for ordering and delayed-transaction completion status.

### 4.2 Supported Transaction Classes

The bridge supports PCI memory, I/O, configuration, and interrupt-acknowledge classes as documented for the core feature set. Transaction acceptance and completion behavior are controlled by image configuration, command-type enable settings, and run-time status.

Burst transfers are supported with linear burst ordering support. For accesses that require deferred completion behavior, the bridge uses delayed-read handling and posted-write mechanisms according to configured policy.

### 4.3 Image-Based Address Mapping and Configuration Space Control

Address translation and access qualification are image-based on both directions:

- PCI-originated accesses are matched to configured PCI images and mapped to WISHBONE address regions.
- WISHBONE-originated accesses are matched to configured WISHBONE images and mapped to PCI address regions.

Configuration space exposes control/state for:

- Image base/mask/translation registers.
- Image memory-vs-I/O mapping.
- Command behavior control bits.
- Error and interrupt reporting/status.
- Initialization and software-reset related controls.

### 4.4 WB B3 / Classic Adaptation

When `PCI_WB_REV_B3` is enabled (default in current constants), an internal wrapper converts incoming WISHBONE B3 cycle information (`CTI/BTE`) into the bridge’s internal CAB-style sequencing context. This preserves burst intent while interfacing to internal logic designed around classic burst-control semantics.

### 4.5 FIFO and Cross-Clock Decoupling

The PCI and WISHBONE clocks are independent. The bridge uses direction-specific FIFOs and synchronization logic to decouple the domains and carry request/data/completion information across domains.

Synchronization logic coordinates request-set and completion-delete style events so each side observes consistent transaction state before issuing or completing related operations.

### 4.6 Parity, Error, and Interrupt Behavior

Parity generation/checking logic supervises relevant PCI address/data and command phases and can assert parity/system error signaling outputs when enabled through configuration controls.

Error status from both directions is captured and exposed through configuration/status paths. WISHBONE-facing responses (`ack`, `rty`, `err`) reflect bridge-internal completion status for translated transactions.

Interrupt propagation is profile-dependent:

- In `HOST`, PCI interrupt observation can be reflected toward WISHBONE interrupt signaling.
- In `GUEST`, WISHBONE interrupt input can be propagated toward PCI interrupt signaling.

### 4.7 Reset Behavior by Profile

Reset source and propagation are profile-dependent and controlled in `pci_rst_int`:

- `HOST`: WISHBONE reset input is the primary bridge reset source and can drive PCI reset signaling.
- `GUEST` (current default): PCI reset input (`RST#` style) is the primary bridge reset source and can drive WISHBONE reset output.

Software reset control from configuration space participates in reset propagation logic.

## 5. Implementation Details

### 5.1 Top-Level Block Composition

`pci_bridge32` integrates the following major blocks:

- `pci_wb_slave_unit`: WISHBONE-slave front end for WB→PCI path, including request qualification, control-path generation, and WB response generation.
- `pci_target_unit`: PCI-target front end for PCI→WB path, including PCI target protocol handling and WISHBONE master transaction generation.
- `pci_conf_space`: shared configuration/status subsystem for image registers, control bits, interrupt and error status, and initialization controls.
- `pci_io_mux`: arbitration/mux layer for PCI output drive values and enables across master/target/parity/error sources.
- `pci_cur_out_reg` and `pci_in_reg`: registered PCI output backup and input sampling stages.
- `pci_parity_check`: parity generation/checking and PERR/SERR control.
- `pci_rst_int`: reset/interrupt direction handling across `HOST`/`GUEST` profiles.
- `pci_wbs_wbb3_2_wbb2`: optional WISHBONE B3-to-internal classic adaptation wrapper when B3 mode is enabled.

### 5.2 Control/Data Relationships

- WB→PCI side control outputs from `pci_wb_slave_unit` feed PCI I/O drive selection and arbitration request handling.
- PCI→WB side control/data outputs from `pci_target_unit` directly drive `wbm_*` outputs.
- Configuration-space outputs (image maps, masks, translation values, enable bits) feed both direction units.
- Parity/status outputs feed both PCI I/O muxing and configuration/status capture.

### 5.3 Profile-Dependent Integration

Top-level wiring selects configuration read/write ownership and reset/interrupt propagation based on compile-time profile:

- `HOST` routes configuration write path primarily from WISHBONE side and read path from PCI side.
- `GUEST` routes configuration write path primarily from PCI side and read path from WISHBONE side.

Current checked-in constants define `GUEST`, `NO_CNF_IMAGE`, and `PCI_WB_REV_B3`.

## 6. Submodule List

### 6.1 `pci_wb_slave_unit`

Role: Accepts local WISHBONE slave requests and initiates corresponding PCI master transactions.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `ADDR_I`, `SDATA_I`, `SEL_I`, `CYC_I`, `STB_I`, `WE_I` | Input | 32/32/4/1/1/1 | WISHBONE slave request inputs. |
| `SDATA_O`, `ACK_O`, `RTY_O`, `ERR_O` | Output | 32/1/1/1 | WISHBONE slave response outputs. |
| `wbu_pciif_req_out` | Output | 1 | PCI bus request generation output. |
| `wbu_pciif_frame_out`, `wbu_pciif_irdy_out`, `wbu_pciif_ad_out`, `wbu_pciif_cbe_out` | Output | control/data | PCI master command/data driving context. |
| `wbu_conf_*` | Output | mixed | Configuration-space access and write data/control outputs. |

### 6.2 `pci_target_unit`

Role: Accepts PCI target transactions and issues WISHBONE master transactions.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `pciu_pciif_*_in` | Input | mixed | PCI observed protocol/data/control signals. |
| `pciu_wbm_adr_o`, `pciu_wbm_dat_o`, `pciu_wbm_sel_o`, `pciu_wbm_cyc_o`, `pciu_wbm_stb_o`, `pciu_wbm_we_o` | Output | mixed | WISHBONE master transaction outputs. |
| `pciu_wbm_dat_i`, `pciu_wbm_ack_i`, `pciu_wbm_rty_i`, `pciu_wbm_err_i` | Input | mixed | WISHBONE master completion/data inputs. |
| `pciu_conf_*` | Output | mixed | Configuration-space access outputs from target path. |
| `pciu_err_*` | Output | mixed | Captured transaction error details for status reporting. |

### 6.3 `pci_conf_space`

Role: Holds bridge configuration/status registers for both traffic directions.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `w_conf_*`, `r_conf_*` | Input/Output | mixed | Configuration read/write interfaces from active control side(s). |
| `pci_*_out`, `wb_*_out` | Output | mixed | Image base/mask/translation and control outputs for PCI and WB directions. |
| `*_error_*` | Input | mixed | Error details captured from both bridge directions. |
| `int_out`, `icr_soft_res` | Output | 1 | Interrupt control/status and software-reset control outputs. |

### 6.4 `pci_io_mux`

Role: Selects and drives PCI output data/control/enable signals among initiator, target, and parity/error sources.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `frame_*`, `irdy_*`, `devsel_*`, `trdy_*`, `stop_*` | Input/Output | control | PCI control signal value and output-enable selection. |
| `mas_ad_*`, `tar_ad_*`, `ad_*`, `cbe_*` | Input/Output | data/control | PCI AD/CBE value and enable multiplexing. |
| `par_*`, `perr_*`, `serr_*`, `req_*` | Input/Output | control | Error/parity/request signal drive and enable multiplexing. |

### 6.5 `pci_parity_check`

Role: Generates and checks PCI parity and drives parity/system-error indications when enabled.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `pci_par_in`, `pci_perr_in`, protocol/data/context inputs | Input | mixed | Observed bus/parity context for checking. |
| `pci_par_out`, `pci_par_en_out`, `pci_perr_out`, `pci_perr_en_out`, `pci_serr_out`, `pci_serr_en_out` | Output | control | Driven parity/error values and enables. |
| `par_err_detect_out`, `perr_mas_detect_out`, `sig_serr_out` | Output | 1 | Internal parity/system-error detection indications. |

### 6.6 `pci_rst_int`

Role: Implements profile-dependent reset and interrupt routing between PCI and WISHBONE domains.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `rst_i`, `pci_rstn_in`, `conf_soft_res_in` | Input | 1 | Reset and software-reset control inputs. |
| `reset`, `rst_o`, `pci_rstn_out`, `pci_rstn_en_out` | Output | 1 | Internal and propagated reset outputs. |
| `pci_intan_in`, `conf_int_in`, `int_i` | Input | 1 | Interrupt source/status inputs. |
| `pci_intan_out`, `pci_intan_en_out`, `int_o`, `conf_isr_int_prop_out` | Output | 1 | Interrupt propagation and status outputs. |

### 6.7 `pci_wbs_wbb3_2_wbb2` (when `PCI_WB_REV_B3` is enabled)

Role: Converts WISHBONE B3 slave cycles into internal classic/CAB-style control sequencing used by bridge internals.

| Signal | Direction | Width | Description |
| --- | --- | --- | --- |
| `wbs_cti_i`, `wbs_bte_i` | Input | 3 / 2 | B3 burst type/cycle information. |
| `wbs_cab_o` | Output | 1 | Converted consecutive-address burst indication. |
| `wbs_*_i` / `wbs_*_o` | Input/Output | mixed | Wrapped slave request/response path signals. |

## 7. Clock and Reset

- The design uses two independent clocks:
- `wb_clk_i` for WISHBONE-side logic.
- `pci_clk_i` for PCI-side logic.
- Cross-domain interactions are buffered and synchronized through FIFO/synchronization submodules.
- The bridge reset source is profile-dependent:
- `HOST`: reset derived from `wb_rst_i`.
- `GUEST` (default): reset derived from `pci_rst_i` (`RST#` style input behavior in reset block).
- `wb_rst_o`, `pci_rst_o`, and `pci_rst_oe_o` are generated by reset/interrupt control logic and should be interpreted together during integration.

## 8. Constraints

- Current checked-in profile defaults:
- `GUEST` is enabled.
- `NO_CNF_IMAGE` is enabled.
- `PCI_WB_REV_B3` is enabled.
- `WB_IMAGE2` is enabled; additional WB/PCI images are optional by compile-time constants.
- `ACTIVE_LOW_OE` is enabled for PCI output-enable polarity.
- Optional interfaces (`PCI_BIST`, `PCI_CPCI_HS_IMPLEMENT`, `PCI_SPOCI`) are conditional and absent unless explicitly enabled.
- Image mapping, command behavior, parity/error response, and interrupt generation depend on configuration-space register programming.
- Integration must ensure that external PCI tri-state buffers and output-enable polarity match the selected build constants.
