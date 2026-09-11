import SwiftUI
import AppKit

@main
struct NoteyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {

        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    let noteStore = NoteStore()
    let windowManager = WindowModeManager()

    var deckController: DeckPanelController!
    var editorController: EditorPanelController!
    var archiveController: ArchivePanelController!
    var onboardingController: OnboardingPanelController!
    var statusBar: StatusBarController!
    var hotKeyManager: HotKeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        noteStore.loadNotes()

        noteStore.seedDefaultNotesIfEmpty()

        deckController = DeckPanelController(
            noteStore: noteStore,
            windowManager: windowManager
        )
        windowManager.deckController = deckController

        editorController = EditorPanelController(
            noteStore: noteStore,
            windowManager: windowManager
        )
        editorController.onClose = { [weak self] in
            self?.deckController.isEditorOpen = false
            self?.deckController.show()
        }

        deckController.onSelectNote = { [weak self] note in
            guard let self else { return }
            self.deckController.isEditorOpen = true
            self.deckController.deckState.reset()
            DispatchQueue.main.async {
                self.editorController.openNote(note)
            }
        }
        showOnboardingTour()

        archiveController = ArchivePanelController(noteStore: noteStore)

        hotKeyManager = HotKeyManager()
        hotKeyManager.registerArchiveToggle { [weak self] in
            self?.archiveController.toggle()
        }

        statusBar = StatusBarController(
            noteStore: noteStore,
            onNewNote: { [weak self] in
                guard let self else { return }
                let colors: [NoteColor] = [.yellow, .coral, .mint, .blue, .lavender]
                let nextColor = colors[self.noteStore.activeDeckNotes.count % colors.count]
                let newNote = self.noteStore.createNote(
                    title: "Untitled note",
                    body: "",
                    color: nextColor
                )
                self.deckController.isEditorOpen = true
                self.editorController.openNote(newNote)
            },
            onShowDeck: { [weak self] in
                self?.deckController.show()
            },
            onToggleArchive: { [weak self] in
                self?.archiveController.toggle()
            },
            onShowTour: { [weak self] in
                self?.showOnboardingTour()
            }
        )

        print("[Notey] App launched. \(noteStore.notes.count) notes loaded.")
    }

    func showOnboardingTour() {
        if onboardingController == nil {
            onboardingController = OnboardingPanelController()
        }
        onboardingController.onComplete = { [weak self] in
            self?.deckController.show()
        }
        onboardingController.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        
        false
    }
}
