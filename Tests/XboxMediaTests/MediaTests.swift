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

    func testXISODescriptorRecognition() throws {
        let root = FileManager.default.temporaryDirectory
        let disc = root.appendingPathComponent(UUID().uuidString + ".iso")
        defer { try? FileManager.default.removeItem(at: disc) }
        var bytes = Data(repeating: 0, count: 0x10800)
        let signature = Data("MICROSOFT*XBOX*MEDIA".utf8)
        bytes.replaceSubrange(0x10000..<(0x10000 + signature.count), with: signature)
        bytes.replaceSubrange(0x107EC..<(0x107EC + signature.count), with: signature)
        try bytes.write(to: disc)
        XCTAssertTrue(try XboxMedia.isXISO(disc))
        XCTAssertNil(try XboxMedia.identify(disc))
        bytes[0x107EC] = 0
        try bytes.write(to: disc)
        XCTAssertFalse(try XboxMedia.isXISO(disc))
    }
}
