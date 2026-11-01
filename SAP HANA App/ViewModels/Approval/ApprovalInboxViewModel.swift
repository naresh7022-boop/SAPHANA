//
//  ApprovalInboxViewModel.swift
//  SAPHANAApp
//
//  ViewModel managing unified Approval Queue (My Inbox)
//  with SAP Function Import execution (ApproveTask / RejectTask)
//

import Foundation
import Observation

@Observable
@MainActor
public final class ApprovalInboxViewModel {
    
    private let repository = SAPDataRepository.shared
    private let notificationManager = SAPNotificationManager.shared
    
    public var selectedCategory: String = "All"
    public var filterCategories: [String] = ["All", "Purchase Order", "Sales Order", "Sales Quotation", "Requisition"]
    
    public var isProcessing: Bool = false
    public var selectedTaskForRejection: ApprovalTask?
    public var rejectionReason: String = ""
    public var errorMessage: String?
    public var statusMessage: String?
    
    public init() {}
    
    public var activeTasks: [ApprovalTask] {
        let tasks = repository.approvalTasks.filter { !$0.isProcessed }
        if selectedCategory == "All" {
            return tasks
        }
        return tasks.filter { $0.documentType.rawValue == selectedCategory }
    }
    
    public var processedTasks: [ApprovalTask] {
        return repository.approvalTasks.filter { $0.isProcessed }
    }
    
    // MARK: - Actions
    
    public func approve(task: ApprovalTask) async {
        isProcessing = true
        errorMessage = nil
        do {
            try await repository.approveTask(taskId: task.taskId)
            statusMessage = "Approved \(task.documentType.rawValue) #\(task.documentNumber)"
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    public func prepareRejection(task: ApprovalTask) {
        selectedTaskForRejection = task
        rejectionReason = ""
    }
    
    public func confirmRejection() async {
        guard let task = selectedTaskForRejection, !rejectionReason.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "A mandatory rejection reason is required."
            return
        }
        
        isProcessing = true
        errorMessage = nil
        do {
            try await repository.rejectTask(taskId: task.taskId, reason: rejectionReason)
            statusMessage = "Rejected \(task.documentType.rawValue) #\(task.documentNumber)"
            selectedTaskForRejection = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    public func simulateIncomingWorkflowAlert() {
        if let first = activeTasks.first {
            notificationManager.scheduleApprovalNotification(task: first)
            statusMessage = "Simulated interactive push notification for Task #\(first.taskId)"
        }
    }
}

