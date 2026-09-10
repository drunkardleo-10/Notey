import SwiftUI

struct NoteEditorView: View {

    let noteStore: NoteStore
    @State var note: Note
    var onClose: (() -> Void)?
    var onDelete: ((UUID) -> Void)?
    var onArchive: ((UUID) -> Void)?

    @State private var autosaveStatus: String = "Saved · now"
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            
            EditorHeaderView(
                title: $note.title,
                isPinned: note.isPinned,
                autosaveStatus: autosaveStatus,
                onTogglePin: {
                    note.isPinned.toggle()
                    save()
                },
                onClose: { onClose?() }
            )

            NoteBodyEditorView(
                markdown: $note.body,
                isChecklist: $note.isChecklist,
                onChange: { _ in scheduleAutosave() }
            )

            EditorToolbarView(
                color: note.color,
                isChecklist: note.isChecklist,
                onColorChange: { newColor in
                    note.color = newColor
                    save()
                },
                onToggleChecklist: {
                    note.isChecklist.toggle()
                    if note.isChecklist {
                        let items = MarkdownUtilities.markdownToChecklist(note.body)
                        note.body = MarkdownUtilities.checklistToMarkdown(items)
                    } else {
                        note.body = MarkdownUtilities.checklistToPlainText(note.body)
                    }
                    save()
                },
                onDelete: { onDelete?(note.id) },
                onComplete: { onArchive?(note.id) },
                onClose: { onClose?() }
            )
        }
        .frame(
            width: NoteyLayout.editorWidth,
            height: NoteyLayout.editorHeight
        )
        .background(
            RoundedRectangle(cornerRadius: NoteyLayout.editorCornerRadius)
                .fill(note.color.swiftUIColor)
                .shadow(
                    color: Color.textPrimary.opacity(0.25),
                    radius: 20,
                    x: -4,
                    y: 8
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: NoteyLayout.editorCornerRadius))
        .onChange(of: note.title) { _, _ in scheduleAutosave() }
        .onExitCommand { onClose?() } 
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
