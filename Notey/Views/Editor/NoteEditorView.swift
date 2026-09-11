import SwiftUI
import AppKit

struct NoteEditorView: View {
    let noteStore: NoteStore
    @State var note: Note
    var onClose: (() -> Void)?
    var onDelete: ((UUID) -> Void)?
    var onArchive: ((UUID) -> Void)?
    var onPinChange: ((Bool) -> Void)?

    @State private var autosaveStatus: String = "Saved · now"
    @State private var debounceTask: Task<Void, Never>?
    @State private var registeredTextView: NSTextView?

    var body: some View {
        VStack(spacing: 0) {
            EditorHeaderView(
                title: $note.title,
                isPinned: note.isPinned,
                autosaveStatus: autosaveStatus,
                onUndo: {
                    registeredTextView?.undoManager?.undo()
                },
                onRedo: {
                    registeredTextView?.undoManager?.redo()
                },
                onTogglePin: {
                    note.isPinned.toggle()
                    save()
                    onPinChange?(note.isPinned)
                },
                onClose: { onClose?() }
            )

            NoteBodyEditorView(
                markdown: $note.body,
                isChecklist: $note.isChecklist,
                noteColor: note.color,
                onChange: { _ in scheduleAutosave() },
                onRegisterTextView: { tv in
                    self.registeredTextView = tv
                }
            )

            EditorToolbarView(
                color: note.color,
                isChecklist: note.isChecklist,
                onColorChange: { newColor in
                    withAnimation(.easeInOut(duration: 0.35)) {
                        note.color = newColor
                    }
                    save()
                },
                onToggleChecklist: {
                    guard let tv = findTextView() else { return }
                    tv.toggleChecklistAtCursor()
                    note.body = tv.toMarkdown()
                    note.isChecklist = tv.string.contains("☐ ") || tv.string.contains("☑ ")
                    save()
                },
                onDelete: { onDelete?(note.id) },
                onComplete: { onArchive?(note.id) },
                onClose: { onClose?() }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: NoteyLayout.editorCornerRadius)
                .fill(note.color.swiftUIColor)
        )
        .animation(.easeInOut(duration: 0.35), value: note.color)
        .clipShape(RoundedRectangle(cornerRadius: NoteyLayout.editorCornerRadius))
        .onChange(of: note.title) { _, _ in scheduleAutosave() }
        .onExitCommand { onClose?() }
    }

    private func findTextView() -> MarkdownNSTextView? {
        if let tv = registeredTextView as? MarkdownNSTextView {
            return tv
        }
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            return findMarkdownTextView(in: window.contentView)
        }
        return nil
    }

    private func findMarkdownTextView(in view: NSView?) -> MarkdownNSTextView? {
        guard let view = view else { return nil }
        if let tv = view as? MarkdownNSTextView { return tv }
        for sub in view.subviews {
            if let found = findMarkdownTextView(in: sub) { return found }
        }
        return nil
    }

    private func scheduleAutosave() {
        debounceTask?.cancel()
        autosaveStatus = "Saving..."

        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            save()
        }
    }

    private func save() {
        note = noteStore.saveNote(note)
        autosaveStatus = "Saved · now"
    }
}
