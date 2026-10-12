import SwiftUI

struct EdgeDeckView: View {
    let noteStore: NoteStore
    let deckState: DeckState
    let windowManager: WindowModeManager
    var onSelectNote: ((Note) -> Void)?
    var onAddNote: (() -> Void)?

    @State private var isCascaded: Bool = false
    @State private var isStackMounted: Bool = false
    @State private var unmountWork: DispatchWorkItem?

    private var cascadeCount: Int {
        noteStore.activeDeckNotes.count + 1
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            ZStack(alignment: .trailing) {
                if isStackMounted {
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
                                .frame(width: NoteyLayout.tabExpandedWidth, alignment: .trailing)
                                .zIndex(Double(index + 1))
                                .rotationEffect(
                                    .degrees(fanAngle(index: index, noteId: note.id)),
                                    anchor: .trailing
                                )
                                .animation(.noteySpring, value: deckState.expandedNoteId)
                                .offset(
                                    x: isCascaded ? 0 : 42,
                                    y: isCascaded ? 0 : DeckCascade.collapsedOffset(
                                        index: index,
                                        noteCount: noteStore.activeDeckNotes.count
                                    )
                                )
                                .opacity(isCascaded ? 1.0 : 0.0)
                                .animation(
                                    .deckCascade(index: index, count: cascadeCount, opening: isCascaded),
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
                            .deckCascade(
                                index: noteStore.activeDeckNotes.count,
                                count: cascadeCount,
                                opening: isCascaded
                            ),
                            value: isCascaded
                        )
                    }
                    .transition(.opacity)
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
            .animation(.easeInOut(duration: 0.20), value: isStackMounted)
        }
        .onChange(of: deckState.isHovered) { _, hovered in
            setDeckOpen(hovered)
        }
        .onChange(of: cascadeCount, initial: true) { _, count in
            deckState.noteCount = count
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

    private func fanAngle(index: Int, noteId: UUID) -> Double {
        guard isCascaded, deckState.expandedNoteId != noteId else { return 0 }
        return DeckCascade.fanAngle(index: index, noteCount: noteStore.activeDeckNotes.count)
    }

    private func setDeckOpen(_ open: Bool) {
        unmountWork?.cancel()
        unmountWork = nil

        if open {
            if !isStackMounted {
                isCascaded = false
                isStackMounted = true
            }
            DispatchQueue.main.async {
                isCascaded = true
            }
        } else if deckState.closesInstantly {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isCascaded = false
                isStackMounted = false
            }
        } else {
            isCascaded = false
            let work = DispatchWorkItem {
                isStackMounted = false
            }
            unmountWork = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + DeckCascade.closeDuration(count: cascadeCount) + 0.05,
                execute: work
            )
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
