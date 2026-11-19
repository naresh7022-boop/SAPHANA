# TECHNICAL SPECIFICATION: QC PHYSICAL SAMPLE COLLECTION (ZPPLIS_NN)

**Target System:** SAP S/4HANA (DS4 / Client 220)  
**Transaction Codes:** `ZPPLIS_NN` (Primary Dialog) / `ZPLIS_NN` (Short Code)  
**Program:** `SAPMZPPLIS_NN`  
**Screen:** `0100` (QC Physical Sample Collection Cockpit)  
**Custom Audit Table:** `ZQC_SAMPLE_LOG`  
**Label Print Driver:** `ZQC_SAMPLE_LABEL_PRINT` (SmartForms / Adobe Forms / Zebra ZPL II)  
**FLP Intent:** `#SampleCollection-manage`  

---

## 1. Functional Specification & Business Process

The Physical Sample Collection Cockpit is designed for warehouse operators and Quality Control (QC) analysts drawing representative samples from received goods or production batches before laboratory release.

### 1.1 Input / Selection Screen:
- **Primary Input:** Inspection Lot Number (`QALS-PRUEFLOS`).
- **Action:** When user enters/scans the lot number and presses **Enter** or clicks **Execute**:
  - Enqueue lock is placed on the lot using `ENQUEUE_EQALS` to prevent concurrent modifications.
  - Header data is fetched from SAP tables and locked for sampling.

### 1.2 Header Data Display (Read-Only Fields):
- **Material Code:** `QALS-MATNR`
- **Material Description:** `MAKT-MAKTX` (from `MAKT` using `MATNR` and logon language)
- **Plant:** `QALS-WERK`
- **Batch Number:** `QALS-CHARG`
- **Supplier Batch Number:** `MCH1-LICHA` (from `MCH1` using `MATNR` and `CHARG`)
- **Received Quantity & UoM:** `QALS-LOSMENGE` and `QALS-MEINS`
- **Total Number of Bags/Drums ($N$):** Count of Handling Units (`VEKP`/`VEPO`) or Storage Units (`LEIN`/`LQUA`) associated with the inspection lot / batch.

### 1.3 Business Logic: The Root $N + 1$ Formula
The number of physical samples to be collected from $N$ containers follows the statistical formula:
$$\text{Target Samples} = \operatorname{ceil}(\sqrt{N} + 1)$$

**Rounding Rule:** If the calculated value is a fraction/decimal, round it UP to the next integer.
- Example 1: $N = 10 \implies \sqrt{10} + 1 \approx 3.162 + 1 = 4.162 \implies \text{Target} = \mathbf{5}\text{ samples}$.
- Example 2: $N = 25 \implies \sqrt{25} + 1 = 5 + 1 = \mathbf{6}\text{ samples}$.
- Example 3: $N = 1 \implies \sqrt{1} + 1 = 1 + 1 = \mathbf{2}\text{ samples}$.
- Displayed on screen as **"Target Samples to Collect"**.

### 1.4 Execution & Scanning Area (Interactive UI):
- **Scan Field:** Text entry field to scan the Handling Unit Number (`VEKP-EXIDV`) or Storage Unit Number (`LEIN-LENUM`).
- **Validation 1 (Lot / Batch Match):**
  - Check if scanned HU/SU belongs to the active lot and batch in `VEPO`/`LQUA`.
  - Error if mismatch: **`"Invalid HU/SU for this Inspection Lot."`**
- **Validation 2 (Duplicate Check):**
  - Check if scanned HU/SU was already sampled in `ZQC_SAMPLE_LOG` or during the current session.
  - Error if duplicate: **`"Sample already collected from this HU/SU."`**
- **Live Counter Display:** Displays progress in real time: **`"Samples Collected: X / Target"`**.

### 1.5 Output / Action (Automatic Label Printing):
- Once a valid HU/SU is scanned, update counter ($X \gets X + 1$).
- Save audit entry to database table `ZQC_SAMPLE_LOG`.
- Automatically trigger print of a **Sample Collection Label** (Zebra ZPL II direct thermal or SmartForm/Adobe Form).
- **Label Details:**
  - Inspection Lot Number
  - Material Code & Description
  - Batch Number & Supplier Batch
  - Scanned HU/SU Number & Barcode
  - Sample Item Number ($X$ of Target)
  - Date, Time, and User ID (`SY-UNAME`)
- **Completion:** Once $X = \text{Target}$:
  - Display success message: **`"Physical Sample Collection Completed"`**
  - Clear/reset screen for the next inspection lot.

---

## 2. Technical Objects & Architecture

### 2.1 Database Tables Utilized:
| Table | Description | Fields Used |
| :--- | :--- | :--- |
| **`QALS`** | Inspection Lot Master | `PRUEFLOS`, `MATNR`, `WERK`, `CHARG`, `LOSMENGE`, `MEINS`, `VBELN`, `POSNR` |
| **`MAKT`** | Material Descriptions | `MATNR`, `SPRAS`, `MAKTX` |
| **`MCH1`** | Batch Master | `MATNR`, `CHARG`, `LICHA` (Supplier Batch) |
| **`VEKP` / `VEPO`** | Handling Unit Master / Items | `VENUM`, `EXIDV` (HU No), `MATNR`, `CHARG` |
| **`LEIN` / `LQUA`** | Storage Units / Quants | `LENUM` (SU No), `MATNR`, `CHARG`, `WERKS` |
| **`ZQC_SAMPLE_LOG`** | Custom Audit Trail Table | `MANDT`, `PRUEFLOS`, `EXIDV`, `SAMPLE_NO`, `TARGET_SAMPLES`, `TOTAL_BAGS`, `MATNR`, `MAKTX`, `CHARG`, `LICHA`, `WERKS`, `ERDAT`, `ERZET`, `ERNAM`, `STATUS`, `LABEL_PRINTED` |
| **`TSTC` / `TSTCC`** | Transaction Code Registry | `TCODE = ZPPLIS_NN`, `S_WEBGUI = '1'` |

---

## 3. ABAP Source Code Deliverables

1. **`ZSETUP_ZPPLIS_NN`** ([`src/zsetup_zpplis_nn.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/src/zsetup_zpplis_nn.prog.abap)):
   - Automated 1-click installer report.
   - Injects and compiles `SAPMZPPLIS_NN`, builds Dynpro `0100`, sets up CUA statuses, registers `ZPPLIS_NN` with WebGUI enabled (`S_WEBGUI = '1'`), and resets buffers.
2. **`SAPMZPPLIS_NN`** ([`src/sapmzpplis_nn.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/src/sapmzpplis_nn.prog.abap)):
   - Complete Module Pool program containing all business logic, enqueuing, $\sqrt{N} + 1$ calculation, validation, and auto-print triggers.
3. **`ZQC_SAMPLE_LOG`** ([`src/zqc_sample_log.tabl.asddls`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/src/zqc_sample_log.tabl.asddls)):
   - ABAP Dictionary / CDS Table definition for compliance audit logging.
4. **`ZQC_SAMPLE_LABEL_PRINT`** ([`src/zqc_sample_label_print.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/src/zqc_sample_label_print.prog.abap)):
   - Print driver for SmartForms (`ZQC_SAMPLE_LABEL`), Adobe Forms (`ZQC_SAMPLE_LABEL_AF`), and high-speed Zebra ZPL II raw commands.
5. **Standalone Fiori WebUI App** ([`sample_collection_fiori_app.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/sample_collection_fiori_app.html)):
   - Full SAP Fiori Horizon client-side application with live video camera barcode detection (ZXing) and USB laser scanner wedge support.
