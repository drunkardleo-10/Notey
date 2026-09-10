import Foundation

enum MarkdownUtilities {

    static func markdownToChecklist(_ markdown: String) -> [ChecklistItem] {
        let lines = markdown.components(separatedBy: "\n")
        var items: [ChecklistItem] = []

        for (i, line) in lines.enumerated() {
            
            if let match = line.taskMatch() {
                items.append(ChecklistItem(
                    id: "item-\(i)-\(Date().timeIntervalSince1970)",
                    text: match.text,
                    isCompleted: match.isCompleted
                ))
                continue
            }

            if let text = line.bulletText() {
                items.append(ChecklistItem(
                    id: "item-\(i)-\(Date().timeIntervalSince1970)",
                    text: text,
                    isCompleted: false
                ))
                continue
            }

            if let text = line.numberedText() {
                items.append(ChecklistItem(
                    id: "item-\(i)-\(Date().timeIntervalSince1970)",
                    text: text,
                    isCompleted: false
                ))
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                items.append(ChecklistItem(
                    id: "item-\(i)-\(Date().timeIntervalSince1970)",
                    text: trimmed,
                    isCompleted: false
                ))
            }
        }

        if items.isEmpty {
            items.append(ChecklistItem(
                id: "item-0-\(Date().timeIntervalSince1970)",
                text: "",
                isCompleted: false
            ))
        }

        return items
    }

    static func checklistToMarkdown(_ items: [ChecklistItem]) -> String {
        
        if items.count == 1 && items[0].text.trimmingCharacters(in: .whitespaces).isEmpty {
            return ""
        }

        return items
            .map { "- [\($0.isCompleted ? "x" : " ")] \($0.text)" }
            .joined(separator: "\n")
    }

    static func checklistToPlainText(_ markdown: String) -> String {
        markdown
            .components(separatedBy: "\n")
            .map { line in
                if let match = line.taskMatch() {
                    return match.text
                }
                return line
            }
            .joined(separator: "\n")
    }

    struct NoteLine: Identifiable, Equatable {
        let id: String
        var isChecklist: Bool
        var isCompleted: Bool
        var text: String
    }

    static func parseLines(_ markdown: String) -> [NoteLine] {
        guard !markdown.isEmpty else {
            return [NoteLine(
                id: "line-\(UUID().uuidString)",
                isChecklist: false,
                isCompleted: false,
                text: ""
            )]
        }

        return markdown.components(separatedBy: "\n").enumerated().map { (i, raw) in
            if let match = raw.taskMatch() {
                return NoteLine(
                    id: "line-\(UUID().uuidString)-\(i)",
                    isChecklist: true,
                    isCompleted: match.isCompleted,
                    text: match.text
                )
            }
            return NoteLine(
                id: "line-\(UUID().uuidString)-\(i)",
                isChecklist: false,
                isCompleted: false,
                text: raw
            )
        }
    }

    static func serializeLines(_ lines: [NoteLine]) -> String {
        lines.map { line in
            if line.isChecklist {
                return "- [\(line.isCompleted ? "x" : " ")] \(line.text)"
            }
            return line.text
        }.joined(separator: "\n")
    }
}

private extension String {

    struct TaskMatch {
        let isCompleted: Bool
        let text: String
    }

    func taskMatch() -> TaskMatch? {
        let pattern = #"^[-*]\s+\[([ xX])\]\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: self,
                  range: NSRange(startIndex..., in: self)
              ) else {
            return nil
        }

        let checkRange = Range(match.range(at: 1), in: self)!
        let textRange = Range(match.range(at: 2), in: self)!
        let checkChar = String(self[checkRange]).lowercased()

        return TaskMatch(
            isCompleted: checkChar == "x",
            text: String(self[textRange])
        )
    }

    func bulletText() -> String? {
        let pattern = #"^[-*+]\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: self,
                  range: NSRange(startIndex..., in: self)
              ),
              let textRange = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[textRange])
    }

    func numberedText() -> String? {
        let pattern = #"^\d+[.)]\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: self,
                  range: NSRange(startIndex..., in: self)
              ),
              let textRange = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[textRange])
    }
}
