import CoreKit
import Foundation

enum FixtureLoader {
    static func load<T: Decodable>(_ name: String, from bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw AppError.decoding("Missing fixture \(name).json.")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.decoding("Could not decode \(name).json. \(error.localizedDescription)")
        }
    }

    static func models<DTO: Decodable, Model>(
        _ name: String,
        from bundle: Bundle,
        _ transform: (DTO) throws -> Model
    ) throws -> [Model] {
        let decoded: [DTO] = try load(name, from: bundle)
        var models: [Model] = []
        models.reserveCapacity(decoded.count)
        for item in decoded {
            models.append(try transform(item))
        }
        return models
    }
}

enum SampleDateParser {
    static func date(from string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: string) else {
            throw AppError.decoding("Unrecognized sample timestamp \(string).")
        }
        return date
    }
}
