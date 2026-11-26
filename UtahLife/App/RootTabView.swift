import AlertsFeature
import CoreKit
import DesignSystem
import DomainKit
import EnvironmentFeature
import ExploreFeature
import HomeFeature
import SwiftUI
import TravelFeature

struct RootTabView: View {
    @ObservedObject var dependencies: AppDependencies
    @ObservedObject var router: AppRouter

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.router = dependencies.router
    }

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView(
                        store: dependencies.home,
                        onNavigate: { navigation in
                            Task { await dependencies.router.open(navigation, environment: dependencies.environment, alerts: dependencies.alerts) }
                        },
                        onSelectLocation: { location in
                            Task { await dependencies.select(location) }
                        }
                    )
                }
                .accessibilityIdentifier(A11yID.tabHome)
            }

            Tab("Explore", systemImage: "map", value: AppTab.explore) {
                NavigationStack {
                    ExploreView(store: dependencies.explore) { location in
                        Task { await dependencies.select(location) }
                    }
                }
                .accessibilityIdentifier(A11yID.tabExplore)
            }

            Tab("Travel", systemImage: "car", value: AppTab.travel) {
                NavigationStack {
                    TravelView(store: dependencies.travel) { location in
                        Task { await dependencies.select(location) }
                    }
                }
                .accessibilityIdentifier(A11yID.tabTravel)
            }

            Tab("Environment", systemImage: "cloud.sun", value: AppTab.environment) {
                NavigationStack {
                    EnvironmentView(store: dependencies.environment) { location in
                        Task { await dependencies.select(location) }
                    }
                }
                .accessibilityIdentifier(A11yID.tabEnvironment)
            }

            Tab("Alerts", systemImage: "bell", value: AppTab.alerts) {
                NavigationStack {
                    AlertsView(store: dependencies.alerts) { location in
                        Task { await dependencies.select(location) }
                    }
                }
                .accessibilityIdentifier(A11yID.tabAlerts)
            }
        }
        .tint(UtahColor.accent)
    }
}
