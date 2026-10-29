import SwiftUI

/// One line; scrolls only while hovered and only if the text overflows (nothing invisible animates).
struct MarqueeText: View {
    let text: String
    let font: Font
    @State private var hovering = false
    @State private var textWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { textWidth = $0 }
            .offset(x: offset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { boxWidth = $0 }
            .clipped()
            .onHover { inside in
                hovering = inside
                let overflow = textWidth - boxWidth
                guard overflow > 0, !reduceMotion, inside else {
                    withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
                    return
                }
                withAnimation(.linear(duration: min(2, Double(overflow) / 40))) { offset = -overflow }
            }
            .accessibilityLabel(text)
    }
}
