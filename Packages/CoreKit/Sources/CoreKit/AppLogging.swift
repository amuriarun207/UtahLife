public protocol AppLogging: Sendable {
    func log(_ message: String)
}

public struct NoOpLogger: AppLogging {
    public init() {}

    public func log(_ message: String) {}
}
