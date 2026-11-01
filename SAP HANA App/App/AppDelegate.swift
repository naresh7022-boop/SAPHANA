//
//  AppDelegate.swift
//  SAPHANAApp
//
//  Application Lifecycle & Push Notification Interception
//

import UIKit
import UserNotifications

public final class AppDelegate: NSObject, UIApplicationDelegate {
    
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        // 1. Initialize Interactive Notification Delegate
        UNUserNotificationCenter.current().delegate = SAPNotificationManager.shared
        
        // 2. Request Notification Authorization
        Task { @MainActor in
            _ = await SAPNotificationManager.shared.requestAuthorization()
        }
        
        // 3. Register for Remote Notifications (APNs)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📲 Registered APNs Device Token: \(token)")
    }
    
    public func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Background sync when new approval task arrives
        Task { @MainActor in
            _ = try? await SAPDataRepository.shared.fetchSalesOrders()
            _ = try? await SAPDataRepository.shared.fetchPurchaseOrders()
            completionHandler(.newData)
        }
    }
}

