import CoreKit
import SwiftUI

public struct UtahCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(UtahColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                    .strokeBorder(UtahColor.separator.opacity(0.45), lineWidth: 1)
            )
    }
}

public struct SectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(UtahFont.headline)
                .foregroundStyle(UtahColor.primaryText)
            Spacer(minLength: Spacing.small)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(UtahFont.callout.weight(.semibold))
            }
        }
    }
}

public struct StatusPill: View {
    private let title: String
    private let symbol: String
    private let tone: StatusTone

    public init(title: String, symbol: String, tone: StatusTone) {
        self.title = title
        self.symbol = symbol
        self.tone = tone
    }

    public var body: some View {
        Label(title, systemImage: symbol)
            .font(UtahFont.caption.weight(.semibold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(tone.foreground.opacity(0.12))
            .clipShape(Capsule())
            .accessibilityElement(children: .combine)
    }
}

public struct CategoryChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(UtahFont.caption.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .foregroundStyle(isSelected ? UtahColor.onAccent : UtahColor.primaryText)
                .background(isSelected ? UtahColor.accent : UtahColor.chipBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public struct LastUpdatedLabel: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(UtahFont.caption)
            .foregroundStyle(UtahColor.secondaryText)
    }
}

public struct MockDataBanner: View {
    public init() {}

    public var body: some View {
        Label(SampleCopy.banner, systemImage: "info.circle")
            .font(UtahFont.caption)
            .foregroundStyle(UtahColor.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(SampleCopy.banner)
    }
}
