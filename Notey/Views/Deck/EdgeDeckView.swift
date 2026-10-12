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
    @State private var draggingId: UUID?
    @State private var dragStartIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var suppressSelect: Bool = false

    private let tabPitch: CGFloat = DeckCascade.tabPitch

    private var cascadeCount: Int {
        noteStore.activeDeckNotes.count + 1
    }

    private var edge: DeckEdge {
        deckState.edge
    }

    private func cascadeOffset(index: Int) -> CGSize {
        guard !isCascaded else { return .zero }
        let along = DeckCascade.collapsedOffset(index: index, noteCount: noteStore.activeDeckNotes.count)
        let alongSize = edge.alongOffset(along)
        return CGSize(
            width: edge.outward.width * 42 + alongSize.width,
            height: edge.outward.height * 42 + alongSize.height
        )
    }

    private func depthPinned<V: View>(_ view: V) -> some View {
        Group {
            if edge.isVertical {
                view.frame(width: NoteyLayout.tabExpandedWidth, alignment: edge.alignment)
            } else {
                view.frame(height: NoteyLayout.tabExpandedWidth, alignment: edge.alignment)
            }
        }
    }

    var body: some View {
        ZStack(alignment: edge.alignment) {
            if isStackMounted {
                AxisStack(edge: edge, spacing: 16) {
                    AxisStack(edge: edge, spacing: -12) {
                        ForEach(Array(noteStore.activeDeckNotes.enumerated()), id: \.element.id) { index, note in
                            let shift = edge.alongOffset(reorderShift(index: index, id: note.id))
                            let offset = cascadeOffset(index: index)

                            depthPinned(
                                CollapsedTabView(
                                    note: note,
                                    edge: edge,
                                    isDeckHovered: deckState.isHovered,
                                    isCardExpanded: deckState.expandedNoteId == note.id,
                                    onSelect: {
                                        guard !suppressSelect else { return }
                                        onSelectNote?(note)
                                    },
                                    onHover: { deckState.tabMouseEntered(noteId: note.id, windowManager: windowManager) },
                                    onLeave: { deckState.tabMouseExited(noteId: note.id) }
                                )
                            )
                            .zIndex(draggingId == note.id ? 1000 : Double(index + 1))
                            .rotationEffect(
                                .degrees(fanAngle(index: index, noteId: note.id)),
                                anchor: edge.unitPoint
                            )
                            .animation(.noteySpring, value: deckState.expandedNoteId)
                            .offset(x: offset.width, y: offset.height)
                            .opacity(isCascaded ? 1.0 : 0.0)
                            .animation(
                                .deckCascade(index: index, count: cascadeCount, opening: isCascaded),
                                value: isCascaded
                            )
                            .offset(x: shift.width, y: shift.height)
                            .scaleEffect(draggingId == note.id ? 1.04 : 1, anchor: edge.unitPoint)
                            .animation(
                                draggingId == note.id ? nil : .spring(response: 0.3, dampingFraction: 0.8),
                                value: dragTargetIndex
                            )
                            .simultaneousGesture(reorderGesture(index: index, note: note))
                        }
                    }

                    EdgeAnchorView(
                        edge: edge,
                        isDeckHovered: true,
                        onAddNote: onAddNote,
                        onGripChanged: {
                            if !deckState.isMovingDeck {
                                deckState.beginDeckMove(windowManager: windowManager)
                            } else {
                                deckState.trackDeckMove(windowManager: windowManager)
                            }
                        },
                        onGripEnded: { deckState.endDeckMove(windowManager: windowManager) },
                        onGripHover: { deckState.isGripHovered = $0 }
                    )
                    .offset(
                        x: isCascaded ? 0 : edge.outward.width * 42,
                        y: isCascaded ? 0 : edge.outward.height * 42
                    )
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
                idleCapsule(for: edge)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(
                                with: .offset(x: edge.outward.width * -8, y: edge.outward.height * -8)
                            ),
                            removal: .opacity
                        )
                    )
            }
        }
        .animation(.easeInOut(duration: 0.20), value: isStackMounted)
        .opacity(deckState.isMovingDeck ? 0 : 1)
        .onChange(of: deckState.isHovered) { _, hovered in
            setDeckOpen(hovered)
        }
        .onChange(of: cascadeCount, initial: true) { _, count in
            deckState.noteCount = count
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: edge.alignment)
        .overlay {
            if deckState.isMovingDeck {
                DeckMoveOverlay(
                    colors: noteStore.activeDeckNotes.prefix(3).map { $0.color.swiftUIColor },
                    point: deckState.movePoint,
                    sway: deckState.swayAngle,
                    settling: deckState.isSettlingMove,
                    previewEdge: deckState.previewEdge,
                    previewOffset: deckState.previewOffset,
                    ghost: idleCapsule(for: deckState.previewEdge)
                )
            }
        }
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

    private var deckCount: Int {
        noteStore.activeDeckNotes.count
    }

    private var dragTargetIndex: Int {
        guard draggingId != nil else { return -1 }
        let moved = Int((dragOffset / tabPitch).rounded())
        return min(max(dragStartIndex + moved, 0), max(deckCount - 1, 0))
    }

    private func reorderShift(index: Int, id: UUID) -> CGFloat {
        guard let dragId = draggingId else { return 0 }
        if id == dragId { return dragOffset }
        let target = dragTargetIndex
        if dragStartIndex < target, index > dragStartIndex, index <= target { return -tabPitch }
        if target < dragStartIndex, index >= target, index < dragStartIndex { return tabPitch }
        return 0
    }

    private func reorderGesture(index: Int, note: Note) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                if draggingId == nil {
                    draggingId = note.id
                    dragStartIndex = index
                    suppressSelect = true
                    deckState.beginReordering()
                }
                guard draggingId == note.id else { return }
                let travel = edge.along(value.translation)
                let lower = -CGFloat(dragStartIndex) * tabPitch
                let upper = CGFloat(max(deckCount - 1 - dragStartIndex, 0)) * tabPitch
                dragOffset = min(max(travel, lower), upper)
            }
            .onEnded { _ in
                guard draggingId == note.id else { return }
                let target = dragTargetIndex
                let residual = dragOffset - CGFloat(target - dragStartIndex) * tabPitch

                var instant = Transaction(animation: nil)
                instant.disablesAnimations = true
                withTransaction(instant) {
                    noteStore.moveDeckNote(id: note.id, to: target)
                    dragStartIndex = target
                    dragOffset = residual
                }
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        dragOffset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        draggingId = nil
                        deckState.endReordering(windowManager: windowManager)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    suppressSelect = false
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

    private func idleCapsule(for edge: DeckEdge) -> some View {
        let pillWidth = edge.isVertical ? NoteyLayout.tabIdlePillWidth : NoteyLayout.tabIdlePillHeight
        let pillHeight = edge.isVertical ? NoteyLayout.tabIdlePillHeight : NoteyLayout.tabIdlePillWidth
        let shape = UnevenRoundedRectangle(cornerRadii: edge.farCornerRadii(7, 7))

        return AxisStack(edge: edge, spacing: 5.5) {
            if noteStore.activeDeckNotes.isEmpty {
                Capsule()
                    .fill(Color.textPrimary.opacity(0.35))
                    .frame(width: pillWidth, height: pillHeight)
            } else {
                ForEach(noteStore.activeDeckNotes) { note in
                    Capsule()
                        .fill(note.color.swiftUIColor)
                        .frame(width: pillWidth, height: pillHeight)
                }
            }
        }
        .padding(.vertical, edge.isVertical ? 6 : 4)
        .padding(.horizontal, edge.isVertical ? 4 : 6)
        .background(
            shape
                .fill(Color(hex: 0x1E1E24).opacity(0.45))
                .overlay(
                    shape.stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}
