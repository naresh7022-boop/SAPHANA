//
//  SalesListView.swift
//  SAPHANAApp
//
//  SAP S/4HANA Sales & Distribution (SD) List Report & Object Views
//  Services: API_SALES_ORDER_SRV, API_SALES_INQUIRY_SRV,
//            API_SALES_QUOTATION_SRV, API_SALES_CONTRACT_SRV
//

import SwiftUI

public enum SalesCategory: String, CaseIterable, Identifiable {
    case orders = "Orders"
    case quotations = "Quotations"
    case inquiries = "Inquiries"
    case contracts = "Contracts"
    
    public var id: String { rawValue }
}

public struct SalesListView: View {
    @State private var repository = SAPDataRepository.shared
    @State private var selectedCategory: SalesCategory = .orders
    @State private var searchText: String = ""
    @State private var showCreateSheet: Bool = false
    @State private var isRefreshing: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fiori Filter Segment
                Picker("Sales Category", selection: $selectedCategory) {
                    ForEach(SalesCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(FioriColors.sapBackground)
                
                // Content based on category
                List {
                    switch selectedCategory {
                    case .orders:
                        salesOrdersSection
                    case .quotations:
                        salesQuotationsSection
                    case .inquiries:
                        salesInquiriesSection
                    case .contracts:
                        salesContractsSection
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await refreshData()
                }
                .searchable(text: $searchText, prompt: "Search by number or customer...")
            }
            .navigationTitle("Sales (SD)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showCreateSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(FioriColors.sapBlue)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateOrderView()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var salesOrdersSection: some View {
        Section(header: Text("Sales Orders (API_SALES_ORDER_SRV)")) {
            let filtered = repository.salesOrders.filter {
                searchText.isEmpty ||
                $0.salesOrder.localizedCaseInsensitiveContains(searchText) ||
                $0.customerName.localizedCaseInsensitiveContains(searchText)
            }
            
            ForEach(filtered) { order in
                NavigationLink(destination: SalesOrderDetailView(order: order)) {
                    FUIObjectCell(
                        iconName: "cart.fill",
                        headline: "Order #\(order.salesOrder)",
                        subheadline: "\(order.customerName) (Party: \(order.soldToParty))",
                        footnote: "PO Ref: \(order.purchaseOrderByCustomer) • \(order.items.count) Items",
                        statusText: "$\(order.netAmount)",
                        statusColor: FioriColors.sapBlue,
                        subStatusText: order.status.rawValue
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var salesQuotationsSection: some View {
        Section(header: Text("Sales Quotations (API_SALES_QUOTATION_SRV)")) {
            let filtered = repository.salesQuotations.filter {
                searchText.isEmpty ||
                $0.quotationNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.customerName.localizedCaseInsensitiveContains(searchText)
            }
            
            ForEach(filtered) { qtn in
                FUIObjectCell(
                    iconName: "doc.plaintext.fill",
                    headline: "Quotation #\(qtn.quotationNumber)",
                    subheadline: qtn.customerName,
                    footnote: "Valid to: \(qtn.bindingPeriodEndDate.formatted(date: .abbreviated, time: .omitted))",
                    statusText: "$\(qtn.netAmount)",
                    statusColor: FioriColors.positive,
                    subStatusText: "\(qtn.probabilityPercent)% Win Chance"
                )
            }
        }
    }
    
    @ViewBuilder
    private var salesInquiriesSection: some View {
        Section(header: Text("Sales Inquiries (API_SALES_INQUIRY_SRV)")) {
            let filtered = repository.salesInquiries.filter {
                searchText.isEmpty ||
                $0.inquiryNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.customerName.localizedCaseInsensitiveContains(searchText)
            }
            
            ForEach(filtered) { inq in
                FUIObjectCell(
                    iconName: "questionmark.folder.fill",
                    headline: "Inquiry #\(inq.inquiryNumber)",
                    subheadline: inq.customerName,
                    footnote: "\(inq.itemsCount) line items requested",
                    statusText: "$\(inq.netAmount)",
                    statusColor: FioriColors.sapBlue,
                    subStatusText: inq.status.rawValue
                )
            }
        }
    }
    
    @ViewBuilder
    private var salesContractsSection: some View {
        Section(header: Text("Sales Contracts (API_SALES_CONTRACT_SRV)")) {
            let filtered = repository.salesContracts.filter {
                searchText.isEmpty ||
                $0.contractNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.customerName.localizedCaseInsensitiveContains(searchText)
            }
            
            ForEach(filtered) { contract in
                FUIObjectCell(
                    iconName: "doc.badge.gearshape.fill",
                    headline: "Contract #\(contract.contractNumber)",
                    subheadline: contract.customerName,
                    footnote: "Target: $\(contract.targetAmount)",
                    statusText: "\(Int(contract.fulfillmentPercentage))%",
                    statusColor: FioriColors.critical,
                    subStatusText: "Released: $\(contract.releasedAmount)"
                )
            }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        _ = try? await repository.fetchSalesOrders()
        isRefreshing = false
    }
}

// MARK: - Sales Order Detail View
public struct SalesOrderDetailView: View {
    public let order: SalesOrder
    
    public var body: some View {
        List {
            Section {
                FUIObjectHeader(
                    icon: "cart.fill",
                    title: "Sales Order #\(order.salesOrder)",
                    subtitle: order.customerName,
                    status: order.status.rawValue,
                    statusColor: order.status == .approved ? FioriColors.positive : FioriColors.critical,
                    footnote: "Customer PO: \(order.purchaseOrderByCustomer)",
                    description: "Standard Order Type \(order.salesOrderType) in Sales Org \(order.salesOrganization).",
                    kpiValue: "$\(order.netAmount)",
                    kpiCaption: "Total Order Net Value"
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            Section(header: Text("Header Data")) {
                FUIKeyValueItem(key: "Sold-to Party (KUNNR)", value: order.soldToParty)
                FUIKeyValueItem(key: "Sales Organization (VKORG)", value: order.salesOrganization)
                FUIKeyValueItem(key: "Distribution Channel (VTWEG)", value: order.distributionChannel)
                FUIKeyValueItem(key: "Division (SPART)", value: order.organizationDivision)
                FUIKeyValueItem(key: "Creation Date", value: order.creationDate.formatted(date: .abbreviated, time: .shortened))
            }
            
            Section(header: Text("Line Items (\(order.items.count))")) {
                if order.items.isEmpty {
                    Text("No line item details loaded.")
                        .foregroundColor(FioriColors.secondaryText)
                } else {
                    ForEach(order.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.materialDescription)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("$\(item.netAmount)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(FioriColors.sapBlue)
                            }
                            
                            HStack {
                                Text("Item \(item.itemNumber) • Material: \(item.material)")
                                    .font(.caption)
                                    .foregroundColor(FioriColors.secondaryText)
                                Spacer()
                                Text("Qty: \(Int(item.requestedQuantity)) \(item.requestedUoM) • Plant: \(item.plant)")
                                    .font(.caption)
                                    .foregroundColor(FioriColors.secondaryText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(order.salesOrder)
    }
}

