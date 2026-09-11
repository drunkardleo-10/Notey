import SwiftUI

struct EdgeDeckView: View {
    let noteStore: NoteStore
    let deckState: DeckState
    let windowManager: WindowModeManager
    var onSelectNote: ((Note) -> Void)?
    var onAddNote: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack(alignment: .trailing) {
                if deckState.isHovered {
                    VStack(alignment: .trailing, spacing: 16) {
                        VStack(alignment: .trailing, spacing: -(NoteyLayout.tabPeekingHeight - NoteyLayout.tabStepHeight)) {
                            ForEach(Array(noteStore.activeDeckNotes.enumerated()), id: \.element.id) { index, note in
                                CollapsedTabView(
                                    note: note,
                                    isDeckHovered: deckState.isHovered,
                                    isCardExpanded: deckState.expandedNoteId == note.id,
                                    onSelect: { onSelectNote?(note) },
                                    onHover: { deckState.tabMouseEntered(noteId: note.id, windowManager: windowManager) },
                                    onLeave: { deckState.tabMouseExited(noteId: note.id) }
                                )
                                .zIndex(deckState.expandedNoteId == note.id ? 100 : Double(index + 1))
                            }
                        }
                        .padding(.trailing, 0)

                        EdgeAnchorView(
                            isDeckHovered: true,
                            onAddNote: onAddNote
                        )
                        .padding(.trailing, 0)
                    }
                    .transition(.opacity.combined(with: .offset(x: 10)))
                } else {
                    idleCapsule
                        .transition(.opacity.combined(with: .offset(x: 4)))
                }
            }
            .animation(.noteySpring, value: deckState.isHovered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onHover { isInside in
            if isInside {
                deckState.mouseEntered(windowManager: windowManager)
            } else {
                deckState.panelMouseExited(windowManager: windowManager)
            }
        }
    }

    private var idleCapsule: some View {
        VStack(spacing: 5.5) {
            if noteStore.activeDeckNotes.isEmpty {
                Capsule()
                    .fill(Color.textPrimary.opacity(0.35))
                    .frame(width: NoteyLayout.tabIdlePillWidth, height: NoteyLayout.tabIdlePillHeight)
            } else {
                ForEach(noteStore.activeDeckNotes) { note in
                    Capsule()
                        .fill(note.color.swiftUIColor)
                        .frame(width: NoteyLayout.tabIdlePillWidth, height: NoteyLayout.tabIdlePillHeight)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 7,
                bottomLeadingRadius: 7,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(Color(hex: 0x1E1E24).opacity(0.45))
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 7,
                    bottomLeadingRadius: 7,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        )
    }
}
