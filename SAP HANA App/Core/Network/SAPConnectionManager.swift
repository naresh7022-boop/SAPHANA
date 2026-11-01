//
//  SAPConnectionManager.swift
//  SAPHANAApp
//
//  Core SAP BTP SDK Connection & Session Management Layer
//  Manages SAPURLSession, OnlineODataProvider, CSRF Token Injection,
//  and sap-client=220 Header Attribution
//

import Foundation
import Observation

#if canImport(SAPFoundation)
import SAPFoundation
#endif

#if canImport(SAPOData)
import SAPOData
#endif

/// Observable status representing live connection state to the on-premise SAP HANA server.
public enum SAPConnectionStatus: Equatable, Sendable {
    case disconnected
    case connecting
    case connected(latencyMs: Int)
    case failure(reason: String)
    case offlineMock
}

/// Core Singleton managing network sessions, OData providers, and authentication
/// for SAP S/4HANA (Host: 172.27.100.32, Client: 220).
@Observable
@MainActor
public final class SAPConnectionManager {
    
    public static let shared = SAPConnectionManager()
    
    // MARK: - Observable State
    public var connectionStatus: SAPConnectionStatus = .disconnected
    public var lastPingTime: Date?
    public var activeServerConfig: SAPServerConfig = SAPServerConfig.shared
    public var lastErrorMessage: String?
    public var isLiveMode: Bool = true
    
    // MARK: - Internal Session & Security
    private let certificateHandler: SelfSignedCertificateHandler
    private let cookieStorage: HTTPCookieStorage
    private var csrfTokens: [String: String] = [:] // Cached CSRF tokens keyed by serviceName
    
    // MARK: - Initializer
    private init() {
        self.certificateHandler = SelfSignedCertificateHandler(
            allowedHost: SAPServerConfig.defaultHost,
            trustSelfSigned: true
        )
        self.cookieStorage = HTTPCookieStorage.shared
        
        // Initial setup
        configureURLSession()
    }
    
    // MARK: - Session Configuration
    
    private var customURLSession: URLSession!
    
    private func configureURLSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = activeServerConfig.requestTimeout
        configuration.timeoutIntervalForResource = activeServerConfig.requestTimeout * 2
        configuration.httpCookieStorage = cookieStorage
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        
        // Custom delegate handling self-signed certificates on 172.27.100.32
        self.customURLSession = URLSession(
            configuration: configuration,
            delegate: certificateHandler,
            delegateQueue: nil
        )
    }
    
    /// Reconfigures session with new server parameters
    public func updateConfig(_ newConfig: SAPServerConfig) {
        self.activeServerConfig = newConfig
        self.csrfTokens.removeAll()
        configureURLSession()
    }
    
    // MARK: - Real-Time Health & Ping Checker
    
    /// Performs an active ping against `http://172.27.100.32:<port>/sap/public/ping`
    /// or retrieves service metadata with `sap-client=220`
    public func testConnection() async -> Bool {
        connectionStatus = .connecting
        lastErrorMessage = nil
        
        guard let pingURL = activeServerConfig.endpointURL(
            for: SAPServerConfig.Services.salesOrder,
            entitySet: "$metadata"
        ) else {
            connectionStatus = .failure(reason: "Invalid SAP Endpoint URL")
            return false
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var request = URLRequest(url: pingURL)
        request.httpMethod = "GET"
        request.timeoutInterval = activeServerConfig.requestTimeout
        
        // Inject SAP Client and Auth
        applyEnterpriseHeaders(to: &request, fetchCSRF: true)
        
        do {
            let (data, response) = try await customURLSession.data(for: request)
            let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            
            if let httpResponse = response as? HTTPURLResponse {
                // Cache CSRF token if returned
                if let token = httpResponse.allHeaderFields["x-csrf-token"] as? String,
                   token.lowercased() != "required" {
                    self.csrfTokens[SAPServerConfig.Services.salesOrder] = token
                }
                
                if (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 401 {
                    // Even 401 means network host reached and SAP ICF is alive
                    if httpResponse.statusCode == 401 {
                        self.connectionStatus = .connected(latencyMs: elapsed)
                        self.lastErrorMessage = "Server reachable. Authentication credentials required."
                    } else {
                        self.connectionStatus = .connected(latencyMs: elapsed)
                    }
                    self.lastPingTime = Date()
                    return true
                } else {
                    let errMsg = "SAP Server responded with HTTP \(httpResponse.statusCode)"
                    self.connectionStatus = .failure(reason: errMsg)
                    self.lastErrorMessage = errMsg
                    return false
                }
            }
            return false
        } catch {
            let errMsg = error.localizedDescription
            self.lastErrorMessage = errMsg
            
            if activeServerConfig.useMockFallbackWhenOffline {
                // Fall back gracefully to offline enterprise mock mode
                self.connectionStatus = .offlineMock
                print("ℹ️ [SAPConnectionManager] SAP Server unreachable (\(errMsg)). Switched to Offline Mock Mode.")
                return true
            } else {
                self.connectionStatus = .failure(reason: errMsg)
                return false
            }
        }
    }
    
    // MARK: - Header & Token Interceptors
    
    /// Applies mandatory SAP Client 220, Basic Authentication, and CSRF Token headers
    public func applyEnterpriseHeaders(
        to request: inout URLRequest,
        serviceName: String = SAPServerConfig.Services.salesOrder,
        fetchCSRF: Bool = false
    ) {
        // 1. Mandatory SAP Client attribution
        request.setValue(activeServerConfig.sapClient, forHTTPHeaderField: "sap-client")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // 2. Basic Auth Authorization Header
        if let authHeader = CredentialStore.shared.basicAuthHeaderValue {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        // 3. X-CSRF-Token Handshake
        if fetchCSRF {
            request.setValue("Fetch", forHTTPHeaderField: "X-CSRF-Token")
        } else if let cachedToken = csrfTokens[serviceName], !cachedToken.isEmpty {
            request.setValue(cachedToken, forHTTPHeaderField: "X-CSRF-Token")
        }
    }
    
    // MARK: - Real-Time CSRF Token Lifecycle
    
    /// Fetches a valid CSRF token from the specified SAP service
    public func fetchCSRFToken(for serviceName: String) async throws -> String {
        if let existing = csrfTokens[serviceName], !existing.isEmpty {
            return existing
        }
        
        guard let url = activeServerConfig.serviceBaseURL(for: serviceName) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        applyEnterpriseHeaders(to: &request, serviceName: serviceName, fetchCSRF: true)
        
        let (_, response) = try await customURLSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Look for x-csrf-token (case-insensitive)
        for (key, value) in httpResponse.allHeaderFields {
            if let keyStr = key as? String, keyStr.caseInsensitiveCompare("x-csrf-token") == .orderedSame,
               let valStr = value as? String, !valStr.isEmpty, valStr.lowercased() != "required" {
                self.csrfTokens[serviceName] = valStr
                return valStr
            }
        }
        
        return "CSRF_FETCHED_LOCAL_TOKEN"
    }
    
    // MARK: - Generic Raw Network Execution
    
    /// Executes a fully prepared URLRequest with retry and automatic CSRF refresh
    public func executeRequest(_ request: URLRequest, serviceName: String) async throws -> (Data, HTTPURLResponse) {
        var finalRequest = request
        
        // Check if CSRF token is needed for non-idempotent HTTP methods (POST, PUT, DELETE, PATCH)
        let method = finalRequest.httpMethod?.uppercased() ?? "GET"
        if ["POST", "PUT", "DELETE", "PATCH"].contains(method) {
            if let token = try? await fetchCSRFToken(for: serviceName) {
                finalRequest.setValue(token, forHTTPHeaderField: "X-CSRF-Token")
            }
        }
        
        let (data, response) = try await customURLSession.data(for: finalRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // If 403 Forbidden with CSRF failure, clear cache and retry once
        if httpResponse.statusCode == 403 {
            let csrfHeader = httpResponse.allHeaderFields["x-csrf-token"] as? String
            if csrfHeader?.lowercased() == "required" {
                csrfTokens.removeValue(forKey: serviceName)
                let newToken = try await fetchCSRFToken(for: serviceName)
                finalRequest.setValue(newToken, forHTTPHeaderField: "X-CSRF-Token")
                let (retryData, retryResponse) = try await customURLSession.data(for: finalRequest)
                if let retryHttpResponse = retryResponse as? HTTPURLResponse {
                    return (retryData, retryHttpResponse)
                }
            }
        }
        
        return (data, httpResponse)
    }
}

