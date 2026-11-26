public enum AsyncValue<Value: Equatable & Sendable>: Equatable, Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(AppError)

    public var value: Value? {
        if case let .loaded(value) = self {
            return value
        }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    public var error: AppError? {
        if case let .failed(error) = self {
            return error
        }
        return nil
    }
}
