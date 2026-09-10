import SwiftUI

struct EditorHeaderView: View {

    @Binding var title: String
    let isPinned: Bool
    let autosaveStatus: String
    var onTogglePin: (() -> Void)?
    var onClose: (() -> Void)?
    var onDragStart: ((NSPoint) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                
                HStack(spacing: 6) {
                    Button(action: { onClose?() }) {
                        Circle()
                            .fill(Color.textPrimary.opacity(0.2))
                            .frame(width: 11, height: 11)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close note")

                    Circle()
                        .fill(Color.textPrimary.opacity(0.12))
                        .frame(width: 11, height: 11)
                }

                TextField("Untitled note", text: $title)
                    .textFieldStyle(.plain)
                    .font(NoteyFonts.ui(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                Text(autosaveStatus)
                    .font(NoteyFonts.ui(size: 11))
                    .foregroundStyle(Color.textPrimary.opacity(0.5))
                    .lineLimit(1)

                HStack(spacing: 2.5) {
                    VStack(spacing: 2.5) {
                        Circle().fill(Color.textPrimary.opacity(0.38)).frame(width: 3, height: 3)
                        Circle().fill(Color.textPrimary.opacity(0.38)).frame(width: 3, height: 3)
                        Circle().fill(Color.textPrimary.opacity(0.38)).frame(width: 3, height: 3)
                    }
                    VStack(spacing: 2.5) {
                        Circle().fill(Color.textPrimary.opacity(0.38)).frame(width: 3, height: 3)
                        Circle().fill(Color.textPrimary.opacity(0.38)).frame(width: 3, height: 3)
                        Circle().fill(Color.textPrimary.opacity(0.38)).frame(width: 3, height: 3)
                    }
                }
                .frame(width: 18, height: 18)
                .accessibilityLabel("Drag note")

                Button(action: { onTogglePin?() }) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .rotationEffect(.degrees(isPinned ? 0 : 45))
                        .opacity(isPinned ? 1 : 0.65)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPinned ? "Unpin note" : "Pin note")
            }
            .padding(.init(top: 12, leading: 16, bottom: 8, trailing: 16))

            Rectangle()
                .fill(Color.textPrimary.opacity(0.08))
                .frame(height: 1)
        }
    }
}
