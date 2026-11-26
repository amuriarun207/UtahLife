import Foundation

public actor MemoryLocationPreferences: LocationPreferencesProtocol {
    private var stored: String?

    public init(selectedID: String? = nil) {
        stored = selectedID
    }

    public func selectedLocationID() async -> String? {
        stored
    }

    public func setSelectedLocationID(_ id: String) async {
        stored = id
    }
}

public actor MemoryNotificationPreferences: NotificationPreferencesRepositoryProtocol {
    private var preferences: NotificationPreferences

    public init(preferences: NotificationPreferences = .sampleDefault) {
        self.preferences = preferences
    }

    public func load() async -> NotificationPreferences {
        preferences
    }

    public func save(_ preferences: NotificationPreferences) async {
        self.preferences = preferences
    }
}
