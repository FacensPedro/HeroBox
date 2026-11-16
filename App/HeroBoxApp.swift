import SwiftUI
import UniformTypeIdentifiers
import XboxMedia

@main
struct HeroBoxApp: App {
    var body: some Scene {
        WindowGroup { MediaInspector() }
    }
}

struct MediaInspector: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var choosingMedia = false
    @State private var result = ""
    @State private var selection = ""

    @State private var showingSettings = false

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ConsoleHeader()
                    ConsoleTile(title: "Inspect game media", icon: "opticaldisc", featured: true) {
                        choosingMedia = true
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: geometry.size.width >= 650 ? 215 : 145), spacing: 12)], spacing: 12) {
                        ConsoleTile(title: "Original Xbox", icon: "gamecontroller") {
                            selection = "Original Xbox"
                            result = "The original Xbox core requires a MCPX ROM, a compatible BIOS, and a formatted HDD image. The three-console unified build is not yet available."
                        }
                        ConsoleTile(title: "Xbox 360", icon: "gamecontroller.fill") {
                            selection = "Xbox 360"
                            result = "XeniOS does not require Xbox 360 OS files for game execution, but its current app executable must be adapted to run in the shared HeroBox host."
                        }
                        ConsoleTile(title: "Xbox One", icon: "square.stack.3d.up") {
                            selection = "Xbox One"
                            result = "Utsuro needs a decrypted game dump with Mount and EmbeddedXvd. Its FEX runtime still needs a working in-process adapter for the unified app."
                        }
                    }
                    ConsoleTile(title: "Runtime settings", icon: "gearshape") { showingSettings = true }
                    if !result.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selection).font(.headline)
                            Text(result).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 1120 : 620)
                .padding(.horizontal, geometry.size.width < 400 ? 12 : 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .background(ConsolePalette.canvas.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    List { RuntimeControls() }
                        .navigationTitle("Runtime settings")
                        .toolbar {
                            Button("Done") { showingSettings = false }
                        }
                }
                .preferredColorScheme(.dark)
            }
            .fileImporter(isPresented: $choosingMedia, allowedContentTypes: [.data, .folder]) { response in
                switch response {
                case .success(let url):
                    Task {
                        let message = await Task.detached(priority: .userInitiated) {
                            let scoped = url.startAccessingSecurityScopedResource()
                            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                            do {
                                switch try XboxMedia.identify(url) {
                                case .original: return "Original Xbox media detected."
                                case .xbox360: return "Xbox 360 media detected. The unified three-console runtime is not complete yet."
                                case .xboxOne: return "Xbox One package layout detected."
                                case nil:
                                    return try XboxMedia.isXISO(url)
                                        ? "Xbox XDVDFS disc image detected. The disc layout does not uniquely identify the console generation."
                                        : "Unrecognized game media."
                                }
                            } catch { return error.localizedDescription }
                        }.value
                        selection = url.lastPathComponent
                        result = message
                    }
                case .failure(let error):
                    selection = "Import"
                    result = error.localizedDescription
                }
            }
            }
        }
    }
}
