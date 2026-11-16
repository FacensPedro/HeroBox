"""Assemble the HeroBox device target around the pinned Xbox One runtime."""
import plistlib
import shutil
import sys
from pathlib import Path

core, root = map(Path, sys.argv[1:])
ios = core / "ios"
app = ios / "Utsuro"
project = ios / "project.yml"
spec = project.read_text()
assert "UTSURO_BUNDLE_IDENTIFIER: com.utsuro.app" in spec
spec = spec.replace("    SWIFT_VERSION:", '    SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) HEROBOX_XBOX_ONE"\n    SWIFT_VERSION:')
project.write_text(spec.replace("UTSURO_BUNDLE_IDENTIFIER: com.utsuro.app",
                                "UTSURO_BUNDLE_IDENTIFIER: com.facenspedro.herobox"))
info = app / "Info.plist"
metadata = plistlib.loads(info.read_bytes())
metadata["CFBundleDisplayName"] = "HeroBox"
info.write_bytes(plistlib.dumps(metadata))
entitlements = app / "Utsuro.entitlements"
effective = plistlib.loads(entitlements.read_bytes())
effective.update(plistlib.loads((root / "HeroBox.entitlements").read_bytes()))
entitlements.write_bytes(plistlib.dumps(effective))

# Compile the media inspector into the same process as the game engine.
inspector = (root / "App/HeroBoxApp.swift").read_text()
view = inspector[inspector.index("struct MediaInspector: View"):]
(app / "MediaInspector.swift").write_text("import SwiftUI\nimport UniformTypeIdentifiers\n" + view)
shutil.copy(root / "App/RuntimeControls.swift", app)
shutil.copy(root / "Sources/XboxMedia/XboxMedia.swift", app)
homepage = app / "RootView.swift"
source = homepage.read_text()
anchor = "                    SettingsView()"
assert source.count(anchor) == 1
source = source.replace("struct RootView: View {", "struct RootView: View {\n    @State private var inspectingMedia = false")
homepage.write_text(source.replace(anchor, anchor + """
                        .safeAreaInset(edge: .bottom) {
                            Button("Inspect game media") { inspectingMedia = true }
                        }
                        .sheet(isPresented: $inspectingMedia) { MediaInspector() }
"""))
