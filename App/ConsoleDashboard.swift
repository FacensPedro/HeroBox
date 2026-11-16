import SwiftUI

enum ConsolePalette {
    static let canvas = Color(red: 0.065, green: 0.071, blue: 0.075)
    static let green = Color(red: 0.12, green: 0.48, blue: 0.13)
    static let accent = Color(red: 0.48, green: 0.83, blue: 0.28)
    static let slate = Color(red: 0.17, green: 0.19, blue: 0.20)
}

struct ConsoleHeader: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Home")
                .font(.largeTitle.weight(.light))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text("HeroBox")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottomLeading) {
            Rectangle().fill(ConsolePalette.accent).frame(width: 52, height: 3)
        }
    }
}

struct ConsoleTile: View {
    let title: String
    let icon: String
    var featured = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: featured ? 40 : 26, weight: .light))
                    .accessibilityHidden(true)
                Spacer(minLength: 4)
                Text(title).font(featured ? .title2 : .headline)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: featured ? 148 : 108, alignment: .leading)
            .background(featured ? ConsolePalette.green : ConsolePalette.slate)
            .contentShape(Rectangle())
        }
        .buttonStyle(ConsoleTileStyle())
    }
}

private struct ConsoleTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay {
            Rectangle().strokeBorder(Color.white, lineWidth: configuration.isPressed ? 3 : 0)
        }
    }
}
