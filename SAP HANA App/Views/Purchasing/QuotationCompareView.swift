//
//  QuotationCompareView.swift
//  SAPHANAApp
//
//  Purchase Quotation Comparison Matrix (Collective RFQ Evaluation)
//  Compares multi-vendor bids side-by-side with lowest price, delivery lead time,
//  and one-tap "Award & Convert to PO" execution
//

import SwiftUI

public struct QuotationCompareView: View {
    @State private var repository = SAPDataRepository.shared
    @State private var selectedGroupIndex: Int = 0
    @State private var isAwarding: Bool = false
    @State private var awardedPO: PurchaseOrder?
    @State private var showAwardSuccessDialog: Bool = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var currentSet: QuotationComparisonSet? {
        guard !repository.quotationComparisonSets.isEmpty,
              selectedGroupIndex < repository.quotationComparisonSets.count else {
            return nil
        }
        return repository.quotationComparisonSets[selectedGroupIndex]
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let currentSet = currentSet {
                    // Header Banner
                    FUIObjectHeader(
                        icon: "square.grid.3x3.topleft.filled",
                        title: currentSet.title,
                        subtitle: "Collective RFQ: \(currentSet.collectiveRFQ)",
                        status: "\(currentSet.bids.count) Bids Received",
                        statusColor: FioriColors.sapBlue,
                        footnote: "Material: \(currentSet.material) • \(currentSet.materialDescription)",
                        description: "Side-by-side vendor evaluation against SAP MM RFQ requirements.",
                        kpiValue: "\(Int(currentSet.requestedQuantity)) \(currentSet.uom)",
                        kpiCaption: "Total Sourcing Demand"
                    )
                    
                    // Comparison Matrix Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle().fill(FioriColors.positive).frame(width: 8, height: 8)
                            Text("Lowest Price")
                                .font(.caption2.bold())
                                .foregroundColor(FioriColors.secondaryText)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(FioriColors.sapBlue).frame(width: 8, height: 8)
                            Text("Fastest Delivery")
                                .font(.caption2.bold())
                                .foregroundColor(FioriColors.secondaryText)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(FioriColors.critical).frame(width: 8, height: 8)
                            Text("Highest Compliance")
                                .font(.caption2.bold())
                                .foregroundColor(FioriColors.secondaryText)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Side-by-Side Horizontal Matrix Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(currentSet.bids) { bid in
                                VendorBidCard(
                                    bid: bid,
                                    uom: currentSet.uom,
                                    isAwarding: isAwarding,
                                    onAward: {
                                        Task {
                                            await awardVendor(bid: bid)
                                        }
                                    }
                                )
                                .frame(width: 310)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Comparison Breakdown Table
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EVALUATION CRITERIA TABLE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(FioriColors.secondaryText)
                        
                        VStack(spacing: 0) {
                            ForEach(currentSet.bids) { bid in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bid.supplierName)
                                            .font(.subheadline.bold())
                                        Text("Ref: \(bid.quotationNumber) • Terms: \(bid.paymentTerms)")
                                            .font(.caption2)
                                            .foregroundColor(FioriColors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(bid.totalAmount)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(bid.isLowestPrice ? FioriColors.positive : FioriColors.primaryText)
                                        Text("\(bid.deliveryLeadTimeDays) days lead")
                                            .font(.caption2)
                                            .foregroundColor(bid.isFastestDelivery ? FioriColors.sapBlue : FioriColors.secondaryText)
                                    }
                                }
                                .padding(12)
                                .background(bid.isAwarded ? FioriColors.positive.opacity(0.08) : Color.clear)
                                
                                Divider()
                            }
                        }
                        .background(FioriColors.sapCardBackground)
                        .cornerRadius(12)
                    }
                } else {
                    Text("No active quotation comparison sets available.")
                        .foregroundColor(FioriColors.secondaryText)
                }
            }
            .padding()
        }
        .background(FioriColors.sapBackground)
        .navigationTitle("Quotation Comparison")
        .alert("Contract Awarded & PO Generated", isPresented: $showAwardSuccessDialog) {
            Button("Done") {}
        } message: {
            if let po = awardedPO {
                Text("Successfully awarded to \(po.supplierName)!\n\nStandard SAP Purchase Order #\(po.purchaseOrder) generated with total value of $\(po.totalNetAmount).")
            }
        }
    }
    
    private func awardVendor(bid: VendorQuotationBid) async {
        guard let currentSet = currentSet else { return }
        isAwarding = true
        errorMessage = nil
        do {
            let po = try await repository.awardQuotation(
                collectiveRFQ: currentSet.collectiveRFQ,
                quotationNumber: bid.quotationNumber
            )
            self.awardedPO = po
            self.showAwardSuccessDialog = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isAwarding = false
    }
}

// MARK: - Individual Vendor Bid Matrix Card
public struct VendorBidCard: View {
    public let bid: VendorQuotationBid
    public let uom: String
    public let isAwarding: Bool
    public let onAward: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bid.supplierName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("Supplier ID: \(bid.supplierId)")
                        .font(.caption2)
                        .foregroundColor(FioriColors.secondaryText)
                }
                Spacer()
                if bid.isAwarded {
                    Text("AWARDED")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FioriColors.positive.opacity(0.15))
                        .foregroundColor(FioriColors.positive)
                        .clipShape(Capsule())
                }
            }
            
            Divider()
            
            // Metrics
            VStack(spacing: 8) {
                HStack {
                    Text("Unit Price")
                        .font(.subheadline)
                        .foregroundColor(FioriColors.secondaryText)
                    Spacer()
                    Text("$\(bid.unitPrice) / \(uom)")
                        .font(.subheadline.bold())
                        .foregroundColor(bid.isLowestPrice ? FioriColors.positive : FioriColors.primaryText)
                }
                
                HStack {
                    Text("Total Net Price")
                        .font(.subheadline)
                        .foregroundColor(FioriColors.secondaryText)
                    Spacer()
                    Text("$\(bid.totalAmount)")
                        .font(.headline.bold())
                        .foregroundColor(bid.isLowestPrice ? FioriColors.positive : FioriColors.primaryText)
                }
                
                HStack {
                    Text("Delivery Lead Time")
                        .font(.subheadline)
                        .foregroundColor(FioriColors.secondaryText)
                    Spacer()
                    Text("\(bid.deliveryLeadTimeDays) Days")
                        .font(.subheadline.bold())
                        .foregroundColor(bid.isFastestDelivery ? FioriColors.sapBlue : FioriColors.primaryText)
                }
                
                HStack {
                    Text("Payment Terms")
                        .font(.subheadline)
                        .foregroundColor(FioriColors.secondaryText)
                    Spacer()
                    Text(bid.paymentTerms)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Compliance Score")
                        .font(.subheadline)
                        .foregroundColor(FioriColors.secondaryText)
                    Spacer()
                    Text("\(Int(bid.complianceScore))%")
                        .font(.subheadline.bold())
                        .foregroundColor(FioriColors.critical)
                }
            }
            
            Divider()
            
            // Action Button
            if bid.isAwarded {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(FioriColors.positive)
                    Text("Awarded to Vendor")
                        .font(.subheadline.bold())
                        .foregroundColor(FioriColors.positive)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                Button(action: onAward) {
                    HStack {
                        Spacer()
                        if isAwarding {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "trophy.fill")
                            Text("Award & Convert to PO")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .background(FioriColors.sapBlue)
                    .cornerRadius(8)
                }
                .disabled(isAwarding)
            }
        }
        .padding(16)
        .background(FioriColors.sapCardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(bid.isLowestPrice ? FioriColors.positive : (bid.isAwarded ? FioriColors.positive : Color.clear), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

