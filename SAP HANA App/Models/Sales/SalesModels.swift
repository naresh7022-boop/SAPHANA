//
//  SalesModels.swift
//  SAPHANAApp
//
//  Data Models for SAP S/4HANA Sales & Distribution (SD)
//  Services: API_SALES_INQUIRY_SRV, API_SALES_QUOTATION_SRV, API_SALES_CONTRACT_SRV, API_SALES_ORDER_SRV
//

import Foundation

// MARK: - Transaction Status
public enum SAPSalesStatus: String, Codable, CaseIterable, Sendable {
    case open = "Open"
    case inProcess = "In Process"
    case pendingApproval = "Pending Approval"
    case approved = "Approved"
    case rejected = "Rejected"
    case completed = "Completed"
    
    public var badgeColor: String {
        switch self {
        case .open: return "blue"
        case .inProcess: return "orange"
        case .pendingApproval: return "yellow"
        case .approved: return "green"
        case .rejected: return "red"
        case .completed: return "gray"
        }
    }
}

// MARK: - Sales Order Item Model
public struct SalesOrderItem: Identifiable, Codable, Sendable {
    public var id: String { "\(salesOrder)_\(itemNumber)" }
    public var salesOrder: String
    public var itemNumber: String           // e.g. "000010"
    public var material: String             // MATNR, e.g. "TG11"
    public var materialDescription: String  // MAKTX
    public var requestedQuantity: Decimal   // KWMENG
    public var requestedUoM: String         // VRKME, e.g. "PC", "EA", "KG"
    public var netAmount: Decimal           // NETWR
    public var currency: String             // WAERK, e.g. "USD", "EUR", "INR"
    public var plant: String                // WERKS, e.g. "1010"
    public var storageLocation: String      // LGORT, e.g. "101A"
    
    public init(
        salesOrder: String = "",
        itemNumber: String = "000010",
        material: String,
        materialDescription: String,
        requestedQuantity: Decimal,
        requestedUoM: String = "EA",
        netAmount: Decimal,
        currency: String = "USD",
        plant: String = "1010",
        storageLocation: String = "101A"
    ) {
        self.salesOrder = salesOrder
        self.itemNumber = itemNumber
        self.material = material
        self.materialDescription = materialDescription
        self.requestedQuantity = requestedQuantity
        self.requestedUoM = requestedUoM
        self.netAmount = netAmount
        self.currency = currency
        self.plant = plant
        self.storageLocation = storageLocation
    }
    
    // Mapping for SAP OData Deep Insert payload (to_Item)
    public func toODataDictionary() -> [String: Any] {
        return [
            "SalesOrderItem": itemNumber,
            "Material": material,
            "RequestedQuantity": "\(requestedQuantity)",
            "RequestedQuantityUnit": requestedUoM,
            "NetAmount": "\(netAmount)",
            "TransactionCurrency": currency,
            "ProductionPlant": plant,
            "StorageLocation": storageLocation
        ]
    }
}

// MARK: - Sales Order Header Model
public struct SalesOrder: Identifiable, Codable, Sendable {
    public var id: String { salesOrder }
    public var salesOrder: String           // VBELN, e.g. "5000001"
    public var salesOrderType: String       // AUART, e.g. "OR"
    public var salesOrganization: String    // VKORG, e.g. "1010"
    public var distributionChannel: String  // VTWEG, e.g. "10"
    public var organizationDivision: String // SPART, e.g. "00"
    public var soldToParty: String          // KUNNR, e.g. "1000001"
    public var customerName: String         // Customer Name
    public var purchaseOrderByCustomer: String // BSTNK
    public var creationDate: Date
    public var netAmount: Decimal           // NETWR
    public var currency: String             // WAERK
    public var status: SAPSalesStatus
    public var items: [SalesOrderItem]      // to_Item
    
    public init(
        salesOrder: String,
        salesOrderType: String = "OR",
        salesOrganization: String = "1010",
        distributionChannel: String = "10",
        organizationDivision: String = "00",
        soldToParty: String,
        customerName: String,
        purchaseOrderByCustomer: String = "PO-MOBILE-REF",
        creationDate: Date = Date(),
        netAmount: Decimal,
        currency: String = "USD",
        status: SAPSalesStatus = .open,
        items: [SalesOrderItem] = []
    ) {
        self.salesOrder = salesOrder
        self.salesOrderType = salesOrderType
        self.salesOrganization = salesOrganization
        self.distributionChannel = distributionChannel
        self.organizationDivision = organizationDivision
        self.soldToParty = soldToParty
        self.customerName = customerName
        self.purchaseOrderByCustomer = purchaseOrderByCustomer
        self.creationDate = creationDate
        self.netAmount = netAmount
        self.currency = currency
        self.status = status
        self.items = items
    }
    
    // Helper for Deep Insert OData Payload
    public func toDeepInsertDictionary() -> [String: Any] {
        let itemsPayload = items.enumerated().map { (index, item) -> [String: Any] in
            var dict = item.toODataDictionary()
            let formattedItemNo = String(format: "%06d", (index + 1) * 10)
            dict["SalesOrderItem"] = formattedItemNo
            return dict
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        return [
            "SalesOrderType": salesOrderType,
            "SalesOrganization": salesOrganization,
            "DistributionChannel": distributionChannel,
            "OrganizationDivision": organizationDivision,
            "SoldToParty": soldToParty,
            "PurchaseOrderByCustomer": purchaseOrderByCustomer,
            "to_Item": [
                "results": itemsPayload
            ]
        ]
    }
}

// MARK: - Sales Inquiry Model (API_SALES_INQUIRY_SRV)
public struct SalesInquiry: Identifiable, Codable, Sendable {
    public var id: String { inquiryNumber }
    public var inquiryNumber: String        // VBELN
    public var inquiryType: String          // e.g. "IN"
    public var soldToParty: String
    public var customerName: String
    public var creationDate: Date
    public var validToDate: Date
    public var netAmount: Decimal
    public var currency: String
    public var status: SAPSalesStatus
    public var itemsCount: Int
    
    public init(
        inquiryNumber: String,
        inquiryType: String = "IN",
        soldToParty: String,
        customerName: String,
        creationDate: Date = Date(),
        validToDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
        netAmount: Decimal,
        currency: String = "USD",
        status: SAPSalesStatus = .open,
        itemsCount: Int = 1
    ) {
        self.inquiryNumber = inquiryNumber
        self.inquiryType = inquiryType
        self.soldToParty = soldToParty
        self.customerName = customerName
        self.creationDate = creationDate
        self.validToDate = validToDate
        self.netAmount = netAmount
        self.currency = currency
        self.status = status
        self.itemsCount = itemsCount
    }
}

// MARK: - Sales Quotation Model (API_SALES_QUOTATION_SRV)
public struct SalesQuotation: Identifiable, Codable, Sendable {
    public var id: String { quotationNumber }
    public var quotationNumber: String      // VBELN
    public var quotationType: String        // e.g. "QT"
    public var soldToParty: String
    public var customerName: String
    public var creationDate: Date
    public var bindingPeriodEndDate: Date
    public var netAmount: Decimal
    public var currency: String
    public var status: SAPSalesStatus
    public var probabilityPercent: Int
    
    public init(
        quotationNumber: String,
        quotationType: String = "QT",
        soldToParty: String,
        customerName: String,
        creationDate: Date = Date(),
        bindingPeriodEndDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        netAmount: Decimal,
        currency: String = "USD",
        status: SAPSalesStatus = .open,
        probabilityPercent: Int = 75
    ) {
        self.quotationNumber = quotationNumber
        self.quotationType = quotationType
        self.soldToParty = soldToParty
        self.customerName = customerName
        self.creationDate = creationDate
        self.bindingPeriodEndDate = bindingPeriodEndDate
        self.netAmount = netAmount
        self.currency = currency
        self.status = status
        self.probabilityPercent = probabilityPercent
    }
}

// MARK: - Sales Contract Model (API_SALES_CONTRACT_SRV)
public struct SalesContract: Identifiable, Codable, Sendable {
    public var id: String { contractNumber }
    public var contractNumber: String       // VBELN
    public var contractType: String         // e.g. "CQ" (Quantity) or "WK" (Value)
    public var soldToParty: String
    public var customerName: String
    public var contractStartDate: Date
    public var contractEndDate: Date
    public var targetAmount: Decimal
    public var releasedAmount: Decimal
    public var currency: String
    public var status: SAPSalesStatus
    
    public var fulfillmentPercentage: Double {
        guard targetAmount > 0 else { return 0.0 }
        return Double(truncating: (releasedAmount / targetAmount) as NSNumber) * 100.0
    }
    
    public init(
        contractNumber: String,
        contractType: String = "CQ",
        soldToParty: String,
        customerName: String,
        contractStartDate: Date = Date(),
        contractEndDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
        targetAmount: Decimal,
        releasedAmount: Decimal = 0,
        currency: String = "USD",
        status: SAPSalesStatus = .open
    ) {
        self.contractNumber = contractNumber
        self.contractType = contractType
        self.soldToParty = soldToParty
        self.customerName = customerName
        self.contractStartDate = contractStartDate
        self.contractEndDate = contractEndDate
        self.targetAmount = targetAmount
        self.releasedAmount = releasedAmount
        self.currency = currency
        self.status = status
    }
}

