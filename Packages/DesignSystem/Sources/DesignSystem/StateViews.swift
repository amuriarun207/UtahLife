import CoreKit
import SwiftUI

public struct EmptyStateView: View {
    private let title: String
    private let message: String
    private let symbol: String

    public init(title: String, message: String, symbol: String) {
        self.title = title
        self.message = message
        self.symbol = symbol
    }

    public var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: symbol)
                .font(.system(.title, design: .default).weight(.semibold))
                .foregroundStyle(UtahColor.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(UtahFont.title)
                .multilineTextAlignment(.center)
            Text(message)
                .font(UtahFont.body)
                .foregroundStyle(UtahColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xLarge)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(A11yID.stateEmpty)
    }
}

public struct ErrorStateView: View {
    private let message: String
    private let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(.title, design: .default).weight(.semibold))
                .foregroundStyle(UtahColor.critical)
                .accessibilityHidden(true)
            Text("Sample data unavailable")
                .font(UtahFont.title)
                .multilineTextAlignment(.center)
            Text(message)
                .font(UtahFont.body)
                .foregroundStyle(UtahColor.secondaryText)
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(UtahColor.accent)
                .accessibilityIdentifier(A11yID.stateRetry)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xLarge)
    }
}

public struct LoadingStateView: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        VStack(spacing: Spacing.medium) {
            ProgressView()
            Text(title)
                .font(UtahFont.callout)
                .foregroundStyle(UtahColor.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .accessibilityIdentifier(A11yID.stateLoading)
    }
}

public struct ReadableScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
    }
}

public struct AdaptiveColumnGrid<Content: View>: View {
    private let minItemWidth: CGFloat
    private let content: Content

    public init(minItemWidth: CGFloat = 320, @ViewBuilder content: () -> Content) {
        self.minItemWidth = minItemWidth
        self.content = content()
    }

    public var body: some View {
        WrappingColumnLayout(minItemWidth: minItemWidth, maxItemWidth: 520, spacing: Spacing.large) {
            content
        }
    }
}

/// Eager wrapping columns. `LazyVGrid` omits off-screen cells, which drops cards from the accessibility tree on a short display.
private struct WrappingColumnLayout: Layout {
    var minItemWidth: CGFloat
    var maxItemWidth: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrangement(proposal: proposal, subviews: subviews).frames
        for (index, frame) in frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let available = proposal.width ?? maxItemWidth
        let columns = max(1, Int((available + spacing) / (minItemWidth + spacing)))
        let itemWidth = min(maxItemWidth, (available - (spacing * CGFloat(columns - 1))) / CGFloat(columns))
        var frames: [CGRect] = []
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var column = 0
        for subview in subviews {
            if column == columns {
                y += rowHeight + spacing
                rowHeight = 0
                column = 0
            }
            let height = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height
            let x = CGFloat(column) * (itemWidth + spacing)
            frames.append(CGRect(x: x, y: y, width: itemWidth, height: height))
            rowHeight = max(rowHeight, height)
            column += 1
        }
        return (CGSize(width: available, height: y + rowHeight), frames)
    }
}

public struct AdaptivePair<Primary: View, Secondary: View>: View {
    private let breakpoint: CGFloat
    private let primary: Primary
    private let secondary: Secondary
    @State private var width: CGFloat = 0

    public init(
        breakpoint: CGFloat = 760,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.breakpoint = breakpoint
        self.primary = primary()
        self.secondary = secondary()
    }

    public var body: some View {
        let layout = width >= breakpoint
            ? AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.large))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.large))
        layout {
            primary
                .frame(maxWidth: .infinity, alignment: .topLeading)
            secondary
                .frame(maxWidth: width >= breakpoint ? 420 : .infinity, alignment: .topLeading)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            guard abs(width - newWidth) > 0.5 else { return }
            width = newWidth
        }
    }
}
