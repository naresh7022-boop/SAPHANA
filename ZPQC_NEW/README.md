# ZPQC_NEW - RFQ Price Comparison, PO Creation & Fiori Cockpit

**SAP Transaction Code:** `ZPQC_NEW`  
**ABAP Report Program:** `ZMM_R_ME49N` (Active Version: **v3.4**)  
**System:** SAP S/4HANA (`DS4/220`) · Client `220`  
**Package:** `$TMP` (Local Object)  
**Fiori Launchpad Intent:** `#ZPQC_NEW-manage`  

---

## 📌 Executive Summary

`ZPQC_NEW` is an enterprise quotation price comparison and PO generation cockpit built for SAP S/4HANA. It provides procurement buyers and approval managers with an interactive matrix comparing up to 40 supplier quotations per collective RFQ. The system supports multi-currency conversion to base currency (INR), automated lowest-cost (L1) ranking factoring item & header delivery costs/freight from `PRCD_ELEMENTS`, historical Last Purchase Price (LPP) benchmarking with % variance badges, role-based approval workflows with compulsory non-L1 justification remarks, strict state-locking safeguards, and one-click Purchase Order creation via standard BAPI (`BAPI_PO_CREATE1`).

In addition to traditional SAP GUI access, `ZPQC_NEW` is fully configured for deployment as a **SAP Fiori Launchpad Tile** (WebGUI / SAP GUI for HTML), allowing buyers to launch and use the comparison cockpit directly from their Fiori Launchpad homepage.

---

## 🌟 What's New in Version 3.4

### 1. Quotation-Wise Item-Level Delivery Cost & Individual Downside Rows
* **Item-Level Freight Extraction (`PRCD_ELEMENTS`)**: Reads item condition records using 6-digit `kposn` (`UNPACK ls_data-ebelp TO lv_kposn_item`) matching `NUMC 6` format in `PRCD_ELEMENTS` (resolving character length mismatch where `kposn = '000010'` and `ebelp = '00010'`).
* **Condition Pool**: Captures all 122 delivery & freight condition types configured in `T685A` (`KNTYP = 'B'` / `KOAID = 'B'` / `KSCHL LIKE 'FR%'`, `ZAFR`, `ZDT1`, `ZDP1`, `ZI01`, etc.).
* **Individual Downside Row (`Total Delivery Cost`)**: Added a dedicated individual summary row directly below item amounts in both Classical ALV (`ls_frt_tot`, `maktx = 'Total Delivery Cost'`, color `C300`) and the Modern HTML dashboard (`Total Delivery Cost / Freight`, highlighted in amber `#b45309`).
* **Landed Total Calculation**: `Total Quotation Amount` explicitly sums material item total + total delivery cost:
  $$\text{Total Quotation Amount} = \text{Total Item Amount} + \text{Total Delivery Cost}$$
* **Financing Parity**: Maintained `gt_final1` indexing (index 1 = `ls_total`, index 2 = `ls_days`) so interest/financing evaluations continue to calculate based on the true Landed Grand Total.

### 2. Standardized Approver Rejection Error Notification & Creator Return
* **Specific Rejection Error Format**: Rejection notifications now match the exact required format:
  `Item { ebelp } rejected with remark: { remark }. Sent back to creator.`
* **Message Display (`TYPE 'S' DISPLAY LIKE 'E'`)**: Renders with red error bar styling in SAP GUI without aborting or dumping the transaction, alerting the user immediately.
* **Unlock for Creator**: Rejected items automatically unlock remarks and line-item preferences so the creator can edit quotation details via `ME47` and resubmit back to HOD for approval.
* **PO Creation Guard**: PO creation remains strictly locked for any item in `Rejected` (`R`) or `Draft` state.

---

## 🌟 Previous Milestones (Version 3.3)

### 1. Last Purchase Price (LPP) Historical Benchmark & Variance Analytics
* **Automated PO History Extraction:** Queries `EKPO` + `EKKO` + `LFA1` (`bstyp = 'F'`, `loekz = ' '`, `netpr > 0`) ordered by `bedat DESC` to find the most recent standard Purchase Order for each material.
* **Comparative Metrics:** Displays the historical unit rate, unit of measure, previous PO number with direct `ME23N` hyperlink, PO order date, and previous supplier name.
* **Smart Variance Badges:** Calculates percentage difference between the current System Suggested (L1) rate and the previous PO rate:
  * 🟢 **Cost Savings (`▼ -X% Savings`):** Current L1 price is cheaper than previous purchase.
  * 🔴 **Inflation Warning (`▲ +X% vs LPP`):** Current L1 price is higher than previous purchase, alerting the purchasing manager to negotiate.
  * ⚪ **Price Parity (`= Same Rate`):** Price identical to previous purchase.

### 2. Resolved Default Supplier Selection (Always Defaults to L1 Winner)
* **Root Cause Identified:** In `init_approval_status`, when no saved user preference existed (`userpref = 'X'`), a fallback `READ TABLE lt_t021 WITH KEY zqitem = ebelp` matched the very first row in `ZMM_T_021`. Because RFQs are queried and sorted by `lifnr ASCENDING`, Supplier 1 was always picked by default.
* **Resolution:** Removed the blind first-row fallback. When no explicit preference has been saved in `ZMM_T_021`, the cockpit strictly pre-populates the **System Suggested L1 (Lowest Landed Cost)** winner as default.

### 3. Delivery Cost & Additional Freight Condition Integration
* **Pricing Condition Extraction:** Reads active pricing condition records from `PRCD_ELEMENTS` linked by `EKKO-KNUMV` and filters for delivery condition category `KNTYP = 'B'` (e.g. `FRA1`, `FRB1`, `FRC1`) and custom freight types (`ZAFR`, `WT01`, `FREI`) defined in `T685A`.
* **Landed Cost Ranking:** Adds item-specific freight condition amounts and apportioned header-level freight conditions into the quotation landed total. L1 ranking is evaluated on true landed cost.
* **Visual Breakdown:** Each supplier quotation explicitly displays `+₹{ freight } Delivery` if freight conditions exist, and the L1/Selected columns display `(incl. ₹{ freight } delivery)`.
* **PO Condition Inheritance:** During `BAPI_PO_CREATE1` execution, `ls_poitem-rfq_no` and `ls_poitem-rfq_item` link the PO to the winning quotation, ensuring standard SAP copies all pricing and delivery conditions directly into the new Purchase Order.

---

## 📁 Folder Contents (`ZPQC_NEW/`)

| File | Type | Description |
| :--- | :--- | :--- |
| **[`zmm_r_me49n.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/zmm_r_me49n.prog.abap)** | ABAP Source | Main executable report program (v3.3) deployed as `ZMM_R_ME49N`. |
| **[`zcreate_fiori_tile_zpqc.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/zcreate_fiori_tile_zpqc.prog.abap)** | ABAP Utility | Automated setup program that registered Semantic Objects `ZPQC_NEW` and `ZPriceComparison` on SAP. |
| **[`price_comparison_preview.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/price_comparison_preview.html)** | Interactive UI | Live interactive preview supporting **SAP Fiori Launchpad**, **Modern HTML View**, and **Classical ALV Grid (AVL)**. |
| **[`zcreate_tcode_me49n.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/zcreate_tcode_me49n.prog.abap)** | ABAP Helper | Utility report used to register SAP transaction code `ZPQC_NEW`. |
| **[`deploy-me49n.cjs`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/deploy-me49n.cjs)** | Deployment Tool | Automated script to upload and activate `ZMM_R_ME49N` on SAP via ADT MCP bridge. |
| **[`README.md`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/README.md)** | Documentation | Complete system design, Fiori setup, operational guide, and architecture reference. |
| **`backup/`** | History | Timestamped source backups across iterative development milestones. |

---

## 📱 SAP Fiori Launchpad (FLP) Tile Configuration

### 1. Registered Semantic Objects (Active on DS4/220)
The following Semantic Objects have been registered in customizing tables `/UI2/SEMOBJC` and `/UI2/SEMOBJCT`:
* **`ZPQC_NEW`**: Description: `Quotation Price Comparison Cockpit`
* **`ZPriceComparison`**: Description: `Quotation Price Comparison & PO Creation`

### 2. Target Mapping Specification (Fiori Launchpad Content Manager)
In transaction `/UI2/FLPCM_CUST` (or Launchpad Designer `/UI2/FLPD_CUST`), configure the Target Mapping under Business Catalog `ZBC_PURCHASING`:

| Parameter | Configuration Value | Notes |
| :--- | :--- | :--- |
| **Semantic Object** | `ZPQC_NEW` (or `ZPriceComparison`) | Select registered object |
| **Action** | `manage` (or `compare`) | Standard procurement verb |
| **Target Intent** | `#ZPQC_NEW-manage` | Launchpad navigation key |
| **Application Type** | `Transaction` | Standard WebGUI app |
| **Transaction Code** | `ZPQC_NEW` | Deployed transaction |
| **SAP GUI Type** | `SAP GUI for HTML` | Seamless in-browser execution |
| **System Alias** | *(leave empty or enter `LOCAL`)* | Defaults to local S/4HANA system |
| **Device Types** | `Desktop`, `Tablet` | Mobile smartphones optional |

### 3. Fiori Launchpad Static Tile Specification

| Parameter | Value |
| :--- | :--- |
| **Tile Type** | `Static Tile` |
| **Title** | `Price Quotation Comparison` |
| **Subtitle** | `ZPQC_NEW · Quotation Matrix & PO` |
| **Information** | `Collective RFQ Analysis` |
| **Keywords** | `RFQ, ME49, Comparison, Quotation, PO, ZPQC, Matrix` |
| **Icon** | `sap-icon://compare` (or `sap-icon://sales-quote`) |
| **Semantic Object** | `ZPQC_NEW` |
| **Action** | `manage` |
| **Target URL** | `#ZPQC_NEW-manage` |

### 4. Direct Browser Launch URLs
* **SAP Fiori Launchpad URL:**  
  `https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#ZPQC_NEW-manage`
* **Approver Direct WebGUI URL (DRATHOD):**  
  `https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=DRATHOD&~transaction=ZPQC_NEW`
* **Creator Direct WebGUI URL (NARESH):**  
  `https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZPQC_NEW`

---

## ⚙️ Key Functional Capabilities

### 1. Quotation Comparison Matrix (Up to 40 Suppliers)
* Compares line items across up to 40 RFQs (`QUAT1` through `QUAT40`) linked by Collective RFQ Number (`SUBMI`).
* Calculates total landed cost including basic price, freight, customs, packing/forwarding, and taxes.
* Converts foreign currency prices to local currency (INR) using live exchange rates from `TCURR`.
* Displays landed price per standard unit and price per KG for standard weight comparison.

### 2. Intelligent L1 Recommendation & Manual Override
* Automatically identifies and pre-selects the **L1 (Lowest Landed Cost)** quotation for each line item.
* Allows procurement specialists to manually select non-L1 suppliers (L2, L3, etc.) when justified by delivery time, quality, or vendor reliability.
* **Compulsory Justification:** If any non-L1 supplier is selected, the system enforces a mandatory justification remark before submission.

### 3. Role-Based Approval Workflow
* **Requester Mode (Standard User):**
  * Selects quotations, enters justification remarks for non-L1 selections.
  * Submits items for approval (`Send to HOD` / `Submit for Approval`).
  * Approve & Reject actions are hidden from the UI.
* **HOD Approver Mode (Authorized Manager):**
  * Approver role identified dynamically via authorization object `ZMM_HOD_APP` or parameter ID `ZMM_HOD`.
  * Views requester's justification remarks highlighted in the approval cockpit.
  * Can **Approve** or **Reject** individual items or all pending items simultaneously (`Approve All`, `Reject All`).
  * Triggers automated SAP Business Workplace notification / email dispatch to requester upon status transition.

### 4. Strict State-Locking & Data Integrity Guards
* **In-Approval State (`⏳ In Approval`):**
  * When an item is submitted for approval, all editing controls are locked.
  * Checkbox toggles, supplier radio buttons, and `[Edit Reason]` links are disabled.
  * Backend routines reject any modification attempt with warning:  
    `"Item is currently in approval. Details cannot be changed."`
* **Approved State (`✓ Approved`):**
  * The approved supplier selection is locked permanently.
  * Deselection, editing remarks, and changing suppliers are strictly disabled.
  * Only the **`🛒 Create PO`** action button is displayed on the approved item row.
  * Prevents accidental PO creation for unapproved or draft items.

### 5. Multi-View Presentation with Full Workflow Parity
* **SAP Fiori Launchpad (FLP):** Real-time Fiori Horizon shell with interactive tile launching into the cockpit.
* **Modern HTML Cockpit:** Rich browser-based GUI rendered inside WebGUI / SAP GUI (`CL_GUI_HTML_VIEWER`) with custom CSS, status pills, radio selectors, and modal dialogs.
* **Classical ALV Grid ("AVL List"):** Matrix display via `REUSE_ALV_LIST_DISPLAY` (`p_v_alv = 'X'`) with status cell coloring and interactive hotspots.

### 6. Automated BAPI Purchase Order Creation
* Uses standard SAP function `BAPI_PO_CREATE1` to create standard Purchase Orders.
* Automatically retrieves the RFQ net price from quotation condition table `ZMM_T_021` or `A016` / `EKPO-NETPR`.
* Derives required fields: Material, Plant, Storage Location, Quantity, Unit of Measure, Net Price, Currency, and Vendor.
* On successful creation, immediately records the generated PO number (`EBELN`) and provides direct navigation to `ME23N`.

### 7. Accurate Freight & Delivery Condition Calculation & Item-Wise Breakdown
* **Data Source:** Evaluated directly from `PRCD_ELEMENTS` (S/4HANA pricing condition table) using condition record logic (`KNUMV`, `KPOSN`, `KSCHL`).
* **Condition Classification:** Condition classes `B` (Basic prices: `PB00`, `PBXX`, `P001`, `P002`), discounts (`RA00`, `SKTO`), and taxes are strictly segregated from freight and delivery. Only delivery charges (`ZI01` Ocean Freight, `ZI04` Customs Clearance, `ZI42` Marine Insurance, etc.) are included in the delivery total.
* **Currency Conversion:** Automatically converts foreign quotation freight conditions (e.g., USD via exchange rate `EKKO-WKURS`) into base currency (INR).
* **Quotation & Item-Wise Granularity:**
  - In Classical ALV: Dedicated `Delivery:` row for each item with `@0S@ View Breakdown` hotspot and clickable summary row `Total Delivery Cost`.
  - In Modern HTML Cockpit: Interactive link `+₹X Delivery (ZI01: ₹X) 🔍` under each quote, L1 column, and user-selected column, plus clickable footer `Total Delivery Cost / Freight`.
* **Interactive Drill-Down (`show_item_freight_details`):**
  - Clicking any delivery hotspot or link opens a detailed ALV grid popup listing Quotation No, Item No, Vendor Code, Vendor Name, Condition Type, Description, Condition Rate, Rate Currency, Condition Value, Document Currency, and Total Amount in INR.

---

## 🚀 Deployment Instructions

### Prerequisites
* SAP S/4HANA system access (e.g., `DS4/220`).
* ADT (ABAP Development Tools) enabled or SAP GUI developer access.

### Automated Deployment via ADT MCP Script
```bash
node ZPQC_NEW/deploy-me49n.cjs
```

### Manual Deployment via SAP GUI (SE38)
1. Open transaction `SE38` or `SE80`.
2. Open or create report program **`ZMM_R_ME49N`**.
3. Paste the contents of [`zmm_r_me49n.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/zmm_r_me49n.prog.abap).
4. Save (`Ctrl+S`), check syntax (`Ctrl+F2`), and activate (`Ctrl+F3`).
5. Ensure transaction code **`ZPQC_NEW`** points to program `ZMM_R_ME49N`.

---

## 🧪 Testing & Verification Guide

1. **Test in Fiori Launchpad Simulation:**
   * Open **[`price_comparison_preview.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/price_comparison_preview.html)** in any browser.
   * Click **`📱 SAP Fiori Launchpad (FLP Tile)`** to view the live Fiori Launchpad home screen.
   * Click the **`Price Quotation Comparison`** tile: Watch it launch directly into the cockpit with the Fiori top shell navigation.
2. **Test in SAP GUI:**
   * Execute transaction **`ZPQC_NEW`** in SAP client `220`.
   * Test both Modern HTML mode and Classical ALV mode.
3. **Test in WebGUI:**
   * **Approver Mode (`DRATHOD`):** Launch `https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=DRATHOD&~transaction=ZPQC_NEW`
   * **Creator Mode (`NARESH`):** Launch `https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZPQC_NEW`

---

**Maintained by:** Enterprise SAP Development Team  
**Last Updated:** October 2026
