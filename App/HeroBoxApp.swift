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
    @State private var choosingMedia = false
    @State private var result = ""
    @State private var selection = ""

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ConsoleHeader()
                    ConsoleTile(title: "Inspect game media", icon: "opticaldisc", featured: true) {
                        choosingMedia = true
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
                .frame(maxWidth: 920)
                .padding(20)
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
                                case .xbox360: return "Xbox 360 media detected."
                                case .xboxOne: return "Xbox One package layout detected."
                                case nil: return "Unrecognized game media."
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
