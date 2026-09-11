import SwiftUI

struct EdgeAnchorView: View {
    let isDeckHovered: Bool
    var onAddNote: (() -> Void)?

    var body: some View {
        Button(action: { onAddNote?() }) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.96))
                        .shadow(
                            color: Color.black.opacity(0.14),
                            radius: 3, x: 0, y: 1.5
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.textPrimary.opacity(0.12), lineWidth: 0.8)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Add new note")
        .frame(width: NoteyLayout.tabPeekingWidth, height: 32)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.noteyQuick, value: configuration.isPressed)
    }
}
