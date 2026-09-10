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
                
                HStack(spacing: 8) {
                    ColorSwatchPicker(
                        selected: color,
                        onSelect: { onColorChange?($0) }
                    )

                    Button(action: { onToggleChecklist?() }) {
                        Image(systemName: "checklist")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .padding(3)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(isChecklist
                                          ? Color.textPrimary.opacity(0.14)
                                          : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Toggle checklist mode")
                }

                Spacer()

                HStack(spacing: 6) {
                    
                    Button(action: { onDelete?() }) {
                        Text("Delete")
                            .font(NoteyFonts.ui(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xC62828))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color(hex: 0xD32F2F).opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { onComplete?() }) {
                        Text("Mark complete")
                            .font(NoteyFonts.ui(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.textPrimary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { onClose?() }) {
                        Text("Close")
                            .font(NoteyFonts.ui(size: 11.5, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.textPrimary.opacity(0.18), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.init(top: 10, leading: 14, bottom: 10, trailing: 14))
            .background(Color.textPrimary.opacity(0.04))
        }
    }
}
