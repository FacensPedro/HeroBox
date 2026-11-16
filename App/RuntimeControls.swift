import Darwin
import os
import SwiftUI

struct RuntimeControls: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var phase
    @State private var available = os_proc_available_memory()
    @State private var status = ""

    var body: some View {
        Section("Memory+") {
            LabeledContent("Available process memory", value: ByteCountFormatter.string(
                fromByteCount: Int64(available), countStyle: .memory))
            Button("Refresh memory") { available = os_proc_available_memory() }
        }
        .onChange(of: phase) { current in
            if current == .active { available = os_proc_available_memory() }
        }
        Section("JIT") {
            Button("Open StikDebug") {
#if HEROBOX_XBOX_ONE
                status = JITBootstrap.requestAttach() ? "Requested runtime JIT setup." : "StikDebug is unavailable."
#else
                guard let identifier = Bundle.main.bundleIdentifier else { return }
                var request = URLComponents()
                request.scheme = "stikjit"
                request.host = "enable-jit"
                request.queryItems = [URLQueryItem(name: "bundle-id", value: identifier)]
                if let url = request.url {
                    openURL(url) { accepted in
                        status = accepted ? "Request sent to StikDebug." : "Could not open StikDebug."
                    }
                }
#endif
            }
            if !status.isEmpty { Text(status) }
        }
    }
}
