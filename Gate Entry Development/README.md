# Gate Entry Development (ZGATEENTRY)

This directory contains the SAP WebGUI integration, URL launchers, and ABAP deployment configurations for the SAP Gate Entry program **`ZGATEENTRY`** on SAP S/4HANA (DS4 / Client 220).

---

## 🌐 Quick WebGUI Links

| Launch Mode | Target URL | Description |
| :--- | :--- | :--- |
| **Direct WebGUI (Standard)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZGATEENTRY`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZGATEENTRY) | Standard browser login prompt into `ZGATEENTRY` on Client 220 |
| **Direct WebGUI (User NARESH)** | [`https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZGATEENTRY`](https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&sap-user=NARESH&~transaction=ZGATEENTRY) | Pre-fills SAP user `NARESH` |
| **SAP Fiori Launchpad (FLP)** | [`https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#GateEntry-manage`](https://172.27.100.32:44300/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html?sap-client=220#GateEntry-manage) | Launches inside Fiori Launchpad shell via intent `#GateEntry-manage` |
| **Interactive Web Cockpit** | [`launch_gate_entry_webgui.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/Gate%20Entry%20Development/launch_gate_entry_webgui.html) | Interactive URL builder, one-click launcher, and parameter configurator |

---

## 📁 Folder Contents (`Gate Entry Development/`)

```text
Gate Entry Development/
├── ZGATEENTRY_WebGUI.webloc           # Native macOS double-clickable shortcut (opens directly in Safari/Chrome)
├── ZGATEENTRY_WebGUI.url              # Windows standard Internet Shortcut (opens directly in Edge/Chrome)
├── launch_gate_entry_webgui.html      # Interactive Web Launcher portal with parameter builder & copy tools
├── README.md                          # Technical specifications and setup guide
└── src/
    ├── zcreate_tcode_zgateentry.prog.abap    # ABAP utility to ensure TCODEs ZGATEENTRY & ZGE01 have S_WEBGUI='1'
    └── zcreate_fiori_tile_zgateentry.prog.abap # ABAP utility to register FLP Semantic Object GateEntry
```

---

## 💻 Native Desktop Shortcuts

- **macOS Users:** Double-click [`ZGATEENTRY_WebGUI.webloc`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/Gate%20Entry%20Development/ZGATEENTRY_WebGUI.webloc) directly in Finder. Your default browser will immediately open the SAP WebGUI page.
- **Windows Users:** Open [`ZGATEENTRY_WebGUI.url`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/Gate%20Entry%20Development/ZGATEENTRY_WebGUI.url).

---

## 🛠️ SAP Backend Prerequisites & Configuration

### 1. SICF Service Activation
Ensure the standard WebGUI ICF node is activated in transaction `SICF`:
- Service Path: `/default_host/sap/bc/gui/sap/its/webgui`

### 2. Transaction Code Registration
To ensure `ZGATEENTRY` opens cleanly in browser without dynpro execution restrictions, run report:
- **`ZCREATE_TCODE_ZGATEENTRY`** (located at [`src/zcreate_tcode_zgateentry.prog.abap`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/Gate%20Entry%20Development/src/zcreate_tcode_zgateentry.prog.abap))
  - Sets `TSTCC-S_WEBGUI = '1'` (SAP GUI for HTML enabled).
  - Also provisions short quick code `ZGE01` for mobile terminals.

### 3. SAP Fiori Launchpad Tile (FLP Content Manager `/UI2/FLPCM_CUST`)

| Parameter | Configuration Value | Description |
| :--- | :--- | :--- |
| **Semantic Object** | `GateEntry` | Registered via `ZCREATE_FIORI_TILE_ZGATEENTRY` |
| **Action** | `manage` | Standard CRUD verb |
| **Target Intent** | `#GateEntry-manage` | FLP Navigation Intent |
| **Application Type** | `Transaction` | WebGUI transaction |
| **Transaction Code** | `ZGATEENTRY` | Target Program |
| **GUI Type** | `SAP GUI for HTML` | Seamless Web execution |
| **Tile Title** | `Gate Entry Cockpit` | Home Screen Title |
| **Tile Subtitle** | `Material Inward / Outward` | Secondary text |
| **Tile Icon** | `sap-icon://shipping-status` | Standard SAP Fiori Icon |

---

## ⚡ URL Parameterization Reference

You can pass initial screen selection parameters into the WebGUI link by appending space-separated parameters inside `~transaction`:

```text
https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZGATEENTRY%20P_EBELN=4500001234
```

To pre-fill multiple parameters:
```text
https://172.27.100.32:44300/sap/bc/gui/sap/its/webgui?sap-client=220&~transaction=ZGATEENTRY%20P_EBELN=4500001234%20P_VEHNO=MH12AB1234
```
Use the interactive builder in [`launch_gate_entry_webgui.html`](file:///Users/naresh/Documents/Github%20Development/SAPHANA/Gate%20Entry%20Development/launch_gate_entry_webgui.html) to dynamically generate these links.
