# RF Screen Development: Single-Step Reservation to WM Transfer

This directory contains the production-ready custom SAP RF (Radio Frequency) barcode scanning application for warehouse mobile handheld terminals (Zebra, Honeywell, Datalogic) running **ITSmobile**, **WebGUI**, or **SAP GUI / SAP Console**.

---

## 🚀 Active Transaction Codes in SAP DS4/220

| Transaction Code | Short Code | Program Name | Initial Screen | Description | WebGUI / ITSmobile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ZRF_RESWM`** | **`ZRF01`** | `SAPMZRF_RES_WM_TRANSFER` | `0100` | RF Reservation to WM Transfer | **Enabled** (`S_WEBGUI = '1'`, `S_WIN32 = 'X'`) |

---

## 🌐 Quick WebGUI & Mobile ITSmobile Links

| Launch Mode | Target URL | Description |
| :--- | :--- | :--- |
| **Direct WebGUI (`ZRF_RESWM`)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZRF_RESWM`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZRF_RESWM) | Primary RF reservation-to-WM scanner on Client 220 |
| **Direct WebGUI (`ZRF_RESWM` NARESH)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZRF_RESWM`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZRF_RESWM) | Pre-fills SAP user `NARESH` |
| **Mobile Short Code (`ZRF01`)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZRF01`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZRF01) | Handheld RF gun short transaction |
| **SAP Fiori Launchpad (FLP)** | [`https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#RFTransfer-manage`](https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#RFTransfer-manage) | Launches inside Fiori Launchpad shell via intent `#RFTransfer-manage` |
| **Interactive Web Cockpit & QR** | [`launch_rf_reswm_webgui.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/launch_rf_reswm_webgui.html) | Interactive URL builder, one-click launcher, and QR Code scanner for Zebra/Honeywell |

### 💻 Desktop Shortcuts Included:
- **macOS Users:** Double-click [`ZRF_RESWM_WebGUI.webloc`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/ZRF_RESWM_WebGUI.webloc) or [`ZRF01_Mobile_WebGUI.webloc`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/ZRF01_Mobile_WebGUI.webloc) directly in Finder.
- **Windows Users:** Double-click [`ZRF_RESWM_WebGUI.url`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/ZRF_RESWM_WebGUI.url) or [`ZRF01_Mobile_WebGUI.url`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/ZRF01_Mobile_WebGUI.url).

---

- **Primary TCODE**: `ZRF_RESWM`
- **Short TCODE**: `ZRF01` (Quick entry for handheld virtual keyboards)
- **Target System**: SAP S/4HANA (DS4/220)
- **Target Program**: `SAPMZRF_RES_WM_TRANSFER`
- **Backend Class**: `ZCL_RF_AUTO_WM_IM_TRANSFER`
- **TCODE Deployer**: `ZCREATE_TCODE_ZRF_RESWM`

---

## 📁 Repository Structure

```text
RF Screen Development/
├── src/                                  # ABAP Source Code
│   ├── zcl_rf_auto_wm_im_transfer.clas.abap  # Backend Controller Class (LUW, BAPIs, Validation)
│   ├── zrf_res_wm_transfer.prog.abap         # Main Self-Contained Module Pool Program
│   ├── zcreate_tcode_zrf_reswm.prog.abap     # Automated TCODE Generator (TSTC / TSTCT / TSTCC)
│   ├── zrf_reservation_badi.abap             # Auto-TR BAdI Enhancement (MB_RESERVATION_BADI)
│   ├── zrf_res_wm_transfer_top.abap          # Modular TOP Include (reference)
│   ├── zrf_res_wm_transfer_o01.abap          # Modular PBO Include (reference)
│   ├── zrf_res_wm_transfer_i01.abap          # Modular PAI Include (reference)
│   └── zrf_res_wm_transfer_f01.abap          # Modular Forms Include (reference)
├── screens/                              # Dynpro Layout Specifications
│   ├── screen_0100.txt                       # Initial Scan Screen (Warehouse & Doc Scan)
│   └── screen_0200.txt                       # Picking & Verification Screen (HU, Batch, Serials)
├── templates/                            # ITSmobile HTML5 Templates
│   ├── itsp_screen_0100.html                 # Mobile-responsive HTML template for Dynpro 0100
│   └── itsp_screen_0200.html                 # Mobile-responsive HTML template for Dynpro 0200
├── deploy/                               # Automated Deployment Pipeline
│   └── deploy_rf_program.cjs                 # ADT Node.js deployment script for DS4/220
└── docs/                                 # Architectural Specifications
    └── TECHNICAL_SPECIFICATION.md            # Comprehensive end-to-end technical documentation
```

---

## 🔑 Key Features & Architecture

1. **Atomic LUW Synchronization**:
   - Executes IM Goods Movement (`BAPI_GOODSMVT_CREATE`) and LE-WM Transfer Order confirmation (`L_TO_CREATE_TR` / `L_TO_CREATE_SINGLE` with `squit = 'X'`).
   - If TO creation fails, compensatory rollback (`BAPI_GOODSMVT_CANCEL`) is automatically triggered, preventing orphan stock in interim storage types (`9xx`).

2. **Full Traceability & HU Validation**:
   - Scans External Handling Unit (`EXIDV`).
   - Validates storage location, batch (`MCHB`), serial numbers (`SER06` + `OBJK`), and available WM quant (`LQUA`).

3. **Auto-TR Generation**:
   - Automatically generates a Transfer Requirement on the fly via `L_TR_CREATE` if the reservation did not create a TR.

4. **Multi-Form Factor UI**:
   - Designed for 16x20 and 8x40 character displays as well as modern HTML5 touchscreen browsers.

---

## 🛠 Deployment & Execution

To deploy or refresh the objects on SAP DS4/220:

**From Repository Root (`SAPHANA/`):**
```bash
node deploy/deploy_rf_program.cjs
# or
node "RF Screen Development/deploy/deploy_rf_program.cjs"
```

**From `RF Screen Development/` directory:**
```bash
cd "RF Screen Development"
node deploy/deploy_rf_program.cjs
```

---

## 💡 Troubleshooting & Architecture Notes

### Resolution: "Status STATUS_0100 of the user interface SAPMZRF_RES_WM_TRANSFER missing (Message No. 00264)"
- **Root Cause**: 
  In PBO modules `status_0100` and `status_0200`, `SET PF-STATUS 'STATUS_0100'` / `'STATUS_0200'` and `SET TITLEBAR` were called without a compiled Menu Painter GUI status in table `D344L` / `RSMPTEXTS`, triggering SAP kernel termination with error 00264.
- **Fix Applied**:
  1. **Safe Dynamic Guarding in PBO**: In `SAPMZRF_RES_WM_TRANSFER`, guarded `SET PF-STATUS` and `SET TITLEBAR` by querying `D344L` and `RSMPTEXTS` (`WHERE progname = @sy-repid`). If the CUA status or title is not yet compiled, the screen defaults cleanly to standard SAP GUI navigation without halting.
  2. **Universal Enter Key Support in PAI**: In `MODULE user_command_0100 INPUT` and `user_command_0200 INPUT`, added support for `WHEN c_fcode_enter OR space OR '/00'`, so pressing the `[Enter]` key, scanner gun trigger, or clicking the green checkmark executes the search and validation immediately.
  3. **On-Screen Touch Action Buttons**: Replaced passive text labels with real interactive pushbuttons on Dynpro 0100 (`[Process [Enter]]`, `[Exit [F3]]`) and Dynpro 0200 (`[Post]`, `[Prev]`, `[Next]`, `[Back]`, `[Serials]`, `[Stock Bins]`), making the screen fully operational on barcode scanner touchscreens, SAP GUI, and ITSmobile web browsers.

### Resolution: "Invalid field format (dynpro error)"
- **Root Cause**:
  In Dynpro 0200, numeric quantity fields were bound to `TYPE menge_d` (`p decimals 3`) while the screen template contained underscore fill masks (`_____________`). SAP GUI's dynpro processor fails packed decimal conversion when input text contains trailing underscores.
- **Fix Applied**:
  1. Converted screen exchange structure `ty_scr0200` to format numbers as `CHAR` types (`post_qty TYPE char13`, `target_qty TYPE char13`, `open_qty TYPE char13`, `item_curr TYPE char4`, `item_total TYPE char4`).
  2. Set `text = space` on all template input fields in `add_template_field` within `ZCREATE_TCODE_ZRF_RESWM`.
  3. Performed explicit numeric sanitization and decimal comma/dot normalization in ABAP PAI `execute_posting`.

### Resolution: "HU Goods Movement Failed (Code 1)"
- **Root Cause**:
  In standard SAP HUM function module `HU_CREATE_GOODS_MOVEMENT`, the exporting parameter `ef_posted` returns `1` when real posting succeeds (`0` in simulation mode, `2` on error) and populates `es_emkpf-mblnr`. In `ZCL_RF_AUTO_WM_IM_TRANSFER`, the success condition was hardcoded to `IF ef_posted = 0 AND es_emkpf-mblnr IS NOT INITIAL`. When real posting succeeded, `ef_posted` was `1`, which bypassed the success block and fell into the error fallback string: `HU Goods Movement Failed (Code { ef_posted })` (`Code 1`), even though the material document was actually created in `MSEG`.
- **Fix Applied**:
  Updated the check in `ZCL_RF_AUTO_WM_IM_TRANSFER` line 846 to:
  ```abap
  " In HU_CREATE_GOODS_MOVEMENT: ef_posted = 1 means posted, 0 = simulated, 2 = error
  IF es_emkpf-mblnr IS NOT INITIAL AND ( ef_posted = 1 OR ef_posted = 0 ).
  ```
  The screen now recognizes the posting as successful, displays `Success: MIGO <doc> Posted for HU <hu>`, updates open requirements, and clears the scanned HU for subsequent scanning.

---

## 📦 Multi-HU & Storage Unit (SU) Fulfillment Architecture

1. **Dual Lookup (HU & SU)**:
   - When a barcode is scanned, [ZCL_RF_AUTO_WM_IM_TRANSFER](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/src/zcl_rf_auto_wm_im_transfer.clas.abap) first checks `VEKP`/`VEPO` (Handling Unit). If not found, it checks `LQUA` for Storage Unit (`LENUM`).
2. **Automatic Quantity Fetching & Capping**:
   - The quantity packed in the scanned HU/SU is automatically retrieved and placed into `Qty`.
   - If the scanned quantity exceeds the remaining open requirement (`open_qty`), the default `Qty` is capped to `open_qty`.
   - Posting more than `open_qty` or more than the available quantity in the HU/SU is strictly blocked.
3. **Multi-Step Fulfillment**:
   - For items requiring multiple smaller HUs or SUs, posting a partial quantity decreases `open_qty` and updates the display (`Req: X.XXX Open: Y.YYY`).
   - The scanned HU and Qty fields clear automatically, and the cursor returns to `Scan HU :` with the prompt: `Posted X.XXX. Open: Y.YYY. Scan next HU/SU.`.
   - Once `open_qty` reaches 0, the item status becomes complete (`C`), and the screen advances to the next reservation/TR item.
4. **Barcode Gun Double-Enter Support**:
   - **Scan 1**: Operator scans HU/SU barcode (or presses Enter) -> Validates HU/SU and auto-populates `Qty`.
   - **Scan 2 / Enter**: Pressing Enter a second time on the confirmed quantity automatically posts the transfer (or click `[Post]`).

---

## 🚀 Post Button & Requirement Navigation Logic

### 1. Post Button Execution & HU Movement Support
- **Direct Post Click**: Clicking `[Post]` immediately after scanning an HU (without hitting Enter first) automatically validates the HU, determines the appropriate quantity capped to `open_qty`, and posts in a single step.
- **HU Storage Location Transfer (HUM Integration)**:
  - Movement type 311 from an HU-managed storage location (e.g. `CS02`, `XHUPF = 'X'`) routes goods movement to standard SAP HUM function module `HU_CREATE_GOODS_MOVEMENT`.
  - **Event Code**: Uses `if_event = '0006'` (311 Transfer Posting Storage Location).
  - **HU Number Format**: Preserves full external HU ID with leading zeros intact (e.g., `00000000002000020328`) as stored in `VEKP-EXIDV`.
  - **Diagnostic Error Handling**: Imports both `es_message` and `et_messages` to extract genuine SAP diagnostic messages (e.g., `L9 042` / `L9 610`) rather than returning generic fallback messages.
  - **Warehouse Management Rule (SAP Note 1594558)**:
    Within the same warehouse (`W01`), direct 1-step transfer posting (311) between an HU-managed location (`CS02`) and a non-HU location (`CIS1`) is strictly restricted by SAP standard WM design (`L9 610` / `L9 042: Storage type OH1 not suitable as an interface`). Transfers from HU storage locations must target either an HU-managed location (e.g., `FG01`, `RA01`, `RJ01`) or the configured IM partner storage location (`HU01`).
- **UI Event Dispatch**: `user_command_0100` and `user_command_0200` capture `sy-ucomm` from screen pushbutton clicks (`save_ok = sy-ucomm. IF save_ok IS INITIAL. save_ok = ok_code. ENDIF.`), ensuring immediate execution when clicking `[Post]`.

### 3. "Successfully Completed Transaction" Status Confirmation
- **Prompt & Status Line Synchronization**:
  - On successful posting of a transfer (via MIGO or Transfer Order), the transaction emits an immediate confirmation message:
    ```abap
    MESSAGE s000(00) WITH |Successfully completed transaction! MIGO: { lv_mblnr_str } posted.|.
    ```
    This prints prominently in the standard SAP GUI status bar (bottom of the screen).
  - Simultaneously, the RF scanner status text field (`G_SCR0200-STATUS_MSG`) displays:
    - If all items complete: `'Successfully completed transaction!'`
    - If other open items remain: `'Successfully completed! Next: <item>'`
    - If partial quantity remains on the current item: `'Successfully completed! Rem: <qty>'`
  - Fixed PAI execution flow so automatic item navigation (`navigate_next_item`) preserves the `Successfully completed` message rather than immediately overwriting it with `Item loaded`.

### 4. Strict "Only Open Reservation or TR" Document Enforcement
- **Screen 0100 Document Validation**:
  - Scanning or typing a closed/completed reservation or TR is immediately blocked on Screen 0100.
  - The screen remains on 0100 and displays:
    ```
    Only open RES allowed. Doc is closed.
    ```
    (or `Reservation <doc> is already closed/completed` / `No open items found for TR <doc>`), accompanied by a status bar error (`DISPLAY LIKE 'E'`).
- **Database Fulfillment Synchronization (`RESB`, `LTBP`, & `LTBK`)**:
  - Standard SAP `HU_CREATE_GOODS_MOVEMENT` does not automatically update Reservation (`RESB`) or Transfer Requirement (`LTBP`/`LTBK`) tables.
  - In [ZCL_RF_AUTO_WM_IM_TRANSFER](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/src/zcl_rf_auto_wm_im_transfer.clas.abap), explicit database synchronization is now performed atomically before `COMMIT WORK AND WAIT`:
    - **Reservations**: Increments `RESB-ENMNG` by the posted quantity. If `enmng >= bdmng`, automatically sets `RESB-KZEAR = 'X'` (Final Issue Indicator).
    - **Transfer Requirement Items (`LTBP`)**: Increments `LTBP-TAMEN` by the posted quantity. If `tamen >= menge`, automatically sets `LTBP-ELIKZ = 'X'` (Delivery Completed Indicator), `LTBP-TDATU = sy-datum`, and `LTBP-TZEIT = sy-uzeit`.
    - **Transfer Requirement Header (`LTBK`)**: When all items are complete (`LTBP-ELIKZ = 'X'`), automatically updates `LTBK-STATU = 'E'` (Processing Complete / Endgeliefert), attaches the material document reference (`LTBK-MBLNR = mblnr`, `LTBK-MJAHR = mjahr`), and sets `LTBK-PDATU = sy-datum`, `LTBK-PZEIT = sy-uzeit`.
  - This ensures that once a reservation or TR item is fully transferred, SAP and the RF transaction immediately recognize it as closed, preventing double-posting or re-opening of fulfilled documents.

### 5. Automatic Transfer Requirement (TR) Header & Item Closure (`LTBK` / `LTBP`)
- **LE-WM Reporting Mechanism (`LB10`, `LB11`, `LB12`, `LB13`)**:
  - In SAP LE-WM, transactions `LB10` (TR per Storage Type), `LB11` (TR per Material), `LB12` (TR per Material Document), and `LB13` (TR per Requirement Number) check the header status `LTBK-STATU` (Domain `MLLVSKON`):
    - `space` / `null` = Open (`CON_OFFEN`)
    - `'T'` = Partially Delivered (`CON_TEILGELIEFERT`)
    - `'E'` = Processing Complete (`CON_ENDGELIEFERT`)
  - If only `LTBP-ELIKZ = 'X'` is set without updating `LTBK-STATU = 'E'`, LE-WM transaction reports continue to treat the TR as **Open**, causing operators to see unfulfilled TR lists even though MMBE and LX02 stock were already transferred.
- **Automated Closure Implementation (`update_reservation_and_tr`)**:
  - In method `update_reservation_and_tr` within [ZCL_RF_AUTO_WM_IM_TRANSFER](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/src/zcl_rf_auto_wm_im_transfer.clas.abap):
    1. **Identifies Linked TRs**: Cross-references `LTBK` and `LTBP` where `k~rsnum = @lv_rsnum` or `( k~betyp = 'P' AND k~benum = @lv_rsnum )` with leading zeros preserved.
    2. **Item Status Update**: Updates `LTBP-TAMEN = TAMEN + PostQty`, `LTBP-ELIKZ = 'X'`, `LTBP-TDATU = sy-datum`, `LTBP-TZEIT = sy-uzeit`.
    3. **Remaining Open Items Check**: Queries `SELECT COUNT(*) FROM LTBP WHERE lgnum = @lgnum AND tbnum = @tbnum AND elikz = space`.
    4. **Header Closure**:
       - If `remaining_open = 0`: Sets `LTBK-STATU = 'E'` (Processing Complete), `LTBK-MBLNR = mblnr`, `LTBK-MJAHR = mjahr`, `LTBK-PDATU = sy-datum`, `LTBK-PZEIT = sy-uzeit`.
       - If `remaining_open > 0`: Sets `LTBK-STATU = 'T'` (Partially Delivered).
- **Historical Reconciliation**:
  - Class `ZCL_RF_AUTO_WM_IM_TRANSFER` implements `if_oo_adt_classrun`. Running the class directly via ADT or SE24/SE38 auto-reconciles any historical TRs whose items are already fulfilled, marking `LTBK-STATU = 'E'` and clearing them from `LB10`/`LB13`. TR `0001000878` and TR `0001000879` in Warehouse `W01` were verified and marked `'E'` with material document reference `4900050268`.

### 6. Automatic Bin & Storage Type Update in LE-WM (`LX02` / `LQUA`)
- **Root Cause of Unchanged Bin in `LX02`**:
  - In Handling Unit transfer postings (`XHUPF = 'X'`), standard function module `HU_CREATE_GOODS_MOVEMENT` posts the Inventory Management (IM) 311 transfer document (`MBLNR`).
  - Previously, after posting IM and updating the reservation/TR, the method executed an immediate `RETURN`, bypassing **Step B: LE-WM Transfer Order Creation & Auto-Confirmation**.
  - While IM updated `LQUA-LGORT` to the receiving Storage Location, `LQUA-LGTYP` (Storage Type) and `LQUA-LGPLA` (Storage Bin) remained unchanged at the source bin (e.g. `EN1 / 1-L0001-04`). Consequently, report `LX02` (Stock Overview per Storage Bin) showed the stock in the new storage location but still sitting in the old bin and old storage type!
- **Automated Putaway Destination Strategy (`determine_destination_bin`)**:
  - Implemented dynamic destination bin determination in method `determine_destination_bin` within [ZCL_RF_AUTO_WM_IM_TRANSFER](file:///Users/naresh/Documents/Github%20Development/SAPHANA/RF%20Screen%20Development/src/zcl_rf_auto_wm_im_transfer.clas.abap):
    1. **Fixed Bin Check (`MLGT`)**: Inspects table `MLGT` for any material-specific fixed storage bin defined in warehouse `W01`. If found and active in `LAGP` (`SKZUE = space`), it is selected as the primary target.
    2. **Receiving Storage Location Mapping (`T320` / `LAGP`)**:
       - `OH01` / `OH02` (On-Hold Storage) $\rightarrow$ Storage Type **`OH1`** (Bin: **`ONHOLD`**)
       - `CS01` (Raw Materials) $\rightarrow$ Storage Type **`RM1`** (Selected from 1,599 active bins in `LAGP`)
       - `CS02` / `HS01` / `MT01` / `MT02` / `CIS1` (Engineering / Returns) $\rightarrow$ Storage Type **`EN1`** (20 active bins in `LAGP`)
       - `GS01` (Green Stage) $\rightarrow$ Storage Type **`GS1`** (Bins: `0002000589`, `TRANSFER`)
       - `FG01` (Finished Goods) $\rightarrow$ Storage Type **`100`** / **`EN1`** / **`OH1`**
       - Fallback: Scans active quants in `LQUA` for the destination SLoc to match configured operational storage types, or defaults to interim `921 / TRANSFER`.
    3. **Unblocked Available Bin Selection (`LAGP`)**: Queries `LAGP` to pick the first unblocked bin (`SKZUE = space`, `SKZUA = space`) that is **different from the source bin** (`( lgtyp <> source_lgtyp OR lgpla <> source_lgpla )`), guaranteeing physical movement in the warehouse.
- **Transfer Order Execution & Auto-Confirmation (`L_TO_CREATE_MOVE_SU` / `L_TO_CREATE_SINGLE`)**:
  - Immediately following IM goods movement, the class invokes:
    - **Storage Unit / HU Transfers**: Calls `L_TO_CREATE_MOVE_SU` passing `i_lenum = lenum`, movement type `i_bwlvs = '999'`, explicit destination `i_nltyp` and `i_nlpla`, and auto-confirmation `i_squit = 'X'`, `i_commit_work = 'X'`.
    - **Non-SU Material Transfers**: Calls `L_TO_CREATE_SINGLE` with source bin (`VLTYP`, `VLPLA`) and resolved destination bin (`NLTYP`, `NLPLA`), auto-confirming immediately (`I_SQUIT = 'X'`).
- **Real-Time RF Screen Feedback**:
  - Screen 0200 status message and the SAP GUI message bar now display the exact destination storage type, bin, and Transfer Order:
    ```
    Success! Bin: EN1/0-L0001-01 Next: 0001
    MIGO: 4900050269 TO: 0001037366 posted.
    ```
- **Live Verification on SAP DS4/220**:
  - Storage Unit `00000000002000020327` (Material `000000008000009754`) was tested in Warehouse `W01`:
    - **Before**: `LQUA` quant was at `EN1 / 1-L0001-04`.
    - **TO Created**: Transfer Order `0001037366` created and confirmed automatically.
    - **After**: `LQUA` quant and `LX02` stock overview immediately updated to destination Storage Type **`EN1`**, Storage Bin **`0-L0001-01`**.

### 7. Dynamic Scanning Scenarios: Serial-Managed vs. Batch-Managed Materials
- **Business Requirement**:
  - **Serial-Managed Materials**: Handheld terminal scanning must strictly be of **Handling Unit (HU)** or **Storage Unit (SU)** numbers containing serial items.
  - **Batch-Managed Materials (Non-Serialized)**: Store team scans the physical **Batch Number** barcode directly from the item.
- **Dynamic Detection & Validation Architecture**:
  1. **Automatic Material Classification (`get_document_details`)**:
     - Serial Managed: `MARC-SERNP IS NOT INITIAL` $\rightarrow$ `is_serialized = abap_true`.
     - Batch Managed: `MARC-XCHPF = 'X'` or `MARA-XCHPF = 'X'` $\rightarrow$ `is_batch_managed = abap_true`.
  2. **Adaptive Dynpro 0200 UI**:
     - Dynamic Scan Label (`G_SCR0200-SCAN_LBL`) automatically toggles:
       - Serial Materials: Displays `Scan HU/SU:`
       - Batch Materials: Displays `Scan Batch:`
     - Contextual Operator Guidance:
       - Serial Materials: Prompt displays `Serial material: Scan HU or SU barcode`.
       - Batch Materials: Prompt displays `Batch material: Scan Batch number`.
  3. **Verification Logic (`validate_hu_and_stock`)**:
     - **Serial Materials (Scenario A)**:
       - Must match a valid Handling Unit in `VEKP` or Storage Unit in `LQUA`.
       - Scanned plain batch numbers are rejected with: `Serial material: Scan valid HU or SU. '<scan>' not found.`
       - Serials are retrieved via `SER06` / `OBJK` for traceability.
     - **Batch Materials (Scenario B)**:
       - User scans the batch barcode (`CHARG`).
       - Validates batch master record in `MCHA` / `MCH1`.
       - Verifies unrestricted stock availability in `MCHB-CLABS`.
       - Locates active quants in `LQUA` (`LGNUM = lgnum`, `MATNR = matnr`, `CHARG = scan`, `VERME > 0`).
       - Auto-fills Source Storage Type (`VLTYP`), Source Storage Bin (`VLPLA`), Storage Unit (`LENUM`), Batch (`CHARG`), and Available Quantity (`MENGE`), capping to reservation open requirement.
  4. **Single-Step Posting Routing**:
     - For Handling Units (`venum IS NOT INITIAL`), invokes `HU_CREATE_GOODS_MOVEMENT`.
     - For Pure Batch movements (`venum IS INITIAL`), invokes `BAPI_GOODSMVT_CREATE` with `bapi2017_gm_item_create-batch = is_hu_info-charg`.
     - Followed immediately by destination putaway bin determination (`determine_destination_bin`) and auto-confirmed Transfer Order creation (`L_TO_CREATE_SINGLE`), ensuring zero orphan quants in interim storage `922`.
  5. **Dynamic Open Quantity Calculation (Pending / Remaining Quantity)**:
     - **Before Scan**: `Open:` displays the full unposted open requirement (e.g. `2.000 NOS`).
     - **After Scan & Verification ("Material OK")**: `Open:` instantly recalculates to display the **projected remaining balance** (`Pending Open = Current Open - Scanned Quantity`).
     - **Live Verification Example (Screen 0200)**:
       - Reservation Requirement: `2.000 NOS` | Initial Open: `2.000 NOS`.
       - Operator scans HU `0000000001000059690` containing `1.000 NOS`.
       - Screen dynamically updates: `Req: 2.000   Open: 1.000   NOS` | `Qty: 1.000`.
       - Status Message: `HU/SU 0000000001000059690 valid. Rem: 1.000 NOS. Press Post`.
     - Once posted, the transaction updates `picked_qty = 1.000` and `open_qty = 1.000`, cleanly preserving the open item for the next scan until full closure (`Open = 0.000`).
  6. **Airtight Duplicate HU / SU Scan Prevention in Single Reservation ("HU or SU is already scan")**:
     - **Business Requirement**: Under no circumstances should an operator scan or post the same Handling Unit (HU) or Storage Unit (SU) multiple times within a single reservation request (`RSNUM`).
     - **Airtight 4-Layer Prevention Architecture**:
       1. **Screen Focus & Barcode Gun Auto-Post Elimination**:
          - Dynpro Screen 0200 PBO (`status_0200`) strictly keeps cursor focus on `G_SCR0200-EXIDV_SCAN` (`SET CURSOR FIELD 'G_SCR0200-EXIDV_SCAN'`), preventing barcode scanners from inadvertently typing numbers into `POST_QTY`.
          - In PAI (`user_command_0200`), Enter (`c_fcode_enter` / `space` / `'/00'`) **never auto-posts**. If the user scans the active HU again or presses Enter on `EXIDV_SCAN`, it immediately rejects it with:
            ```text
            HU or SU is already scan
            ```
          - Posting is strictly triggered by clicking `[Post]` (F1 / `c_fcode_post`). Enter on `POST_QTY` only updates the projected remaining open balance.
       2. **Multi-Representation Normalization (Raw, Stripped, Padded)**:
          - Automatically normalizes all barcodes into:
            - Raw text (condensed with no gaps)
            - Stripped text (leading zeros deleted, e.g. `1000005555`)
            - 20-digit padded format (`ALPHA = IN` for `EXIDV`)
            - 10-digit padded format (`ALPHA = IN` for `LENUM`)
          - Duplicate checks compare all representations so scanning `00000000001000005555` after scanning `1000005555` is immediately rejected.
       3. **Cross-Session Database Cluster Persistence (`DATABASE indx(rf)`)**:
          - Every posted HU and SU is exported to SAP standard database cluster `INDX(rf)` with Key `|ZRF_RES_{ lv_rsnum }|`.
          - When a reservation is loaded in Screen 0100 (`get_document_details` / `fetch_document_data`), `mt_scanned_hus` and `gt_scanned_hus` are automatically restored from the cluster database and standard historical tables.
          - Even if the operator logs out, restarts the RF terminal, or re-opens the reservation hours later, repeat scans of previously used HUs/SUs are permanently blocked.
       4. **Deep Standard SAP Historical Table Verification**:
          - **`VBEH` $\bowtie$ `MSEG`**: Checks standard SAP Handling Unit history for material documents posted under the reservation.
          - **`LTBK` $\bowtie$ `LTAP`**: Checks Transfer Requirements and Transfer Orders for source (`VLENR`) and destination (`NLENR`) Storage Units linked to the reservation.
          - **`SER06` $\bowtie$ `OBJK` $\bowtie$ `MSEG`**: Checks serial numbers and Handling Units recorded during goods movement.
          - **Resolved HU $\leftrightarrow$ SU Cross-Check**: Validates both the scanned string AND the resolved `EXIDV` / `LENUM` to prevent scanning an SU when its parent HU was already used (or vice versa).
          - Upon detecting any repeat scan, all HU details are cleared, `Open:` reverts to the actual remaining unposted quantity, and the system displays:
            ```text
            HU or SU is already scan
            ```
