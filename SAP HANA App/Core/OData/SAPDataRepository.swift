//
//  SAPDataRepository.swift
//  SAPHANAApp
//
//  Unified Data Repository for all SAP Modules:
//  SD, MM, CRM, Master Data Pickers, and Approvals
//

import Foundation
import Observation

/// Central data repository managing local and remote datasets for all 13 sub-modules
@Observable
public final class SAPDataRepository: @unchecked Sendable {
    
    public static let shared = SAPDataRepository()
    
    private let odata = ODataServiceLayer.shared
    private let connection = SAPConnectionManager.shared
    
    // MARK: - In-Memory State & Cache
    public var salesOrders: [SalesOrder] = []
    public var salesInquiries: [SalesInquiry] = []
    public var salesQuotations: [SalesQuotation] = []
    public var salesContracts: [SalesContract] = []
    
    public var purchaseOrders: [PurchaseOrder] = []
    public var purchaseRequisitions: [PurchaseRequisition] = []
    public var quotationComparisonSets: [QuotationComparisonSet] = []
    
    public var products: [SAPProduct] = []
    public var suppliers: [SAPSupplier] = []
    public var customers: [SAPCustomer] = []
    
    public var activities: [CRMActivity] = []
    public var tasks: [CRMTask] = []
    public var approvalTasks: [ApprovalTask] = []
    
    private init() {
        loadMockBaselineData()
    }
    
    // MARK: - SD (Sales) Operations
    
    public func fetchSalesOrders(search: String = "") async throws -> [SalesOrder] {
        if case .connected = connection.connectionStatus {
            let query = ODataQueryBuilder()
                .expand(["to_Item"])
                .top(50)
                .orderBy("CreationDate", ascending: false)
                .searchFilter(query: search, fields: ["SalesOrder", "SoldToParty", "CustomerName"])
            
            let raw = try await odata.fetchEntities(
                serviceName: SAPServerConfig.Services.salesOrder,
                entitySet: SAPServerConfig.EntitySets.salesOrders,
                query: query
            )
            
            if !raw.isEmpty {
                // Map OData JSON to SalesOrder
                self.salesOrders = raw.compactMap { dict in
                    guard let id = dict["SalesOrder"] as? String else { return nil }
                    let customer = dict["SoldToParty"] as? String ?? "1000001"
                    let customerName = dict["CustomerName"] as? String ?? "Global Enterprise Ltd"
                    let net = Decimal(string: dict["NetAmount"] as? String ?? "0") ?? 12500
                    return SalesOrder(
                        salesOrder: id,
                        soldToParty: customer,
                        customerName: customerName,
                        netAmount: net,
                        status: .approved
                    )
                }
            }
        }
        
        if search.isEmpty {
            return salesOrders
        } else {
            return salesOrders.filter {
                $0.salesOrder.localizedCaseInsensitiveContains(search) ||
                $0.customerName.localizedCaseInsensitiveContains(search)
            }
        }
    }
    
    public func createSalesOrder(order: SalesOrder) async throws -> SalesOrder {
        if case .connected = connection.connectionStatus {
            let payload = order.toDeepInsertDictionary()
            let response = try await odata.createDeepEntity(
                serviceName: SAPServerConfig.Services.salesOrder,
                entitySet: SAPServerConfig.EntitySets.salesOrders,
                payload: payload
            )
            
            let generatedId = response["SalesOrder"] as? String ?? String(format: "%010d", Int.random(in: 5000010...5000999))
            var created = order
            created.salesOrder = generatedId
            self.salesOrders.insert(created, at: 0)
            return created
        } else {
            // Local / Offline Simulation
            var created = order
            let mockId = String(format: "%010d", Int.random(in: 5000100...5000999))
            created.salesOrder = mockId
            self.salesOrders.insert(created, at: 0)
            return created
        }
    }
    
    // MARK: - MM (Purchasing) Operations
    
    public func fetchPurchaseOrders(search: String = "") async throws -> [PurchaseOrder] {
        if case .connected = connection.connectionStatus {
            let query = ODataQueryBuilder()
                .expand(["to_PurchaseOrderItem"])
                .top(50)
                .orderBy("CreationDate", ascending: false)
                .searchFilter(query: search, fields: ["PurchaseOrder", "Supplier", "SupplierName"])
            
            let raw = try await odata.fetchEntities(
                serviceName: SAPServerConfig.Services.purchaseOrder,
                entitySet: SAPServerConfig.EntitySets.purchaseOrders,
                query: query
            )
            
            if !raw.isEmpty {
                self.purchaseOrders = raw.compactMap { dict in
                    guard let id = dict["PurchaseOrder"] as? String else { return nil }
                    let supplier = dict["Supplier"] as? String ?? "10300001"
                    let supplierName = dict["SupplierName"] as? String ?? "Acme Components GmbH"
                    let net = Decimal(string: dict["TotalNetAmount"] as? String ?? "0") ?? 48200
                    return PurchaseOrder(
                        purchaseOrder: id,
                        supplier: supplier,
                        supplierName: supplierName,
                        totalNetAmount: net,
                        status: .approved
                    )
                }
            }
        }
        
        if search.isEmpty {
            return purchaseOrders
        } else {
            return purchaseOrders.filter {
                $0.purchaseOrder.localizedCaseInsensitiveContains(search) ||
                $0.supplierName.localizedCaseInsensitiveContains(search)
            }
        }
    }
    
    public func createPurchaseOrder(po: PurchaseOrder) async throws -> PurchaseOrder {
        if case .connected = connection.connectionStatus {
            let payload = po.toDeepInsertDictionary()
            let response = try await odata.createDeepEntity(
                serviceName: SAPServerConfig.Services.purchaseOrder,
                entitySet: SAPServerConfig.EntitySets.purchaseOrders,
                payload: payload
            )
            
            let generatedId = response["PurchaseOrder"] as? String ?? String(format: "%010d", Int.random(in: 450000100...450000999))
            var created = po
            created.purchaseOrder = generatedId
            self.purchaseOrders.insert(created, at: 0)
            return created
        } else {
            var created = po
            let mockId = String(format: "%010d", Int.random(in: 450000100...450000999))
            created.purchaseOrder = mockId
            self.purchaseOrders.insert(created, at: 0)
            return created
        }
    }
    
    // MARK: - Quotation Comparison & Award
    
    public func awardQuotation(collectiveRFQ: String, quotationNumber: String) async throws -> PurchaseOrder {
        guard let groupIndex = quotationComparisonSets.firstIndex(where: { $0.collectiveRFQ == collectiveRFQ }) else {
            throw NSError(domain: "SAPRFQ", code: 404, userInfo: [NSLocalizedDescriptionKey: "RFQ Not found"])
        }
        
        // Find winning bid
        guard let bid = quotationComparisonSets[groupIndex].bids.first(where: { $0.quotationNumber == quotationNumber }) else {
            throw NSError(domain: "SAPRFQ", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bid Not found"])
        }
        
        // Update bid states
        quotationComparisonSets[groupIndex].bids = quotationComparisonSets[groupIndex].bids.map { b in
            var updated = b
            updated.isAwarded = (b.quotationNumber == quotationNumber)
            return updated
        }
        
        // Convert to PO via Deep Insert
        let poItem = PurchaseOrderItem(
            material: quotationComparisonSets[groupIndex].material,
            materialDescription: quotationComparisonSets[groupIndex].materialDescription,
            orderQuantity: quotationComparisonSets[groupIndex].requestedQuantity,
            orderUnit: quotationComparisonSets[groupIndex].uom,
            netPriceAmount: bid.unitPrice,
            netAmount: bid.totalAmount
        )
        
        let newPO = PurchaseOrder(
            purchaseOrder: "",
            supplier: bid.supplierId,
            supplierName: bid.supplierName,
            totalNetAmount: bid.totalAmount,
            status: .approved,
            items: [poItem]
        )
        
        let createdPO = try await createPurchaseOrder(po: newPO)
        return createdPO
    }
    
    // MARK: - Approval Decisions (Function Imports)
    
    public func approveTask(taskId: String) async throws {
        if case .connected = connection.connectionStatus {
            _ = try await odata.executeFunctionImport(
                serviceName: SAPServerConfig.Services.taskProcessing,
                functionName: "ApproveTask",
                parameters: ["TaskId": taskId]
            )
        }
        
        if let idx = approvalTasks.firstIndex(where: { $0.taskId == taskId }) {
            approvalTasks[idx].isProcessed = true
            approvalTasks[idx].decision = "APPROVED"
        }
    }
    
    public func rejectTask(taskId: String, reason: String) async throws {
        if case .connected = connection.connectionStatus {
            _ = try await odata.executeFunctionImport(
                serviceName: SAPServerConfig.Services.taskProcessing,
                functionName: "RejectTask",
                parameters: ["TaskId": taskId, "Reason": reason]
            )
        }
        
        if let idx = approvalTasks.firstIndex(where: { $0.taskId == taskId }) {
            approvalTasks[idx].isProcessed = true
            approvalTasks[idx].decision = "REJECTED"
            approvalTasks[idx].comments = reason
        }
    }
    
    // MARK: - Master Data Pickers (F4 Help)
    
    public func fetchProducts(search: String = "") async throws -> [SAPProduct] {
        if search.isEmpty {
            return products
        }
        return products.filter {
            $0.product.localizedCaseInsensitiveContains(search) ||
            $0.productDescription.localizedCaseInsensitiveContains(search)
        }
    }
    
    public func fetchSuppliers(search: String = "") async throws -> [SAPSupplier] {
        if search.isEmpty {
            return suppliers
        }
        return suppliers.filter {
            $0.supplier.localizedCaseInsensitiveContains(search) ||
            $0.supplierName.localizedCaseInsensitiveContains(search) ||
            $0.city.localizedCaseInsensitiveContains(search)
        }
    }
    
    public func fetchCustomers(search: String = "") async throws -> [SAPCustomer] {
        if search.isEmpty {
            return customers
        }
        return customers.filter {
            $0.customer.localizedCaseInsensitiveContains(search) ||
            $0.customerName.localizedCaseInsensitiveContains(search) ||
            $0.city.localizedCaseInsensitiveContains(search)
        }
    }
    
    // MARK: - Baseline Enterprise Datasets
    
    private func loadMockBaselineData() {
        // Products
        self.products = [
            SAPProduct(product: "TG11", productType: "FERT", productGroup: "ELEC", baseUnit: "EA", productDescription: "Hydraulic Pump Unit High-Pressure 240V", plantStock: 45, standardPrice: 1250.00, plant: "1010"),
            SAPProduct(product: "TG12", productType: "FERT", productGroup: "ELEC", baseUnit: "EA", productDescription: "Precision Stepper Motor Assembly 48V", plantStock: 120, standardPrice: 420.50, plant: "1010"),
            SAPProduct(product: "RM201", productType: "ROH", productGroup: "RAW", baseUnit: "KG", productDescription: "Industrial Titanium Alloy Sheet 5mm", plantStock: 850, standardPrice: 48.00, plant: "1010"),
            SAPProduct(product: "SV900", productType: "DIEN", productGroup: "SERV", baseUnit: "HR", productDescription: "On-Site Installation & Calibration Service", plantStock: 999, standardPrice: 150.00, plant: "1010"),
            SAPProduct(product: "TG15", productType: "FERT", productGroup: "MECH", baseUnit: "SET", productDescription: "Heavy-Duty Ceramic Ball Bearings (Set of 4)", plantStock: 340, standardPrice: 85.00, plant: "1010")
        ]
        
        // Customers
        self.customers = [
            SAPCustomer(customer: "1000001", customerName: "Apex Manufacturing Inc.", salesOrganization: "1010", city: "Detroit", country: "US", creditLimit: 250000.0, taxNumber: "US382910491"),
            SAPCustomer(customer: "1000042", customerName: "Vortex Aero Systems AG", salesOrganization: "1010", city: "Munich", country: "DE", creditLimit: 500000.0, taxNumber: "DE129485732"),
            SAPCustomer(customer: "1000088", customerName: "Pacific Precision Machinery", salesOrganization: "1010", city: "Tokyo", country: "JP", creditLimit: 150000.0, taxNumber: "JP948372615"),
            SAPCustomer(customer: "1000115", customerName: "OmniTech Solutions Corp", salesOrganization: "1010", city: "Austin", country: "US", creditLimit: 100000.0, taxNumber: "US746392019")
        ]
        
        // Suppliers
        self.suppliers = [
            SAPSupplier(supplier: "10300001", supplierName: "Alpha Industrial Metals Corp", purchasingOrganization: "1010", taxNumber: "GSTIN27AABCV1234F1Z9", paymentTerms: "NT30", city: "Chicago", ratingStars: 4.9),
            SAPSupplier(supplier: "10300025", supplierName: "Global Seal & Gasket Ltd", purchasingOrganization: "1010", taxNumber: "GB948372019", paymentTerms: "2% 10 Net 30", city: "Manchester", ratingStars: 4.7),
            SAPSupplier(supplier: "10300067", supplierName: "Shinsei Precision Hydraulics", purchasingOrganization: "1010", taxNumber: "JP293847561", paymentTerms: "NT60", city: "Osaka", ratingStars: 4.8),
            SAPSupplier(supplier: "10300099", supplierName: "EuroTech Components GmbH", purchasingOrganization: "1010", taxNumber: "DE847362910", paymentTerms: "NT30", city: "Stuttgart", ratingStars: 4.6)
        ]
        
        // Sales Orders
        let item1 = SalesOrderItem(salesOrder: "5000001", itemNumber: "000010", material: "TG11", materialDescription: "Hydraulic Pump Unit High-Pressure 240V", requestedQuantity: 10, netAmount: 12500.0)
        let item2 = SalesOrderItem(salesOrder: "5000001", itemNumber: "000020", material: "TG15", materialDescription: "Heavy-Duty Ceramic Ball Bearings (Set of 4)", requestedQuantity: 20, netAmount: 1700.0)
        
        self.salesOrders = [
            SalesOrder(salesOrder: "5000001", soldToParty: "1000001", customerName: "Apex Manufacturing Inc.", purchaseOrderByCustomer: "PO-APX-8492", netAmount: 14200.0, status: .approved, items: [item1, item2]),
            SalesOrder(salesOrder: "5000002", soldToParty: "1000042", customerName: "Vortex Aero Systems AG", purchaseOrderByCustomer: "PO-VRX-1120", netAmount: 84100.0, status: .inProcess, items: [
                SalesOrderItem(salesOrder: "5000002", itemNumber: "000010", material: "TG12", materialDescription: "Precision Stepper Motor Assembly 48V", requestedQuantity: 200, netAmount: 84100.0)
            ]),
            SalesOrder(salesOrder: "5000003", soldToParty: "1000115", customerName: "OmniTech Solutions Corp", purchaseOrderByCustomer: "PO-OMN-9943", netAmount: 32000.0, status: .open, items: [])
        ]
        
        // Sales Inquiries & Quotations & Contracts
        self.salesInquiries = [
            SalesInquiry(inquiryNumber: "1000004", soldToParty: "1000001", customerName: "Apex Manufacturing Inc.", netAmount: 45000.0, status: .open, itemsCount: 4),
            SalesInquiry(inquiryNumber: "1000005", soldToParty: "1000088", customerName: "Pacific Precision Machinery", netAmount: 92000.0, status: .inProcess, itemsCount: 8)
        ]
        
        self.salesQuotations = [
            SalesQuotation(quotationNumber: "2000012", soldToParty: "1000042", customerName: "Vortex Aero Systems AG", netAmount: 125000.0, status: .pendingApproval, probabilityPercent: 85),
            SalesQuotation(quotationNumber: "2000019", soldToParty: "1000115", customerName: "OmniTech Solutions Corp", netAmount: 28500.0, status: .open, probabilityPercent: 60)
        ]
        
        self.salesContracts = [
            SalesContract(contractNumber: "4000001", soldToParty: "1000001", customerName: "Apex Manufacturing Inc.", targetAmount: 500000.0, releasedAmount: 215000.0, status: .approved),
            SalesContract(contractNumber: "4000008", soldToParty: "1000042", customerName: "Vortex Aero Systems AG", targetAmount: 1200000.0, releasedAmount: 890000.0, status: .approved)
        ]
        
        // Purchase Orders
        let poItem1 = PurchaseOrderItem(purchaseOrder: "4500000001", itemNumber: "00010", material: "RM201", materialDescription: "Industrial Titanium Alloy Sheet 5mm", orderQuantity: 1000, orderUnit: "KG", netPriceAmount: 48.0, netAmount: 48000.0)
        self.purchaseOrders = [
            PurchaseOrder(purchaseOrder: "4500000001", supplier: "10300001", supplierName: "Alpha Industrial Metals Corp", totalNetAmount: 48000.0, status: .approved, items: [poItem1]),
            PurchaseOrder(purchaseOrder: "4500000002", supplier: "10300025", supplierName: "Global Seal & Gasket Ltd", totalNetAmount: 19400.0, status: .orderPlaced, items: []),
            PurchaseOrder(purchaseOrder: "4500000003", supplier: "10300067", supplierName: "Shinsei Precision Hydraulics", totalNetAmount: 67300.0, status: .inApproval, items: [])
        ]
        
        self.purchaseRequisitions = [
            PurchaseRequisition(requisitionNumber: "10000192", description: "Q4 Raw Material Restocking for Plant 1010", requestedBy: "NARESH", totalAmount: 78500.0, status: .inApproval, itemsCount: 6),
            PurchaseRequisition(requisitionNumber: "10000240", description: "Cleanroom Equipment Maintenance Components", requestedBy: "ENGINEERING", totalAmount: 21300.0, status: .approved, itemsCount: 2)
        ]
        
        // Quotation Comparison Matrix Data (Collective RFQ)
        let bid1 = VendorQuotationBid(quotationNumber: "60000011", collectiveRFQ: "RFQ_COLLECTIVE_1001", supplierId: "10300001", supplierName: "Alpha Industrial Metals Corp", unitPrice: 48.0, totalAmount: 48000.0, deliveryLeadTimeDays: 7, paymentTerms: "NT30", warrantyMonths: 24, complianceScore: 98.0)
        let bid2 = VendorQuotationBid(quotationNumber: "60000012", collectiveRFQ: "RFQ_COLLECTIVE_1001", supplierId: "10300025", supplierName: "Global Seal & Gasket Ltd", unitPrice: 52.5, totalAmount: 52500.0, deliveryLeadTimeDays: 4, paymentTerms: "2% 10 Net 30", warrantyMonths: 18, complianceScore: 94.0)
        let bid3 = VendorQuotationBid(quotationNumber: "60000013", collectiveRFQ: "RFQ_COLLECTIVE_1001", supplierId: "10300099", supplierName: "EuroTech Components GmbH", unitPrice: 46.5, totalAmount: 46500.0, deliveryLeadTimeDays: 14, paymentTerms: "NT60", warrantyMonths: 12, complianceScore: 92.0)
        
        self.quotationComparisonSets = [
            QuotationComparisonSet(
                collectiveRFQ: "RFQ_COLLECTIVE_1001",
                title: "Procurement of Titanium Alloy Sheets (1,000 KG)",
                material: "RM201",
                materialDescription: "Industrial Titanium Alloy Sheet 5mm",
                requestedQuantity: 1000,
                uom: "KG",
                bids: [bid1, bid2, bid3]
            )
        ]
        
        // CRM
        self.activities = [
            CRMActivity(title: "Contract Renewal Negotiation", type: .clientMeeting, businessPartnerId: "1000001", businessPartnerName: "Apex Manufacturing Inc.", notes: "Discussed multi-year supply agreement. Client requested 5% volume rebate on TG11 pumps."),
            CRMActivity(title: "Supplier Lead-Time Audit", type: .onSiteVisit, businessPartnerId: "10300001", businessPartnerName: "Alpha Industrial Metals Corp", notes: "Reviewed manufacturing line at Chicago warehouse. Plant confirmed 7-day turnaround for bulk orders."),
            CRMActivity(title: "Urgent Expedite Call", type: .phoneCall, businessPartnerId: "1000042", businessPartnerName: "Vortex Aero Systems AG", notes: "Confirmed priority shipment for SO 5000002 stepper motors.")
        ]
        
        self.tasks = [
            CRMTask(title: "Approve High-Value Purchase Order", details: "PO 4500000003 exceeds $50k threshold for hydraulic parts.", priority: .urgent, status: .notStarted, dueDate: Date(), relatedDocumentRef: "PO# 4500000003"),
            CRMTask(title: "Review Collective RFQ 1001 Matrix", details: "Compare vendor quotes from Alpha, Global Seal, and EuroTech.", priority: .high, status: .inProgress, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), relatedDocumentRef: "RFQ_COLLECTIVE_1001"),
            CRMTask(title: "Audit Plant 1010 Inventory Counts", details: "Quarterly stock variance reconciliation for FERT materials.", priority: .medium, status: .notStarted, dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())
        ]
        
        // Approvals (My Inbox)
        self.approvalTasks = [
            ApprovalTask(taskId: "0000109284", documentType: .purchaseOrder, documentNumber: "4500000003", title: "PO Release: Shinsei Precision Hydraulics", businessPartnerName: "Shinsei Precision Hydraulics", amount: 67300.0, requesterName: "M. Schneider (Plant 1010)", urgency: .critical),
            ApprovalTask(taskId: "0000109285", documentType: .salesQuotation, documentNumber: "2000012", title: "Quotation Approval: Vortex Aero Systems", businessPartnerName: "Vortex Aero Systems AG", amount: 125000.0, requesterName: "A. Patel (Sales Org 1010)", urgency: .high),
            ApprovalTask(taskId: "0000109286", documentType: .salesOrder, documentNumber: "5000002", title: "Sales Order Release: Stepper Motors", businessPartnerName: "Vortex Aero Systems AG", amount: 84100.0, requesterName: "A. Patel (Sales Org 1010)", urgency: .high),
            ApprovalTask(taskId: "0000109287", documentType: .purchaseRequisition, documentNumber: "10000192", title: "Requisition Release: Q4 Raw Materials", businessPartnerName: "Plant 1010 Central Store", amount: 78500.0, requesterName: "NARESH", urgency: .normal)
        ]
    }
}

