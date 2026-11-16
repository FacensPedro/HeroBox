import XCTest
@testable import XboxMedia

final class MediaTests: XCTestCase {
    func testRecognizedMedia() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let file = root.appendingPathComponent("game")
        let cases: [(String, XboxGeneration?)] = [("XBEH", .original), ("XEX2", .xbox360), ("", nil)]
        for (header, generation) in cases {
            try Data(header.utf8).write(to: file)
            XCTAssertEqual(try XboxMedia.identify(file), generation)
        }
        XCTAssertNil(try XboxMedia.identify(root))
        let original = root.appendingPathComponent("DEFAULT.XBE")
        let sequel = root.appendingPathComponent("default.xex")
        try Data("XEX2".utf8).write(to: original)
        XCTAssertNil(try XboxMedia.identify(root))
        try Data("XBEH".utf8).write(to: original)
        XCTAssertEqual(try XboxMedia.identify(root), .original)
        try Data("XEX2".utf8).write(to: sequel)
        XCTAssertNil(try XboxMedia.identify(root))
        try fm.removeItem(at: original)
        XCTAssertEqual(try XboxMedia.identify(root), .xbox360)
        try fm.removeItem(at: sequel)
        XCTAssertThrowsError(try XboxMedia.identify(sequel))
        for child in ["Mount", "EmbeddedXvd"] {
            try fm.createDirectory(at: root.appendingPathComponent(child), withIntermediateDirectories: false)
        }
        XCTAssertEqual(try XboxMedia.identify(root), .xboxOne)
    }
}
