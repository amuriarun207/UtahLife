import Foundation

public enum DistanceCalculator {
    public static func miles(
        fromLatitude: Double,
        fromLongitude: Double,
        toLatitude: Double,
        toLongitude: Double
    ) -> Double {
        let earthRadiusMiles = 3958.8
        let lat1 = fromLatitude * .pi / 180
        let lat2 = toLatitude * .pi / 180
        let deltaLat = (toLatitude - fromLatitude) * .pi / 180
        let deltaLon = (toLongitude - fromLongitude) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMiles * c
    }

    public static func label(miles: Double) -> String {
        if miles < 0.1 {
            return "Under 0.1 mi"
        }
        return String(format: "%.1f mi", miles)
    }
}
