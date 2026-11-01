//
//  ODataServiceLayer.swift
//  SAPHANAApp
//
//  Unified OData Service Layer for SAP S/4HANA On-Premise
//  Wraps SAPOData OnlineODataProvider & DataService operations
//  Covers SD, MM, CRM, Master Data F4 Pickers, and Workflow Approvals
//

import Foundation
import Observation

#if canImport(SAPOData)
import SAPOData
#endif

/// Thread-safe singleton providing high-level CRUD and query execution against
/// SAP Gateway OData services on 172.27.100.32 (Client 220).
@Observable
public final class ODataServiceLayer: @unchecked Sendable {
    
    public static let shared = ODataServiceLayer()
    
    private let connectionManager = SAPConnectionManager.shared
    
    private init() {}
    
    // MARK: - Generic GET & Execute
    
    /// Queries an OData entity set using the fluent ODataQueryBuilder
    public func fetchEntities(
        serviceName: String,
        entitySet: String,
        query: ODataQueryBuilder = ODataQueryBuilder()
    ) async throws -> [[String: Any]] {
        guard let baseURL = connectionManager.activeServerConfig.serviceBaseURL(for: serviceName) else {
            throw URLError(.badURL)
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent(entitySet), resolvingAgainstBaseURL: true)
        components?.queryItems = query.buildQueryItems()
        
        guard let finalURL = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        connectionManager.applyEnterpriseHeaders(to: &request, serviceName: serviceName)
        
        do {
            let (data, response) = try await connectionManager.executeRequest(request, serviceName: serviceName)
            if (200...299).contains(response.statusCode) {
                return parseODataResponse(data: data)
            } else {
                throw NSError(
                    domain: "SAPODataError",
                    code: response.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "SAP Gateway returned HTTP \(response.statusCode)"]
                )
            }
        } catch {
            if connectionManager.activeServerConfig.useMockFallbackWhenOffline {
                return [] // Fallback handled by individual domain repositories
            }
            throw error
        }
    }
    
    // MARK: - Deep Insert Entity Creation
    
    /// Creates a parent entity with nested navigation children (Deep Insert)
    /// Example: Sales Order + to_Item or Purchase Order + to_PurchaseOrderItem
    public func createDeepEntity(
        serviceName: String,
        entitySet: String,
        payload: [String: Any]
    ) async throws -> [String: Any] {
        guard let baseURL = connectionManager.activeServerConfig.serviceBaseURL(for: serviceName) else {
            throw URLError(.badURL)
        }
        
        let targetURL = baseURL.appendingPathComponent(entitySet)
        var components = URLComponents(url: targetURL, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "sap-client", value: connectionManager.activeServerConfig.sapClient),
            URLQueryItem(name: "$format", value: "json")
        ]
        
        guard let finalURL = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        connectionManager.applyEnterpriseHeaders(to: &request, serviceName: serviceName)
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        request.httpBody = jsonData
        
        let (data, response) = try await connectionManager.executeRequest(request, serviceName: serviceName)
        
        if (200...299).contains(response.statusCode) || response.statusCode == 201 {
            let parsed = parseODataSingleEntity(data: data)
            return parsed
        } else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown SAP Error"
            throw NSError(
                domain: "SAPDeepInsertError",
                code: response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Failed deep insert creation: \(errorText)"]
            )
        }
    }
    
    // MARK: - Function Import Execution (Approvals / Actions)
    
    /// Executes an OData Function Import (e.g. ApproveTask / RejectTask)
    public func executeFunctionImport(
        serviceName: String,
        functionName: String,
        parameters: [String: String],
        httpMethod: String = "POST"
    ) async throws -> Bool {
        guard let baseURL = connectionManager.activeServerConfig.serviceBaseURL(for: serviceName) else {
            throw URLError(.badURL)
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent(functionName), resolvingAgainstBaseURL: true)
        var queryItems = [
            URLQueryItem(name: "sap-client", value: connectionManager.activeServerConfig.sapClient),
            URLQueryItem(name: "$format", value: "json")
        ]
        
        for (k, v) in parameters {
            queryItems.append(URLQueryItem(name: k, value: "'\(v)'"))
        }
        components?.queryItems = queryItems
        
        guard let finalURL = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = httpMethod
        connectionManager.applyEnterpriseHeaders(to: &request, serviceName: serviceName)
        
        let (_, response) = try await connectionManager.executeRequest(request, serviceName: serviceName)
        return (200...299).contains(response.statusCode)
    }
    
    // MARK: - OData v2 JSON Parser Helpers
    
    private func parseODataResponse(data: Data) -> [[String: Any]] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        
        // Standard OData v2 JSON response structure: { "d": { "results": [ ... ] } }
        if let d = json["d"] as? [String: Any] {
            if let results = d["results"] as? [[String: Any]] {
                return results
            }
        } else if let results = json["d"] as? [[String: Any]] {
            return results
        }
        
        return []
    }
    
    private func parseODataSingleEntity(data: Data) -> [String: Any] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        // Structure: { "d": { ... } }
        if let d = json["d"] as? [String: Any] {
            return d
        }
        return json
    }
}

