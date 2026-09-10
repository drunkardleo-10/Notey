import Foundation

final class JsonStore: Sendable {
    let basePath: URL

    init(basePath: URL? = nil) {
        if let basePath {
            self.basePath = basePath
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            self.basePath = appSupport
                .appendingPathComponent("Notey", isDirectory: true)
                .appendingPathComponent("notes", isDirectory: true)
        }
    }

    func ensureDirectory() throws {
        try FileManager.default.createDirectory(
            at: basePath,
            withIntermediateDirectories: true
        )
    }

    func notePath(for id: UUID) -> URL {
        basePath.appendingPathComponent("\(id.uuidString).json")
    }

    func saveNote(_ note: Note) throws {
        try ensureDirectory()
        let data = try NoteCoding.encoder.encode(note)
        let target = notePath(for: note.id)
        try data.write(to: target, options: [.atomic])
    }

    func loadNote(id: UUID) throws -> Note {
        let path = notePath(for: id)
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw JsonStoreError.noteNotFound(id)
        }
        let data = try Data(contentsOf: path)
        return try NoteCoding.decoder.decode(Note.self, from: data)
    }

    func loadAllNotes() throws -> [Note] {
        guard FileManager.default.fileExists(atPath: basePath.path) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: basePath,
            includingPropertiesForKeys: nil
        )

        var notes: [Note] = []
        for fileURL in contents where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let note = try NoteCoding.decoder.decode(Note.self, from: data)
                notes.append(note)
            } catch {
                
                continue
            }
        }

        notes.sort { $0.updatedAt > $1.updatedAt }
        return notes
    }

    func deleteNote(id: UUID) throws -> Bool {
        let path = notePath(for: id)
        guard FileManager.default.fileExists(atPath: path.path) else {
            return false
        }
        try FileManager.default.removeItem(at: path)
        return true
    }

    func archiveNote(id: UUID) throws -> Note {
        var note = try loadNote(id: id)
        note.isArchived = true
        note.markUpdated()
        try saveNote(note)
        return note
    }

    func restoreNote(id: UUID) throws -> Note {
        var note = try loadNote(id: id)
        note.isArchived = false
        note.markUpdated()
        try saveNote(note)
        return note
    }

    func searchNotes(query: String) throws -> [Note] {
        let normalized = query.trimmingCharacters(in: .whitespaces).lowercased()
        let allNotes = try loadAllNotes()

        guard !normalized.isEmpty else {
            return allNotes
        }

        return allNotes.filter { note in
            note.title.lowercased().contains(normalized)
            || note.body.lowercased().contains(normalized)
        }
    }
}

enum JsonStoreError: LocalizedError {
    case noteNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .noteNotFound(let id):
            return "Note not found: \(id)"
        }
    }
}
