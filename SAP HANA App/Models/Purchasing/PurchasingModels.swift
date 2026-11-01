//
//  PurchasingModels.swift
//  SAPHANAApp
//
//  Data Models for SAP S/4HANA Materials Management / Sourcing & Procurement (MM)
//  Services: API_PURCHASEREQ_PROCESS_SRV, API_QTN_PROCESS_SRV, API_PURCHASEORDER_PROCESS_SRV
//

import Foundation

// MARK: - Purchasing Status
public enum SAPPurchaseStatus: String, Codable, CaseIterable, Sendable {
    case draft = "Draft"
    case inApproval = "In Approval"
    case approved = "Approved"
    case rejected = "Rejected"
    case orderPlaced = "Order Placed"
    case closed = "Closed"
}

// MARK: - Purchase Order Item Model
public struct PurchaseOrderItem: Identifiable, Codable, Sendable {
    public var id: String { "\(purchaseOrder)_\(itemNumber)" }
    public var purchaseOrder: String
    public var itemNumber: String             // e.g. "00010"
    public var material: String               // MATNR
    public var materialDescription: String    // TXZ01
    public var orderQuantity: Decimal         // MENGE
    public var orderUnit: String              // MEINS
    public var netPriceAmount: Decimal        // NETPR
    public var netAmount: Decimal             // NETWR
    public var currency: String               // WAERS
    public var plant: String                  // WERKS
    public var storageLocation: String        // LGORT
    
    public init(
        purchaseOrder: String = "",
        itemNumber: String = "00010",
        material: String,
        materialDescription: String,
        orderQuantity: Decimal,
        orderUnit: String = "EA",
        netPriceAmount: Decimal,
        netAmount: Decimal,
        currency: String = "USD",
        plant: String = "1010",
        storageLocation: String = "101A"
    ) {
        self.purchaseOrder = purchaseOrder
        self.itemNumber = itemNumber
        self.material = material
        self.materialDescription = materialDescription
        self.orderQuantity = orderQuantity
        self.orderUnit = orderUnit
        self.netPriceAmount = netPriceAmount
        self.netAmount = netAmount
        self.currency = currency
        self.plant = plant
        self.storageLocation = storageLocation
    }
    
    public func toODataDictionary() -> [String: Any] {
        return [
            "PurchaseOrderItem": itemNumber,
            "Material": material,
            "PurchaseOrderItemText": materialDescription,
            "OrderQuantity": "\(orderQuantity)",
            "PurchaseOrderQuantityUnit": orderUnit,
            "NetPriceAmount": "\(netPriceAmount)",
            "NetAmount": "\(netAmount)",
            "Plant": plant,
            "StorageLocation": storageLocation
        ]
    }
}

// MARK: - Purchase Order Header Model
public struct PurchaseOrder: Identifiable, Codable, Sendable {
    public var id: String { purchaseOrder }
    public var purchaseOrder: String           // EBELN, e.g. "4500000001"
    public var purchaseOrderType: String       // BSART, e.g. "NB"
    public var purchasingOrganization: String  // EKORG, e.g. "1010"
    public var purchasingGroup: String         // EKGRP, e.g. "001"
    public var companyCode: String             // BUKRS, e.g. "1010"
    public var supplier: String                // LIFNR, e.g. "10300001"
    public var supplierName: String
    public var creationDate: Date
    public var totalNetAmount: Decimal         // RLWRT
    public var currency: String                // WAERS
    public var status: SAPPurchaseStatus
    public var items: [PurchaseOrderItem]      // to_PurchaseOrderItem
    
    public init(
        purchaseOrder: String,
        purchaseOrderType: String = "NB",
        purchasingOrganization: String = "1010",
        purchasingGroup: String = "001",
        companyCode: String = "1010",
        supplier: String,
        supplierName: String,
        creationDate: Date = Date(),
        totalNetAmount: Decimal,
        currency: String = "USD",
        status: SAPPurchaseStatus = .approved,
        items: [PurchaseOrderItem] = []
    ) {
        self.purchaseOrder = purchaseOrder
        self.purchaseOrderType = purchaseOrderType
        self.purchasingOrganization = purchasingOrganization
        self.purchasingGroup = purchasingGroup
        self.companyCode = companyCode
        self.supplier = supplier
        self.supplierName = supplierName
        self.creationDate = creationDate
        self.totalNetAmount = totalNetAmount
        self.currency = currency
        self.status = status
        self.items = items
    }
    
    public func toDeepInsertDictionary() -> [String: Any] {
        let itemsPayload = items.enumerated().map { (index, item) -> [String: Any] in
            var dict = item.toODataDictionary()
            let formattedItemNo = String(format: "%05d", (index + 1) * 10)
            dict["PurchaseOrderItem"] = formattedItemNo
            return dict
        }
        
        return [
            "PurchaseOrderType": purchaseOrderType,
            "PurchasingOrganization": purchasingOrganization,
            "PurchasingGroup": purchasingGroup,
            "CompanyCode": companyCode,
            "Supplier": supplier,
            "to_PurchaseOrderItem": [
                "results": itemsPayload
            ]
        ]
    }
}

// MARK: - Purchase Requisition Model (API_PURCHASEREQ_PROCESS_SRV)
public struct PurchaseRequisition: Identifiable, Codable, Sendable {
    public var id: String { requisitionNumber }
    public var requisitionNumber: String     // BANFN
    public var requisitionType: String       // e.g. "NB"
    public var description: String
    public var requestedBy: String
    public var creationDate: Date
    public var totalAmount: Decimal
    public var currency: String
    public var status: SAPPurchaseStatus
    public var itemsCount: Int
    
    public init(
        requisitionNumber: String,
        requisitionType: String = "NB",
        description: String,
        requestedBy: String,
        creationDate: Date = Date(),
        totalAmount: Decimal,
        currency: String = "USD",
        status: SAPPurchaseStatus = .inApproval,
        itemsCount: Int = 1
    ) {
        self.requisitionNumber = requisitionNumber
        self.requisitionType = requisitionType
        self.description = description
        self.requestedBy = requestedBy
        self.creationDate = creationDate
        self.totalAmount = totalAmount
        self.currency = currency
        self.status = status
        self.itemsCount = itemsCount
    }
}

// MARK: - Purchase Quotation Comparison Matrix Model
public struct VendorQuotationBid: Identifiable, Codable, Sendable {
    public var id: String { quotationNumber }
    public var quotationNumber: String       // EBELN (RFQ / Quotation)
    public var collectiveRFQ: String         // SUBMI
    public var supplierId: String            // LIFNR
    public var supplierName: String
    public var unitPrice: Decimal
    public var totalAmount: Decimal
    public var currency: String
    public var deliveryLeadTimeDays: Int
    public var paymentTerms: String          // ZTERM, e.g. "Net 30 Days", "2% 10, Net 30"
    public var warrantyMonths: Int
    public var complianceScore: Double       // 0.0 to 100.0
    public var isLowestPrice: Bool
    public var isFastestDelivery: Bool
    public var isAwarded: Bool
    
    public init(
        quotationNumber: String,
        collectiveRFQ: String,
        supplierId: String,
        supplierName: String,
        unitPrice: Decimal,
        totalAmount: Decimal,
        currency: String = "USD",
        deliveryLeadTimeDays: Int,
        paymentTerms: String,
        warrantyMonths: Int = 12,
        complianceScore: Double = 95.0,
        isLowestPrice: Bool = false,
        isFastestDelivery: Bool = false,
        isAwarded: Bool = false
    ) {
        self.quotationNumber = quotationNumber
        self.collectiveRFQ = collectiveRFQ
        self.supplierId = supplierId
        self.supplierName = supplierName
        self.unitPrice = unitPrice
        self.totalAmount = totalAmount
        self.currency = currency
        self.deliveryLeadTimeDays = deliveryLeadTimeDays
        self.paymentTerms = paymentTerms
        self.warrantyMonths = warrantyMonths
        self.complianceScore = complianceScore
        self.isLowestPrice = isLowestPrice
        self.isFastestDelivery = isFastestDelivery
        self.isAwarded = isAwarded
    }
}

// MARK: - Collective RFQ Comparison Group
public struct QuotationComparisonSet: Identifiable, Codable, Sendable {
    public var id: String { collectiveRFQ }
    public var collectiveRFQ: String
    public var title: String
    public var material: String
    public var materialDescription: String
    public var requestedQuantity: Decimal
    public var uom: String
    public var targetDate: Date
    public var bids: [VendorQuotationBid]
    
    public init(
        collectiveRFQ: String,
        title: String,
        material: String,
        materialDescription: String,
        requestedQuantity: Decimal,
        uom: String = "EA",
        targetDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
        bids: [VendorQuotationBid]
    ) {
        self.collectiveRFQ = collectiveRFQ
        self.title = title
        self.material = material
        self.materialDescription = materialDescription
        self.requestedQuantity = requestedQuantity
        self.uom = uom
        
        // Calculate lowest price and fastest delivery
        let lowest = bids.min(by: { $0.unitPrice < $1.unitPrice })?.unitPrice
        let fastest = bids.min(by: { $0.deliveryLeadTimeDays < $1.deliveryLeadTimeDays })?.deliveryLeadTimeDays
        
        self.targetDate = targetDate
        self.bids = bids.map { bid in
            var updated = bid
            if let lowest = lowest, bid.unitPrice == lowest {
                updated.isLowestPrice = true
            }
            if let fastest = fastest, bid.deliveryLeadTimeDays == fastest {
                updated.isFastestDelivery = true
            }
            return updated
        }
    }
}

