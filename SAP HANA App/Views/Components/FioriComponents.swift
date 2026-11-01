//
//  FioriComponents.swift
//  SAPHANAApp
//
//  Native SAP Fiori for iOS Design System UI Controls
//  Conforms to SAP Fiori Design Guidelines:
//  FUIObjectHeader, FUIObjectCell, FUIFilterFormCell, FUIKeyValueItem,
//  FUIBannerMessageView, and Fiori KPI Card Headers.
//

import SwiftUI

// MARK: - Fiori Theme Colors & Tokens
public struct FioriColors {
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let sapBlue = Color(red: 0.05, green: 0.38, blue: 0.67)       // SAP Fiori 72 Shell Blue (#0d61ab)
    public static let sapDarkBlue = Color(red: 0.02, green: 0.22, blue: 0.42)
    public static let sapBackground = Color(uiColor: .systemGroupedBackground)
    public static let sapCardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let positive = Color(red: 0.13, green: 0.58, blue: 0.28)     // SAP Green
    public static let negative = Color(red: 0.82, green: 0.16, blue: 0.16)     // SAP Red
    public static let critical = Color(red: 0.90, green: 0.48, blue: 0.05)     // SAP Orange
    public static let neutral = Color(red: 0.42, green: 0.47, blue: 0.53)      // SAP Grey
}

// MARK: - 1. FUIObjectHeader
public struct FUIObjectHeader: View {
    public let icon: String
    public let title: String
    public let subtitle: String
    public let status: String
    public let statusColor: Color
    public let footnote: String?
    public let description: String?
    public var kpiValue: String?
    public var kpiCaption: String?
    
    public init(
        icon: String = "doc.text.fill",
        title: String,
        subtitle: String,
        status: String,
        statusColor: Color = FioriColors.positive,
        footnote: String? = nil,
        description: String? = nil,
        kpiValue: String? = nil,
        kpiCaption: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.status = status
        self.statusColor = statusColor
        self.footnote = footnote
        self.description = description
        self.kpiValue = kpiValue
        self.kpiCaption = kpiCaption
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Object Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(FioriColors.sapBlue.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(FioriColors.sapBlue)
                }
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(FioriColors.primaryText)
                    Text(subtitle)
                        .font(.system(.subheadline).weight(.medium))
                        .foregroundColor(FioriColors.secondaryText)
                }
                
                Spacer()
                
                // Status Badge
                Text(status)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }
            
            if let desc = description {
                Text(desc)
                    .font(.footnote)
                    .foregroundColor(FioriColors.secondaryText)
                    .lineLimit(2)
            }
            
            // Optional KPI metric strip
            if let kpiVal = kpiValue, let kpiCap = kpiCaption {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kpiCap.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(FioriColors.secondaryText)
                        Text(kpiVal)
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundColor(FioriColors.sapBlue)
                    }
                    Spacer()
                    if let fn = footnote {
                        Text(fn)
                            .font(.caption2)
                            .foregroundColor(FioriColors.secondaryText)
                    }
                }
            }
        }
        .padding(16)
        .background(FioriColors.sapCardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - 2. FUIObjectCell
public struct FUIObjectCell: View {
    public let iconName: String
    public let headline: String
    public let subheadline: String
    public let footnote: String?
    public let statusText: String?
    public let statusColor: Color
    public let subStatusText: String?
    
    public init(
        iconName: String = "doc.fill",
        headline: String,
        subheadline: String,
        footnote: String? = nil,
        statusText: String? = nil,
        statusColor: Color = FioriColors.positive,
        subStatusText: String? = nil
    ) {
        self.iconName = iconName
        self.headline = headline
        self.subheadline = subheadline
        self.footnote = footnote
        self.statusText = statusText
        self.statusColor = statusColor
        self.subStatusText = subStatusText
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(FioriColors.sapBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(FioriColors.sapBlue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(FioriColors.primaryText)
                    .lineLimit(1)
                
                Text(subheadline)
                    .font(.system(.subheadline))
                    .foregroundColor(FioriColors.secondaryText)
                    .lineLimit(1)
                
                if let fn = footnote {
                    Text(fn)
                        .font(.system(.caption2))
                        .foregroundColor(FioriColors.secondaryText)
                }
            }
            
            Spacer()
            
            // Trailing Status
            VStack(alignment: .trailing, spacing: 4) {
                if let status = statusText {
                    Text(status)
                        .font(.system(.callout, design: .rounded).weight(.bold))
                        .foregroundColor(statusColor)
                }
                
                if let subStatus = subStatusText {
                    Text(subStatus)
                        .font(.system(.caption2))
                        .foregroundColor(FioriColors.secondaryText)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 3. FUIFilterFormCell
public struct FUIFilterFormCell<Option: Hashable & CustomStringConvertible>: View {
    public let title: String
    public let options: [Option]
    @Binding public var selectedOption: Option
    
    public init(title: String, options: [Option], selectedOption: Binding<Option>) {
        self.title = title
        self.options = options
        self._selectedOption = selectedOption
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(FioriColors.secondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { opt in
                        Button(action: {
                            selectedOption = opt
                        }) {
                            Text(opt.description)
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selectedOption == opt ? FioriColors.sapBlue : FioriColors.sapCardBackground)
                                .foregroundColor(selectedOption == opt ? .white : FioriColors.primaryText)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedOption == opt ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 4. FUIKeyValueItem
public struct FUIKeyValueItem: View {
    public let key: String
    public let value: String
    public var isHighlighted: Bool = false
    
    public init(key: String, value: String, isHighlighted: Bool = false) {
        self.key = key
        self.value = value
        self.isHighlighted = isHighlighted
    }
    
    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .font(.system(.subheadline))
                .foregroundColor(FioriColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(isHighlighted ? .bold : .medium))
                .foregroundColor(isHighlighted ? FioriColors.sapBlue : FioriColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 5. FUIBannerMessageView
public enum FUIBannerType {
    case info, success, warning, error
    
    public var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .info: return FioriColors.sapBlue
        case .success: return FioriColors.positive
        case .warning: return FioriColors.critical
        case .error: return FioriColors.negative
        }
    }
}

public struct FUIBannerMessageView: View {
    public let message: String
    public let type: FUIBannerType
    public var actionTitle: String? = nil
    public var onAction: (() -> Void)? = nil
    
    public init(
        message: String,
        type: FUIBannerType = .info,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.type = type
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundColor(FioriColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(type.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(type.color.opacity(0.12))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(type.color.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 6. Fiori KPI Card View
public struct FioriKPICard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let trend: String?
    public let isPositiveTrend: Bool
    public let icon: String
    public let accentColor: Color
    
    public init(
        title: String,
        value: String,
        subtitle: String,
        trend: String? = nil,
        isPositiveTrend: Bool = true,
        icon: String = "chart.line.uptrend.xyaxis",
        accentColor: Color = FioriColors.sapBlue
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.isPositiveTrend = isPositiveTrend
        self.icon = icon
        self.accentColor = accentColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FioriColors.secondaryText)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(FioriColors.primaryText)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                if let trend = trend {
                    Image(systemName: isPositiveTrend ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPositiveTrend ? FioriColors.positive : FioriColors.negative)
                    Text(trend)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isPositiveTrend ? FioriColors.positive : FioriColors.negative)
                }
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(FioriColors.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FioriColors.sapCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

