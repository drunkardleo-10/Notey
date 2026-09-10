import SwiftUI

struct EdgeAnchorView: View {

    let isDeckHovered: Bool
    var onAddNote: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            
            Button(action: { onAddNote?() }) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color(hex: 0xF5EFE6).opacity(0.95))
                            .shadow(
                                color: Color.textPrimary.opacity(0.15),
                                radius: 3, x: 0, y: 1
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.textPrimary.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Add new note")

            HStack(spacing: 3) {
                VStack(spacing: 3) {
                    Circle().fill(Color.textPrimary.opacity(0.45)).frame(width: 3.5, height: 3.5)
                    Circle().fill(Color.textPrimary.opacity(0.45)).frame(width: 3.5, height: 3.5)
                    Circle().fill(Color.textPrimary.opacity(0.45)).frame(width: 3.5, height: 3.5)
                }
                VStack(spacing: 3) {
                    Circle().fill(Color.textPrimary.opacity(0.45)).frame(width: 3.5, height: 3.5)
                    Circle().fill(Color.textPrimary.opacity(0.45)).frame(width: 3.5, height: 3.5)
                    Circle().fill(Color.textPrimary.opacity(0.45)).frame(width: 3.5, height: 3.5)
                }
            }
            .frame(width: 20, height: 20)
        }
        .frame(width: 34)
        .opacity(isDeckHovered ? 1 : 0)
        .offset(x: isDeckHovered ? 0 : 18)
        .allowsHitTesting(isDeckHovered)
        .animation(.noteySpring, value: isDeckHovered)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.noteyQuick, value: configuration.isPressed)
    }
}
