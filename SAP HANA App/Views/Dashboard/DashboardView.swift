//
//  DashboardView.swift
//  SAPHANAApp
//
//  SAP Fiori Launchpad Dashboard
//  Houses Fiori KPI Cards, Live Server Status (172.27.100.32:220),
//  and Fiori Launchpad Tiles for all 13 Enterprise Sub-Modules.
//

import SwiftUI

public struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    
    // Grid layout for Fiori Tiles
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 14)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - 1. Live SAP HANA Server Health Banner
                    serverStatusBanner
                    
                    // MARK: - 2. SAP Fiori KPI Header Cards
                    kpiHeaderGrid
                    
                    // MARK: - 3. Fiori Launchpad Tile Shell (13 Modules)
                    launchpadSections
                }
                .padding()
            }
            .background(FioriColors.sapBackground)
            .navigationTitle("SAP S/4HANA")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: ApprovalInboxView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "tray.full.fill")
                                .font(.title3)
                                .foregroundColor(FioriColors.sapBlue)
                            
                            if viewModel.pendingApprovalsCount > 0 {
                                Text("\(viewModel.pendingApprovalsCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(FioriColors.negative)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -6)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.showQuickOrderSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(FioriColors.sapBlue)
                        }
                        
                        Button(action: {
                            viewModel.showSettingsSheet = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(FioriColors.primaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showSettingsSheet) {
                SAPSettingsView()
            }
            .sheet(isPresented: $viewModel.showQuickOrderSheet) {
                CreateOrderView()
            }
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .task {
                await viewModel.refreshDashboard()
            }
        }
    }
    
    // MARK: - Server Status Banner
    private var serverStatusBanner: some View {
        let conf = viewModel.connection.activeServerConfig
        return HStack(spacing: 12) {
            Circle()
                .fill(statusIndicatorColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("SAP On-Premise Gateway:")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                    Text("\(conf.host):\(conf.port) (Client \(conf.sapClient))")
                        .font(.system(.caption, design: .monospaced))
                }
                
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(FioriColors.secondaryText)
            }
            
            Spacer()
            
            Button("Test") {
                Task { await viewModel.refreshDashboard() }
            }
            .font(.caption2.bold())
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(FioriColors.sapCardBackground)
        .cornerRadius(10)
    }
    
    private var statusIndicatorColor: Color {
        switch viewModel.connection.connectionStatus {
        case .connected: return FioriColors.positive
        case .connecting: return FioriColors.critical
        case .offlineMock: return FioriColors.sapBlue
        case .disconnected, .failure: return FioriColors.negative
        }
    }
    
    private var statusText: String {
        switch viewModel.connection.connectionStatus {
        case .connected(let ms): return "Live OData Online (\(ms)ms) • Basic Auth Active"
        case .connecting: return "Handshaking with 172.27.100.32..."
        case .offlineMock: return "Offline Enterprise Sandbox Mode Active"
        case .failure(let reason): return "Error: \(reason)"
        case .disconnected: return "Tap to initialize connection"
        }
    }
    
    // MARK: - KPI Cards
    private var kpiHeaderGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink(destination: ApprovalInboxView()) {
                FioriKPICard(
                    title: "Pending Approvals",
                    value: "\(viewModel.pendingApprovalsCount)",
                    subtitle: "Action required",
                    trend: "+2 new",
                    isPositiveTrend: false,
                    icon: "tray.and.arrow.down.fill",
                    accentColor: FioriColors.critical
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: SalesListView()) {
                FioriKPICard(
                    title: "Sales Orders",
                    value: "$\(Int(truncating: viewModel.salesTotalValue as NSNumber) / 1000)K",
                    subtitle: "\(viewModel.salesOrdersCount) Active Orders",
                    trend: "14.2%",
                    isPositiveTrend: true,
                    icon: "cart.fill",
                    accentColor: FioriColors.sapBlue
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: PurchasingListView()) {
                FioriKPICard(
                    title: "Open POs",
                    value: "$\(Int(truncating: viewModel.openPOsTotalValue as NSNumber) / 1000)K",
                    subtitle: "\(viewModel.openPOsCount) Commitments",
                    trend: "8.1%",
                    isPositiveTrend: true,
                    icon: "shippingbox.fill",
                    accentColor: FioriColors.positive
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: CRMHubView()) {
                FioriKPICard(
                    title: "Overdue Tasks",
                    value: "\(viewModel.overdueTasksCount)",
                    subtitle: "\(viewModel.repository.tasks.count) Total Tasks",
                    trend: "-1 closed",
                    isPositiveTrend: true,
                    icon: "clock.badge.exclamationmark.fill",
                    accentColor: FioriColors.negative
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 13 Sub-Module Launchpad Sections
    private var launchpadSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Section A: Sales & Distribution (SD)
            launchpadGroup(
                title: "Sales & Distribution (SD)",
                subtitle: "Customer documents, contracts, and quotation pipeline",
                tiles: [
                    LaunchpadTileItem(title: "Sales Orders", subtitle: "Deep Insert & List", icon: "cart.fill", badge: "\(viewModel.repository.salesOrders.count)", destination: AnyView(SalesListView())),
                    LaunchpadTileItem(title: "Sales Quotations", subtitle: "Binding Bids", icon: "doc.plaintext.fill", badge: "\(viewModel.repository.salesQuotations.count)", destination: AnyView(SalesListView())),
                    LaunchpadTileItem(title: "Sales Inquiries", subtitle: "Customer Lead Inquiries", icon: "questionmark.folder.fill", badge: "\(viewModel.repository.salesInquiries.count)", destination: AnyView(SalesListView())),
                    LaunchpadTileItem(title: "Sales Contracts", subtitle: "Quantity & Value Contracts", icon: "doc.badge.gearshape.fill", badge: "\(viewModel.repository.salesContracts.count)", destination: AnyView(SalesListView()))
                ]
            )
            
            // Section B: Purchasing & Sourcing (MM)
            launchpadGroup(
                title: "Sourcing & Procurement (MM)",
                subtitle: "Requisitions, multi-vendor RFQ matrices, and Purchase Orders",
                tiles: [
                    LaunchpadTileItem(title: "Purchase Orders", subtitle: "Commitments & Deep Insert", icon: "shippingbox.fill", badge: "\(viewModel.repository.purchaseOrders.count)", destination: AnyView(PurchasingListView())),
                    LaunchpadTileItem(title: "Quotation Matrix", subtitle: "RFQ Comparison & Award", icon: "square.grid.3x3.topleft.filled", badge: "1 Open", destination: AnyView(QuotationCompareView())),
                    LaunchpadTileItem(title: "Purchase Requisitions", subtitle: "Internal Stock Requests", icon: "tray.and.arrow.down.fill", badge: "\(viewModel.repository.purchaseRequisitions.count)", destination: AnyView(PurchasingListView())),
                    LaunchpadTileItem(title: "Vendor RFQs", subtitle: "API_QTN_PROCESS_SRV", icon: "doc.text.magnifyingglass", badge: "Active", destination: AnyView(PurchasingListView()))
                ]
            )
            
            // Section C: Master Data & F4 Search Help Pickers
            launchpadGroup(
                title: "Master Data Directory (F4 Help)",
                subtitle: "Fast paginated lookup for Materials, Customers, and Suppliers",
                tiles: [
                    LaunchpadTileItem(title: "Material Master", subtitle: "Stock & Valuation", icon: "cube.box.fill", badge: "\(viewModel.repository.products.count)", destination: AnyView(MaterialDirectoryView())),
                    LaunchpadTileItem(title: "Customer Directory", subtitle: "Accounts & Credit", icon: "building.2.crop.circle.fill", badge: "\(viewModel.repository.customers.count)", destination: AnyView(CustomerDirectoryView())),
                    LaunchpadTileItem(title: "Vendor Directory", subtitle: "Suppliers & Terms", icon: "shippingbox.circle.fill", badge: "\(viewModel.repository.suppliers.count)", destination: AnyView(VendorDirectoryView()))
                ]
            )
            
            // Section D: Operations & Approvals
            launchpadGroup(
                title: "Operations & Governance",
                subtitle: "Unified My Inbox Approvals, Activity Logging, and Task Tracking",
                tiles: [
                    LaunchpadTileItem(title: "Approval Center", subtitle: "My Inbox (Function Imports)", icon: "tray.full.fill", badge: "\(viewModel.pendingApprovalsCount)", destination: AnyView(ApprovalInboxView())),
                    LaunchpadTileItem(title: "CRM & Activities", subtitle: "Calls, Visits & Notes", icon: "person.2.fill", badge: "\(viewModel.repository.activities.count)", destination: AnyView(CRMHubView()))
                ]
            )
        }
    }
    
    private func launchpadGroup(title: String, subtitle: String, tiles: [LaunchpadTileItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(FioriColors.secondaryText)
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tiles) { item in
                    NavigationLink(destination: item.destination) {
                        LaunchpadTileView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Launchpad Tile Model & View
public struct LaunchpadTileItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let badge: String?
    public let destination: AnyView
}

public struct LaunchpadTileView: View {
    public let item: LaunchpadTileItem
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FioriColors.sapBlue.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(FioriColors.sapBlue)
                }
                
                Spacer()
                
                if let badge = item.badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(FioriColors.sapBlue.opacity(0.12))
                        .foregroundColor(FioriColors.sapBlue)
                        .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(FioriColors.primaryText)
                    .lineLimit(1)
                
                Text(item.subtitle)
                    .font(.system(.caption2))
                    .foregroundColor(FioriColors.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(FioriColors.sapCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

