import SwiftUI
import AppKit

@main
enum NoteyMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
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
    var updaterController: UpdaterController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        BackgroundCursor.enable()

        updaterController = UpdaterController()

        noteStore.loadNotes()

        noteStore.seedGuideNotesIfFirstLaunch()

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
            guard self.editorController.currentNote?.id != note.id else { return }
            self.deckController.isEditorOpen = true
            DispatchQueue.main.async {
                self.editorController.openNote(note)
            }
        }
        if !OnboardingPanelController.hasCompletedOnboarding {
            showOnboardingTour()
        }

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
            },
            onCheckForUpdates: { [weak self] in
                self?.updaterController.checkForUpdates()
            }
        )
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
