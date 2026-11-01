//
//  CredentialStore.swift
//  SAPHANAApp
//
//  Secure Keychain Credential Storage for SAP S/4HANA Authentication
//

import Foundation
import Security

/// Thread-safe storage managing SAP Basic Authentication credentials
/// using Apple Keychain Services.
public final class CredentialStore: @unchecked Sendable {
    
    public static let shared = CredentialStore()
    
    private let serviceIdentifier = "com.sap.hana.enterprise.credentials"
    private let accountKey = "SAP_CURRENT_USER"
    private let passwordKey = "SAP_CURRENT_PASS"
    private let lock = NSLock()
    
    // In-memory cache for ultra-fast request signing
    private var cachedUsername: String?
    private var cachedPassword: String?
    
    private init() {
        // Load initial defaults if available (defaulting to NARESH as identified in system README)
        self.cachedUsername = readKeychain(key: accountKey) ?? "NARESH"
        self.cachedPassword = readKeychain(key: passwordKey) ?? "InitPass2026!"
    }
    
    // MARK: - Public API
    
    public var currentUsername: String {
        lock.lock()
        defer { lock.unlock() }
        return cachedUsername ?? "NARESH"
    }
    
    public var currentPassword: String {
        lock.lock()
        defer { lock.unlock() }
        return cachedPassword ?? ""
    }
    
    public var basicAuthHeaderValue: String? {
        lock.lock()
        defer { lock.unlock() }
        guard let user = cachedUsername, !user.isEmpty else { return nil }
        let pass = cachedPassword ?? ""
        let loginString = "\(user):\(pass)"
        guard let loginData = loginString.data(using: .utf8) else { return nil }
        let base64 = loginData.base64EncodedString()
        return "Basic \(base64)"
    }
    
    public func saveCredentials(username: String, password: String) {
        lock.lock()
        defer { lock.unlock() }
        cachedUsername = username
        cachedPassword = password
        
        writeKeychain(key: accountKey, value: username)
        writeKeychain(key: passwordKey, value: password)
    }
    
    public func clearCredentials() {
        lock.lock()
        defer { lock.unlock() }
        cachedUsername = nil
        cachedPassword = nil
        
        deleteKeychain(key: accountKey)
        deleteKeychain(key: passwordKey)
    }
    
    // MARK: - Keychain Primitives
    
    private func writeKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Remove existing item if present
        deleteKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

