import Foundation

public enum AppError: Error, Equatable, Sendable, Hashable {
    case message(String)
    case decoding(String)
    case unavailable(String)
    case empty(String)

    public var message: String {
        switch self {
        case let .message(text),
             let .decoding(text),
             let .unavailable(text),
             let .empty(text):
            return text
        }
    }

    public init(_ error: any Error) {
        if let appError = error as? AppError {
            self = appError
            return
        }
        if error is CancellationError {
            self = .message("The sample request was cancelled.")
            return
        }
        self = .message(error.localizedDescription)
    }

    public var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
}
