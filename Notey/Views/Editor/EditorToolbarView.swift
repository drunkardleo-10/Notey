import SwiftUI

struct EditorToolbarView: View {
    let color: NoteColor
    let isChecklist: Bool
    var onColorChange: ((NoteColor) -> Void)?
    var onToggleChecklist: (() -> Void)?
    var onDelete: (() -> Void)?
    var onComplete: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.textPrimary.opacity(0.08))
                .frame(height: 1)

            HStack {
                HStack(spacing: 6) {
                    ColorSwatchPicker(
                        selected: color,
                        onSelect: { onColorChange?($0) }
                    )

                    Button(action: { onToggleChecklist?() }) {
                        Image(systemName: "checklist")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isChecklist
                                          ? Color.textPrimary.opacity(0.14)
                                          : Color.textPrimary.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Toggle checklist mode")
                }

                Spacer(minLength: 6)

                HStack(spacing: 6) {
                    Button(action: { onDelete?() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: 0xD32F2F))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: 0xD32F2F).opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete note")

                    Button(action: { onComplete?() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12, weight: .bold))
                            Text("Complete")
                                .font(NoteyFonts.ui(size: 12, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.textPrimary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(Color.textPrimary.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .accessibilityLabel("Complete note")

                    Button(action: { onClose?() }) {
                        Text("Close")
                            .font(NoteyFonts.ui(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule()
                                    .stroke(Color.textPrimary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .accessibilityLabel("Close editor")
                }
            }
            .padding(.init(top: 10, leading: 12, bottom: 10, trailing: 12))
            .background(Color.textPrimary.opacity(0.03))
        }
    }
}
