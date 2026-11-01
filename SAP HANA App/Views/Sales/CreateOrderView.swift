//
//  CreateOrderView.swift
//  SAPHANAApp
//
//  SAP S/4HANA Sales Order Creation Form with Master Data Value Help (F4)
//  Executes Real-Time OData Deep Insert (to_Item) to 172.27.100.32 (Client 220)
//

import SwiftUI

public struct CreateOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateOrderViewModel()
    @State private var showSuccessDialog = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Header Banner
                Section {
                    FUIBannerMessageView(
                        message: "Creating Sales Order on SAP S/4HANA (Host: 172.27.100.32, Client: 220)",
                        type: .info
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Section 1: Customer Selection (Value Help F4)
                Section(header: Text("Customer / Sold-To Party (F4 Help)")) {
                    if let customer = viewModel.selectedCustomer {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(customer.customerName)
                                    .font(.headline)
                                Text("Customer ID: \(customer.customer) • \(customer.city)")
                                    .font(.caption)
                                    .foregroundColor(FioriColors.secondaryText)
                                Text("Credit Limit: $\(Int(customer.creditLimit)) • Sales Org: \(customer.salesOrganization)")
                                    .font(.caption2)
                                    .foregroundColor(FioriColors.sapBlue)
                            }
                            Spacer()
                            Button("Change") {
                                viewModel.showCustomerPicker = true
                            }
                            .font(.subheadline)
                        }
                    } else {
                        Button(action: {
                            viewModel.showCustomerPicker = true
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundColor(FioriColors.sapBlue)
                                Text("Select Customer from Master Data...")
                                    .foregroundColor(FioriColors.sapBlue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Section 2: Order Header Details
                Section(header: Text("Sales Document Configuration")) {
                    HStack {
                        Text("Order Type")
                            .foregroundColor(FioriColors.secondaryText)
                        Spacer()
                        Text(viewModel.salesOrderType)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Sales Organization")
                            .foregroundColor(FioriColors.secondaryText)
                        Spacer()
                        Text(viewModel.salesOrganization)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Customer PO Reference")
                            .foregroundColor(FioriColors.secondaryText)
                        Spacer()
                        TextField("Customer PO Ref", text: $viewModel.purchaseOrderByCustomer)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Requested Delivery", selection: $viewModel.requestedDeliveryDate, displayedComponents: .date)
                }
                
                // Section 3: Multi-Line Items (Materials)
                Section(header: HStack {
                    Text("Line Items (\(viewModel.items.count))")
                    Spacer()
                    Button(action: {
                        viewModel.showMaterialPicker = true
                    }) {
                        Label("Add Material", systemImage: "plus.circle.fill")
                            .font(.caption.bold())
                    }
                }) {
                    if viewModel.items.isEmpty {
                        Text("No materials added yet. Tap 'Add Material' to open the Product Catalog.")
                            .font(.footnote)
                            .foregroundColor(FioriColors.secondaryText)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(viewModel.items) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.product.productDescription)
                                            .font(.subheadline.bold())
                                        Text("Material: \(item.product.product) • Plant: \(item.plant)")
                                            .font(.caption2)
                                            .foregroundColor(FioriColors.secondaryText)
                                    }
                                    Spacer()
                                    Text("$\(item.netAmount)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(FioriColors.sapBlue)
                                }
                                
                                HStack {
                                    Stepper(value: Binding(
                                        get: { item.quantity },
                                        set: { newQty in viewModel.updateQuantity(for: item.id, newQuantity: newQty) }
                                    ), in: 1...999) {
                                        Text("Qty: \(Int(item.quantity)) \(item.product.baseUnit) @ $\(item.product.standardPrice)")
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.removeItem)
                    }
                }
                
                // Section 4: Real-time Pricing Summary
                if !viewModel.items.isEmpty {
                    Section(header: Text("Pricing & Tax Calculation")) {
                        FUIKeyValueItem(key: "Net Items Value", value: "$\(viewModel.subtotal)")
                        FUIKeyValueItem(key: "Estimated Tax (18% GST)", value: "$\(viewModel.taxAmount)")
                        FUIKeyValueItem(
                            key: "Total Net Amount (USD)",
                            value: "$\(viewModel.grandTotal)",
                            isHighlighted: true
                        )
                    }
                }
                
                // Error display
                if let error = viewModel.errorMessage {
                    Section {
                        FUIBannerMessageView(message: error, type: .error)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Section 5: Submit Deep Insert
                Section {
                    Button(action: {
                        Task {
                            let success = await viewModel.submitSalesOrder()
                            if success {
                                showSuccessDialog = true
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Executing OData Deep Insert...")
                                    .fontWeight(.bold)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Create Sales Order (Deep Insert)")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .navigationTitle("New Sales Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showCustomerPicker) {
                CustomerPickerSheet { customer in
                    viewModel.selectedCustomer = customer
                }
            }
            .sheet(isPresented: $viewModel.showMaterialPicker) {
                ProductPickerSheet { product in
                    viewModel.addMaterial(product)
                }
            }
            .alert("Sales Order Created", isPresented: $showSuccessDialog) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let order = viewModel.createdOrder {
                    Text("Successfully committed to SAP S/4HANA (Client 220)!\n\nDocument ID: \(order.salesOrder)\nCustomer: \(order.customerName)\nItems: \(order.items.count)\nTotal: $\(order.netAmount)")
                } else {
                    Text("Transaction created successfully.")
                }
            }
        }
    }
}

