import SwiftUI

struct EdgeDeckView: View {
    let noteStore: NoteStore
    let deckState: DeckState
    let windowManager: WindowModeManager
    var onSelectNote: ((Note) -> Void)?
    var onAddNote: (() -> Void)?

    @State private var isCascaded: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack(alignment: .trailing) {
                if deckState.isHovered {
                    VStack(alignment: .trailing, spacing: 16) {
                        VStack(alignment: .trailing, spacing: -12) {
                            ForEach(Array(noteStore.activeDeckNotes.enumerated()), id: \.element.id) { index, note in
                                CollapsedTabView(
                                    note: note,
                                    isDeckHovered: deckState.isHovered,
                                    isCardExpanded: deckState.expandedNoteId == note.id,
                                    onSelect: { onSelectNote?(note) },
                                    onHover: { deckState.tabMouseEntered(noteId: note.id, windowManager: windowManager) },
                                    onLeave: { deckState.tabMouseExited(noteId: note.id) }
                                )
                                .zIndex(Double(index + 1))
                                .offset(x: isCascaded ? 0 : 42)
                                .opacity(isCascaded ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.22, dampingFraction: 0.76)
                                    .delay(Double(index) * 0.038),
                                    value: isCascaded
                                )
                            }
                        }
                        .padding(.trailing, 0)

                        EdgeAnchorView(
                            isDeckHovered: true,
                            onAddNote: onAddNote
                        )
                        .padding(.trailing, 0)
                        .offset(x: isCascaded ? 0 : 42)
                        .opacity(isCascaded ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.22, dampingFraction: 0.76)
                            .delay(Double(noteStore.activeDeckNotes.count) * 0.038),
                            value: isCascaded
                        )
                    }
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .offset(x: 36))
                        )
                    )
                    .onAppear {
                        isCascaded = false
                        DispatchQueue.main.async {
                            isCascaded = true
                        }
                    }
                    .onDisappear {
                        isCascaded = false
                    }
                } else {
                    idleCapsule
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 8)),
                                removal: .opacity
                            )
                        )
                }
            }
            .animation(.easeInOut(duration: 0.20), value: deckState.isHovered)
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
