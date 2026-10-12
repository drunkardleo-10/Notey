import AppKit
import SwiftUI
import Observation

@MainActor @Observable
final class DeckState {
    var isHovered: Bool = false
    var expandedNoteId: UUID? = nil
    var activeHoverNoteId: UUID? = nil
    var isEditorOpen: Bool = false
    var isDeckOpening: Bool = false
    var noteCount: Int = 1
    var closesInstantly: Bool = false

    private var leaveWorkItem: DispatchWorkItem?
    private var dwellWorkItem: DispatchWorkItem?
    private var tabExitWorkItem: DispatchWorkItem?
    private var deckOpeningWorkItem: DispatchWorkItem?

    func mouseEntered(windowManager: WindowModeManager) {
        guard !isEditorOpen else { return }
        leaveWorkItem?.cancel()
        leaveWorkItem = nil

        if !isHovered {
            closesInstantly = false
            windowManager.setMode(.deckHover)
            isDeckOpening = true
            withAnimation(.noteySpring) {
                isHovered = true
            }

            let openingWork = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.isDeckOpening = false
            }
            deckOpeningWorkItem?.cancel()
            deckOpeningWorkItem = openingWork
            DispatchQueue.main.asyncAfter(deadline: .now() + DeckCascade.openingHold, execute: openingWork)
        }
    }

    func panelMouseExited(windowManager: WindowModeManager) {
        activeHoverNoteId = nil
        dwellWorkItem?.cancel()
        dwellWorkItem = nil

        deckOpeningWorkItem?.cancel()
        deckOpeningWorkItem = nil
        isDeckOpening = false

        tabExitWorkItem?.cancel()
        tabExitWorkItem = nil

        if expandedNoteId != nil {
            withAnimation(.noteyQuick) {
                self.expandedNoteId = nil
            }
        }

        leaveWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.20)) {
                self.isHovered = false
                self.activeHoverNoteId = nil
            }
            let hold = DeckCascade.closeDuration(count: noteCount) + 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                if !self.isHovered && !self.isEditorOpen {
                    windowManager.setMode(.deckIdle)
                }
            }
        }
        leaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    func tabMouseEntered(noteId: UUID, windowManager: WindowModeManager) {
        guard !isEditorOpen else { return }

        leaveWorkItem?.cancel()
        leaveWorkItem = nil

        tabExitWorkItem?.cancel()
        tabExitWorkItem = nil

        dwellWorkItem?.cancel()
        dwellWorkItem = nil

        activeHoverNoteId = noteId

        if !isHovered {
            closesInstantly = false
            windowManager.setMode(.deckHover)
            withAnimation(.noteySpring) {
                isHovered = true
            }
        }

        if isDeckOpening {
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.activeHoverNoteId == noteId, !self.isEditorOpen else { return }
                withAnimation(.noteySpring) {
                    self.expandedNoteId = noteId
                }
            }
            dwellWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + DeckCascade.openingHold, execute: work)
        } else {
            withAnimation(.noteySpring) {
                self.expandedNoteId = noteId
            }
        }
    }

    func tabMouseExited(noteId: UUID) {
        if activeHoverNoteId == noteId {
            activeHoverNoteId = nil
            dwellWorkItem?.cancel()
            dwellWorkItem = nil
        }

        tabExitWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.activeHoverNoteId == nil && self.expandedNoteId == noteId {
                withAnimation(.noteySpring) {
                    self.expandedNoteId = nil
                }
            }
        }
        tabExitWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: work)
    }

    func reset() {
        leaveWorkItem?.cancel()
        dwellWorkItem?.cancel()
        tabExitWorkItem?.cancel()
        deckOpeningWorkItem?.cancel()
        isDeckOpening = false
        activeHoverNoteId = nil
        closesInstantly = true
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
            DispatchQueue.main.async { [weak self] in
                guard let self, self.deckState.isEditorOpen == newValue else { return }
                self.windowManager.setMode(.deckIdle)
            }
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
