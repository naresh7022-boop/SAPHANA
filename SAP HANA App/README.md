# SAP S/4HANA Enterprise Mobile iOS Application

Production-ready native iOS application built using **Swift 6**, **SwiftUI**, and the **SAP BTP SDK for iOS** (`SAPOData`, `SAPFoundation`, `SAPFiori`), connecting in real-time to an on-premise **SAP S/4HANA** instance (Host: `172.27.100.32`, Client: `220`).

---

## 🏛️ Architectural Overview

This application adheres to enterprise iOS engineering patterns and the **SAP Fiori for iOS Design Guidelines**:

```
SAP HANA App/
├── App/
│   ├── SAPHANAApp.swift                 # Main @main SwiftUI application entrypoint
│   ├── AppDelegate.swift                # Push notifications & background processing lifecycle
│   └── Info.plist                       # NSAppTransportSecurity & Local Networking permissions
├── Configuration/
│   └── SAPServerConfig.swift            # Centralized Server IP (172.27.100.32), Port, Client 220, Service paths
├── Core/
│   ├── Network/
│   │   ├── SAPConnectionManager.swift   # SAPURLSession, CSRF token handshake, sap-client=220 injection
│   │   └── SelfSignedCertificateHandler.swift # Custom SSL delegate trusting local 172.27.100.32 certificate
│   ├── OData/
│   │   ├── ODataQueryBuilder.swift      # Fluent builder mirroring SAPOData DataQuery ($select, $filter, $expand, $orderby)
│   │   ├── ODataServiceLayer.swift      # OData v2/v4 Gateway REST executor & deep-insert engine
│   │   └── SAPDataRepository.swift      # Unified cache & transaction coordinator across all 13 modules
│   ├── Storage/
│   │   └── CredentialStore.swift        # Apple Keychain service for SAP Basic Auth credentials
│   └── Notification/
│       └── SAPNotificationManager.swift # Interactive UNUserNotificationCenter push & local alerts (Approve/Reject)
├── Models/
│   ├── Sales/                           # SD: SalesOrder, Item, Inquiry, Quotation, Contract
│   ├── Purchasing/                      # MM: PurchaseOrder, Requisition, RFQ Quotation Matrix
│   ├── MasterData/                      # F4 Help: Material Master (API_PRODUCT_SRV), BP Customers & Vendors
│   ├── CRM/                             # Operational: Activities (Visits, Calls) & Tasks
│   └── Approval/                        # Governance: My Inbox Unified Workflow Tasks
├── ViewModels/                          # MVVM with Swift 6 Concurrency & @Observable
│   ├── Dashboard/DashboardViewModel.swift
│   ├── Sales/CreateOrderViewModel.swift
│   ├── Purchasing/CreatePurchaseOrderViewModel.swift
│   ├── MasterData/MasterDataPickerViewModel.swift
│   └── Approval/ApprovalInboxViewModel.swift
└── Views/                               # SAP Fiori iOS Design System UI
    ├── Components/FioriComponents.swift # FUIObjectHeader, FUIObjectCell, FUIFilterFormCell, FUIKeyValueItem, FUIBannerMessageView, FioriKPICard
    ├── Dashboard/                       # Fiori Launchpad & Server Settings
    ├── Sales/                           # List Reports, Detail Views, Deep Insert Create Form
    ├── Purchasing/                      # PO Lists, Quotation Comparison Matrix with Award & Convert
    ├── MasterData/                      # Paginated F4 Modal Value Help Pickers & Master Directories
    ├── CRM/                             # Activity Logger & Task Tracker
    └── Approval/                        # My Inbox Approval Center with Mandatory Rejection Justification
```

---

## 🌐 On-Premise SAP Server & Network Coordinates

| Parameter | Configuration Value | Description |
| :--- | :--- | :--- |
| **Server Host** | `172.27.100.32` | On-premise SAP S/4HANA application server |
| **SAP Client** | `220` | Mandatory Client attribution on all OData requests |
| **Default HTTP Port** | `8000` | Unencrypted intranet Gateway port |
| **Default HTTPS Port** | `44300` | Encrypted SSL Gateway port |
| **Base Service URL** | `http://172.27.100.32:8000/sap/opu/odata/sap/<SERVICE_NAME>/` | Standard SAP Gateway ICF path |
| **Client Attribution** | `sap-client=220` | Injected into both HTTP Headers and Query Parameters |
| **Security Mode** | Intranet SSL Bypass | `SelfSignedCertificateHandler` automatically trusts `172.27.100.32` during development |
| **Offline Resilience** | Dual Live / Mock Sandbox | Seamlessly falls back to local data if server is unreachable |

---

## 📦 Core Functional Modules (13 Sub-Modules)

### 1. Sales & Distribution (SD)
- **Sales Orders (`API_SALES_ORDER_SRV`):** Complete List Report with search, status filters, pull-to-refresh, object details, and multi-line item **Deep Insert** (`to_Item`) creation.
- **Sales Quotations (`API_SALES_QUOTATION_SRV`):** Quotation status tracking, binding period end dates, and probability analysis.
- **Sales Inquiries (`API_SALES_INQUIRY_SRV`):** Customer inquiries with item counts and fulfillment tracking.
- **Sales Contracts (`API_SALES_CONTRACT_SRV`):** Value and quantity contracts with progress bars and release percentages.

### 2. Sourcing & Procurement (MM)
- **Purchase Orders (`API_PURCHASEORDER_PROCESS_SRV`):** Full list report and multi-item Deep Insert (`to_PurchaseOrderItem`).
- **Purchase Requisitions (`API_PURCHASEREQ_PROCESS_SRV`):** Department stock requisitions with approval states.
- **Purchase Quotation Comparison Matrix:** Dedicated side-by-side UI comparing multiple vendor bids against a **Collective RFQ**. Highlights lowest net price, fastest delivery lead time, and payment terms, with a one-tap **"Award & Convert to PO"** action.

### 3. Master Data Directory & Modal F4 Search Help Pickers
- **Material Master (`API_PRODUCT_SRV`):** Material number, description, base unit of measure (UoM), plant stock, moving standard price.
- **Customer Master (`API_BUSINESS_PARTNER`):** Sold-to party, sales organization, credit limits, city, country, tax number.
- **Vendor / Supplier Master (`API_BUSINESS_PARTNER`):** Supplier ID, name, purchasing organization, payment terms, quality ratings.

### 4. CRM & Operational Management
- **Activity Management:** Log and track phone calls, client meetings, on-site visits, and quotation follow-ups linked to SAP Business Partners.
- **Task Management:** Assign action items with due dates, priority badges, related SAP document references, and toggleable completion statuses.

### 5. Approval Center (My Inbox) & Real-Time Push Notifications
- **My Inbox:** Unified queue for pending Sales Orders, Purchase Orders, Quotations, and Credit Limit releases.
- **Function Import Execution:** Executes `ApproveTask` and `RejectTask` (with mandatory rejection comment modal).
- **Interactive Actionable Notifications:** Configured with `UNUserNotificationCenter` categories allowing immediate "Approve" or "Reject with Reason" directly from the iOS notification banner.

---

## 🛠️ Step-by-Step Implementation Guide

### Phase 1: Core Connection & Session (`SAPConnectionManager.swift`)
- Configured `SAPURLSession` with cookie management, basic auth keychain tokenization, and automatic `X-CSRF-Token` fetching.
- Added `sap-client=220` header and query interceptor to guarantee SAP Client 220 routing.
- Configured `App/Info.plist` with `NSAppTransportSecurity`:
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsLocalNetworking</key>
      <true/>
      <key>NSExceptionDomains</key>
      <dict>
          <key>172.27.100.32</key>
          <dict>
              <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
              <true/>
          </dict>
      </dict>
  </dict>
  ```

### Phase 2: OData Entity Wrappers & Fluent Query Builder (`ODataQueryBuilder.swift`)
- Implemented fluent query chaining mirroring `SAPOData.DataQuery`:
  ```swift
  let query = ODataQueryBuilder()
      .expand(["to_Item"])
      .top(50)
      .orderBy("CreationDate", ascending: false)
      .searchFilter(query: "Apex", fields: ["CustomerName", "SoldToParty"])
  ```
- Implemented Deep Insert JSON serializer sending hierarchical parent-child trees in a single atomic transaction.

### Phase 3: Fiori Launchpad Dashboard (`DashboardView.swift`)
- Signature Fiori KPI cards tracking Pending Approvals, Total Sales Net, Open PO Commitments, and Overdue Tasks.
- Live server ping monitor showing connection latency to `172.27.100.32:8000` (Client `220`).
- Responsive tile grid launching all 13 functional modules.

### Phase 4: End-to-End Deep Insert Creation (`CreateOrderView.swift`)
- Integrated modal F4 Search Help sheets for selecting Customers and Materials.
- Dynamic line item quantity steppers, automatic 18% tax calculation, and real-time net valuation.
- Atomic OData Deep Insert commit with confirmation dialog.

### Phase 5: Quotation Matrix & Approval Center (`QuotationCompareView.swift` & `ApprovalInboxView.swift`)
- Side-by-side vendor quotation cards with comparison badges (Lowest Price, Fastest Delivery).
- One-tap "Award & Convert to PO" triggering immediate backend PO creation.
- Approval Inbox with one-tap Approve and mandatory Rejection dialog sending SAP Function Imports.
- Interactive notification triggers simulating real-time SAP workflow events.

---

## 🚀 How to Run in Xcode

1. Open Xcode 16+ on macOS.
2. Select **File > Open** and choose the `SAP HANA App` directory.
3. Select an iOS 17+ Simulator (e.g., iPhone 16 Pro) or a connected enterprise physical device.
4. Press **⌘ + R** to build and run.
5. In the app toolbar, tap the **Gear icon** to view or customize server parameters (`172.27.100.32`, Port `8000`/`44300`, Client `220`, SAP User `NARESH`).
6. Tap **"Test Live Connection Now"** to verify communication with the SAP Gateway.

