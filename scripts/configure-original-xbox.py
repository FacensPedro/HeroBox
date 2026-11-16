"""Build the existing HeroBox dashboard and Xbox media tools into DukeX's native host."""
import plistlib
import shutil
import sys
from pathlib import Path

app, root = map(Path, sys.argv[1:])
entry = app / "App/DukeXApp.swift"
source = entry.read_text()
source = source.replace("@StateObject private var store", "@State private var playingXbox = false\n    @StateObject private var store", 1)
assert source.count("            ContentView()") == 1
source = source.replace("            ContentView()", """            Group {
                if playingXbox {
                    ContentView()
                } else {
                    MediaInspector(openLibrary: { playingXbox = true })
                }
            }""", 1)
inspector = (root / "App/HeroBoxApp.swift").read_text()
inspector = inspector[inspector.index("struct MediaInspector: View"):]
inspector = inspector.replace("struct MediaInspector: View {", "struct MediaInspector: View {\n    let openLibrary: () -> Void", 1)
anchor = '                    ConsoleTile(title: "Inspect game media"'
assert inspector.count(anchor) == 1
inspector = inspector.replace(anchor, '''                    ConsoleTile(title: "Play original Xbox", icon: "gamecontroller.fill", featured: true, action: openLibrary)
''' + anchor, 1)
parts = [source, "import UniformTypeIdentifiers", inspector]
for file in ["App/ConsoleDashboard.swift", "App/RuntimeControls.swift", "Sources/XboxMedia/XboxMedia.swift"]:
    parts.append((root / file).read_text())
entry.write_text("\n".join(parts))
assets = next(app.rglob("Assets.xcassets"))
for name in ["HeroBoxIcon.appiconset", "HeroBoxLogo.imageset"]:
    shutil.copytree(root / "App/HeroBoxAssets.xcassets" / name, assets / name)
entitlements = app / "DukeX.entitlements"
data = plistlib.loads(entitlements.read_bytes())
data.update(plistlib.loads((root / "HeroBox.entitlements").read_bytes()))
entitlements.write_bytes(plistlib.dumps(data))

# Work around a Swift type-checking timeout in the pinned DukeX FAT timestamp helper.
# Keep the fix in the temporary checkout rather than modifying upstream.
cloud_store = app / "Services/CloudSaves/FATXHDDCloudSaveStore.swift"
cloud_source = cloud_store.read_text()
original_timestamp = """        let time = UInt16(((components.hour ?? 0) << 11) | ((components.minute ?? 0) << 5) | ((components.second ?? 0) / 2))"""
corrected_timestamp = """        let hour = UInt16(components.hour ?? 0)
        let minute = UInt16(components.minute ?? 0)
        let second = UInt16(components.second ?? 0)
        let time = (hour << 11) | (minute << 5) | (second / 2)"""
assert cloud_source.count(original_timestamp) == 1
cloud_store.write_text(cloud_source.replace(original_timestamp, corrected_timestamp))
