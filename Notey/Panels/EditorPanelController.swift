import AppKit
import SwiftUI

@MainActor
final class EditorPanelController: NSObject {
    let panel: NoteyPanel

    private let noteStore: NoteStore
    private let windowManager: WindowModeManager
    private let containerView: NSView
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
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        containerView = NSView(frame: CGRect(origin: .zero, size: frame.size))
        containerView.autoresizingMask = [.width, .height]
        panel.contentView = containerView

        super.init()

        panel.configureAsEditor()
    }

    func openNote(_ note: Note) {
        currentNote = note
        isPinned = note.isPinned

        panel.level = isPinned ? .statusBar : .floating

        positionPanel()

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
            },
            onPinChange: { [weak self] pinned in
                self?.handlePinChange(pinned)
            }
        )

        hostingView?.removeFromSuperview()

        let hosting = NoteyHostingView(rootView: editorView)
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        hosting.frame = containerView.bounds
        hosting.autoresizingMask = [.width, .height]
        containerView.addSubview(hosting)
        self.hostingView = hosting

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeMain()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.panel.makeKey()
            if let tv = self.findTextView(in: self.panel.contentView) {
                self.panel.makeFirstResponder(tv)
            }
        }

        setupDeactivationObserver()
    }

    private func findTextView(in view: NSView?) -> NSView? {
        guard let view = view else { return nil }
        if view is NSTextView { return view }
        for sub in view.subviews {
            if let found = findTextView(in: sub) { return found }
        }
        return nil
    }

    func close() {
        removeDeactivationObserver()
        panel.orderOut(nil)
        hostingView?.removeFromSuperview()
        hostingView = nil
        currentNote = nil
        onClose?()
    }

    private func handlePinChange(_ pinned: Bool) {
        isPinned = pinned
        panel.level = pinned ? .statusBar : .floating
        panel.orderFrontRegardless()
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
