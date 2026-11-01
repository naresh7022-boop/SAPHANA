//
//  MasterDataPickerViewModel.swift
//  SAPHANAApp
//
//  ViewModel managing paginated F4 Search Help Pickers & Master Data Lists
//

import Foundation
import Observation

@Observable
@MainActor
public final class MasterDataPickerViewModel {
    
    private let repository = SAPDataRepository.shared
    
    public var products: [SAPProduct] = []
    public var customers: [SAPCustomer] = []
    public var suppliers: [SAPSupplier] = []
    
    public var searchText: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    public init() {}
    
    // MARK: - Actions
    
    public func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            self.products = try await repository.fetchProducts(search: searchText)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func loadCustomers() async {
        isLoading = true
        errorMessage = nil
        do {
            self.customers = try await repository.fetchCustomers(search: searchText)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func loadSuppliers() async {
        isLoading = true
        errorMessage = nil
        do {
            self.suppliers = try await repository.fetchSuppliers(search: searchText)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

