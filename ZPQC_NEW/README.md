# ZPQC_NEW - RFQ Price Comparison, PO Creation & Fiori Cockpit

**SAP Transaction Code:** `ZPQC_NEW`  
**ABAP Report Program:** `ZMM_R_ME49N` (Active Version: **v3.1**)  
**System:** SAP S/4HANA (`DS4/220`) · Client `220`  
**Package:** `$TMP` (Local Object)  
**Fiori Launchpad Intent:** `#ZPQC_NEW-manage`  

---

## 📌 Executive Summary

`ZPQC_NEW` is an enterprise quotation price comparison and PO generation cockpit built for SAP S/4HANA. It provides procurement buyers and approval managers with an interactive matrix comparing up to 40 supplier quotations per collective RFQ. The system supports multi-currency conversion to base currency (INR), automated lowest-cost (L1) ranking, role-based approval workflows with compulsory non-L1 justification remarks, strict state-locking safeguards, and one-click Purchase Order creation via standard BAPI (`BAPI_PO_CREATE1`).

In addition to traditional SAP GUI access, `ZPQC_NEW` is fully configured for deployment as a **SAP Fiori Launchpad Tile** (WebGUI / SAP GUI for HTML), allowing buyers to launch and use the comparison cockpit directly from their Fiori Launchpad homepage.

---

## 📁 Folder Contents (`ZPQC_NEW/`)

| File | Type | Description |
| :--- | :--- | :--- |
| **[`zmm_r_me49n.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/ZPQC_NEW/zmm_r_me49n.prog.abap)** | ABAP Source | Main executable report program (v3.1) deployed as `ZMM_R_ME49N`. |
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
* **Direct WebGUI URL:**  
  `https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPQC_NEW`

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
   * Launch `https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPQC_NEW`.

---

**Maintained by:** Enterprise SAP Development Team  
**Last Updated:** October 2026
