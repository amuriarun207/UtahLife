import Foundation

public enum FixtureScenario: String, Sendable, Equatable {
    case populated
    case empty
    case failure

    public static let launchArgument = "-UtahLifeScenario"

    public static func from(arguments: [String]) -> FixtureScenario {
        guard let index = arguments.firstIndex(of: launchArgument),
              arguments.indices.contains(index + 1) else {
            return .populated
        }
        return FixtureScenario(rawValue: arguments[index + 1]) ?? .populated
    }
}
