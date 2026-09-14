import SwiftUI

struct ColorSwatchPicker: View {

    let selected: NoteColor
    var onSelect: ((NoteColor) -> Void)?

    @State private var isPickerHovered: Bool = false

    private let swatches: [(color: NoteColor, hex: UInt)] = [
        (.yellow,   0xFDC844),
        (.coral,    0xFF8A80),
        (.mint,     0x80E5D0),
        (.blue,     0x82B1FF),
        (.lavender, 0xCE93D8),
    ]

    private let rainbowGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(hex: 0xFF5252),
            Color(hex: 0xFF7A00),
            Color(hex: 0xFFD600),
            Color(hex: 0x00E676),
            Color(hex: 0x00B0FF),
            Color(hex: 0x7C4DFF),
            Color(hex: 0xFF4081),
            Color(hex: 0xFF5252)
        ]),
        center: .center
    )

    var body: some View {
        HStack(spacing: 5) {
            ForEach(swatches, id: \.color) { swatch in
                Button(action: {
                    onSelect?(swatch.color)
                    ColorPanelPresenter.shared.updateColorIfVisible(swatch.color)
                }) {
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

            // Custom Color Picker Swatch
            Button(action: {
                ColorPanelPresenter.shared.show(color: selected) { newColor in
                    onSelect?(newColor)
                }
            }) {
                ZStack {
                    if selected.isCustom {
                        RoundedRectangle(cornerRadius: 5.5)
                            .fill(selected.swiftUIColor)
                            .frame(width: 17, height: 17)

                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(Color.textPrimary.opacity(0.7))
                    } else {
                        RoundedRectangle(cornerRadius: 5.5)
                            .fill(rainbowGradient)
                            .frame(width: 17, height: 17)

                        Image(systemName: "plus")
                            .font(.system(size: 7.5, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.45), radius: 1, x: 0, y: 0.5)
                    }
                }
                .frame(width: 17, height: 17)
                .overlay(
                    RoundedRectangle(cornerRadius: 5.5)
                        .stroke(
                            selected.isCustom
                                ? Color.textPrimary
                                : Color.textPrimary.opacity(0.18),
                            lineWidth: selected.isCustom ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.18),
                    radius: 2.5,
                    x: 0,
                    y: 1.5
                )
                .scaleEffect(selected.isCustom || isPickerHovered ? 1.08 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isPickerHovered)
            }
            .buttonStyle(.plain)
            .onHover { isPickerHovered = $0 }
            .help(selected.isCustom ? "Custom color \(selected.hexCode). Click to change." : "Custom color picker...")
            .accessibilityLabel(selected.isCustom ? "Custom color \(selected.hexCode)" : "Custom color picker")
            .contextMenu {
                Button {
                    ColorPanelPresenter.shared.show(color: selected) { newColor in
                        onSelect?(newColor)
                    }
                } label: {
                    Label("Color Panel...", systemImage: "paintpalette")
                }

                Button {
                    ColorPanelPresenter.shared.pickFromScreen { newColor in
                        onSelect?(newColor)
                    }
                } label: {
                    Label("Pick Color from Screen", systemImage: "eyedropper")
                }
            }
        }
    }
}
