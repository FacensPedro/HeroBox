"""Assemble the HeroBox device target around the pinned Xbox One runtime."""
import plistlib
import shutil
import sys
from pathlib import Path

core, root = map(Path, sys.argv[1:])
ios = core / "ios"
app = ios / "Utsuro"
project = ios / "project.yml"
shutil.copytree(root / "App/HeroBoxAssets.xcassets", app / "HeroBoxAssets.xcassets")
spec = project.read_text().replace("ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon",
                                   "ASSETCATALOG_COMPILER_APPICON_NAME: HeroBoxIcon")
assert "UTSURO_BUNDLE_IDENTIFIER: com.utsuro.app" in spec
spec = spec.replace("    SWIFT_VERSION:", '    SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) HEROBOX_XBOX_ONE"\n    SWIFT_VERSION:')
project.write_text(spec.replace("UTSURO_BUNDLE_IDENTIFIER: com.utsuro.app",
                                "UTSURO_BUNDLE_IDENTIFIER: com.facenspedro.herobox"))
shutil.copy(root / "Version.xcconfig", ios)
spec = project.read_text().replace("settings:\n  base:", "configFiles:\n  Debug: Version.xcconfig\n  Release: Version.xcconfig\n\nsettings:\n  base:", 1)
project.write_text(spec)
for bundle in (app, ios / "UtsuroJITHelper"):
    plist = bundle / "Info.plist"
    data = plistlib.loads(plist.read_bytes())
    data["CFBundleShortVersionString"] = "$(MARKETING_VERSION)"
    data["CFBundleVersion"] = "$(CURRENT_PROJECT_VERSION)"
    plist.write_bytes(plistlib.dumps(data))
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
shutil.copy(root / "App/ConsoleDashboard.swift", app)
shutil.copy(root / "Sources/XboxMedia/XboxMedia.swift", app)
homepage = app / "RootView.swift"
source = homepage.read_text()
anchor = "                    SettingsView()"
assert source.count(anchor) == 1
source = source.replace("struct RootView: View {", "struct RootView: View {\n    @State private var inspectingMedia = false")
header = """                    header
                        .padding(.horizontal, 2)
                        .padding(.bottom, 14)"""
assert source.count(header) == 1
source = source.replace(header, """                    HStack {
                        ConsoleHeader()
                        HomeMenu()
                    }
                    .padding(.bottom, 14)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 8) {
                        ConsoleTile(title: "My games", icon: "square.grid.2x2", featured: true) {
                            router.tab = .library
                        }
                        ConsoleTile(title: "Import game", icon: "plus.rectangle") {
                            router.addingGame = true
                        }
                    }
                    .padding(.bottom, 16)""")
source = source.replace(".background(Ink.page.ignoresSafeArea())",
                        ".background(ConsolePalette.canvas.ignoresSafeArea())", 1)
tab_end = """                }
            }
        }
        .sheet(isPresented: $jit.showSetup)"""
assert source.count(tab_end) == 1
source = source.replace(tab_end, tab_end.replace("                }", """                }
                .tint(ConsolePalette.accent)
                .preferredColorScheme(.dark)""", 1))
homepage.write_text(source.replace(anchor, anchor + """
                        .safeAreaInset(edge: .bottom) {
                            Button("Inspect game media") { inspectingMedia = true }
                        }
                        .sheet(isPresented: $inspectingMedia) { MediaInspector() }
"""))
