//
//  CreateOrderViewModel.swift
//  SAPHANAApp
//
//  ViewModel managing multi-line Sales Order creation with
//  real-time pricing and OData Deep Insert execution (to_Item)
//

import Foundation
import Observation

public struct DraftOrderItem: Identifiable, Sendable {
    public let id = UUID()
    public var product: SAPProduct
    public var quantity: Decimal
    public var plant: String
    public var storageLocation: String
    
    public var netAmount: Decimal {
        product.standardPrice * quantity
    }
}

@Observable
@MainActor
public final class CreateOrderViewModel {
    
    private let repository = SAPDataRepository.shared
    
    // Header Form State
    public var selectedCustomer: SAPCustomer?
    public var salesOrderType: String = "OR"
    public var salesOrganization: String = "1010"
    public var distributionChannel: String = "10"
    public var organizationDivision: String = "00"
    public var purchaseOrderByCustomer: String = "PO-MOBILE-" + String(Int.random(in: 1000...9999))
    public var requestedDeliveryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    
    // Multi-line Item State
    public var items: [DraftOrderItem] = []
    
    // Execution State
    public var isSubmitting: Bool = false
    public var createdOrder: SalesOrder?
    public var errorMessage: String?
    public var showCustomerPicker: Bool = false
    public var showMaterialPicker: Bool = false
    
    public init() {}
    
    // MARK: - Calculations
    
    public var subtotal: Decimal {
        items.reduce(Decimal(0)) { $0 + $1.netAmount }
    }
    
    public var taxRate: Decimal {
        return Decimal(string: "0.18") ?? Decimal(0) // Standard 18% GST / VAT
    }
    
    public var taxAmount: Decimal {
        subtotal * taxRate
    }
    
    public var grandTotal: Decimal {
        subtotal + taxAmount
    }
    
    public var isValid: Bool {
        selectedCustomer != nil && !items.isEmpty && items.allSatisfy { $0.quantity > 0 }
    }
    
    // MARK: - Line Item Management
    
    public func addMaterial(_ product: SAPProduct) {
        let draft = DraftOrderItem(
            product: product,
            quantity: 1,
            plant: product.plant,
            storageLocation: "101A"
        )
        items.append(draft)
    }
    
    public func removeItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    public func updateQuantity(for id: UUID, newQuantity: Decimal) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if newQuantity > 0 {
            items[index].quantity = newQuantity
        }
    }
    
    // MARK: - Execute Deep Insert Creation
    
    public func submitSalesOrder() async -> Bool {
        guard isValid, let customer = selectedCustomer else {
            errorMessage = "Please select a Customer and add at least one line item."
            return false
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let orderItems: [SalesOrderItem] = items.enumerated().map { (index, draft) in
            let itemNo = String(format: "%06d", (index + 1) * 10)
            return SalesOrderItem(
                itemNumber: itemNo,
                material: draft.product.product,
                materialDescription: draft.product.productDescription,
                requestedQuantity: draft.quantity,
                requestedUoM: draft.product.baseUnit,
                netAmount: draft.netAmount,
                currency: draft.product.currency,
                plant: draft.plant,
                storageLocation: draft.storageLocation
            )
        }
        
        let newOrder = SalesOrder(
            salesOrder: "",
            salesOrderType: salesOrderType,
            salesOrganization: salesOrganization,
            distributionChannel: distributionChannel,
            organizationDivision: organizationDivision,
            soldToParty: customer.customer,
            customerName: customer.customerName,
            purchaseOrderByCustomer: purchaseOrderByCustomer,
            netAmount: grandTotal,
            currency: "USD",
            status: .open,
            items: orderItems
        )
        
        do {
            let result = try await repository.createSalesOrder(order: newOrder)
            self.createdOrder = result
            self.isSubmitting = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }
    
    public func resetForm() {
        selectedCustomer = nil
        items.removeAll()
        purchaseOrderByCustomer = "PO-MOBILE-" + String(Int.random(in: 1000...9999))
        createdOrder = nil
        errorMessage = nil
    }
}

