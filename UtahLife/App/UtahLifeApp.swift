import CoreKit
import DataKit
import DesignSystem
import DomainKit
import SwiftUI

@main
struct UtahLifeApp: App {
    @State private var launch: LaunchState = .loading

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .loading:
                LoadingStateView(title: "Loading sample data")
                    .task { await start() }
            case let .ready(dependencies):
                RootTabView(dependencies: dependencies)
            case let .failed(message):
                ErrorStateView(message: message) {
                    launch = .loading
                }
            }
        }
    }

    private func start() async {
        do {
            launch = .ready(try await AppDependencies.make())
        } catch {
            launch = .failed(AppError(error).message)
        }
    }
}

private enum LaunchState {
    case loading
    case ready(AppDependencies)
    case failed(String)
}
