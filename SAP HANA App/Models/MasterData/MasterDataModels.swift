//
//  MasterDataModels.swift
//  SAPHANAApp
//
//  Master Data Entities & Value Help (F4 Search Help) Models
//  Services: API_PRODUCT_SRV, API_BUSINESS_PARTNER
//

import Foundation

// MARK: - Material Master (API_PRODUCT_SRV)
public struct SAPProduct: Identifiable, Codable, Sendable, Hashable {
    public var id: String { product }
    public var product: String                 // MATNR, e.g. "MZ-FG-M550"
    public var productType: String             // MTART, e.g. "FERT", "ROH"
    public var productGroup: String            // MATKL
    public var baseUnit: String                // MEINS, e.g. "PC", "KG"
    public var productDescription: String      // MAKTX
    public var plantStock: Decimal             // LABST
    public var standardPrice: Decimal          // STPRS
    public var currency: String                // WAERS
    public var plant: String                   // WERKS
    
    public init(
        product: String,
        productType: String = "FERT",
        productGroup: String = "01",
        baseUnit: String = "PC",
        productDescription: String,
        plantStock: Decimal = 100,
        standardPrice: Decimal,
        currency: String = "USD",
        plant: String = "1010"
    ) {
        self.product = product
        self.productType = productType
        self.productGroup = productGroup
        self.baseUnit = baseUnit
        self.productDescription = productDescription
        self.plantStock = plantStock
        self.standardPrice = standardPrice
        self.currency = currency
        self.plant = plant
    }
}

// MARK: - Customer Master (API_BUSINESS_PARTNER / A_Customer)
public struct SAPCustomer: Identifiable, Codable, Sendable, Hashable {
    public var id: String { customer }
    public var customer: String               // KUNNR, e.g. "1000001"
    public var customerName: String           // NAME1
    public var salesOrganization: String      // VKORG, e.g. "1010"
    public var distributionChannel: String    // VTWEG
    public var division: String               // SPART
    public var city: String                   // ORT01
    public var country: String                // LAND1
    public var creditLimit: Decimal           // Credit limit in currency
    public var currency: String
    public var taxNumber: String              // STCEG
    
    public init(
        customer: String,
        customerName: String,
        salesOrganization: String = "1010",
        distributionChannel: String = "10",
        division: String = "00",
        city: String,
        country: String = "US",
        creditLimit: Decimal = 50000.0,
        currency: String = "USD",
        taxNumber: String = "US987654321"
    ) {
        self.customer = customer
        self.customerName = customerName
        self.salesOrganization = salesOrganization
        self.distributionChannel = distributionChannel
        self.division = division
        self.city = city
        self.country = country
        self.creditLimit = creditLimit
        self.currency = currency
        self.taxNumber = taxNumber
    }
}

// MARK: - Vendor / Supplier Master (API_BUSINESS_PARTNER / A_Supplier)
public struct SAPSupplier: Identifiable, Codable, Sendable, Hashable {
    public var id: String { supplier }
    public var supplier: String               // LIFNR, e.g. "10300001"
    public var supplierName: String           // NAME1
    public var purchasingOrganization: String // EKORG, e.g. "1010"
    public var taxNumber: String              // Tax/GST No
    public var paymentTerms: String           // ZTERM
    public var city: String
    public var country: String
    public var currency: String
    public var ratingStars: Double            // 1.0 - 5.0 vendor evaluation
    
    public init(
        supplier: String,
        supplierName: String,
        purchasingOrganization: String = "1010",
        taxNumber: String = "GSTIN27AABCV1234F1Z9",
        paymentTerms: String = "NT30",
        city: String,
        country: String = "US",
        currency: String = "USD",
        ratingStars: Double = 4.8
    ) {
        self.supplier = supplier
        self.supplierName = supplierName
        self.purchasingOrganization = purchasingOrganization
        self.taxNumber = taxNumber
        self.paymentTerms = paymentTerms
        self.city = city
        self.country = country
        self.currency = currency
        self.ratingStars = ratingStars
    }
}

