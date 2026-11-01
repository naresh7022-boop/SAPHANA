//
//  MasterDataViews.swift
//  SAPHANAApp
//
//  F4 Search Help Pickers & Master Data Directory Views
//  Services: API_PRODUCT_SRV, API_BUSINESS_PARTNER
//

import SwiftUI

// MARK: - Customer F4 Help Modal Picker
public struct CustomerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MasterDataPickerViewModel()
    public let onSelect: (SAPCustomer) -> Void
    
    public init(onSelect: @escaping (SAPCustomer) -> Void) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("SAP S/4HANA Customer Master (Client 220)")) {
                    ForEach(viewModel.customers) { customer in
                        Button(action: {
                            onSelect(customer)
                            dismiss()
                        }) {
                            FUIObjectCell(
                                iconName: "building.2.crop.circle.fill",
                                headline: customer.customerName,
                                subheadline: "Customer ID: \(customer.customer) • Org: \(customer.salesOrganization)",
                                footnote: "\(customer.city), \(customer.country) • Tax: \(customer.taxNumber)",
                                statusText: "$\(Int(customer.creditLimit))",
                                statusColor: FioriColors.sapBlue,
                                subStatusText: "Credit Limit"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText, prompt: "Search by Name, ID, or City...")
            .onChange(of: viewModel.searchText) { _, _ in
                Task { await viewModel.loadCustomers() }
            }
            .navigationTitle("Select Customer (F4)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadCustomers()
            }
        }
    }
}

// MARK: - Material / Product F4 Help Modal Picker
public struct ProductPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MasterDataPickerViewModel()
    public let onSelect: (SAPProduct) -> Void
    
    public init(onSelect: @escaping (SAPProduct) -> Void) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("SAP S/4HANA Product Master (API_PRODUCT_SRV)")) {
                    ForEach(viewModel.products) { product in
                        Button(action: {
                            onSelect(product)
                            dismiss()
                        }) {
                            FUIObjectCell(
                                iconName: "cube.box.fill",
                                headline: product.productDescription,
                                subheadline: "Material: \(product.product) • Plant: \(product.plant) • Type: \(product.productType)",
                                footnote: "Stock Available: \(product.plantStock) \(product.baseUnit)",
                                statusText: "$\(product.standardPrice)",
                                statusColor: FioriColors.positive,
                                subStatusText: "per \(product.baseUnit)"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText, prompt: "Search Material or Description...")
            .onChange(of: viewModel.searchText) { _, _ in
                Task { await viewModel.loadProducts() }
            }
            .navigationTitle("Select Material (F4)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadProducts()
            }
        }
    }
}

// MARK: - Vendor / Supplier F4 Help Modal Picker
public struct SupplierPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MasterDataPickerViewModel()
    public let onSelect: (SAPSupplier) -> Void
    
    public init(onSelect: @escaping (SAPSupplier) -> Void) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("SAP S/4HANA Vendor Master (A_Supplier)")) {
                    ForEach(viewModel.suppliers) { supplier in
                        Button(action: {
                            onSelect(supplier)
                            dismiss()
                        }) {
                            FUIObjectCell(
                                iconName: "shippingbox.circle.fill",
                                headline: supplier.supplierName,
                                subheadline: "Supplier ID: \(supplier.supplier) • Org: \(supplier.purchasingOrganization)",
                                footnote: "\(supplier.city), \(supplier.country) • Terms: \(supplier.paymentTerms)",
                                statusText: "\(supplier.ratingStars) ★",
                                statusColor: FioriColors.critical,
                                subStatusText: "Vendor Rating"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText, prompt: "Search Vendor Name or ID...")
            .onChange(of: viewModel.searchText) { _, _ in
                Task { await viewModel.loadSuppliers() }
            }
            .navigationTitle("Select Vendor (F4)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadSuppliers()
            }
        }
    }
}

// MARK: - Master Data Standalone Directory Views

public struct MaterialDirectoryView: View {
    @State private var viewModel = MasterDataPickerViewModel()
    
    public init() {}
    
    public var body: some View {
        List {
            Section(header: Text("Material Master Catalog (API_PRODUCT_SRV)")) {
                ForEach(viewModel.products) { product in
                    NavigationLink(destination: MaterialDetailView(product: product)) {
                        FUIObjectCell(
                            iconName: "cube.box.fill",
                            headline: product.productDescription,
                            subheadline: "Material: \(product.product) • Plant: \(product.plant)",
                            footnote: "Type: \(product.productType) • Group: \(product.productGroup)",
                            statusText: "$\(product.standardPrice)",
                            statusColor: FioriColors.sapBlue,
                            subStatusText: "Stock: \(Int(product.plantStock)) \(product.baseUnit)"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search product catalog...")
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.loadProducts() }
        }
        .navigationTitle("Material Master")
        .task {
            await viewModel.loadProducts()
        }
    }
}

public struct MaterialDetailView: View {
    public let product: SAPProduct
    
    public var body: some View {
        List {
            Section {
                FUIObjectHeader(
                    icon: "cube.box.fill",
                    title: product.productDescription,
                    subtitle: "Material Number: \(product.product)",
                    status: "\(Int(product.plantStock)) In Stock",
                    statusColor: product.plantStock > 0 ? FioriColors.positive : FioriColors.negative,
                    footnote: "Plant: \(product.plant) • Type: \(product.productType)",
                    description: "Standard SAP Product Master record on Client 220.",
                    kpiValue: "$\(product.standardPrice)",
                    kpiCaption: "Standard Moving Price"
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            Section(header: Text("Product Attributes")) {
                FUIKeyValueItem(key: "Material Number", value: product.product)
                FUIKeyValueItem(key: "Base Unit of Measure", value: product.baseUnit)
                FUIKeyValueItem(key: "Material Type", value: product.productType)
                FUIKeyValueItem(key: "Material Group", value: product.productGroup)
                FUIKeyValueItem(key: "Plant Assignment", value: product.plant)
                FUIKeyValueItem(key: "Stock Valuation", value: "$\(product.standardPrice * product.plantStock)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(product.product)
    }
}

public struct CustomerDirectoryView: View {
    @State private var viewModel = MasterDataPickerViewModel()
    
    public init() {}
    
    public var body: some View {
        List {
            Section(header: Text("Customer Accounts (API_BUSINESS_PARTNER)")) {
                ForEach(viewModel.customers) { customer in
                    NavigationLink(destination: CustomerDetailView(customer: customer)) {
                        FUIObjectCell(
                            iconName: "building.2.crop.circle.fill",
                            headline: customer.customerName,
                            subheadline: "ID: \(customer.customer) • \(customer.city), \(customer.country)",
                            footnote: "Sales Org: \(customer.salesOrganization) • Div: \(customer.division)",
                            statusText: "$\(Int(customer.creditLimit))",
                            statusColor: FioriColors.positive,
                            subStatusText: "Credit Available"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search customers...")
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.loadCustomers() }
        }
        .navigationTitle("Customer Directory")
        .task {
            await viewModel.loadCustomers()
        }
    }
}

public struct CustomerDetailView: View {
    public let customer: SAPCustomer
    
    public var body: some View {
        List {
            Section {
                FUIObjectHeader(
                    icon: "building.2.crop.circle.fill",
                    title: customer.customerName,
                    subtitle: "Customer ID: \(customer.customer)",
                    status: "Active Account",
                    statusColor: FioriColors.positive,
                    footnote: "\(customer.city), \(customer.country)",
                    description: "Business Partner Sold-to Party for Sales Organization \(customer.salesOrganization).",
                    kpiValue: "$\(Int(customer.creditLimit))",
                    kpiCaption: "Credit Limit"
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            Section(header: Text("Account Details")) {
                FUIKeyValueItem(key: "Customer ID", value: customer.customer)
                FUIKeyValueItem(key: "Sales Organization", value: customer.salesOrganization)
                FUIKeyValueItem(key: "Distribution Channel", value: customer.distributionChannel)
                FUIKeyValueItem(key: "Division", value: customer.division)
                FUIKeyValueItem(key: "Tax Registration / GST", value: customer.taxNumber)
                FUIKeyValueItem(key: "Location", value: "\(customer.city), \(customer.country)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(customer.customer)
    }
}

public struct VendorDirectoryView: View {
    @State private var viewModel = MasterDataPickerViewModel()
    
    public init() {}
    
    public var body: some View {
        List {
            Section(header: Text("Supplier Directory (API_BUSINESS_PARTNER)")) {
                ForEach(viewModel.suppliers) { supplier in
                    NavigationLink(destination: VendorDetailView(supplier: supplier)) {
                        FUIObjectCell(
                            iconName: "shippingbox.circle.fill",
                            headline: supplier.supplierName,
                            subheadline: "Supplier ID: \(supplier.supplier) • \(supplier.city)",
                            footnote: "Purchasing Org: \(supplier.purchasingOrganization) • Terms: \(supplier.paymentTerms)",
                            statusText: "\(supplier.ratingStars) ★",
                            statusColor: FioriColors.critical,
                            subStatusText: "Vendor Rating"
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, prompt: "Search suppliers...")
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.loadSuppliers() }
        }
        .navigationTitle("Vendor Directory")
        .task {
            await viewModel.loadSuppliers()
        }
    }
}

public struct VendorDetailView: View {
    public let supplier: SAPSupplier
    
    public var body: some View {
        List {
            Section {
                FUIObjectHeader(
                    icon: "shippingbox.circle.fill",
                    title: supplier.supplierName,
                    subtitle: "Supplier Number: \(supplier.supplier)",
                    status: "Approved Supplier",
                    statusColor: FioriColors.positive,
                    footnote: "Purchasing Org: \(supplier.purchasingOrganization)",
                    description: "Preferred S/4HANA Vendor for Procurement Operations.",
                    kpiValue: "\(supplier.ratingStars) / 5.0",
                    kpiCaption: "Quality & Lead Score"
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            Section(header: Text("Vendor Attributes")) {
                FUIKeyValueItem(key: "Supplier ID", value: supplier.supplier)
                FUIKeyValueItem(key: "Purchasing Organization", value: supplier.purchasingOrganization)
                FUIKeyValueItem(key: "Payment Terms", value: supplier.paymentTerms)
                FUIKeyValueItem(key: "Tax Registration", value: supplier.taxNumber)
                FUIKeyValueItem(key: "City / Country", value: "\(supplier.city), \(supplier.country)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(supplier.supplier)
    }
}

