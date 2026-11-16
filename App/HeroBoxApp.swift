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

    var body: some View {
        NavigationStack {
            List {
                Button("Inspect game file or folder") { choosingMedia = true }
                RuntimeControls()
                if !result.isEmpty {
                    Section(selection) { Text(result) }
                }
            }
            .navigationTitle("HeroBox")
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
