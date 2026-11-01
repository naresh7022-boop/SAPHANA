//
//  PurchasingListView.swift
//  SAPHANAApp
//
//  SAP S/4HANA Sourcing & Procurement (MM) List Reports & Navigation
//  Services: API_PURCHASEORDER_PROCESS_SRV, API_PURCHASEREQ_PROCESS_SRV, API_QTN_PROCESS_SRV
//

import SwiftUI

public enum PurchasingCategory: String, CaseIterable, Identifiable {
    case purchaseOrders = "Orders"
    case requisitions = "Requisitions"
    case rfqComparison = "RFQ Matrix"
    
    public var id: String { rawValue }
}

public struct PurchasingListView: View {
    @State private var repository = SAPDataRepository.shared
    @State private var selectedCategory: PurchasingCategory = .purchaseOrders
    @State private var searchText: String = ""
    @State private var showCreatePOSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Purchasing View", selection: $selectedCategory) {
                    ForEach(PurchasingCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(FioriColors.sapBackground)
                
                List {
                    switch selectedCategory {
                    case .purchaseOrders:
                        purchaseOrdersSection
                    case .requisitions:
                        requisitionsSection
                    case .rfqComparison:
                        rfqComparisonSection
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search purchase documents...")
            }
            .navigationTitle("Purchasing (MM)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showCreatePOSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(FioriColors.sapBlue)
                    }
                }
            }
            .sheet(isPresented: $showCreatePOSheet) {
                CreatePurchaseOrderView()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var purchaseOrdersSection: some View {
        Section(header: Text("Purchase Orders (API_PURCHASEORDER_PROCESS_SRV)")) {
            let filtered = repository.purchaseOrders.filter {
                searchText.isEmpty ||
                $0.purchaseOrder.localizedCaseInsensitiveContains(searchText) ||
                $0.supplierName.localizedCaseInsensitiveContains(searchText)
            }
            
            ForEach(filtered) { po in
                NavigationLink(destination: PurchaseOrderDetailView(po: po)) {
                    FUIObjectCell(
                        iconName: "shippingbox.fill",
                        headline: "PO #\(po.purchaseOrder)",
                        subheadline: po.supplierName,
                        footnote: "Purchasing Org: \(po.purchasingOrganization) • Type: \(po.purchaseOrderType)",
                        statusText: "$\(po.totalNetAmount)",
                        statusColor: FioriColors.sapBlue,
                        subStatusText: po.status.rawValue
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var requisitionsSection: some View {
        Section(header: Text("Purchase Requisitions (API_PURCHASEREQ_PROCESS_SRV)")) {
            let filtered = repository.purchaseRequisitions.filter {
                searchText.isEmpty ||
                $0.requisitionNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
            
            ForEach(filtered) { pr in
                FUIObjectCell(
                    iconName: "tray.and.arrow.down.fill",
                    headline: "PR #\(pr.requisitionNumber)",
                    subheadline: pr.description,
                    footnote: "Requested by: \(pr.requestedBy) • \(pr.itemsCount) items",
                    statusText: "$\(pr.totalAmount)",
                    statusColor: FioriColors.critical,
                    subStatusText: pr.status.rawValue
                )
            }
        }
    }
    
    @ViewBuilder
    private var rfqComparisonSection: some View {
        Section(header: Text("Quotation Comparison Matrices")) {
            ForEach(repository.quotationComparisonSets) { set in
                NavigationLink(destination: QuotationCompareView()) {
                    FUIObjectCell(
                        iconName: "square.grid.3x3.topleft.filled",
                        headline: set.title,
                        subheadline: "Collective RFQ: \(set.collectiveRFQ)",
                        footnote: "\(set.bids.count) competing vendor bids received",
                        statusText: "\(Int(set.requestedQuantity)) \(set.uom)",
                        statusColor: FioriColors.positive,
                        subStatusText: "Open Sourcing"
                    )
                }
            }
        }
    }
}

// MARK: - Purchase Order Detail View
public struct PurchaseOrderDetailView: View {
    public let po: PurchaseOrder
    
    public var body: some View {
        List {
            Section {
                FUIObjectHeader(
                    icon: "shippingbox.fill",
                    title: "Purchase Order #\(po.purchaseOrder)",
                    subtitle: po.supplierName,
                    status: po.status.rawValue,
                    statusColor: FioriColors.positive,
                    footnote: "Supplier ID: \(po.supplier)",
                    description: "Standard S/4HANA PO Type \(po.purchaseOrderType) in Org \(po.purchasingOrganization).",
                    kpiValue: "$\(po.totalNetAmount)",
                    kpiCaption: "Total Net Commitment"
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            Section(header: Text("Procurement Organization")) {
                FUIKeyValueItem(key: "Supplier (LIFNR)", value: po.supplier)
                FUIKeyValueItem(key: "Purchasing Org (EKORG)", value: po.purchasingOrganization)
                FUIKeyValueItem(key: "Purchasing Group (EKGRP)", value: po.purchasingGroup)
                FUIKeyValueItem(key: "Company Code (BUKRS)", value: po.companyCode)
                FUIKeyValueItem(key: "Creation Date", value: po.creationDate.formatted(date: .abbreviated, time: .shortened))
            }
            
            Section(header: Text("Items Scheduled (\(po.items.count))")) {
                ForEach(po.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
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
                            Text("Qty: \(Int(item.orderQuantity)) \(item.orderUnit) • Plant: \(item.plant)")
                                .font(.caption)
                                .foregroundColor(FioriColors.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(po.purchaseOrder)
    }
}

// MARK: - Create Purchase Order Modal View
public struct CreatePurchaseOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreatePurchaseOrderViewModel()
    @State private var showSuccessDialog: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Supplier Selection (F4 Help)")) {
                    if let supplier = viewModel.selectedSupplier {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(supplier.supplierName)
                                    .font(.headline)
                                Text("Supplier ID: \(supplier.supplier) • Org: \(supplier.purchasingOrganization)")
                                    .font(.caption)
                                    .foregroundColor(FioriColors.secondaryText)
                            }
                            Spacer()
                            Button("Change") { viewModel.showVendorPicker = true }
                        }
                    } else {
                        Button(action: { viewModel.showVendorPicker = true }) {
                            HStack {
                                Image(systemName: "shippingbox.circle.fill")
                                    .foregroundColor(FioriColors.sapBlue)
                                Text("Select Vendor from Master Data...")
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("Line Items (\(viewModel.items.count))")
                    Spacer()
                    Button("Add Material") { viewModel.showMaterialPicker = true }
                        .font(.caption.bold())
                }) {
                    if viewModel.items.isEmpty {
                        Text("Tap 'Add Material' to include products in this PO.")
                            .font(.footnote)
                            .foregroundColor(FioriColors.secondaryText)
                    } else {
                        ForEach(viewModel.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.product.productDescription)
                                        .font(.subheadline.bold())
                                    Text("Qty: \(Int(item.quantity)) \(item.product.baseUnit) @ $\(item.negotiatedPrice)")
                                        .font(.caption)
                                        .foregroundColor(FioriColors.secondaryText)
                                }
                                Spacer()
                                Text("$\(item.netAmount)")
                                    .font(.subheadline.bold())
                            }
                        }
                        .onDelete(perform: viewModel.removeItem)
                    }
                }
                
                if !viewModel.items.isEmpty {
                    Section(header: Text("Order Valuation")) {
                        FUIKeyValueItem(
                            key: "Total PO Value (USD)",
                            value: "$\(viewModel.totalAmount)",
                            isHighlighted: true
                        )
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            let ok = await viewModel.submitPurchaseOrder()
                            if ok { showSuccessDialog = true }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSubmitting {
                                ProgressView()
                                Text("Posting Deep Insert to SAP...")
                            } else {
                                Image(systemName: "arrow.up.doc.fill")
                                Text("Create Purchase Order")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .navigationTitle("New Purchase Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showVendorPicker) {
                SupplierPickerSheet { supplier in
                    viewModel.selectedSupplier = supplier
                }
            }
            .sheet(isPresented: $viewModel.showMaterialPicker) {
                ProductPickerSheet { product in
                    viewModel.addMaterial(product)
                }
            }
            .alert("Purchase Order Created", isPresented: $showSuccessDialog) {
                Button("Done") { dismiss() }
            } message: {
                if let po = viewModel.createdPO {
                    Text("Committed to SAP S/4HANA (Client 220)!\n\nDocument ID: \(po.purchaseOrder)\nSupplier: \(po.supplierName)\nTotal: $\(po.totalNetAmount)")
                }
            }
        }
    }
}

