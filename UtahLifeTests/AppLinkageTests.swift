import CoreKit
import XCTest

final class AppLinkageTests: XCTestCase {
    func testSampleCopyStaysExplicit() {
        XCTAssertTrue(SampleCopy.banner.localizedCaseInsensitiveContains("sample"))
        XCTAssertTrue(SampleCopy.banner.localizedCaseInsensitiveContains("not a live"))
    }
}
