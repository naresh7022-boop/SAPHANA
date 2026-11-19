# QC Sample Collection (ZPPLIS_NN) - Barcode Scanner & Fiori / WebGUI

This directory contains the production-ready duplicate implementation of transaction code **`ZPPLIS`** (with standard suffix **`_NN`**), featuring full Dynpro screen duplication (Screens `0100` & `0200`), SAP WebGUI / ITSmobile integration, SAP Fiori Launchpad Tile configuration, and a modern responsive **HTML5 Barcode Scanner WebUI** supporting real-time camera scanning and handheld laser scanner wedge input.

---

## 🚀 Active Transaction Codes & Program Names in SAP DS4/220

| Transaction Code | Short Code | Program Name | Initial Screen | Description | WebGUI / ITSmobile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ZPPLIS_NN`** | **`ZPLIS_NN`** | `SAPMZPPLIS_NN` | `0100` | QC Sample Collection & Barcode Scanner | **Enabled** (`S_WEBGUI = '1'`, `S_WIN32 = 'X'`, `S_PLATIN = 'X'`) |

---

## 🌐 Quick WebGUI & Fiori Tile Links (Client 220)

| Launch Mode | Target URL | Description |
| :--- | :--- | :--- |
| **Direct WebGUI (`ZPPLIS_NN`)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPPLIS_NN`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPPLIS_NN) | Primary browser-based WebGUI for Sample Collection on Client 220 |
| **Direct WebGUI (`ZPPLIS_NN` NARESH)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZPPLIS_NN`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZPPLIS_NN) | Pre-fills SAP user `NARESH` for quick testing |
| **Mobile Short Code (`ZPLIS_NN`)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPLIS_NN`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZPLIS_NN) | Handheld RF gun / barcode scanner terminal short transaction |
| **SAP Fiori Launchpad (FLP)** | [`https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#SampleCollection-manage`](https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#SampleCollection-manage) | Launches inside Fiori Launchpad shell via intent `#SampleCollection-manage` |
| **Live Camera Barcode Scanner WebUI** | [`sample_collection_fiori_app.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/sample_collection_fiori_app.html) | Standalone Fiori Horizon WebUI with live camera barcode detector, audio beep, and ZPL label preview |
| **Interactive Web Cockpit & QR Portal** | [`launch_sample_collection_webgui.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/launch_sample_collection_webgui.html) | Interactive URL builder, one-click launcher, and QR code scanner for mobile devices |

### 💻 Desktop Shortcuts Included:
- **macOS Users:** Double-click [`ZPPLIS_NN_WebGUI.webloc`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/ZPPLIS_NN_WebGUI.webloc) directly in Finder.
- **Windows Users:** Double-click [`ZPPLIS_NN_WebGUI.url`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/QC%20Sample%20Collection/ZPPLIS_NN_WebGUI.url).

---

## 📁 Repository Structure (`QC Sample Collection/`)

```text
QC Sample Collection/
├── README.md                                 # Technical overview & quick links
├── TECHNICAL_SPECIFICATION.md                # Detailed architecture & schema specs
├── ZPPLIS_NN_WebGUI.webloc                   # Native macOS double-clickable shortcut
├── ZPPLIS_NN_WebGUI.url                      # Windows standard Internet Shortcut
├── launch_sample_collection_webgui.html      # Interactive Web Cockpit & QR Code Portal
├── sample_collection_fiori_app.html          # Standalone Fiori WebUI Barcode Scanner App
├── deploy/
│   └── deploy_zpplis_nn.cjs                  # Automated ADT deployment script for DS4/220
├── screens/
│   ├── screen_0100.txt                       # Initial Scan Screen (Lot / Barcode Scan)
│   └── screen_0200.txt                       # Physical Sample Collection & Tube Scan Screen
├── templates/
│   ├── itsp_screen_0100.html                 # Mobile-responsive HTML template for Dynpro 0100
│   └── itsp_screen_0200.html                 # Mobile-responsive HTML template for Dynpro 0200
└── src/
    ├── zcl_sample_collection_nn.clas.abap    # Backend Controller Class (QALS, QPRS, Validation)
    ├── sapmzpplis_nn.prog.abap               # Main Self-Contained Module Pool Program
    ├── zcreate_tcode_zpplis_nn.prog.abap     # Automated TCODE & Dynpro Generator (RPY_DYNPRO_INSERT)
    └── zcreate_fiori_tile_zpplis_nn.prog.abap# FLP Semantic Object & Target Mapping Configurator
```

---

## 🔑 Key Features & Architecture

1. **Object Duplication (`_NN` Suffix)**:
   - Module Pool program: `SAPMZPPLIS_NN`
   - Primary TCODE: `ZPPLIS_NN`
   - Mobile Short Code: `ZPLIS_NN`
   - Backend Class: `ZCL_SAMPLE_COLLECTION_NN`
   - Dynpro Screens: `0100` (Lot/Scan) & `0200` (Sample Verification)
   - TCODE & Dynpro Deployer: `ZCREATE_TCODE_ZPPLIS_NN`
   - Fiori Tile Deployer: `ZCREATE_FIORI_TILE_ZPPLIS_NN`

2. **Physical Sample Collection Workflow (`QALS` & `QPRS`)**:
   - Searches inspection lots (`PRUEFLOS`) or barcode values directly.
   - Manages physical samples across categories (Primary, Pooled, Reserve).
   - Validates scanned tube barcode against the planned sample number.
   - Updates sample status (`QPRS-STATUS` = `'SMPL'`), collector username (`SY-UNAME`), sample timestamp, container type, storage bin, and temperature.

3. **Dual Barcode Scanner Facility**:
   - **Camera Scanner (Mobile / Tablet / PC)**: High-speed real-time video stream detection using HTML5 and ZXing MultiFormat reader for 1D (Code 128, Code 39, EAN) and 2D (DataMatrix, QR Code) sample tubes.
   - **Hardware Laser Gun Scanner (Zebra MC9300, Honeywell, Datalogic)**: Keystroke wedge listener automatically captures scans with sub-second response and acoustic beep feedback.

4. **SAP Fiori Launchpad (FLP) Integration**:
   - Semantic Objects: `ZSampleCollection` and `ZPPLIS_NN` registered in `/UI2/SEMOBJC` & `/UI2/SEMOBJCT`.
   - Target Mapping Intent: `#SampleCollection-manage` with WebGUI execution.

---

## 🛠 Deployment to SAP DS4/220

Once your SAP credentials in `.env` are updated:
```bash
node "QC Sample Collection/deploy/deploy_zpplis_nn.cjs"
```
Or manually execute `ZCREATE_TCODE_ZPPLIS_NN` and `ZCREATE_FIORI_TILE_ZPPLIS_NN` in SE38 / SA38 to generate the screens and Fiori tiles.
