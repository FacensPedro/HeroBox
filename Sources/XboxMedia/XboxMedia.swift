import Foundation

public enum XboxGeneration: Equatable {
    case original, xbox360, xboxOne
}

public enum XboxMedia {
    /// Recognizes extracted executables and Utsuro's extracted package layout.
    public static func identify(_ url: URL) throws -> XboxGeneration? {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey]
        let attributes = try url.resourceValues(forKeys: keys)
        if attributes.isDirectory == true {
            let children = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]
            )
            let directories = try children.filter {
                try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
            }
            let names = Set(directories.map { $0.lastPathComponent.lowercased() })
            if names.isSuperset(of: ["mount", "embeddedxvd"]) { return .xboxOne }

            var matches = Set<String>()
            for child in children {
                let name = child.lastPathComponent.lowercased()
                guard ["default.xbe", "default.xex"].contains(name),
                      try child.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
                else { continue }
                let generation = try executableGeneration(child)
                if name == "default.xbe", generation == .original { matches.insert(name) }
                if name == "default.xex", generation == .xbox360 { matches.insert(name) }
            }
            guard matches.count == 1 else { return nil }
            return matches.contains("default.xbe") ? .original : .xbox360
        }
        guard attributes.isRegularFile == true else { return nil }
        return try executableGeneration(url)
    }

    private static func executableGeneration(_ url: URL) throws -> XboxGeneration? {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        switch try file.read(upToCount: 4) {
        case Data("XBEH".utf8): return .original
        case Data("XEX2".utf8): return .xbox360
        default: return nil
        }
    }
}
