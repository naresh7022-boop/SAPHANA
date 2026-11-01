//
//  SAPHANAApp.swift
//  SAPHANAApp
//
//  Main Application Entrypoint for SAP S/4HANA Enterprise Mobile iOS Application
//  Built with Swift 6, SwiftUI, and SAP BTP SDK for iOS (Targeting iOS 17+)
//

import SwiftUI

@main
struct SAPHANAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .tint(FioriColors.sapBlue)
        }
    }
}

