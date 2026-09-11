import SwiftUI
import AppKit

struct NoteBodyEditorView: View {
    @Binding var markdown: String
    @Binding var isChecklist: Bool
    var noteColor: NoteColor = .yellow
    var onChange: ((String) -> Void)?
    var onRegisterTextView: ((NSTextView) -> Void)?

    @State private var internalTextView: MarkdownNSTextView?

    var body: some View {
        MarkdownEditorRepresentable(
            markdown: $markdown,
            isChecklist: $isChecklist,
            noteColor: noteColor,
            onTextViewReady: { tv in
                self.internalTextView = tv
                self.onRegisterTextView?(tv)
            },
            onChange: { newMarkdown in
                onChange?(newMarkdown)
            }
        )
        .onHover { hovering in
            if hovering {
                NSCursor.iBeam.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .padding(.init(top: 8, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isChecklist) { _, newValue in
            internalTextView?.toggleChecklistMode(newValue)
        }
    }
}

final class EditorScrollView: NSScrollView {
    weak var textView: MarkdownNSTextView?

    override func layout() {
        super.layout()
        guard let tv = textView else { return }
        let clipBounds = contentView.bounds
        if clipBounds.height > 0 {
            if tv.minSize.height != clipBounds.height {
                tv.minSize = NSSize(width: 0, height: clipBounds.height)
            }
            if tv.frame.height < clipBounds.height {
                tv.frame = NSRect(x: 0, y: 0, width: clipBounds.width, height: clipBounds.height)
            }
            if tv.frame.width != clipBounds.width {
                tv.frame.size.width = clipBounds.width
            }
        }
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.iBeam.set()
    }

    override func mouseDown(with event: NSEvent) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
        window?.makeKey()
        if let tv = textView {
            window?.makeFirstResponder(tv)
        }
        super.mouseDown(with: event)
    }
}

struct MarkdownEditorRepresentable: NSViewRepresentable {
    @Binding var markdown: String
    @Binding var isChecklist: Bool
    var noteColor: NoteColor
    var onTextViewReady: (MarkdownNSTextView) -> Void
    var onChange: (String) -> Void

    func makeNSView(context: Context) -> EditorScrollView {
        let scrollView = EditorScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = MarkdownNSTextView(frame: .zero)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        textView.isRichText = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.importsGraphics = false
        textView.allowsImageEditing = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.noteColor = noteColor

        textView.setMarkdownText(markdown)

        scrollView.documentView = textView
        scrollView.textView = textView
        context.coordinator.textView = textView
        DispatchQueue.main.async {
            onTextViewReady(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: EditorScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownNSTextView else { return }
        if textView.noteColor != noteColor {
            textView.noteColor = noteColor
            textView.needsDisplay = true
        }
        if textView.window?.firstResponder != textView {
            let currentMarkdown = textView.toMarkdown()
            if currentMarkdown != markdown {
                textView.setMarkdownText(markdown)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditorRepresentable
        weak var textView: MarkdownNSTextView?

        init(_ parent: MarkdownEditorRepresentable) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? MarkdownNSTextView else { return }
            let md = tv.toMarkdown()
            parent.markdown = md
            parent.isChecklist = tv.string.contains("☐ ") || tv.string.contains("☑ ")
            parent.onChange(md)
        }
    }
}

final class MarkdownNSTextView: NSTextView {
    var baseFont: NSFont = NoteyFonts.noteNSFont(size: 24, weight: .regular)
    var boldFont: NSFont = NoteyFonts.noteNSFont(size: 24, weight: .bold)
    var italicFont: NSFont = NoteyFonts.noteNSFont(size: 24, weight: .regular, italic: true)
    var boldItalicFont: NSFont = NoteyFonts.noteNSFont(size: 24, weight: .bold, italic: true)
    var baseColor: NSColor = NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 1.0)
    var noteColor: NoteColor = .yellow
    private var checkboxFont: NSFont = NSFont.systemFont(ofSize: 22, weight: .medium)
    private var isApplyingFormat: Bool = false

    override init(frame frameRect: NSRect, textContainer: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: textContainer)
        configure()
    }

    convenience override init(frame frameRect: NSRect) {
        let textContainer = NSTextContainer(containerSize: NSSize(width: frameRect.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let storage = NSTextStorage()
        storage.addLayoutManager(layoutManager)
        self.init(frame: frameRect, textContainer: textContainer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        font = baseFont
        textColor = baseColor
        insertionPointColor = baseColor
        isEditable = true
        isSelectable = true
        allowsUndo = true
        isRichText = true
        importsGraphics = false
        allowsImageEditing = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = window {
            window.invalidateCursorRects(for: self)
            DispatchQueue.main.async { [weak self, weak window] in
                guard let self = self, let window = window else { return }
                if window.firstResponder == nil || window.firstResponder == window {
                    window.makeFirstResponder(self)
                }
            }
        }
    }

    func setMarkdownText(_ text: String) {
        let attr = MarkdownBridge.toAttributedString(
            text,
            baseFont: baseFont,
            boldFont: boldFont,
            italicFont: italicFont,
            boldItalicFont: boldItalicFont,
            baseColor: baseColor
        )
        textStorage?.setAttributedString(attr)
        refreshFormatting()
    }

    func toMarkdown() -> String {
        if let storage = textStorage {
            return MarkdownBridge.attributedStringToMarkdown(storage)
        }
        return MarkdownBridge.toMarkdown(string)
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        super.insertText(string, replacementRange: replacementRange)
        checkAutoMarkdownTriggers()
        refreshFormatting()
    }

    override func doCommand(by selector: Selector) {
        if selector == #selector(insertNewline(_:)) {
            if handleNewline() {
                return
            }
        } else if selector == #selector(deleteBackward(_:)) {
            if handleDeleteBackward() {
                return
            }
        }
        super.doCommand(by: selector)
        refreshFormatting()
    }

    override func mouseDown(with event: NSEvent) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
        window?.makeKey()
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        if let layoutManager = layoutManager, let textContainer = textContainer {
            let nsString = string as NSString
            let origin = textContainerOrigin

            var index = 0
            while index < nsString.length {
                let char = nsString.substring(with: NSRange(location: index, length: 1))
                if char == "☐" || char == "☑" {
                    let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
                    let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer).offsetBy(dx: origin.x, dy: origin.y)
                    let boxSize: CGFloat = 19
                    let boxX = rect.minX + 1.5
                    let boxY = rect.midY - (boxSize / 2)
                    let clickableRect = NSRect(x: boxX - 4, y: boxY - 4, width: boxSize + 8, height: boxSize + 8)
                    if clickableRect.contains(point) {
                        let newChar = char == "☐" ? "☑" : "☐"
                        replaceCharacters(in: NSRange(location: index, length: 1), with: newChar)
                        didChangeText()
                        refreshFormatting()
                        needsDisplay = true
                        return
                    }
                }
                index += 1
            }

            let charIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            if charIndex < nsString.length {
                let char = nsString.substring(with: NSRange(location: charIndex, length: 1))
                if char == "☐" || char == "☑" {
                    let newChar = char == "☐" ? "☑" : "☐"
                    replaceCharacters(in: NSRange(location: charIndex, length: 1), with: newChar)
                    didChangeText()
                    refreshFormatting()
                    needsDisplay = true
                    return
                }
            }
        }
        super.mouseDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let layoutManager = layoutManager, let textContainer = textContainer else { return }
        let nsString = string as NSString
        let origin = textContainerOrigin

        var index = 0
        while index < nsString.length {
            let char = nsString.substring(with: NSRange(location: index, length: 1))
            if char == "☐" || char == "☑" {
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
                let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer).offsetBy(dx: origin.x, dy: origin.y)

                if dirtyRect.intersects(rect) || dirtyRect.contains(rect.origin) {
                    let boxSize: CGFloat = 19
                    let boxX = rect.minX + 1.5
                    let boxY = rect.midY - (boxSize / 2)
                    let boxRect = NSRect(x: boxX, y: boxY, width: boxSize, height: boxSize)

                    if char == "☐" {
                        let strokeRect = boxRect.insetBy(dx: 0.9, dy: 0.9)
                        let path = NSBezierPath(roundedRect: strokeRect, xRadius: 5.0, yRadius: 5.0)

                        baseColor.withAlphaComponent(0.04).setFill()
                        path.fill()

                        baseColor.withAlphaComponent(0.85).setStroke()
                        path.lineWidth = 1.8
                        path.stroke()
                    } else {
                        let fillPath = NSBezierPath(roundedRect: boxRect, xRadius: 5.2, yRadius: 5.2)

                        baseColor.withAlphaComponent(0.92).setFill()
                        fillPath.fill()

                        let check = NSBezierPath()
                        check.lineWidth = 2.4
                        check.lineCapStyle = .round
                        check.lineJoinStyle = .round

                        let startX = boxRect.minX + 4.8
                        let startY = boxRect.minY + 9.8
                        let midX = boxRect.minX + 7.8
                        let midY = boxRect.minY + 14.0
                        let endX = boxRect.minX + 14.2
                        let endY = boxRect.minY + 5.2

                        check.move(to: NSPoint(x: startX, y: startY))
                        check.line(to: NSPoint(x: midX, y: midY))
                        check.line(to: NSPoint(x: endX, y: endY))
                        noteColor.nsColor.setStroke()
                        check.stroke()
                    }
                }
            }
            index += 1
        }
    }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .iBeam)

        guard let layoutManager = layoutManager, let textContainer = textContainer else { return }
        let nsString = string as NSString
        let origin = textContainerOrigin

        var index = 0
        while index < nsString.length {
            let char = nsString.substring(with: NSRange(location: index, length: 1))
            if char == "☐" || char == "☑" {
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
                let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer).offsetBy(dx: origin.x, dy: origin.y)
                let boxSize: CGFloat = 19
                let boxX = rect.minX + 1.5
                let boxY = rect.midY - (boxSize / 2)
                let boxRect = NSRect(x: boxX, y: boxY, width: boxSize, height: boxSize)
                addCursorRect(boxRect, cursor: .pointingHand)
            }
            index += 1
        }
    }

    private func handleNewline() -> Bool {
        let selected = selectedRange()
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: selected)
        let lineText = nsString.substring(with: lineRange)
        let trimmedLine = lineText.trimmingCharacters(in: .newlines)

        if trimmedLine == "•" || trimmedLine == "• " {
            let replaceRange = NSRange(location: lineRange.location, length: min(lineText.count, lineRange.length))
            replaceCharacters(in: replaceRange, with: "")
            setSelectedRange(NSRange(location: lineRange.location, length: 0))
            didChangeText()
            refreshFormatting()
            return true
        }

        if trimmedLine == "☐" || trimmedLine == "☐ " || trimmedLine == "☑" || trimmedLine == "☑ " {
            let replaceRange = NSRange(location: lineRange.location, length: min(lineText.count, lineRange.length))
            replaceCharacters(in: replaceRange, with: "")
            setSelectedRange(NSRange(location: lineRange.location, length: 0))
            cleanTypingAttributes()
            didChangeText()
            refreshFormatting()
            return true
        }

        if trimmedLine.hasPrefix("• ") {
            super.insertNewline(nil)
            insertText("• ", replacementRange: selectedRange())
            refreshFormatting()
            return true
        }

        if trimmedLine.hasPrefix("☐ ") || trimmedLine.hasPrefix("☑ ") {
            super.insertNewline(nil)
            insertText("☐ ", replacementRange: selectedRange())
            refreshFormatting()
            return true
        }

        return false
    }

    private func handleDeleteBackward() -> Bool {
        let selected = selectedRange()
        guard selected.length == 0 else { return false }
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: selected)
        let cursorInLine = selected.location - lineRange.location
        let lineText = nsString.substring(with: lineRange)

        if lineText.hasPrefix("• ") && cursorInLine <= 2 && cursorInLine > 0 {
            replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: "")
            setSelectedRange(NSRange(location: lineRange.location, length: 0))
            didChangeText()
            refreshFormatting()
            return true
        }

        if (lineText.hasPrefix("☐ ") || lineText.hasPrefix("☑ ")) && cursorInLine <= 2 && cursorInLine > 0 {
            replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: "")
            setSelectedRange(NSRange(location: lineRange.location, length: 0))
            cleanTypingAttributes()
            didChangeText()
            refreshFormatting()
            return true
        }

        return false
    }

    private func checkAutoMarkdownTriggers() {
        let selected = selectedRange()
        let nsString = string as NSString
        guard selected.location <= nsString.length else { return }
        let lineRange = nsString.lineRange(for: selected)
        let lineText = nsString.substring(with: lineRange)

        if lineText.hasPrefix("☐  ") || lineText.hasPrefix("☑  ") {
            let isDone = lineText.hasPrefix("☑")
            let marker = isDone ? "☑ " : "☐ "
            let content = String(lineText.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            let newLine = marker + content
            replaceCharacters(in: lineRange, with: newLine)
            setSelectedRange(NSRange(location: lineRange.location + 2, length: 0))
            didChangeText()
            refreshFormatting()
            return
        }

        let checkPrefixes = [
            "• [ ] ", "• [ ]", "• [] ", "• []",
            "- [ ] ", "- [ ]", "- [] ", "- []",
            "[ ] ", "[ ]", "[] ", "[]"
        ]
        for prefix in checkPrefixes {
            if lineText.hasPrefix(prefix) {
                replaceCharacters(in: NSRange(location: lineRange.location, length: prefix.count), with: "☐ ")
                let newCursor = lineRange.location + 2 + max(0, selected.location - (lineRange.location + prefix.count))
                setSelectedRange(NSRange(location: newCursor, length: 0))
                didChangeText()
                refreshFormatting()
                return
            }
        }

        let donePrefixes = [
            "• [x] ", "• [x]", "• [X] ", "• [X]",
            "- [x] ", "- [x]", "- [X] ", "- [X]",
            "[x] ", "[x]", "[X] ", "[X]"
        ]
        for prefix in donePrefixes {
            if lineText.hasPrefix(prefix) {
                replaceCharacters(in: NSRange(location: lineRange.location, length: prefix.count), with: "☑ ")
                let newCursor = lineRange.location + 2 + max(0, selected.location - (lineRange.location + prefix.count))
                setSelectedRange(NSRange(location: newCursor, length: 0))
                didChangeText()
                refreshFormatting()
                return
            }
        }

        if (lineText.hasPrefix("- ") || lineText.hasPrefix("* ")) && !lineText.hasPrefix("- [") && !lineText.hasPrefix("* [") {
            replaceCharacters(in: NSRange(location: lineRange.location, length: 2), with: "• ")
            let offset = max(lineRange.location + 2, selected.location)
            setSelectedRange(NSRange(location: offset, length: 0))
            didChangeText()
            return
        }

        let cursorInLine = selected.location - lineRange.location
        guard cursorInLine > 0 else { return }
        let textBeforeCursor = (lineText as NSString).substring(to: cursorInLine)

        if let boldRegex = try? NSRegularExpression(pattern: #"\*\*([^*\n]+)\*\*$"#),
           let match = boldRegex.firstMatch(in: textBeforeCursor, range: NSRange(location: 0, length: (textBeforeCursor as NSString).length)) {
            let fullMatchRange = match.range(at: 0)
            let groupRange = match.range(at: 1)
            let content = (textBeforeCursor as NSString).substring(with: groupRange)
            let replaceRange = NSRange(location: lineRange.location + fullMatchRange.location, length: fullMatchRange.length)

            let boldAttrStr = NSAttributedString(string: content, attributes: [
                .font: boldFont,
                .foregroundColor: baseColor
            ])
            textStorage?.replaceCharacters(in: replaceRange, with: boldAttrStr)
            setSelectedRange(NSRange(location: replaceRange.location + content.count, length: 0))
            typingAttributes = [
                .font: baseFont,
                .foregroundColor: baseColor
            ]
            didChangeText()
            return
        }

        if let underlineRegex = try? NSRegularExpression(pattern: #"(?:__([^_\n]+)__|(?<!_)_([^_\n]+)_)$"#),
           let match = underlineRegex.firstMatch(in: textBeforeCursor, range: NSRange(location: 0, length: (textBeforeCursor as NSString).length)) {
            let fullMatchRange = match.range(at: 0)
            let g1 = match.range(at: 1)
            let g2 = match.range(at: 2)
            let groupRange = g1.location != NSNotFound ? g1 : g2
            let content = (textBeforeCursor as NSString).substring(with: groupRange)
            let replaceRange = NSRange(location: lineRange.location + fullMatchRange.location, length: fullMatchRange.length)

            let underlineAttrStr = NSAttributedString(string: content, attributes: [
                .font: baseFont,
                .foregroundColor: baseColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])
            textStorage?.replaceCharacters(in: replaceRange, with: underlineAttrStr)
            setSelectedRange(NSRange(location: replaceRange.location + content.count, length: 0))
            typingAttributes = [
                .font: baseFont,
                .foregroundColor: baseColor,
                .underlineStyle: 0
            ]
            didChangeText()
            return
        }

        if let italicRegex = try? NSRegularExpression(pattern: #"(?<!\*)\*([^*\n]+)\*$"#),
           let match = italicRegex.firstMatch(in: textBeforeCursor, range: NSRange(location: 0, length: (textBeforeCursor as NSString).length)) {
            let fullMatchRange = match.range(at: 0)
            let groupRange = match.range(at: 1)
            let content = (textBeforeCursor as NSString).substring(with: groupRange)
            let replaceRange = NSRange(location: lineRange.location + fullMatchRange.location, length: fullMatchRange.length)

            let italicAttrStr = NSAttributedString(string: content, attributes: [
                .font: italicFont,
                .obliqueness: 0.2,
                .foregroundColor: baseColor
            ])
            textStorage?.replaceCharacters(in: replaceRange, with: italicAttrStr)
            setSelectedRange(NSRange(location: replaceRange.location + content.count, length: 0))
            typingAttributes = [
                .font: baseFont,
                .foregroundColor: baseColor
            ]
            didChangeText()
            return
        }
    }

    func makeNewChecklist() {
        let selected = selectedRange()
        let nsString = string as NSString
        guard selected.location <= nsString.length else { return }
        let lineRange = nsString.lineRange(for: selected)
        let lineText = nsString.substring(with: lineRange)
        let trimmed = lineText.trimmingCharacters(in: .newlines).trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            replaceCharacters(in: lineRange, with: "☐ ")
            setSelectedRange(NSRange(location: lineRange.location + 2, length: 0))
        } else if trimmed == "☐" || trimmed == "☑" {
            setSelectedRange(NSRange(location: lineRange.location + 2, length: 0))
        } else {
            let insertPos = lineRange.location + lineRange.length
            let prefix = lineText.hasSuffix("\n") ? "☐ " : "\n☐ "
            replaceCharacters(in: NSRange(location: insertPos, length: 0), with: prefix)
            setSelectedRange(NSRange(location: insertPos + prefix.count, length: 0))
        }
        window?.makeFirstResponder(self)
        didChangeText()
        refreshFormatting()
        needsDisplay = true
    }

    func toggleChecklistAtCursor() {
        let selected = selectedRange()
        let nsString = string as NSString
        guard selected.location <= nsString.length else { return }
        let lineRange = nsString.lineRange(for: selected)
        let lineText = nsString.substring(with: lineRange)

        let lines = lineText.components(separatedBy: "\n")
        var hasNonChecklist = false
        for (idx, line) in lines.enumerated() {
            if idx == lines.count - 1 && line.isEmpty && lines.count > 1 { continue }
            if !line.hasPrefix("☐ ") && !line.hasPrefix("☑ ") {
                hasNonChecklist = true
                break
            }
        }

        var newLines: [String] = []
        for (idx, line) in lines.enumerated() {
            if idx == lines.count - 1 && line.isEmpty && lines.count > 1 {
                newLines.append(line)
                continue
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if hasNonChecklist {
                if trimmed.hasPrefix("• ") {
                    let content = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                    newLines.append("☐ " + content)
                } else if !trimmed.hasPrefix("☐ ") && !trimmed.hasPrefix("☑ ") {
                    newLines.append("☐ " + trimmed)
                } else {
                    newLines.append(line)
                }
            } else {
                if trimmed.hasPrefix("☐ ") || trimmed.hasPrefix("☑ ") {
                    let content = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                    newLines.append(content)
                } else {
                    newLines.append(line)
                }
            }
        }

        let replacement = newLines.joined(separator: "\n")
        replaceCharacters(in: lineRange, with: replacement)
        if lineText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && replacement == "☐ " {
            setSelectedRange(NSRange(location: lineRange.location + 2, length: 0))
        }
        cleanTypingAttributes()
        window?.makeFirstResponder(self)
        didChangeText()
        refreshFormatting()
        needsDisplay = true
    }

    func toggleChecklistMode(_ isCheck: Bool) {
        let selected = selectedRange()
        let nsString = string as NSString
        guard selected.location <= nsString.length else { return }
        let lineRange = nsString.lineRange(for: selected)
        let lineText = nsString.substring(with: lineRange)

        var lines = lineText.components(separatedBy: "\n")
        for i in 0..<lines.count {
            if i == lines.count - 1 && lines[i].isEmpty && lines.count > 1 { continue }
            let line = lines[i]
            if isCheck {
                if !line.hasPrefix("☐ ") && !line.hasPrefix("☑ ") {
                    if line.hasPrefix("• ") {
                        lines[i] = "☐ " + String(line.dropFirst(2))
                    } else {
                        lines[i] = "☐ " + line
                    }
                }
            } else {
                if line.hasPrefix("☐ ") || line.hasPrefix("☑ ") {
                    lines[i] = String(line.dropFirst(2))
                }
            }
        }

        let replaced = lines.joined(separator: "\n")
        replaceCharacters(in: lineRange, with: replaced)
        didChangeText()
        refreshFormatting()
    }

    func toggleBold() {
        let sel = selectedRange()
        guard sel.length > 0, let storage = textStorage else { return }
        var hasBold = false
        storage.enumerateAttribute(.font, in: sel, options: []) { val, _, stop in
            if let font = val as? NSFont, font.fontDescriptor.symbolicTraits.contains(.bold) {
                hasBold = true
                stop.pointee = true
            }
        }
        let newFont = hasBold ? baseFont : boldFont
        storage.addAttribute(.font, value: newFont, range: sel)
        didChangeText()
        refreshFormatting()
    }

    func toggleItalic() {
        let sel = selectedRange()
        guard sel.length > 0, let storage = textStorage else { return }
        var hasItalic = false
        storage.enumerateAttributes(in: sel, options: []) { attrs, _, stop in
            let f = attrs[.font] as? NSFont
            let tr = f.map { NSFontManager.shared.traits(of: $0) } ?? []
            let ob = (attrs[.obliqueness] as? NSNumber)?.doubleValue ?? 0
            if tr.contains(.italicFontMask) || abs(ob) > 0.05 {
                hasItalic = true
                stop.pointee = true
            }
        }
        if hasItalic {
            storage.addAttribute(.font, value: baseFont, range: sel)
            storage.removeAttribute(.obliqueness, range: sel)
        } else {
            storage.addAttribute(.font, value: italicFont, range: sel)
            storage.addAttribute(.obliqueness, value: 0.2, range: sel)
        }
        didChangeText()
        refreshFormatting()
    }

    func toggleUnderline() {
        let sel = selectedRange()
        guard sel.length > 0, let storage = textStorage else { return }
        var hasUnderline = false
        storage.enumerateAttribute(.underlineStyle, in: sel, options: []) { val, _, stop in
            if (val as? Int ?? 0) != 0 {
                hasUnderline = true
                stop.pointee = true
            }
        }
        let newVal = hasUnderline ? 0 : NSUnderlineStyle.single.rawValue
        storage.addAttribute(.underlineStyle, value: newVal, range: sel)
        didChangeText()
        refreshFormatting()
    }

    func cleanTypingAttributes() {
        typingAttributes[.font] = baseFont
        typingAttributes[.foregroundColor] = baseColor
        typingAttributes.removeValue(forKey: .kern)
        typingAttributes.removeValue(forKey: .strikethroughStyle)
        typingAttributes.removeValue(forKey: .strikethroughColor)
    }

    private func ensureLineFonts(in textRange: NSRange) {
        guard textRange.length > 0, let storage = textStorage else { return }
        var location = textRange.location
        let end = textRange.location + textRange.length
        while location < end {
            var effectiveRange = NSRange(location: location, length: 0)
            let currentFont = storage.attribute(.font, at: location, longestEffectiveRange: &effectiveRange, in: NSRange(location: location, length: end - location)) as? NSFont
            let targetFont: NSFont
            if let cf = currentFont, cf.fontDescriptor.symbolicTraits.contains(.bold) && cf.fontDescriptor.symbolicTraits.contains(.italic) {
                targetFont = boldItalicFont
            } else if let cf = currentFont, cf.fontDescriptor.symbolicTraits.contains(.bold) {
                targetFont = boldFont
            } else if let cf = currentFont, cf.fontDescriptor.symbolicTraits.contains(.italic) {
                targetFont = italicFont
            } else {
                targetFont = baseFont
            }
            storage.addAttribute(.font, value: targetFont, range: effectiveRange)
            location = effectiveRange.location + effectiveRange.length
        }
    }

    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
        cleanTypingAttributes()
    }

    func refreshFormatting() {
        guard !isApplyingFormat else { return }
        isApplyingFormat = true
        defer { isApplyingFormat = false }

        guard let textStorage = textStorage else { return }
        let wholeRange = NSRange(location: 0, length: textStorage.length)
        guard wholeRange.length > 0 else { return }

        let nsString = textStorage.string as NSString
        var lineIndex = 0

        textStorage.beginEditing()
        textStorage.removeAttribute(.kern, range: wholeRange)
        while lineIndex < nsString.length {
            let lineRange = nsString.lineRange(for: NSRange(location: lineIndex, length: 0))
            let lineStr = nsString.substring(with: lineRange)

            if lineStr.hasPrefix("• ") {
                let bulletPara = NSMutableParagraphStyle()
                bulletPara.firstLineHeadIndent = 0
                bulletPara.headIndent = 20
                bulletPara.lineSpacing = 3
                textStorage.addAttribute(.paragraphStyle, value: bulletPara, range: lineRange)
                textStorage.removeAttribute(.strikethroughStyle, range: lineRange)
                textStorage.removeAttribute(.strikethroughColor, range: lineRange)
                textStorage.addAttribute(.foregroundColor, value: baseColor, range: lineRange)

                let bulletCharRange = NSRange(location: lineRange.location, length: 1)
                textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: 22, weight: .bold), range: bulletCharRange)

                let textLen = max(0, lineRange.length - 2)
                if textLen > 0 {
                    let textRange = NSRange(location: lineRange.location + 2, length: textLen)
                    ensureLineFonts(in: textRange)
                }
            } else if lineStr.hasPrefix("☐ ") {
                let checkPara = NSMutableParagraphStyle()
                checkPara.firstLineHeadIndent = 0
                checkPara.headIndent = 33
                checkPara.lineSpacing = 3
                textStorage.addAttribute(.paragraphStyle, value: checkPara, range: lineRange)
                textStorage.removeAttribute(.strikethroughStyle, range: lineRange)
                textStorage.removeAttribute(.strikethroughColor, range: lineRange)
                textStorage.addAttribute(.foregroundColor, value: baseColor, range: lineRange)

                let checkCharRange = NSRange(location: lineRange.location, length: 1)
                textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: checkCharRange)
                textStorage.addAttribute(.font, value: checkboxFont, range: checkCharRange)
                textStorage.addAttribute(.kern, value: 12.0, range: checkCharRange)

                let textLen = max(0, lineRange.length - 2)
                if textLen > 0 {
                    let textRange = NSRange(location: lineRange.location + 2, length: textLen)
                    ensureLineFonts(in: textRange)
                }
            } else if lineStr.hasPrefix("☑ ") {
                let checkPara = NSMutableParagraphStyle()
                checkPara.firstLineHeadIndent = 0
                checkPara.headIndent = 33
                checkPara.lineSpacing = 3
                textStorage.addAttribute(.paragraphStyle, value: checkPara, range: lineRange)

                textStorage.removeAttribute(.strikethroughStyle, range: lineRange)
                textStorage.removeAttribute(.strikethroughColor, range: lineRange)
                textStorage.addAttribute(.foregroundColor, value: baseColor, range: lineRange)

                let checkCharRange = NSRange(location: lineRange.location, length: 1)
                textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: checkCharRange)
                textStorage.addAttribute(.font, value: checkboxFont, range: checkCharRange)
                textStorage.addAttribute(.kern, value: 12.0, range: checkCharRange)

                let prefixLen = 2
                let textLen = max(0, lineRange.length - prefixLen - (lineStr.hasSuffix("\n") ? 1 : 0))
                if textLen > 0 {
                    let textRange = NSRange(location: lineRange.location + prefixLen, length: textLen)
                    let mutedColor = baseColor.withAlphaComponent(0.42)
                    textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                    textStorage.addAttribute(.strikethroughColor, value: mutedColor, range: textRange)
                    textStorage.addAttribute(.foregroundColor, value: mutedColor, range: textRange)
                    ensureLineFonts(in: textRange)
                }
            } else {
                let defaultPara = NSMutableParagraphStyle()
                defaultPara.lineSpacing = 3
                textStorage.addAttribute(.paragraphStyle, value: defaultPara, range: lineRange)
                textStorage.removeAttribute(.strikethroughStyle, range: lineRange)
                textStorage.removeAttribute(.strikethroughColor, range: lineRange)
                textStorage.addAttribute(.foregroundColor, value: baseColor, range: lineRange)
                ensureLineFonts(in: lineRange)
            }

            lineIndex = lineRange.location + lineRange.length
        }
        textStorage.endEditing()
        cleanTypingAttributes()
    }
}

enum MarkdownBridge {
    static func toDisplay(_ markdown: String) -> String {
        let dummyFont = NSFont.systemFont(ofSize: 14)
        let dummyColor = NSColor.black
        let attr = toAttributedString(
            markdown,
            baseFont: dummyFont,
            boldFont: dummyFont,
            italicFont: dummyFont,
            boldItalicFont: dummyFont,
            baseColor: dummyColor
        )
        return attr.string
    }

    static func toAttributedString(
        _ markdown: String,
        baseFont: NSFont,
        boldFont: NSFont,
        italicFont: NSFont,
        boldItalicFont: NSFont,
        baseColor: NSColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: baseColor
        ]

        let tokenPattern = #"(?:\*\*\*([^*\n]+?)\*\*\*|\*\*([^*\n]+?)\*\*|(?<!\*)\*([^*\n]+?)\*(?!\*)|__([^_\n]+?)__|(?<!_)_([^_\n]+?)_(?!_))"#
        let regex = try? NSRegularExpression(pattern: tokenPattern)

        for (lineIdx, line) in lines.enumerated() {
            var prefixString = ""
            var remainingLine = line

            if let taskRegex = try? NSRegularExpression(pattern: #"^[-*]\s*\[([ xX])\]\s*(.*)$"#),
               let match = taskRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                let markRange = Range(match.range(at: 1), in: line)!
                let textRange = Range(match.range(at: 2), in: line)!
                let mark = String(line[markRange]).lowercased()
                prefixString = (mark == "x") ? "☑ " : "☐ "
                remainingLine = String(line[textRange])
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                prefixString = "• "
                remainingLine = String(line.dropFirst(2))
            } else if line.hasPrefix("☐ ") || line.hasPrefix("☑ ") || line.hasPrefix("• ") {
                prefixString = String(line.prefix(2))
                remainingLine = String(line.dropFirst(2))
            }

            let lineAttr = NSMutableAttributedString()
            if !prefixString.isEmpty {
                lineAttr.append(NSAttributedString(string: prefixString, attributes: defaultAttrs))
            }

            let nsRemaining = remainingLine as NSString
            let remainingRange = NSRange(location: 0, length: nsRemaining.length)

            if let regex = regex {
                let matches = regex.matches(in: remainingLine, range: remainingRange)
                var lastIdx = 0

                for match in matches {
                    if match.range.location > lastIdx {
                        let plain = nsRemaining.substring(with: NSRange(location: lastIdx, length: match.range.location - lastIdx))
                        lineAttr.append(NSAttributedString(string: plain, attributes: defaultAttrs))
                    }

                    if match.range(at: 1).location != NSNotFound {
                        let content = nsRemaining.substring(with: match.range(at: 1))
                        lineAttr.append(NSAttributedString(string: content, attributes: [
                            .font: boldItalicFont,
                            .obliqueness: 0.2,
                            .foregroundColor: baseColor
                        ]))
                    } else if match.range(at: 2).location != NSNotFound {
                        let content = nsRemaining.substring(with: match.range(at: 2))
                        lineAttr.append(NSAttributedString(string: content, attributes: [
                            .font: boldFont,
                            .foregroundColor: baseColor
                        ]))
                    } else if match.range(at: 3).location != NSNotFound {
                        let content = nsRemaining.substring(with: match.range(at: 3))
                        lineAttr.append(NSAttributedString(string: content, attributes: [
                            .font: italicFont,
                            .obliqueness: 0.2,
                            .foregroundColor: baseColor
                        ]))
                    } else if match.range(at: 4).location != NSNotFound {
                        let content = nsRemaining.substring(with: match.range(at: 4))
                        lineAttr.append(NSAttributedString(string: content, attributes: [
                            .font: baseFont,
                            .foregroundColor: baseColor,
                            .underlineStyle: NSUnderlineStyle.single.rawValue
                        ]))
                    } else if match.range(at: 5).location != NSNotFound {
                        let content = nsRemaining.substring(with: match.range(at: 5))
                        lineAttr.append(NSAttributedString(string: content, attributes: [
                            .font: baseFont,
                            .foregroundColor: baseColor,
                            .underlineStyle: NSUnderlineStyle.single.rawValue
                        ]))
                    }

                    lastIdx = match.range.location + match.range.length
                }

                if lastIdx < nsRemaining.length {
                    let trailing = nsRemaining.substring(with: NSRange(location: lastIdx, length: nsRemaining.length - lastIdx))
                    lineAttr.append(NSAttributedString(string: trailing, attributes: defaultAttrs))
                }
            } else {
                lineAttr.append(NSAttributedString(string: remainingLine, attributes: defaultAttrs))
            }

            let wholeLineRange = NSRange(location: 0, length: lineAttr.length)
            let checkboxFont = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .medium)
            if prefixString == "• " {
                let bulletPara = NSMutableParagraphStyle()
                bulletPara.firstLineHeadIndent = 0
                bulletPara.headIndent = 18
                bulletPara.lineSpacing = 3
                lineAttr.addAttribute(.paragraphStyle, value: bulletPara, range: wholeLineRange)
            } else if prefixString == "☐ " {
                let checkPara = NSMutableParagraphStyle()
                checkPara.firstLineHeadIndent = 0
                checkPara.headIndent = 33
                checkPara.lineSpacing = 3
                lineAttr.addAttribute(.paragraphStyle, value: checkPara, range: wholeLineRange)

                let checkCharRange = NSRange(location: 0, length: 1)
                lineAttr.addAttribute(.foregroundColor, value: NSColor.clear, range: checkCharRange)
                lineAttr.addAttribute(.font, value: checkboxFont, range: checkCharRange)
                lineAttr.addAttribute(.kern, value: 12.0, range: checkCharRange)
            } else if prefixString == "☑ " {
                let checkPara = NSMutableParagraphStyle()
                checkPara.firstLineHeadIndent = 0
                checkPara.headIndent = 33
                checkPara.lineSpacing = 3
                lineAttr.addAttribute(.paragraphStyle, value: checkPara, range: wholeLineRange)

                let checkCharRange = NSRange(location: 0, length: 1)
                lineAttr.addAttribute(.foregroundColor, value: NSColor.clear, range: checkCharRange)
                lineAttr.addAttribute(.font, value: checkboxFont, range: checkCharRange)
                lineAttr.addAttribute(.kern, value: 12.0, range: checkCharRange)

                let prefixLen = 2
                let textLen = max(0, lineAttr.length - prefixLen)
                if textLen > 0 {
                    let textRange = NSRange(location: prefixLen, length: textLen)
                    let mutedColor = baseColor.withAlphaComponent(0.42)
                    lineAttr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                    lineAttr.addAttribute(.strikethroughColor, value: mutedColor, range: textRange)
                    lineAttr.addAttribute(.foregroundColor, value: mutedColor, range: textRange)
                }
            } else {
                let defaultPara = NSMutableParagraphStyle()
                defaultPara.lineSpacing = 3
                lineAttr.addAttribute(.paragraphStyle, value: defaultPara, range: wholeLineRange)
            }

            result.append(lineAttr)
            if lineIdx < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
            }
        }

        return result
    }

    static func attributedStringToMarkdown(_ attrStr: NSAttributedString) -> String {
        let fullString = attrStr.string as NSString
        guard fullString.length > 0 else { return "" }

        var markdownLines: [String] = []
        var lineLocation = 0

        while lineLocation < fullString.length {
            let lineRange = fullString.lineRange(for: NSRange(location: lineLocation, length: 0))
            var effectiveLineLength = lineRange.length
            while effectiveLineLength > 0 {
                let char = fullString.substring(with: NSRange(location: lineRange.location + effectiveLineLength - 1, length: 1))
                if char == "\n" || char == "\r" {
                    effectiveLineLength -= 1
                } else {
                    break
                }
            }

            let actualLineRange = NSRange(location: lineRange.location, length: effectiveLineLength)
            if actualLineRange.length == 0 {
                markdownLines.append("")
                lineLocation = lineRange.location + lineRange.length
                continue
            }

            let lineSubstring = fullString.substring(with: actualLineRange)
            var prefixOut = ""
            var contentOffset = 0

            if lineSubstring.hasPrefix("☐ ") {
                prefixOut = "- [ ] "
                contentOffset = 2
            } else if lineSubstring.hasPrefix("☑ ") {
                prefixOut = "- [x] "
                contentOffset = 2
            } else if lineSubstring.hasPrefix("• ") {
                prefixOut = "- "
                contentOffset = 2
            }

            let contentRange = NSRange(location: actualLineRange.location + contentOffset, length: actualLineRange.length - contentOffset)
            if contentRange.length == 0 {
                markdownLines.append(prefixOut)
                lineLocation = lineRange.location + lineRange.length
                continue
            }

            struct Span {
                var text: String
                var isBold: Bool
                var isItalic: Bool
                var isUnderline: Bool
            }
            var spans: [Span] = []

            attrStr.enumerateAttributes(in: contentRange, options: []) { attrs, range, _ in
                let runText = fullString.substring(with: range)
                let font = attrs[.font] as? NSFont
                let traits = font?.fontDescriptor.symbolicTraits ?? []
                let isBold = traits.contains(.bold)
                let fontTraits = font.map { NSFontManager.shared.traits(of: $0) } ?? []
                let obliqueness = (attrs[.obliqueness] as? NSNumber)?.doubleValue ?? 0
                let isItalic = traits.contains(.italic) || fontTraits.contains(.italicFontMask) || abs(obliqueness) > 0.05
                let isUnderline = (attrs[.underlineStyle] as? Int ?? 0) != 0

                if let last = spans.last, last.isBold == isBold, last.isItalic == isItalic, last.isUnderline == isUnderline {
                    spans[spans.count - 1].text += runText
                } else {
                    spans.append(Span(text: runText, isBold: isBold, isItalic: isItalic, isUnderline: isUnderline))
                }
            }

            var lineOutput = prefixOut
            for span in spans {
                if span.text.trimmingCharacters(in: .whitespaces).isEmpty {
                    lineOutput += span.text
                    continue
                }

                var formatted = span.text
                if span.isBold && span.isItalic {
                    formatted = "***" + formatted + "***"
                } else if span.isBold {
                    formatted = "**" + formatted + "**"
                } else if span.isItalic {
                    formatted = "*" + formatted + "*"
                }

                if span.isUnderline {
                    formatted = "__" + formatted + "__"
                }
                lineOutput += formatted
            }

            markdownLines.append(lineOutput)
            lineLocation = lineRange.location + lineRange.length
        }

        return markdownLines.joined(separator: "\n")
    }

    static func toMarkdown(_ display: String) -> String {
        let lines = display.components(separatedBy: "\n")
        var markdownLines: [String] = []

        for line in lines {
            if line.hasPrefix("☐ ") {
                markdownLines.append("- [ ] " + String(line.dropFirst(2)))
            } else if line.hasPrefix("☑ ") {
                markdownLines.append("- [x] " + String(line.dropFirst(2)))
            } else if line.hasPrefix("• ") {
                markdownLines.append("- " + String(line.dropFirst(2)))
            } else {
                markdownLines.append(line)
            }
        }

        return markdownLines.joined(separator: "\n")
    }
}
