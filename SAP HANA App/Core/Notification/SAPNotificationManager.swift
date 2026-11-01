//
//  SAPNotificationManager.swift
//  SAPHANAApp
//
//  Interactive Notification Manager for SAP Approvals and Real-Time Workflow Alerts
//  Configures UNUserNotificationCenter with Custom Actions (Approve / Reject / View)
//

import Foundation
import UserNotifications

/// Manages local and remote SAP workflow push alerts with interactive actionable notifications
@MainActor
public final class SAPNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    public static let shared = SAPNotificationManager()
    
    public static let categoryApproval = "SAP_APPROVAL_CATEGORY"
    public static let actionApprove = "ACTION_APPROVE"
    public static let actionReject = "ACTION_REJECT"
    public static let actionView = "ACTION_VIEW"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
    }
    
    // MARK: - Permissions & Registration
    
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("❌ Notification authorization failed: \(error)")
            return false
        }
    }
    
    private func registerNotificationCategories() {
        let approveAction = UNNotificationAction(
            identifier: Self.actionApprove,
            title: "Approve Immediately",
            options: [.authenticationRequired]
        )
        
        let rejectAction = UNTextInputNotificationAction(
            identifier: Self.actionReject,
            title: "Reject with Reason",
            options: [.destructive, .authenticationRequired],
            textInputButtonTitle: "Send Rejection",
            textInputPlaceholder: "Enter mandatory reason..."
        )
        
        let viewAction = UNNotificationAction(
            identifier: Self.actionView,
            title: "Open in App",
            options: [.foreground]
        )
        
        let approvalCategory = UNNotificationCategory(
            identifier: Self.categoryApproval,
            actions: [approveAction, rejectAction, viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([approvalCategory])
    }
    
    // MARK: - Trigger Notification for New Approval Task
    
    public func scheduleApprovalNotification(task: ApprovalTask) {
        let content = UNMutableNotificationContent()
        content.title = "SAP Workflow Approval Required"
        content.subtitle = "\(task.documentType.rawValue) #\(task.documentNumber)"
        content.body = "\(task.businessPartnerName) - $\(task.amount) \(task.currency) submitted by \(task.requesterName)"
        content.sound = .default
        content.categoryIdentifier = Self.categoryApproval
        content.userInfo = [
            "taskId": task.taskId,
            "documentNumber": task.documentNumber,
            "documentType": task.documentType.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "SAP_TASK_\(task.taskId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to add notification: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let taskId = userInfo["taskId"] as? String else { return }
        
        switch response.actionIdentifier {
        case Self.actionApprove:
            try? await SAPDataRepository.shared.approveTask(taskId: taskId)
            print("✅ Directly approved task \(taskId) from notification banner")
            
        case Self.actionReject:
            if let textResponse = response as? UNTextInputNotificationResponse {
                let reason = textResponse.userText
                try? await SAPDataRepository.shared.rejectTask(taskId: taskId, reason: reason)
                print("🛑 Rejected task \(taskId) with reason: '\(reason)' from notification banner")
            }
            
        default:
            break
        }
    }
}

