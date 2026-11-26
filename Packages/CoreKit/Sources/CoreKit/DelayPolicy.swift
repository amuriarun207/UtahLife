import Foundation

public protocol DelayPolicy: Sendable {
    func wait() async
}

public struct ImmediateDelayPolicy: DelayPolicy {
    public init() {}

    public func wait() async {}
}

public struct FixedDelayPolicy: DelayPolicy {
    public var duration: Duration

    public init(duration: Duration) {
        self.duration = duration
    }

    public func wait() async {
        try? await Task.sleep(for: duration)
    }
}
