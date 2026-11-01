//
//  SAPServerConfig.swift
//  SAPHANAApp
//
//  Centralized SAP S/4HANA Server & OData Endpoint Configuration
//  Target System: SAP S/4HANA On-Premise / DS4
//  Host: 172.27.100.32 | Client: 220
//

import Foundation

/// Centralized configuration for the on-premise SAP HANA / S/4HANA instance.
/// Allows dynamic switching between HTTP and HTTPS, custom ports, and service paths.
public struct SAPServerConfig: Sendable {
    
    // MARK: - Server Coordinates
    public static let defaultHost: String = "172.27.100.32"
    public static let defaultHTTPPort: Int = 8000
    public static let defaultHTTPSPort: Int = 44300
    public static let defaultClient: String = "220"
    
    // MARK: - Scheme Selection
    public enum NetworkScheme: String, CaseIterable, Identifiable, Sendable {
        case http = "http"
        case https = "https"
        
        public var id: String { rawValue }
        
        public var defaultPort: Int {
            switch self {
            case .http: return SAPServerConfig.defaultHTTPPort
            case .https: return SAPServerConfig.defaultHTTPSPort
            }
        }
    }
    
    // MARK: - State Properties (User-configurable at runtime)
    public var host: String
    public var port: Int
    public var scheme: NetworkScheme
    public var sapClient: String
    public var requestTimeout: TimeInterval
    public var trustSelfSignedCertificates: Bool
    public var useMockFallbackWhenOffline: Bool
    
    // MARK: - Initializer
    public init(
        host: String = SAPServerConfig.defaultHost,
        port: Int = SAPServerConfig.defaultHTTPPort,
        scheme: NetworkScheme = .http,
        sapClient: String = SAPServerConfig.defaultClient,
        requestTimeout: TimeInterval = 15.0,
        trustSelfSignedCertificates: Bool = true,
        useMockFallbackWhenOffline: Bool = true
    ) {
        self.host = host
        self.port = port
        self.scheme = scheme
        self.sapClient = sapClient
        self.requestTimeout = requestTimeout
        self.trustSelfSignedCertificates = trustSelfSignedCertificates
        self.useMockFallbackWhenOffline = useMockFallbackWhenOffline
    }
    
    // MARK: - Default Instance
    public static var shared: SAPServerConfig = SAPServerConfig()
    
    // MARK: - URL Builders
    
    /// Constructs the base URL: `http://172.27.100.32:8000` or `https://172.27.100.32:44300`
    public var baseURLString: String {
        return "\(scheme.rawValue)://\(host):\(port)"
    }
    
    /// Root path for SAP standard OData v2 Gateway services
    public var odataRootPath: String {
        return "/sap/opu/odata/sap"
    }
    
    /// Base URL for a given OData service
    /// Example: `http://172.27.100.32:8000/sap/opu/odata/sap/API_SALES_ORDER_SRV/`
    public func serviceBaseURL(for serviceName: String) -> URL? {
        let cleanServiceName = serviceName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(baseURLString)\(odataRootPath)/\(cleanServiceName)/"
        return URL(string: urlString)
    }
    
    /// Constructs an endpoint URL with `?sap-client=220` appended
    public func endpointURL(for serviceName: String, entitySet: String, queryParameters: [String: String] = [:]) -> URL? {
        guard let base = serviceBaseURL(for: serviceName) else { return nil }
        var components = URLComponents(url: base.appendingPathComponent(entitySet), resolvingAgainstBaseURL: true)
        
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sap-client", value: sapClient)
        ]
        
        for (key, value) in queryParameters {
            items.append(URLQueryItem(name: key, value: value))
        }
        
        components?.queryItems = items
        return components?.url
    }
    
    // MARK: - Standard SAP OData Service Catalog
    public struct Services {
        // SD - Sales
        public static let salesInquiry = "API_SALES_INQUIRY_SRV"
        public static let salesQuotation = "API_SALES_QUOTATION_SRV"
        public static let salesContract = "API_SALES_CONTRACT_SRV"
        public static let salesOrder = "API_SALES_ORDER_SRV"
        
        // MM - Purchasing
        public static let purchaseRequisition = "API_PURCHASEREQ_PROCESS_SRV"
        public static let purchaseQuotation = "API_QTN_PROCESS_SRV"
        public static let purchaseOrder = "API_PURCHASEORDER_PROCESS_SRV"
        
        // Master Data
        public static let productMaster = "API_PRODUCT_SRV"
        public static let businessPartner = "API_BUSINESS_PARTNER"
        
        // Workflow / Approvals
        public static let taskProcessing = "TASKPROCESSING"
        public static let customApproval = "ZAPPROVAL_PROCESS_SRV"
        
        // CRM & Operational
        public static let crmActivity = "ZCRM_ACTIVITY_SRV"
        public static let crmTask = "ZCRM_TASK_SRV"
    }
    
    // MARK: - Entity Set Catalog
    public struct EntitySets {
        // Sales
        public static let salesInquiries = "A_SalesInquiry"
        public static let salesQuotations = "A_SalesQuotation"
        public static let salesContracts = "A_SalesContract"
        public static let salesOrders = "A_SalesOrder"
        public static let salesOrderItems = "A_SalesOrderItem"
        
        // Purchasing
        public static let purchaseRequisitions = "A_PurchaseRequisitionHeader"
        public static let purchaseQuotations = "A_PurchaseQuotation"
        public static let purchaseOrders = "A_PurchaseOrder"
        public static let purchaseOrderItems = "A_PurchaseOrderItem"
        
        // Master Data
        public static let products = "A_Product"
        public static let productPlants = "A_ProductPlant"
        public static let suppliers = "A_Supplier"
        public static let customers = "A_Customer"
        
        // Approvals
        public static let workflowTasks = "TaskCollection"
        public static let customApprovals = "ApprovalTasks"
        
        // CRM
        public static let activities = "Activities"
        public static let tasks = "Tasks"
    }
}

