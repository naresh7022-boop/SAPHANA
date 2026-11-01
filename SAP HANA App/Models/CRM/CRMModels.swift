//
//  CRMModels.swift
//  SAPHANAApp
//
//  CRM & Operational Management Models (Activities & Tasks)
//

import Foundation

// MARK: - Activity Type
public enum CRMActivityType: String, Codable, CaseIterable, Sendable {
    case phoneCall = "Phone Call"
    case clientMeeting = "Client Meeting"
    case onSiteVisit = "On-Site Visit"
    case emailNote = "Email Note"
    case quotationFollowUp = "Quotation Follow-Up"
    
    public var iconName: String {
        switch self {
        case .phoneCall: return "phone.fill"
        case .clientMeeting: return "person.2.fill"
        case .onSiteVisit: return "building.2.fill"
        case .emailNote: return "envelope.fill"
        case .quotationFollowUp: return "doc.text.magnifyingglass"
        }
    }
}

// MARK: - Activity Model
public struct CRMActivity: Identifiable, Codable, Sendable {
    public var id: String { activityId }
    public var activityId: String
    public var title: String
    public var type: CRMActivityType
    public var businessPartnerId: String     // Customer or Vendor ID
    public var businessPartnerName: String
    public var contactPerson: String
    public var notes: String
    public var timestamp: Date
    public var durationMinutes: Int
    public var location: String
    public var outcome: String
    
    public init(
        activityId: String = UUID().uuidString.prefix(8).uppercased(),
        title: String,
        type: CRMActivityType,
        businessPartnerId: String,
        businessPartnerName: String,
        contactPerson: String = "Purchasing Mgr",
        notes: String,
        timestamp: Date = Date(),
        durationMinutes: Int = 30,
        location: String = "Client HQ / Virtual",
        outcome: String = "Follow-up scheduled"
    ) {
        self.activityId = activityId
        self.title = title
        self.type = type
        self.businessPartnerId = businessPartnerId
        self.businessPartnerName = businessPartnerName
        self.contactPerson = contactPerson
        self.notes = notes
        self.timestamp = timestamp
        self.durationMinutes = durationMinutes
        self.location = location
        self.outcome = outcome
    }
}

// MARK: - Task Priority
public enum CRMTaskPriority: String, Codable, CaseIterable, Sendable {
    case urgent = "Urgent"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    public var badgeColor: String {
        switch self {
        case .urgent: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        }
    }
}

// MARK: - Task Status
public enum CRMTaskStatus: String, Codable, CaseIterable, Sendable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    case deferred = "Deferred"
}

// MARK: - Operational Task Model
public struct CRMTask: Identifiable, Codable, Sendable {
    public var id: String { taskId }
    public var taskId: String
    public var title: String
    public var details: String
    public var priority: CRMTaskPriority
    public var status: CRMTaskStatus
    public var dueDate: Date
    public var assignedToUser: String
    public var relatedDocumentRef: String?  // e.g. "SO# 5000001" or "PO# 4500000001"
    public var isCompleted: Bool {
        get { status == .completed }
        set { status = newValue ? .completed : .inProgress }
    }
    
    public init(
        taskId: String = UUID().uuidString.prefix(8).uppercased(),
        title: String,
        details: String,
        priority: CRMTaskPriority = .medium,
        status: CRMTaskStatus = .notStarted,
        dueDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        assignedToUser: String = "NARESH",
        relatedDocumentRef: String? = nil
    ) {
        self.taskId = taskId
        self.title = title
        self.details = details
        self.priority = priority
        self.status = status
        self.dueDate = dueDate
        self.assignedToUser = assignedToUser
        self.relatedDocumentRef = relatedDocumentRef
    }
}

