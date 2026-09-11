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

            VStack(alignment: .trailing, spacing: 12) {
                VStack(alignment: .trailing, spacing: deckState.isHovered ? -14 : 6) {
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

                EdgeAnchorView(
                    isDeckHovered: deckState.isHovered,
                    onAddNote: onAddNote
                )
            }
            .padding(.trailing, 0)
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
}
