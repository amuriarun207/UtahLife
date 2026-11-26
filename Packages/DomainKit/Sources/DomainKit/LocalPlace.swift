import Foundation

public enum PlaceCategory: String, Equatable, Sendable, CaseIterable, Identifiable {
    case parks
    case libraries
    case communityCenters
    case hospitals
    case grocery
    case pharmacies
    case publicFacilities
    case recreation

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .parks: return "Parks"
        case .libraries: return "Libraries"
        case .communityCenters: return "Community centers"
        case .hospitals: return "Hospitals and urgent care"
        case .grocery: return "Grocery stores"
        case .pharmacies: return "Pharmacies"
        case .publicFacilities: return "Public facilities"
        case .recreation: return "Recreation"
        }
    }

    public var symbolName: String {
        switch self {
        case .parks: return "leaf"
        case .libraries: return "books.vertical"
        case .communityCenters: return "person.3"
        case .hospitals: return "cross.case"
        case .grocery: return "basket"
        case .pharmacies: return "pills"
        case .publicFacilities: return "building.columns"
        case .recreation: return "figure.walk"
        }
    }
}

public struct LocalPlace: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var locationId: String
    public var name: String
    public var category: PlaceCategory
    public var address: String
    public var latitude: Double
    public var longitude: Double
    public var description: String
    public var isMockData: Bool

    public init(
        id: String,
        locationId: String,
        name: String,
        category: PlaceCategory,
        address: String,
        latitude: Double,
        longitude: Double,
        description: String,
        isMockData: Bool
    ) {
        self.id = id
        self.locationId = locationId
        self.name = name
        self.category = category
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.isMockData = isMockData
    }
}
