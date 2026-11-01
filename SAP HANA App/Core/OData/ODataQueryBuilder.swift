//
//  ODataQueryBuilder.swift
//  SAPHANAApp
//
//  Fluent OData Query Builder mirroring SAPOData.DataQuery
//  Supports $select, $filter, $expand, $orderby, $top, $skip,
//  Function Imports, and sap-client=220 query attribution
//

import Foundation

/// Swift builder patterned after SAP BTP SDK `DataQuery`.
/// Constructs OData standard v2/v4 URI query strings.
public struct ODataQueryBuilder: Sendable {
    
    public private(set) var selectedProperties: [String] = []
    public private(set) var filterExpressions: [String] = []
    public private(set) var expandProperties: [String] = []
    public private(set) var orderByClause: String?
    public private(set) var topCount: Int?
    public private(set) var skipCount: Int?
    public private(set) var customOptions: [String: String] = ["sap-client": SAPServerConfig.defaultClient]
    public private(set) var functionImportName: String?
    public private(set) var functionParameters: [String: String] = [:]
    
    public init() {}
    
    // MARK: - Fluent Builders
    
    /// Adds properties to the `$select` projection
    public func select(_ properties: [String]) -> ODataQueryBuilder {
        var copy = self
        copy.selectedProperties.append(contentsOf: properties)
        return copy
    }
    
    /// Appends a `$filter` condition
    public func filter(_ expression: String) -> ODataQueryBuilder {
        var copy = self
        if !expression.isEmpty {
            copy.filterExpressions.append(expression)
        }
        return copy
    }
    
    /// Shortcut for text search across fields (using substringof for OData v2)
    public func searchFilter(query: String, fields: [String]) -> ODataQueryBuilder {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return self }
        let cleanQuery = query.replacingOccurrences(of: "'", with: "''")
        let subExpressions = fields.map { "substringof('\(cleanQuery)', \($0)) eq true" }
        let combined = "(" + subExpressions.joined(separator: " or ") + ")"
        return self.filter(combined)
    }
    
    /// Adds navigation properties for deep expansion (`$expand`)
    public func expand(_ properties: [String]) -> ODataQueryBuilder {
        var copy = self
        copy.expandProperties.append(contentsOf: properties)
        return copy
    }
    
    /// Sets `$orderby`
    public func orderBy(_ property: String, ascending: Bool = true) -> ODataQueryBuilder {
        var copy = self
        copy.orderByClause = "\(property) \(ascending ? "asc" : "desc")"
        return copy
    }
    
    /// Sets `$top` pagination
    public func top(_ count: Int) -> ODataQueryBuilder {
        var copy = self
        copy.topCount = count
        return copy
    }
    
    /// Sets `$skip` pagination
    public func skip(_ count: Int) -> ODataQueryBuilder {
        var copy = self
        copy.skipCount = count
        return copy
    }
    
    /// Appends custom query option (such as sap-client)
    public func withCustomQueryOption(_ key: String, _ value: String) -> ODataQueryBuilder {
        var copy = self
        copy.customOptions[key] = value
        return copy
    }
    
    /// Configures builder for an OData Function Import
    public func withFunction(_ name: String, parameters: [String: String] = [:]) -> ODataQueryBuilder {
        var copy = self
        copy.functionImportName = name
        copy.functionParameters = parameters
        return copy
    }
    
    // MARK: - URL Query Item Compilation
    
    public func buildQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        // 1. sap-client and custom options
        for (key, val) in customOptions {
            items.append(URLQueryItem(name: key, value: val))
        }
        
        // 2. $select
        if !selectedProperties.isEmpty {
            items.append(URLQueryItem(name: "$select", value: selectedProperties.joined(separator: ",")))
        }
        
        // 3. $filter
        if !filterExpressions.isEmpty {
            let combinedFilter = filterExpressions.joined(separator: " and ")
            items.append(URLQueryItem(name: "$filter", value: combinedFilter))
        }
        
        // 4. $expand
        if !expandProperties.isEmpty {
            items.append(URLQueryItem(name: "$expand", value: expandProperties.joined(separator: ",")))
        }
        
        // 5. $orderby
        if let orderBy = orderByClause {
            items.append(URLQueryItem(name: "$orderby", value: orderBy))
        }
        
        // 6. $top
        if let top = topCount {
            items.append(URLQueryItem(name: "$top", value: "\(top)"))
        }
        
        // 7. $skip
        if let skip = skipCount {
            items.append(URLQueryItem(name: "$skip", value: "\(skip)"))
        }
        
        // 8. Function Import parameters if present
        for (param, val) in functionParameters {
            items.append(URLQueryItem(name: param, value: "'\(val)'"))
        }
        
        // Always request JSON formatting in OData v2
        items.append(URLQueryItem(name: "$format", value: "json"))
        
        return items
    }
}

