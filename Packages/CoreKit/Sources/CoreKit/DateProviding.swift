import Foundation

public protocol DateProviding: Sendable {
    func now() -> Date
}

public struct SystemDateProvider: DateProviding {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

public struct FixedDateProvider: DateProviding {
    public var date: Date

    public init(date: Date) {
        self.date = date
    }

    public func now() -> Date {
        date
    }
}
