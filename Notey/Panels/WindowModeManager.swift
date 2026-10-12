import AppKit
import Observation

enum WindowMode: String {
    case deckIdle       = "deck"
    case deckHover      = "deck_hover"
    case deckMove       = "deck_move"
    case editor         = "editor"
    case archive        = "archive"
    case onboarding     = "onboarding"
}

@MainActor @Observable
final class WindowModeManager {

    private(set) var currentMode: WindowMode = .deckIdle

    weak var deckController: DeckPanelController?

    @ObservationIgnored nonisolated(unsafe) private var screenObserver: NSObjectProtocol?

    init() {

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reanchorAllPanels()
            }
        }
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func setMode(_ mode: WindowMode) {
        currentMode = mode

        switch mode {
        case .deckIdle:
            showDeckIdle()
        case .deckHover:
            showDeckHover()
        case .deckMove:
            showDeckMove()
        case .editor:
            showEditor()
        case .archive:
            showArchive()
        case .onboarding:
            showOnboarding()
        }
    }

    private func showDeckIdle() {
        guard let controller = deckController else { return }
        let count = controller.noteStore.activeDeckNotes.count
        let frame = ScreenUtilities.edgeDeckIdleFrame(
            for: controller.panel,
            noteCount: count,
            edge: controller.deckState.edge,
            alongOffset: controller.deckState.alongOffset
        )
        controller.panel.setFrame(frame, display: true, animate: false)
        controller.panel.orderFrontRegardless()
        controller.updateTrackingArea()
    }

    private func showDeckMove() {
        guard let controller = deckController else { return }
        let frame = ScreenUtilities.edgeDeckMoveFrame(for: controller.panel)
        controller.panel.setFrame(frame, display: true, animate: false)
        controller.panel.orderFrontRegardless()
        controller.updateTrackingArea()
    }

    private func showDeckHover() {
        guard let controller = deckController else { return }
        let count = controller.noteStore.activeDeckNotes.count
        let frame = ScreenUtilities.edgeDeckHoverFrame(
            for: controller.panel,
            noteCount: count,
            edge: controller.deckState.edge,
            alongOffset: controller.deckState.alongOffset
        )
        controller.panel.setFrame(frame, display: true, animate: false)
        controller.panel.orderFrontRegardless()
        controller.updateTrackingArea()
    }

    private func showEditor() {
        
        showDeckIdle()
        
    }

    private func showArchive() {
        
    }

    private func showOnboarding() {
        
    }

    func reanchorAllPanels() {
        switch currentMode {
        case .deckIdle:
            showDeckIdle()
        case .deckHover:
            showDeckHover()
        case .deckMove:
            showDeckMove()
        case .editor:
            showEditor()
        case .archive:
            showArchive()
        case .onboarding:
            showOnboarding()
        }
    }
}
