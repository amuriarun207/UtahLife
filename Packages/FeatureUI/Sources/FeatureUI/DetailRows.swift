import CoreKit
import DesignSystem
import DomainKit
import SwiftUI

public struct PlaceRow: View {
    private let place: LocalPlace
    private let distance: String

    public init(place: LocalPlace, distance: String) {
        self.place = place
        self.distance = distance
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: place.category.symbolName)
                .frame(width: 28)
                .foregroundStyle(UtahColor.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(place.name)
                    .font(UtahFont.body.weight(.semibold))
                Text(place.category.title)
                    .font(UtahFont.caption)
                    .foregroundStyle(UtahColor.secondaryText)
                Text("\(place.address) · \(distance)")
                    .font(UtahFont.caption)
                    .foregroundStyle(UtahColor.secondaryText)
                Text("Sample listing")
                    .font(UtahFont.caption.weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(A11yID.placeRow(place.id))
    }
}

public struct ForecastDayRow: View {
    private let day: ForecastDay
    private let timeZone: TimeZone
    private let isSelected: Bool

    public init(day: ForecastDay, timeZone: TimeZone, isSelected: Bool) {
        self.day = day
        self.timeZone = timeZone
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: Spacing.medium) {
            Text(ObservationTimestampFormatter.weekday(for: day.date, timeZone: timeZone))
                .font(UtahFont.body.weight(.semibold))
                .frame(width: 48, alignment: .leading)
            Image(systemName: day.condition.symbolName)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(day.condition.title)
                .font(UtahFont.callout)
            Spacer(minLength: Spacing.small)
            Text("\(day.high.display) / \(day.low.display)")
                .font(UtahFont.callout.weight(.semibold))
        }
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ObservationTimestampFormatter.fullDay(for: day.date, timeZone: timeZone)), \(day.condition.title), high \(day.high.display), low \(day.low.display), \(day.precipitationProbability.display) chance of precipitation. Sample forecast.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(A11yID.forecastRow(day.id))
    }
}

public struct RoadConditionCard: View {
    private let condition: RoadCondition
    private let timeZone: TimeZone

    public init(condition: RoadCondition, timeZone: TimeZone) {
        self.condition = condition
        self.timeZone = timeZone
    }

    public var body: some View {
        UtahCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label(condition.condition.title, systemImage: condition.condition.symbolName)
                    .font(UtahFont.headline)
                Text(condition.roadName)
                    .font(UtahFont.body)
                Text(condition.area)
                    .font(UtahFont.caption)
                    .foregroundStyle(UtahColor.secondaryText)
                Text(condition.description)
                    .font(UtahFont.callout)
                LastUpdatedLabel(ObservationTimestampFormatter.string(for: condition.updatedAt, timeZone: timeZone))
                Text("Sample road report")
                    .font(UtahFont.caption.weight(.semibold))
                    .foregroundStyle(UtahColor.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

public struct MetricTile: View {
    private let title: String
    private let value: String
    private let symbol: String

    public init(title: String, value: String, symbol: String) {
        self.title = title
        self.value = value
        self.symbol = symbol
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(title, systemImage: symbol)
                .font(UtahFont.caption)
                .foregroundStyle(UtahColor.secondaryText)
            Text(value)
                .font(UtahFont.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

public struct QuickActionButton: View {
    private let title: String
    private let symbol: String
    private let identifier: String
    private let action: () -> Void

    public init(title: String, symbol: String, identifier: String, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.identifier = identifier
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.small) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(title)
                    .font(UtahFont.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .background(UtahColor.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
