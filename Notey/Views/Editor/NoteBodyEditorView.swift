import SwiftUI
import AppKit

@MainActor
struct NoteBodyEditorView: View {

    @Binding var markdown: String
    @Binding var isChecklist: Bool
    var onChange: ((String) -> Void)?

    @State private var lines: [MarkdownUtilities.NoteLine] = []
    @State private var focusedIndex: Int? = 0
    @State private var lastSerialized: String = ""

    var body: some View {
        Group {
            if isChecklist {
                checklistEditor
            } else {
                plainTextEditor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            syncFromMarkdown()
        }
        .onChange(of: markdown) { _, newValue in
            if newValue != lastSerialized {
                syncFromMarkdown()
            }
        }
        .onChange(of: isChecklist) { _, newValue in
            if newValue {
                var updated = MarkdownUtilities.parseLines(markdown)
                for i in 0..<updated.count {
                    updated[i].isChecklist = true
                }
                lines = updated
                focusedIndex = lines.count - 1
                notify()
            } else {
                markdown = MarkdownUtilities.checklistToPlainText(markdown)
                lastSerialized = markdown
                onChange?(markdown)
            }
        }
    }

    private var plainTextEditor: some View {
        NoteTextView(
            text: $markdown,
            font: NoteyFonts.noteNSFont(size: 20),
            textColor: NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 1.0),
            placeholder: "Write a note...",
            onChange: { newText in
                lastSerialized = newText
                onChange?(newText)
            }
        )
        .padding(.init(top: 14, leading: 20, bottom: 20, trailing: 20))
    }

    private var checklistEditor: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                    ChecklistLineRow(
                        line: bindingForLine(at: index),
                        index: index,
                        totalLines: lines.count,
                        isFocused: focusedIndex == index,
                        onFocus: { focusedIndex = index },
                        onToggleCheck: { toggleCheck(at: index) },
                        onEnter: { caretPos in handleEnter(at: index, caretPos: caretPos) },
                        onBackspaceAtStart: { handleBackspace(at: index) },
                        onUpArrow: { handleUpArrow(at: index) },
                        onDownArrow: { handleDownArrow(at: index) },
                        onInputChanged: { notify() }
                    )
                }
            }
            .padding(.init(top: 14, leading: 20, bottom: 24, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedIndex = max(0, lines.count - 1)
            }
        }
    }

    private func syncFromMarkdown() {
        lines = MarkdownUtilities.parseLines(markdown)
        lastSerialized = markdown
    }

    private func bindingForLine(at index: Int) -> Binding<MarkdownUtilities.NoteLine> {
        Binding(
            get: {
                if index < lines.count {
                    return lines[index]
                }
                return MarkdownUtilities.NoteLine(id: "empty", isChecklist: true, isCompleted: false, text: "")
            },
            set: { newValue in
                guard index < lines.count else { return }
                lines[index] = newValue
            }
        )
    }

    private func notify() {
        let serialized = MarkdownUtilities.serializeLines(lines)
        lastSerialized = serialized
        markdown = serialized
        onChange?(serialized)
    }

    private func toggleCheck(at index: Int) {
        guard index < lines.count else { return }
        lines[index].isCompleted.toggle()
        notify()
    }

    private func handleEnter(at index: Int, caretPos: Int) {
        guard index < lines.count else { return }
        let current = lines[index]
        let text = current.text
        let splitIndex = text.index(text.startIndex, offsetBy: min(caretPos, text.count))
        let before = String(text[..<splitIndex])
        let after = String(text[splitIndex...])

        lines[index].text = before

        let newLine = MarkdownUtilities.NoteLine(
            id: "line-\(UUID().uuidString)",
            isChecklist: true,
            isCompleted: false,
            text: after
        )
        lines.insert(newLine, at: index + 1)
        focusedIndex = index + 1
        notify()
    }

    private func handleBackspace(at index: Int) {
        guard index < lines.count else { return }
        let current = lines[index]

        if index > 0 {
            let prevText = lines[index - 1].text
            lines[index - 1].text = prevText + current.text
            lines.remove(at: index)
            focusedIndex = index - 1
            notify()
        } else if lines.count > 1 && current.text.isEmpty {
            lines.remove(at: 0)
            focusedIndex = 0
            notify()
        }
    }

    private func handleUpArrow(at index: Int) {
        if index > 0 {
            focusedIndex = index - 1
        }
    }

    private func handleDownArrow(at index: Int) {
        if index < lines.count - 1 {
            focusedIndex = index + 1
        }
    }
}

// MARK: - Native Multi-line Text View for Notes

struct NoteTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var textColor: NSColor
    var placeholder: String = "Write a note..."
    var onChange: ((String) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let contentSize = scrollView.contentSize
        let textView = CustomNoteTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.font = font
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.placeholder = placeholder
        textView.string = text
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        context.coordinator.textView = textView

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CustomNoteTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        textView.font = font
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoteTextView
        weak var textView: CustomNoteTextView?

        init(_ parent: NoteTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let newText = tv.string
            parent.text = newText
            parent.onChange?(newText)
        }
    }
}

final class CustomNoteTextView: NSTextView {
    var placeholder: String = "Write a note..." {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string.isEmpty && !placeholder.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font ?? NSFont.systemFont(ofSize: 20),
                .foregroundColor: (textColor ?? .labelColor).withAlphaComponent(0.35)
            ]
            let placeholderRect = NSRect(x: 2, y: 0, width: bounds.width - 4, height: bounds.height)
            placeholder.draw(in: placeholderRect, withAttributes: attrs)
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let clickPoint = convert(event.locationInWindow, from: nil)
        if let layoutManager = layoutManager, let textContainer = textContainer {
            let usedRect = layoutManager.usedRect(for: textContainer)
            if clickPoint.y > usedRect.maxY {
                setSelectedRange(NSRange(location: string.count, length: 0))
            }
        }
    }
}

// MARK: - Checklist Row and TextField with Responder Routing

private struct ChecklistLineRow: View {
    @Binding var line: MarkdownUtilities.NoteLine
    let index: Int
    let totalLines: Int
    let isFocused: Bool
    var onFocus: (() -> Void)?
    var onToggleCheck: (() -> Void)?
    var onEnter: ((Int) -> Void)?
    var onBackspaceAtStart: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onInputChanged: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Button(action: { onToggleCheck?() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4.5)
                        .stroke(Color.textPrimary, lineWidth: 1.8)
                        .fill(line.isCompleted ? Color.textPrimary : Color.white.opacity(0.45))
                        .frame(width: 20, height: 20)

                    if line.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.noteYellow)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(line.isCompleted ? "Mark incomplete" : "Mark complete")

            ChecklistLineTextField(
                text: $line.text,
                isCompleted: line.isCompleted,
                isFirstLine: index == 0 && totalLines == 1,
                isFocused: isFocused,
                onFocus: onFocus,
                onEnter: onEnter,
                onBackspaceAtStart: onBackspaceAtStart,
                onUpArrow: onUpArrow,
                onDownArrow: onDownArrow,
                onChanged: onInputChanged
            )
        }
        .frame(minHeight: 32)
    }
}

private struct ChecklistLineTextField: NSViewRepresentable {
    @Binding var text: String
    let isCompleted: Bool
    let isFirstLine: Bool
    let isFocused: Bool
    var onFocus: (() -> Void)?
    var onEnter: ((Int) -> Void)?
    var onBackspaceAtStart: (() -> Void)?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onChanged: (() -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.isEditable = true
        field.isSelectable = true
        field.lineBreakMode = .byWordWrapping
        field.cell?.wraps = true
        field.cell?.isScrollable = false
        field.delegate = context.coordinator

        field.font = NoteyFonts.noteNSFont(size: 20)
        field.textColor = NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 1)

        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        if field.stringValue != text {
            field.stringValue = text
        }

        field.placeholderString = isFirstLine ? "List item..." : ""

        if isCompleted {
            let attributed = NSMutableAttributedString(string: text)
            attributed.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor(srgbRed: 0x2C/255, green: 0x26/255, blue: 0x22/255, alpha: 0.55),
                .font: field.font ?? NSFont.systemFont(ofSize: 20)
            ], range: NSRange(location: 0, length: attributed.length))
            field.attributedStringValue = attributed
        }

        if isFocused {
            DispatchQueue.main.async {
                if field.window?.firstResponder != field.currentEditor() {
                    field.window?.makeFirstResponder(field)
                    if let editor = field.currentEditor() {
                        let len = field.stringValue.count
                        editor.selectedRange = NSRange(location: len, length: 0)
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ChecklistLineTextField

        init(_ parent: ChecklistLineTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
            parent.onChanged?()
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocus?()
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let caretPos = textView.selectedRange().location
                parent.onEnter?(caretPos)
                return true
            }

            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                let caretPos = textView.selectedRange().location
                if caretPos == 0 {
                    parent.onBackspaceAtStart?()
                    return true
                }
            }

            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                parent.onUpArrow?()
                return true
            }

            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                parent.onDownArrow?()
                return true
            }

            return false
        }
    }
}
