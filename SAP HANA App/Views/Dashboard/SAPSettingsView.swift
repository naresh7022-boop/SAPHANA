//
//  SAPSettingsView.swift
//  SAPHANAApp
//
//  SAP S/4HANA Server & Network Security Configuration View
//  Allows runtime adjustment of IP (172.27.100.32), Port, Client (220), and Credentials
//

import SwiftUI

public struct SAPSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var connection = SAPConnectionManager.shared
    @State private var credentialStore = CredentialStore.shared
    
    @State private var host: String = ""
    @State private var portString: String = ""
    @State private var scheme: SAPServerConfig.NetworkScheme = .http
    @State private var sapClient: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var trustSelfSigned: Bool = true
    @State private var useMockFallback: Bool = true
    @State private var pingResult: String?
    @State private var isPinging: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Connection Status Banner
                Section {
                    switch connection.connectionStatus {
                    case .connected(let ms):
                        FUIBannerMessageView(
                            message: "Connected to SAP HANA server (\(ms) ms latency)",
                            type: .success
                        )
                    case .connecting:
                        FUIBannerMessageView(message: "Contacting \(host)...", type: .info)
                    case .failure(let reason):
                        FUIBannerMessageView(message: "Offline / Failure: \(reason)", type: .error)
                    case .offlineMock:
                        FUIBannerMessageView(
                            message: "Offline Mock Mode Active (Local enterprise sandbox data)",
                            type: .warning
                        )
                    case .disconnected:
                        FUIBannerMessageView(message: "Disconnected from SAP Gateway", type: .info)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Section 2: Server Coordinates
                Section(header: Text("SAP S/4HANA Server Endpoints")) {
                    HStack {
                        Text("Server Host / IP")
                        Spacer()
                        TextField("Host", text: $host)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Protocol Scheme", selection: $scheme) {
                        Text("HTTP (Port 8000)").tag(SAPServerConfig.NetworkScheme.http)
                        Text("HTTPS (Port 44300)").tag(SAPServerConfig.NetworkScheme.https)
                    }
                    .onChange(of: scheme) { _, newScheme in
                        portString = "\(newScheme.defaultPort)"
                    }
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", text: $portString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Mandatory Client")
                        Spacer()
                        TextField("Client", text: $sapClient)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Section 3: Authentication (Basic Auth)
                Section(header: Text("Authentication Credentials")) {
                    HStack {
                        Text("SAP Username")
                        Spacer()
                        TextField("User", text: $username)
                            .textInputAutocapitalization(.characters)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("SAP Password")
                        Spacer()
                        SecureField("Password", text: $password)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Section 4: Security & Fallback
                Section(header: Text("Security & Development Mode")) {
                    Toggle("Trust Self-Signed Certificates", isOn: $trustSelfSigned)
                    Toggle("Offline Mock Data Fallback", isOn: $useMockFallback)
                }
                
                // Section 5: Live Test Action
                Section {
                    Button(action: {
                        Task {
                            applySettings()
                            isPinging = true
                            let ok = await connection.testConnection()
                            isPinging = false
                            if ok {
                                pingResult = "Success: Reached SAP Server at \(host):\(portString) (Client \(sapClient))"
                            } else {
                                pingResult = connection.lastErrorMessage ?? "Connection failed."
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isPinging {
                                ProgressView()
                                Text("Pinging 172.27.100.32...")
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("Test Live Connection Now")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    
                    if let res = pingResult {
                        Text(res)
                            .font(.caption)
                            .foregroundColor(res.contains("Success") ? FioriColors.positive : FioriColors.negative)
                    }
                }
            }
            .navigationTitle("Server Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Done") {
                        applySettings()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    private func loadCurrentSettings() {
        let conf = connection.activeServerConfig
        self.host = conf.host
        self.portString = "\(conf.port)"
        self.scheme = conf.scheme
        self.sapClient = conf.sapClient
        self.trustSelfSigned = conf.trustSelfSignedCertificates
        self.useMockFallback = conf.useMockFallbackWhenOffline
        
        self.username = credentialStore.currentUsername
        self.password = credentialStore.currentPassword
    }
    
    private func applySettings() {
        let parsedPort = Int(portString) ?? scheme.defaultPort
        let newConfig = SAPServerConfig(
            host: host,
            port: parsedPort,
            scheme: scheme,
            sapClient: sapClient,
            trustSelfSignedCertificates: trustSelfSigned,
            useMockFallbackWhenOffline: useMockFallback
        )
        connection.updateConfig(newConfig)
        credentialStore.saveCredentials(username: username, password: password)
    }
}

