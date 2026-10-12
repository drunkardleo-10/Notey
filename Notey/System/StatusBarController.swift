import AppKit

@MainActor
final class StatusBarController: NSObject {

    private var statusItem: NSStatusItem?

    private let noteStore: NoteStore
    private let onNewNote: () -> Void
    private let onShowDeck: () -> Void
    private let onToggleArchive: () -> Void
    private let onShowTour: () -> Void
    private let onCheckForUpdates: () -> Void

    init(
        noteStore: NoteStore,
        onNewNote: @escaping () -> Void,
        onShowDeck: @escaping () -> Void,
        onToggleArchive: @escaping () -> Void,
        onShowTour: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void
    ) {
        self.noteStore = noteStore
        self.onNewNote = onNewNote
        self.onShowDeck = onShowDeck
        self.onToggleArchive = onToggleArchive
        self.onShowTour = onShowTour
        self.onCheckForUpdates = onCheckForUpdates

        super.init()

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            
            button.image = NSImage(
                systemSymbolName: "note.text",
                accessibilityDescription: "Notey"
            )
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true 
        }

        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let newItem = NSMenuItem(
            title: "New Note",
            action: #selector(handleNewNote),
            keyEquivalent: "n"
        )
        newItem.keyEquivalentModifierMask = [.command]
        newItem.target = self
        menu.addItem(newItem)

        let deckItem = NSMenuItem(
            title: "Show Deck",
            action: #selector(handleShowDeck),
            keyEquivalent: ""
        )
        deckItem.target = self
        menu.addItem(deckItem)

        let archiveItem = NSMenuItem(
            title: "Open Archive",
            action: #selector(handleToggleArchive),
            keyEquivalent: "l"
        )
        archiveItem.keyEquivalentModifierMask = [.option, .command]
        archiveItem.target = self
        menu.addItem(archiveItem)

        let tourItem = NSMenuItem(
            title: "Welcome Tour…",
            action: #selector(handleShowTour),
            keyEquivalent: ""
        )
        tourItem.target = self
        menu.addItem(tourItem)

        let updateItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(handleCheckForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Notey",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func handleNewNote() {
        onNewNote()
    }

    @objc private func handleShowDeck() {
        onShowDeck()
    }

    @objc private func handleToggleArchive() {
        onToggleArchive()
    }

    @objc private func handleShowTour() {
        onShowTour()
    }

    @objc private func handleCheckForUpdates() {
        onCheckForUpdates()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
