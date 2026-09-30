import SwiftUI

struct ArchiveView: View {

    let noteStore: NoteStore
    var onClose: (() -> Void)?

    @State private var selectedNoteId: UUID? = nil
    @State private var searchQuery: String = ""

    private var selectedNote: Note? {
        if let id = selectedNoteId, let found = noteStore.archivedNotes.first(where: { $0.id == id }) {
            return found
        }
        return noteStore.archivedNotes.first
    }

    var body: some View {
        HStack(spacing: 0) {
            ArchiveListView(
                archivedNotes: noteStore.archivedNotes,
                selectedNoteId: $selectedNoteId,
                searchQuery: $searchQuery,
                onClose: onClose
            )
            .frame(width: 250)

            Rectangle()
                .fill(Color.textPrimary.opacity(0.08))
                .frame(width: 1)

            ArchiveDetailView(
                note: selectedNote,
                onRestore: { id in
                    noteStore.restoreNote(id: id)
                    selectedNoteId = noteStore.archivedNotes.first?.id
                },
                onDelete: { id in
                    noteStore.deleteNote(id: id)
                    selectedNoteId = noteStore.archivedNotes.first?.id
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            width: NoteyLayout.archiveWidth,
            height: NoteyLayout.archiveHeight
        )
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            if selectedNoteId == nil {
                selectedNoteId = noteStore.archivedNotes.first?.id
            }
        }
        .onExitCommand { onClose?() }
    }
}
