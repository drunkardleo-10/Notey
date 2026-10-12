import AppKit
import SwiftUI

@MainActor
final class ArchivePanelController: NSObject {

    let panel: NoteyPanel

    private let noteStore: NoteStore
    private var hostingView: NoteyHostingView<ArchiveView>?

    var onClose: (() -> Void)?

    init(noteStore: NoteStore) {
        self.noteStore = noteStore

        let frame = ScreenUtilities.centeredFrame(
            width: NoteyLayout.archiveWidth,
            height: NoteyLayout.archiveHeight
        ) ?? CGRect(x: 200, y: 200, width: NoteyLayout.archiveWidth, height: NoteyLayout.archiveHeight)

        panel = NoteyPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.configureAsModal()
    }

    func show() {
        
        let archiveView = ArchiveView(
            noteStore: noteStore,
            onClose: { [weak self] in self?.hide() }
        )

        let hosting = NoteyHostingView(rootView: archiveView)
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hosting
        self.hostingView = hosting

        if let frame = ScreenUtilities.centeredFrame(
            width: NoteyLayout.archiveWidth,
            height: NoteyLayout.archiveHeight
        ) {
            panel.setFrame(frame, display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
        onClose?()
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    var isVisible: Bool { panel.isVisible }
}
