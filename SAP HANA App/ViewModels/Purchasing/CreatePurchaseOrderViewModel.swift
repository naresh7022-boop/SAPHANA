//
//  CreatePurchaseOrderViewModel.swift
//  SAPHANAApp
//
//  ViewModel for Purchase Order Creation with Vendor F4 Help
//  and Deep Insert to API_PURCHASEORDER_PROCESS_SRV
//

import Foundation
import Observation

public struct DraftPurchaseItem: Identifiable, Sendable {
    public let id = UUID()
    public var product: SAPProduct
    public var quantity: Decimal
    public var negotiatedPrice: Decimal
    public var plant: String
    public var storageLocation: String
    
    public var netAmount: Decimal {
        negotiatedPrice * quantity
    }
}

@Observable
@MainActor
public final class CreatePurchaseOrderViewModel {
    
    private let repository = SAPDataRepository.shared
    
    // Header Fields
    public var selectedSupplier: SAPSupplier?
    public var purchaseOrderType: String = "NB"
    public var purchasingOrganization: String = "1010"
    public var purchasingGroup: String = "001"
    public var companyCode: String = "1010"
    public var targetDeliveryDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    
    // Line Items
    public var items: [DraftPurchaseItem] = []
    
    // UI State
    public var isSubmitting: Bool = false
    public var createdPO: PurchaseOrder?
    public var errorMessage: String?
    public var showVendorPicker: Bool = false
    public var showMaterialPicker: Bool = false
    
    public init() {}
    
    public var totalAmount: Decimal {
        items.reduce(Decimal(0)) { $0 + $1.netAmount }
    }
    
    public var isValid: Bool {
        selectedSupplier != nil && !items.isEmpty && items.allSatisfy { $0.quantity > 0 }
    }
    
    public func addMaterial(_ product: SAPProduct) {
        let draft = DraftPurchaseItem(
            product: product,
            quantity: 10,
            negotiatedPrice: product.standardPrice,
            plant: product.plant,
            storageLocation: "101A"
        )
        items.append(draft)
    }
    
    public func removeItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    public func submitPurchaseOrder() async -> Bool {
        guard isValid, let vendor = selectedSupplier else {
            errorMessage = "Please choose a Vendor and add at least one line item."
            return false
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let poItems: [PurchaseOrderItem] = items.enumerated().map { (idx, draft) in
            let itemNo = String(format: "%05d", (idx + 1) * 10)
            return PurchaseOrderItem(
                itemNumber: itemNo,
                material: draft.product.product,
                materialDescription: draft.product.productDescription,
                orderQuantity: draft.quantity,
                orderUnit: draft.product.baseUnit,
                netPriceAmount: draft.negotiatedPrice,
                netAmount: draft.netAmount,
                currency: "USD",
                plant: draft.plant,
                storageLocation: draft.storageLocation
            )
        }
        
        let newPO = PurchaseOrder(
            purchaseOrder: "",
            purchaseOrderType: purchaseOrderType,
            purchasingOrganization: purchasingOrganization,
            purchasingGroup: purchasingGroup,
            companyCode: companyCode,
            supplier: vendor.supplier,
            supplierName: vendor.supplierName,
            totalNetAmount: totalAmount,
            currency: "USD",
            status: .inApproval,
            items: poItems
        )
        
        do {
            let result = try await repository.createPurchaseOrder(po: newPO)
            self.createdPO = result
            self.isSubmitting = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }
}

