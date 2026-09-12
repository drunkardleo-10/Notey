import SwiftUI

struct ColorSwatchPicker: View {

    let selected: NoteColor
    var onSelect: ((NoteColor) -> Void)?

    private let swatches: [(color: NoteColor, hex: UInt)] = [
        (.yellow,   0xFDC844),
        (.coral,    0xFF8A80),
        (.mint,     0x80E5D0),
        (.blue,     0x82B1FF),
        (.lavender, 0xCE93D8),
    ]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(swatches, id: \.color) { swatch in
                Button(action: { onSelect?(swatch.color) }) {
                    RoundedRectangle(cornerRadius: 5.5)
                        .fill(Color(hex: swatch.hex))
                        .frame(width: 17, height: 17)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5.5)
                                .stroke(
                                    selected == swatch.color
                                        ? Color.textPrimary
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.18),
                            radius: 2.5,
                            x: 0,
                            y: 1.5
                        )
                        .scaleEffect(selected == swatch.color ? 1.08 : 1.0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(swatch.color.rawValue) note color")
            }
        }
    }
}
