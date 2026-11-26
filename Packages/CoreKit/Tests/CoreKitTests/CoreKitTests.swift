import CoreKit
import Foundation
import XCTest

final class CoreKitTests: XCTestCase {
    func testGreetingFollowsLocalHour() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        XCTAssertEqual(DayPartGreeting.text(for: date("2026-01-12T08:15:00Z"), calendar: calendar), "Good morning")
        XCTAssertEqual(DayPartGreeting.text(for: date("2026-01-12T13:00:00Z"), calendar: calendar), "Good afternoon")
        XCTAssertEqual(DayPartGreeting.text(for: date("2026-01-12T18:45:00Z"), calendar: calendar), "Good evening")
        XCTAssertEqual(DayPartGreeting.text(for: date("2026-01-12T23:10:00Z"), calendar: calendar), "Good night")
        XCTAssertEqual(DayPartGreeting.text(for: date("2026-01-12T02:00:00Z"), calendar: calendar), "Good night")
    }

    func testTimestampUsesSuppliedTimeZone() {
        let timeZone = TimeZone(identifier: "America/Denver") ?? .gmt
        let text = ObservationTimestampFormatter.string(for: date("2026-01-12T15:30:00Z"), timeZone: timeZone)
        XCTAssertEqual(text, "Sample updated Jan 12, 2026 at 8:30 AM")
    }

    func testWeekdayAndTimeFormatting() {
        let timeZone = TimeZone(identifier: "America/Denver") ?? .gmt
        XCTAssertEqual(ObservationTimestampFormatter.time(for: date("2026-01-12T15:00:00Z"), timeZone: timeZone), "8 AM")
        XCTAssertEqual(ObservationTimestampFormatter.weekday(for: date("2026-01-12T15:00:00Z"), timeZone: timeZone), "Mon")
    }

    func testAsyncValueExposesLoadedValue() {
        let value = AsyncValue.loaded("sample")
        XCTAssertEqual(value.value, "sample")
        XCTAssertNil(AsyncValue<String>.empty.value)
        XCTAssertTrue(AsyncValue<String>.loading.isLoading)
    }

    func testAppErrorPreservesEmptyAndCancellation() {
        XCTAssertTrue(AppError(AppError.empty("none")).isEmpty)
        XCTAssertEqual(AppError(CancellationError()).message, "The sample request was cancelled.")
    }

    private func date(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: string) else {
            XCTFail("Invalid date \(string)")
            return Date(timeIntervalSince1970: 0)
        }
        return date
    }
}
