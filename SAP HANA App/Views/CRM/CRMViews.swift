//
//  CRMViews.swift
//  SAPHANAApp
//
//  SAP CRM & Operational Management Views (Activities & Tasks)
//

import SwiftUI

public struct CRMHubView: View {
    @State private var repository = SAPDataRepository.shared
    @State private var selectedTab: Int = 0
    @State private var showLogActivitySheet: Bool = false
    @State private var showCreateTaskSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Activities").tag(0)
                    Text("Tasks & Action Items").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(FioriColors.sapBackground)
                
                if selectedTab == 0 {
                    activitiesList
                } else {
                    tasksList
                }
            }
            .navigationTitle("CRM & Operations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if selectedTab == 0 {
                            showLogActivitySheet = true
                        } else {
                            showCreateTaskSheet = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(FioriColors.sapBlue)
                    }
                }
            }
            .sheet(isPresented: $showLogActivitySheet) {
                LogActivitySheet()
            }
            .sheet(isPresented: $showCreateTaskSheet) {
                CreateTaskSheet()
            }
        }
    }
    
    // MARK: - Activities
    
    private var activitiesList: some View {
        List {
            Section(header: Text("Logged Business Interactions (\(repository.activities.count))")) {
                ForEach(repository.activities) { act in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(act.title, systemImage: act.type.iconName)
                                .font(.subheadline.bold())
                                .foregroundColor(FioriColors.primaryText)
                            Spacer()
                            Text(act.type.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(FioriColors.sapBlue.opacity(0.12))
                                .foregroundColor(FioriColors.sapBlue)
                                .clipShape(Capsule())
                        }
                        
                        Text("Partner: \(act.businessPartnerName) • Contact: \(act.contactPerson)")
                            .font(.caption)
                            .foregroundColor(FioriColors.secondaryText)
                        
                        Text(act.notes)
                            .font(.footnote)
                            .foregroundColor(FioriColors.primaryText)
                            .padding(.vertical, 2)
                        
                        HStack {
                            Text(act.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(FioriColors.secondaryText)
                            Spacer()
                            Text(act.location)
                                .font(.caption2)
                                .foregroundColor(FioriColors.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Tasks
    
    private var tasksList: some View {
        List {
            Section(header: Text("Action Items & Workflows (\(repository.tasks.count))")) {
                ForEach(repository.tasks) { task in
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            toggleTaskCompletion(task)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(task.isCompleted ? FioriColors.positive : .gray)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.subheadline.bold())
                                .strikethrough(task.isCompleted)
                            
                            Text(task.details)
                                .font(.caption)
                                .foregroundColor(FioriColors.secondaryText)
                            
                            HStack(spacing: 8) {
                                Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(FioriColors.secondaryText)
                                
                                if let doc = task.relatedDocumentRef {
                                    Text("Ref: \(doc)")
                                        .font(.caption2.bold())
                                        .foregroundColor(FioriColors.sapBlue)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text(task.priority.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(task.priority == .urgent ? FioriColors.negative.opacity(0.15) : FioriColors.sapBlue.opacity(0.12))
                            .foregroundColor(task.priority == .urgent ? FioriColors.negative : FioriColors.sapBlue)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func toggleTaskCompletion(_ task: CRMTask) {
        if let idx = repository.tasks.firstIndex(where: { $0.id == task.id }) {
            repository.tasks[idx].isCompleted.toggle()
        }
    }
}

// MARK: - Log Activity Modal Sheet
public struct LogActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var type: CRMActivityType = .clientMeeting
    @State private var partnerName: String = ""
    @State private var notes: String = ""
    @State private var showCustomerPicker = false
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Interaction Type")) {
                    Picker("Type", selection: $type) {
                        ForEach(CRMActivityType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    
                    TextField("Activity Title / Agenda", text: $title)
                }
                
                Section(header: Text("Business Partner")) {
                    HStack {
                        TextField("Partner Name", text: $partnerName)
                        Button("F4 Help") {
                            showCustomerPicker = true
                        }
                        .font(.caption.bold())
                    }
                }
                
                Section(header: Text("Meeting Notes & Follow-up")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newAct = CRMActivity(
                            title: title.isEmpty ? "Call with \(partnerName)" : title,
                            type: type,
                            businessPartnerId: "BP_SYNC",
                            businessPartnerName: partnerName.isEmpty ? "Direct Contact" : partnerName,
                            notes: notes
                        )
                        SAPDataRepository.shared.activities.insert(newAct, at: 0)
                        dismiss()
                    }
                    .disabled(notes.isEmpty)
                }
            }
            .sheet(isPresented: $showCustomerPicker) {
                CustomerPickerSheet { customer in
                    partnerName = customer.customerName
                }
            }
        }
    }
}

// MARK: - Create Task Modal Sheet
public struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var priority: CRMTaskPriority = .medium
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var documentRef: String = ""
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    TextField("Details / Action needed", text: $details)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(CRMTaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    TextField("Related SAP Doc Ref (e.g. PO# 4500000001)", text: $documentRef)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newTask = CRMTask(
                            title: title,
                            details: details,
                            priority: priority,
                            dueDate: dueDate,
                            relatedDocumentRef: documentRef.isEmpty ? nil : documentRef
                        )
                        SAPDataRepository.shared.tasks.insert(newTask, at: 0)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

