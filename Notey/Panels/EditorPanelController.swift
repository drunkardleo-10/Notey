import AppKit
import SwiftUI

@MainActor
final class EditorPanelController: NSObject {

    let panel: NoteyPanel

    private let noteStore: NoteStore
    private let windowManager: WindowModeManager
    private var hostingView: NoteyHostingView<NoteEditorView>?
    private var deactivationObserver: NSObjectProtocol?

    var onClose: (() -> Void)?

    private(set) var currentNote: Note?
    private var isPinned: Bool = false

    init(noteStore: NoteStore, windowManager: WindowModeManager) {
        self.noteStore = noteStore
        self.windowManager = windowManager

        let frame = CGRect(x: 0, y: 0, width: NoteyLayout.editorWidth, height: NoteyLayout.editorHeight)
        panel = NoteyPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.configureAsEditor()
    }

    func openNote(_ note: Note) {
        currentNote = note
        isPinned = note.isPinned

        let editorView = NoteEditorView(
            noteStore: noteStore,
            note: note,
            onClose: { [weak self] in self?.close() },
            onDelete: { [weak self] id in
                self?.noteStore.deleteNote(id: id)
                self?.close()
            },
            onArchive: { [weak self] id in
                self?.noteStore.archiveNote(id: id)
                self?.close()
            }
        )

        let hosting = NoteyHostingView(rootView: editorView)
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hosting
        self.hostingView = hosting

        positionPanel()

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        setupDeactivationObserver()
    }

    func close() {
        removeDeactivationObserver()
        panel.orderOut(nil)
        currentNote = nil
        onClose?()
    }

    private func positionPanel() {
        guard let screenGeo = ScreenUtilities.cursorScreenGeometry() else { return }

        let deckWidth = NoteyLayout.deckIdleWidth
        let editorX = screenGeo.x + screenGeo.width - deckWidth - NoteyLayout.editorWidth - 16
        let editorY = screenGeo.y + (screenGeo.height - NoteyLayout.editorHeight) / 2.0

        panel.setFrame(
            CGRect(
                x: editorX,
                y: editorY,
                width: NoteyLayout.editorWidth,
                height: NoteyLayout.editorHeight
            ),
            display: true
        )
    }

    private func setupDeactivationObserver() {
        removeDeactivationObserver()

        deactivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if !self.isPinned {
                    self.close()
                }
            }
        }
    }

    private func removeDeactivationObserver() {
        if let observer = deactivationObserver {
            NotificationCenter.default.removeObserver(observer)
            deactivationObserver = nil
        }
    }
}
