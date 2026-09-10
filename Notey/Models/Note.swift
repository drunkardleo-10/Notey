import Foundation

enum NoteColor: String, Codable, CaseIterable, Sendable {
    case yellow
    case coral
    case mint
    case blue
    case lavender
}

struct Note: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var body: String
    var color: NoteColor
    var isChecklist: Bool
    var isPinned: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case color
        case isChecklist
        case isPinned
        case isArchived
        case createdAt
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        color: NoteColor,
        isChecklist: Bool = false,
        isPinned: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.color = color
        self.isChecklist = isChecklist
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func markUpdated() {
        updatedAt = Date()
    }
}

struct ChecklistItem: Identifiable, Equatable {
    let id: String
    var text: String
    var isCompleted: Bool
}

enum NoteCoding {
    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }()

    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
}
