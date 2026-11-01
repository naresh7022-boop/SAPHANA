//
//  ApprovalModels.swift
//  SAPHANAApp
//
//  SAP Approval Center (My Inbox) Unified Workflow Task Models
//  Supports Function Import execution: ApproveTask / RejectTask
//

import Foundation

// MARK: - Approval Document Type
public enum ApprovalDocType: String, Codable, CaseIterable, Sendable {
    case salesOrder = "Sales Order"
    case purchaseOrder = "Purchase Order"
    case salesQuotation = "Sales Quotation"
    case purchaseRequisition = "Purchase Requisition"
    case creditRelease = "Credit Limit Release"
    
    public var iconName: String {
        switch self {
        case .salesOrder: return "cart.fill"
        case .purchaseOrder: return "shippingbox.fill"
        case .salesQuotation: return "doc.plaintext.fill"
        case .purchaseRequisition: return "tray.and.arrow.down.fill"
        case .creditRelease: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Approval Urgency
public enum ApprovalUrgency: String, Codable, CaseIterable, Sendable {
    case critical = "Critical"
    case high = "High"
    case normal = "Normal"
    case low = "Low"
}

// MARK: - Approval Task Model
public struct ApprovalTask: Identifiable, Codable, Sendable {
    public var id: String { taskId }
    public var taskId: String                // Workflow Task instance ID, e.g. "0000109284"
    public var documentType: ApprovalDocType
    public var documentNumber: String        // S/4HANA Document number (e.g. "4500000001")
    public var title: String
    public var businessPartnerName: String
    public var amount: Decimal
    public var currency: String
    public var requesterName: String
    public var submissionDate: Date
    public var urgency: ApprovalUrgency
    public var comments: String?
    public var isProcessed: Bool
    public var decision: String?             // "APPROVED", "REJECTED"
    
    public init(
        taskId: String,
        documentType: ApprovalDocType,
        documentNumber: String,
        title: String,
        businessPartnerName: String,
        amount: Decimal,
        currency: String = "USD",
        requesterName: String,
        submissionDate: Date = Date(),
        urgency: ApprovalUrgency = .high,
        comments: String? = nil,
        isProcessed: Bool = false,
        decision: String? = nil
    ) {
        self.taskId = taskId
        self.documentType = documentType
        self.documentNumber = documentNumber
        self.title = title
        self.businessPartnerName = businessPartnerName
        self.amount = amount
        self.currency = currency
        self.requesterName = requesterName
        self.submissionDate = submissionDate
        self.urgency = urgency
        self.comments = comments
        self.isProcessed = isProcessed
        self.decision = decision
    }
}

