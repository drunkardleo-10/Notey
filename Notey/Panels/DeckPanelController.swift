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
    var isReordering: Bool = false
    var isMovingDeck: Bool = false
    var isSettlingMove: Bool = false
    var isGripHovered: Bool = false
    var movePoint: CGPoint = .zero
    var swayAngle: Double = 0
    var previewEdge: DeckEdge = .right
    var previewOffset: CGFloat = 0
    var edge: DeckEdge = DeckEdge(rawValue: UserDefaults.standard.string(forKey: "deckEdge") ?? "") ?? .right
    var alongOffset: CGFloat = CGFloat(
        UserDefaults.standard.object(forKey: "deckAlongOffset") != nil
            ? UserDefaults.standard.double(forKey: "deckAlongOffset")
            : UserDefaults.standard.double(forKey: "deckVerticalOffset")
    )

    @ObservationIgnored private var lastMovePoint: CGPoint = .zero
    @ObservationIgnored private var lastMoveTime: TimeInterval = 0
    @ObservationIgnored private var swayDecayWork: DispatchWorkItem?

    private var leaveWorkItem: DispatchWorkItem?
    private var dwellWorkItem: DispatchWorkItem?
    private var tabExitWorkItem: DispatchWorkItem?
    private var deckOpeningWorkItem: DispatchWorkItem?

    func mouseEntered(windowManager: WindowModeManager) {
        guard !isEditorOpen, !isMovingDeck else { return }
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

    func refreshCursor() {
        if isMovingDeck {
            NSCursor.closedHand.set()
        } else if isGripHovered {
            NSCursor.openHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    func beginDeckMove(windowManager: WindowModeManager) {
        guard !isMovingDeck else { return }
        leaveWorkItem?.cancel()
        dwellWorkItem?.cancel()
        tabExitWorkItem?.cancel()
        activeHoverNoteId = nil
        expandedNoteId = nil
        isMovingDeck = true
        isSettlingMove = false
        swayAngle = 0
        previewEdge = edge
        previewOffset = alongOffset
        windowManager.setMode(.deckMove)
        lastMoveTime = 0
        trackDeckMove(windowManager: windowManager)
        NSCursor.closedHand.set()
    }

    func trackDeckMove(windowManager: WindowModeManager) {
        guard isMovingDeck, !isSettlingMove,
              let controller = windowManager.deckController else { return }
        let panel = controller.panel
        let mouse = NSEvent.mouseLocation
        let frame = panel.frame
        let point = CGPoint(x: mouse.x - frame.minX, y: frame.maxY - mouse.y)

        let now = ProcessInfo.processInfo.systemUptime
        if lastMoveTime > 0, now > lastMoveTime {
            let velocity = (point.x - lastMovePoint.x) / CGFloat(now - lastMoveTime)
            let target = max(-30, min(30, Double(velocity) / 38))
            swayAngle = swayAngle * 0.35 + target * 0.65
        }
        lastMovePoint = point
        lastMoveTime = now
        movePoint = point
        NSCursor.closedHand.set()

        swayDecayWork?.cancel()
        let decay = DispatchWorkItem { [weak self] in
            self?.swayAngle = 0
        }
        swayDecayWork = decay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: decay)

        let target = ScreenUtilities.dropTarget(
            point: point,
            in: frame.size,
            noteCount: controller.noteStore.activeDeckNotes.count,
            for: panel
        )
        previewEdge = target.edge
        previewOffset = target.offset
    }

    func endDeckMove(windowManager: WindowModeManager) {
        guard isMovingDeck, !isSettlingMove,
              let controller = windowManager.deckController else { return }
        swayDecayWork?.cancel()
        let size = controller.panel.frame.size
        let target = (edge: previewEdge, offset: previewOffset)
        let landing: CGPoint
        switch target.edge {
        case .right: landing = CGPoint(x: size.width - 16, y: size.height / 2 - target.offset)
        case .left: landing = CGPoint(x: 16, y: size.height / 2 - target.offset)
        case .top: landing = CGPoint(x: size.width / 2 + target.offset, y: 16)
        case .bottom: landing = CGPoint(x: size.width / 2 + target.offset, y: size.height - 16)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
            isSettlingMove = true
            swayAngle = 0
            movePoint = landing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { [weak self] in
            guard let self else { return }
            self.edge = target.edge
            self.alongOffset = target.offset
            UserDefaults.standard.set(target.edge.rawValue, forKey: "deckEdge")
            UserDefaults.standard.set(Double(target.offset), forKey: "deckAlongOffset")
            NSCursor.arrow.set()
            var instant = Transaction(animation: nil)
            instant.disablesAnimations = true
            withTransaction(instant) {
                self.isMovingDeck = false
                self.isSettlingMove = false
            }
            self.isGripHovered = false
            self.reset()
            windowManager.setMode(.deckIdle)
            self.refreshCursor()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.refreshCursor()
            }
        }
    }

    func beginReordering() {
        isReordering = true
        dwellWorkItem?.cancel()
        dwellWorkItem = nil
        tabExitWorkItem?.cancel()
        tabExitWorkItem = nil
        activeHoverNoteId = nil
        if expandedNoteId != nil {
            withAnimation(.noteyQuick) {
                expandedNoteId = nil
            }
        }
    }

    func endReordering(windowManager: WindowModeManager) {
        isReordering = false
        let inside = windowManager.deckController?.panel.frame.contains(NSEvent.mouseLocation) ?? false
        if !inside {
            panelMouseExited(windowManager: windowManager)
        }
    }

    func panelMouseExited(windowManager: WindowModeManager) {
        guard !isReordering, !isMovingDeck else { return }
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
        guard !isEditorOpen, !isReordering, !isMovingDeck else { return }

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
                .mouseMoved,
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

    @objc(mouseMoved:)
    override func mouseMoved(with event: NSEvent) {
        deckState.refreshCursor()
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
