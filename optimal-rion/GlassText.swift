import SwiftUI

struct GlassText: View {
    let text: String

    var body: some View {
        let font = Font.system(size: 36, weight: .heavy, design: .rounded)

        Text(text)
            .font(font)
            .kerning(0.5)
            .foregroundStyle(.clear)
            .overlay(
                // Frosted material inside the text glyphs
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        Text(text)
                            .font(font)
                    )
            )
            .overlay(
                // Glossy highlight from top to bottom
                LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.25)],
                               startPoint: .top,
                               endPoint: .bottom)
                    .blendMode(.plusLighter)
                    .mask(
                        Text(text)
                            .font(font)
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.2), radius: 2, x: 0, y: -1)
            .multilineTextAlignment(.center)
            .accessibilityLabel(Text(text))
    }
}

