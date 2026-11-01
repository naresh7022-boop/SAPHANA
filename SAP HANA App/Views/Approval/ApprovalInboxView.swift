//
//  ApprovalInboxView.swift
//  SAPHANAApp
//
//  Unified SAP Approval Center (My Inbox)
//  Supports one-tap Approve and Reject (with mandatory rejection dialog)
//  via SAPOData Function Imports (DataQuery().withFunction(...))
//

import SwiftUI

public struct ApprovalInboxView: View {
    @State private var viewModel = ApprovalInboxViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // Header Status or Alerts
                if let status = viewModel.statusMessage {
                    Section {
                        FUIBannerMessageView(message: status, type: .success)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        FUIBannerMessageView(message: error, type: .error)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // Section 1: Category Filter Form Cell
                Section {
                    FUIFilterFormCell(
                        title: "Filter by Workflow Type",
                        options: viewModel.filterCategories,
                        selectedOption: $viewModel.selectedCategory
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                // Section 2: Active Pending Approvals
                Section(header: Text("Pending My Decision (\(viewModel.activeTasks.count))")) {
                    if viewModel.activeTasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 36))
                                .foregroundColor(FioriColors.positive)
                            Text("All Caught Up!")
                                .font(.headline)
                            Text("No pending workflow requests in your inbox.")
                                .font(.caption)
                                .foregroundColor(FioriColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(viewModel.activeTasks) { task in
                            ApprovalTaskRow(
                                task: task,
                                isProcessing: viewModel.isProcessing,
                                onApprove: {
                                    Task { await viewModel.approve(task: task) }
                                },
                                onReject: {
                                    viewModel.prepareRejection(task: task)
                                }
                            )
                        }
                    }
                }
                
                // Section 3: Completed / Processed Decisions
                if !viewModel.processedTasks.isEmpty {
                    Section(header: Text("Completed Today (\(viewModel.processedTasks.count))")) {
                        ForEach(viewModel.processedTasks) { task in
                            HStack {
                                Image(systemName: task.decision == "APPROVED" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(task.decision == "APPROVED" ? FioriColors.positive : FioriColors.negative)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(task.documentType.rawValue) #\(task.documentNumber)")
                                        .font(.subheadline.bold())
                                    Text(task.businessPartnerName)
                                        .font(.caption)
                                        .foregroundColor(FioriColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Text(task.decision ?? "PROCESSED")
                                    .font(.caption.bold())
                                    .foregroundColor(task.decision == "APPROVED" ? FioriColors.positive : FioriColors.negative)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Approval Inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.simulateIncomingWorkflowAlert()
                    }) {
                        Label("Test Alert", systemImage: "bell.badge.fill")
                            .font(.caption)
                    }
                }
            }
            .sheet(item: $viewModel.selectedTaskForRejection) { task in
                RejectionReasonSheet(
                    task: task,
                    reason: $viewModel.rejectionReason,
                    isProcessing: viewModel.isProcessing,
                    onConfirm: {
                        Task { await viewModel.confirmRejection() }
                    },
                    onCancel: {
                        viewModel.selectedTaskForRejection = nil
                    }
                )
            }
        }
    }
}

// MARK: - Approval Task Card Row
public struct ApprovalTaskRow: View {
    public let task: ApprovalTask
    public let isProcessing: Bool
    public let onApprove: () -> Void
    public let onReject: () -> Void
    
    public var urgencyColor: Color {
        switch task.urgency {
        case .critical: return FioriColors.negative
        case .high: return FioriColors.critical
        case .normal: return FioriColors.sapBlue
        case .low: return FioriColors.neutral
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FioriColors.sapBlue.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: task.documentType.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(FioriColors.sapBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.bold())
                    Text("Ref #\(task.documentNumber) • Submitter: \(task.requesterName)")
                        .font(.caption2)
                        .foregroundColor(FioriColors.secondaryText)
                }
                
                Spacer()
                
                Text(task.urgency.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(urgencyColor.opacity(0.15))
                    .foregroundColor(urgencyColor)
                    .clipShape(Capsule())
            }
            
            // Amount & Partner
            HStack {
                Text(task.businessPartnerName)
                    .font(.caption)
                    .foregroundColor(FioriColors.primaryText)
                Spacer()
                Text("$\(task.amount) \(task.currency)")
                    .font(.headline.bold())
                    .foregroundColor(FioriColors.sapBlue)
            }
            
            Divider()
            
            // One-Tap Action Buttons
            HStack(spacing: 12) {
                // Reject Button
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Reject...")
                    }
                    .font(.caption.bold())
                    .foregroundColor(FioriColors.negative)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(FioriColors.negative.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(isProcessing)
                
                // Approve Button
                Button(action: onApprove) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(FioriColors.positive)
                    .cornerRadius(8)
                }
                .disabled(isProcessing)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Rejection Mandatory Reason Dialog Sheet
public struct RejectionReasonSheet: View {
    public let task: ApprovalTask
    @Binding public var reason: String
    public let isProcessing: Bool
    public let onConfirm: () -> Void
    public let onCancel: () -> Void
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item To Reject")) {
                    Text("\(task.documentType.rawValue) #\(task.documentNumber)")
                        .font(.headline)
                    Text("Partner: \(task.businessPartnerName) • Total: $\(task.amount)")
                        .font(.caption)
                        .foregroundColor(FioriColors.secondaryText)
                }
                
                Section(
                    header: Text("Rejection Justification (Mandatory)"),
                    footer: Text("This note will be transmitted to SAP Gateway via OData Function Import and logged in the SAP Audit Trail.")
                ) {
                    TextEditor(text: $reason)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Reject Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onConfirm) {
                        if isProcessing {
                            ProgressView()
                        } else {
                            Text("Reject")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

