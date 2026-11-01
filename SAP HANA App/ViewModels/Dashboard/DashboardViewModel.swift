//
//  DashboardViewModel.swift
//  SAPHANAApp
//
//  ViewModel coordinating the Fiori Launchpad Dashboard
//  Tracks KPI Metrics, Server Connection State, and Quick Actions
//

import Foundation
import Observation

@Observable
@MainActor
public final class DashboardViewModel {
    
    public let connection = SAPConnectionManager.shared
    public let repository = SAPDataRepository.shared
    
    public var isTestingConnection: Bool = false
    public var showSettingsSheet: Bool = false
    public var showQuickOrderSheet: Bool = false
    
    public init() {}
    
    // MARK: - KPI Metric Computations
    
    public var pendingApprovalsCount: Int {
        repository.approvalTasks.filter { !$0.isProcessed }.count
    }
    
    public var salesOrdersCount: Int {
        repository.salesOrders.count
    }
    
    public var salesTotalValue: Decimal {
        repository.salesOrders.reduce(Decimal(0)) { $0 + $1.netAmount }
    }
    
    public var openPOsCount: Int {
        repository.purchaseOrders.count
    }
    
    public var openPOsTotalValue: Decimal {
        repository.purchaseOrders.reduce(Decimal(0)) { $0 + $1.totalNetAmount }
    }
    
    public var overdueTasksCount: Int {
        let now = Date()
        return repository.tasks.filter { !$0.isCompleted && $0.dueDate < now }.count
    }
    
    // MARK: - Actions
    
    public func refreshDashboard() async {
        isTestingConnection = true
        _ = await connection.testConnection()
        _ = try? await repository.fetchSalesOrders()
        _ = try? await repository.fetchPurchaseOrders()
        isTestingConnection = false
    }
}

