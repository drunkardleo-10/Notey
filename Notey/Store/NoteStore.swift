import Foundation
import Observation

@MainActor @Observable
final class NoteStore {

    private(set) var notes: [Note] = []
    var searchQuery: String = ""

    var activeDeckNotes: [Note] {
        notes.filter { !$0.isArchived }
    }

    var archivedNotes: [Note] {
        notes.filter { $0.isArchived }
    }

    private let jsonStore: JsonStore

    init(jsonStore: JsonStore = JsonStore()) {
        self.jsonStore = jsonStore
    }

    func loadNotes() {
        do {
            notes = try jsonStore.loadAllNotes()
            normalizeOrder()
        } catch {
            print("[NoteStore] Failed to load notes: \(error)")
            notes = []
        }
    }

    @discardableResult
    func createNote(title: String, body: String, color: NoteColor) -> Note {
        var note = Note(title: title, body: body, color: color)
        note.sortIndex = (notes.compactMap(\.sortIndex).min() ?? 0) - 1
        do {
            try jsonStore.saveNote(note)
            notes.insert(note, at: 0)
        } catch {
            print("[NoteStore] Failed to create note: \(error)")
        }
        return note
    }

    @discardableResult
    func saveNote(_ note: Note) -> Note {
        var updated = note
        updated.markUpdated()
        if let current = notes.first(where: { $0.id == updated.id }) {
            updated.sortIndex = current.sortIndex
        }
        do {
            try jsonStore.saveNote(updated)
            if let idx = notes.firstIndex(where: { $0.id == updated.id }) {
                notes[idx] = updated
            }
        } catch {
            print("[NoteStore] Failed to save note: \(error)")
        }
        return updated
    }

    @discardableResult
    func deleteNote(id: UUID) -> Bool {
        do {
            let deleted = try jsonStore.deleteNote(id: id)
            if deleted {
                notes.removeAll { $0.id == id }
            }
            return deleted
        } catch {
            print("[NoteStore] Failed to delete note: \(error)")
            return false
        }
    }

    @discardableResult
    func archiveNote(id: UUID) -> Note? {
        do {
            let archived = try jsonStore.archiveNote(id: id)
            if let idx = notes.firstIndex(where: { $0.id == id }) {
                notes[idx] = archived
            }
            return archived
        } catch {
            print("[NoteStore] Failed to archive note: \(error)")
            return nil
        }
    }

    @discardableResult
    func restoreNote(id: UUID) -> Note? {
        do {
            let restored = try jsonStore.restoreNote(id: id)
            if let idx = notes.firstIndex(where: { $0.id == id }) {
                notes[idx] = restored
            }
            return restored
        } catch {
            print("[NoteStore] Failed to restore note: \(error)")
            return nil
        }
    }

    func searchNotes(query: String) -> [Note] {
        do {
            return try jsonStore.searchNotes(query: query)
        } catch {
            print("[NoteStore] Failed to search notes: \(error)")
            return []
        }
    }

    func moveDeckNote(id: UUID, to targetIndex: Int) {
        var deck = activeDeckNotes
        guard let from = deck.firstIndex(where: { $0.id == id }), !deck.isEmpty else { return }
        let to = min(max(targetIndex, 0), deck.count - 1)
        guard from != to else { return }

        let moved = deck.remove(at: from)
        deck.insert(moved, at: to)

        for (position, note) in deck.enumerated() {
            guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { continue }
            guard notes[idx].sortIndex != position else { continue }
            notes[idx].sortIndex = position
            do {
                try jsonStore.saveNote(notes[idx])
            } catch {
                print("[NoteStore] Failed to save note order: \(error)")
            }
        }

        notes = sortedByOrder(notes)
    }

    private func normalizeOrder() {
        if notes.contains(where: { $0.sortIndex == nil }) {
            for idx in notes.indices where notes[idx].sortIndex != idx {
                notes[idx].sortIndex = idx
                do {
                    try jsonStore.saveNote(notes[idx])
                } catch {
                    print("[NoteStore] Failed to migrate note order: \(error)")
                }
            }
        }
        notes = sortedByOrder(notes)
    }

    private func sortedByOrder(_ list: [Note]) -> [Note] {
        list.enumerated()
            .sorted { lhs, rhs in
                let l = lhs.element.sortIndex ?? Int.max
                let r = rhs.element.sortIndex ?? Int.max
                return l == r ? lhs.offset < rhs.offset : l < r
            }
            .map(\.element)
    }

    private static let guideSeededKey = "hasSeededGuideNotesV1"

    func seedGuideNotesIfFirstLaunch() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.guideSeededKey) else { return }
        defaults.set(true, forKey: Self.guideSeededKey)
        guard activeDeckNotes.isEmpty else { return }

        createNote(
            title: "Welcome to Notey",
            body: "Hover the edge of your screen to fan the deck. Click a note to write in it.",
            color: .yellow
        )
        createNote(
            title: "Try a checklist",
            body: "☐ Click the checklist button in a note\n☐ Press Enter for a new item\n☐ Tick this one off",
            color: .mint
        )
        createNote(
            title: "Make it yours",
            body: "Change my color from the bar at the bottom. Delete or archive me when you are done.",
            color: .coral
        )
    }
}
