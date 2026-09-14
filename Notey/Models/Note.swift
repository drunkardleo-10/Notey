import Foundation

enum NoteColor: RawRepresentable, Codable, Hashable, Sendable, CaseIterable {
    case yellow
    case coral
    case mint
    case blue
    case lavender
    case custom(String)

    public static let allCases: [NoteColor] = [
        .yellow, .coral, .mint, .blue, .lavender
    ]

    public var rawValue: String {
        switch self {
        case .yellow: return "yellow"
        case .coral: return "coral"
        case .mint: return "mint"
        case .blue: return "blue"
        case .lavender: return "lavender"
        case .custom(let hex): return Self.normalizeHex(hex)
        }
    }

    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "yellow": self = .yellow
        case "coral": self = .coral
        case "mint": self = .mint
        case "blue": self = .blue
        case "lavender": self = .lavender
        default:
            self = .custom(Self.normalizeHex(rawValue))
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static func normalizeHex(_ hex: String) -> String {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if !clean.hasPrefix("#") {
            clean = "#" + clean
        }
        return clean
    }

    public var isCustom: Bool {
        if case .custom = self {
            return true
        }
        return false
    }

    public static func == (lhs: NoteColor, rhs: NoteColor) -> Bool {
        lhs.rawValue.uppercased() == rhs.rawValue.uppercased()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.uppercased())
    }
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
