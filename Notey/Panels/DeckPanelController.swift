import AppKit
import SwiftUI
import Observation

@MainActor @Observable
final class DeckState {
    var isHovered: Bool = false
    var expandedNoteId: UUID? = nil
    var activeHoverNoteId: UUID? = nil
    var isEditorOpen: Bool = false

    private var leaveWorkItem: DispatchWorkItem?
    private var dwellWorkItem: DispatchWorkItem?

    func mouseEntered(windowManager: WindowModeManager) {
        guard !isEditorOpen else { return }
        leaveWorkItem?.cancel()
        leaveWorkItem = nil

        if !isHovered {
            windowManager.setMode(.deckHover)
            withAnimation(.noteySpring) {
                isHovered = true
            }
        }
    }

    func panelMouseExited(windowManager: WindowModeManager) {
        activeHoverNoteId = nil
        dwellWorkItem?.cancel()
        dwellWorkItem = nil

        leaveWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.noteySpring) {
                self.isHovered = false
                self.expandedNoteId = nil
                self.activeHoverNoteId = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                if !self.isHovered && !self.isEditorOpen {
                    windowManager.setMode(.deckIdle)
                }
            }
        }
        leaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: work)
    }

    func tabMouseEntered(noteId: UUID, windowManager: WindowModeManager) {
        guard !isEditorOpen else { return }

        leaveWorkItem?.cancel()
        leaveWorkItem = nil

        dwellWorkItem?.cancel()
        dwellWorkItem = nil

        activeHoverNoteId = noteId

        if !isHovered {
            windowManager.setMode(.deckHover)
            withAnimation(.noteySpring) {
                isHovered = true
            }
        }

        if expandedNoteId != nil && expandedNoteId != noteId {
            withAnimation(.noteySpring) {
                expandedNoteId = nil
            }
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self, self.activeHoverNoteId == noteId, !self.isEditorOpen else { return }
            withAnimation(.noteySpring) {
                self.expandedNoteId = noteId
            }
        }
        dwellWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: work)
    }

    func tabMouseExited(noteId: UUID) {
        if activeHoverNoteId == noteId {
            activeHoverNoteId = nil
            dwellWorkItem?.cancel()
            dwellWorkItem = nil
        }

        if expandedNoteId == noteId {
            withAnimation(.noteySpring) {
                expandedNoteId = nil
            }
        }
    }

    func reset() {
        leaveWorkItem?.cancel()
        dwellWorkItem?.cancel()
        activeHoverNoteId = nil
        withAnimation(.noteyQuick) {
            isHovered = false
            expandedNoteId = nil
        }
    }
}

@MainActor
final class DeckPanelController: NSResponder {
    let panel: NoteyPanel
    let deckState = DeckState()

    let noteStore: NoteStore
    private let windowManager: WindowModeManager
    private var trackingArea: NSTrackingArea?
    private var hostingView: NoteyHostingView<EdgeDeckView>?

    var onSelectNote: ((Note) -> Void)?

    var isEditorOpen: Bool {
        get { deckState.isEditorOpen }
        set {
            deckState.isEditorOpen = newValue
            deckState.reset()
            windowManager.setMode(.deckIdle)
        }
    }

    init(noteStore: NoteStore, windowManager: WindowModeManager) {
        self.noteStore = noteStore
        self.windowManager = windowManager

        let frame = ScreenUtilities.edgeDeckIdleFrame(
            noteCount: noteStore.activeDeckNotes.count
        )

        panel = NoteyPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.configureAsEdgeDeck()

        let edgeDeckView = EdgeDeckView(
            noteStore: noteStore,
            deckState: deckState,
            windowManager: windowManager,
            onSelectNote: { [weak self] note in
                self?.onSelectNote?(note)
            },
            onAddNote: { [weak self] in
                self?.handleAddNote()
            }
        )

        let container = NSView(frame: panel.contentView?.bounds ?? frame)
        container.autoresizingMask = [.width, .height]
        panel.contentView = container

        let hosting = NoteyHostingView(rootView: edgeDeckView)
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        hosting.layer?.backgroundColor = NSColor.clear.cgColor

        container.addSubview(hosting)
        self.hostingView = hosting

        updateTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTrackingArea() {
        guard let contentView = panel.contentView else { return }

        if let existing = trackingArea {
            contentView.removeTrackingArea(existing)
        }

        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [
                .mouseEnteredAndExited,
                .activeAlways,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(area)
        trackingArea = area
    }

    @objc(mouseEntered:)
    override func mouseEntered(with event: NSEvent) {
        deckState.mouseEntered(windowManager: windowManager)
    }

    @objc(mouseExited:)
    override func mouseExited(with event: NSEvent) {
        deckState.panelMouseExited(windowManager: windowManager)
    }

    private func handleAddNote() {
        let colors: [NoteColor] = [.yellow, .coral, .mint, .blue, .lavender]
        let nextColor = colors[noteStore.activeDeckNotes.count % colors.count]
        let newNote = noteStore.createNote(
            title: "Untitled note",
            body: "",
            color: nextColor
        )
        onSelectNote?(newNote)
    }

    func show() {
        windowManager.setMode(.deckIdle)
    }

    func hide() {
        panel.orderOut(nil)
    }
}
