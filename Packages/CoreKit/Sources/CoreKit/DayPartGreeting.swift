import Foundation

public enum DayPart: String, Equatable, Sendable {
    case morning
    case afternoon
    case evening
    case night
}

public enum DayPartGreeting {
    public static func dayPart(for date: Date, calendar: Calendar) -> DayPart {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .night
        }
    }

    public static func text(for date: Date, calendar: Calendar) -> String {
        switch dayPart(for: date, calendar: calendar) {
        case .morning:
            return "Good morning"
        case .afternoon:
            return "Good afternoon"
        case .evening:
            return "Good evening"
        case .night:
            return "Good night"
        }
    }
}
