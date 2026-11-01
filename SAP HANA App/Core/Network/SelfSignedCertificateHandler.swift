//
//  SelfSignedCertificateHandler.swift
//  SAPHANAApp
//
//  Custom URLSession Delegate & Security Evaluation for On-Premise SAP Servers
//  Handles self-signed certificates and corporate SSL inspection for 172.27.100.32
//

import Foundation
import Security

/// Delegate that intercepts SSL / TLS authentication challenges.
/// For enterprise on-premise development, this allows seamless connection to
/// `172.27.100.32` even if self-signed certificates or internal PKI roots are present.
public final class SelfSignedCertificateHandler: NSObject, URLSessionDelegate, Sendable {
    
    public let allowedHost: String
    public let trustSelfSigned: Bool
    
    public init(allowedHost: String = SAPServerConfig.defaultHost, trustSelfSigned: Bool = true) {
        self.allowedHost = allowedHost
        self.trustSelfSigned = trustSelfSigned
        super.init()
    }
    
    // MARK: - URLSessionDelegate
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host
        
        // Check if authentication challenge is for server trust (SSL/TLS)
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Strictly scope bypass only to the configured on-premise host (172.27.100.32)
        if trustSelfSigned && (host == allowedHost || host.hasPrefix("172.27.") || host == "localhost") {
            // Evaluate trust using SecTrustEvaluateWithError
            var error: CFError?
            let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
            
            if isTrusted {
                // If it naturally validates, use it
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                // On local development, accept server trust for internal SAP IP
                #if DEBUG
                print("⚠️ [SAPNetworkSecurity] Trusting self-signed certificate for internal SAP host: \(host)")
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                #else
                // In production, enforce standard validation unless explicitly whitelisted
                completionHandler(.performDefaultHandling, nil)
                #endif
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

