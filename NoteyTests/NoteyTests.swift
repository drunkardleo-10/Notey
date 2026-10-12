import XCTest
import SwiftUI
@testable import Notey

final class JsonStoreTests: XCTestCase {

    private var tempDir: URL!
    private var store: JsonStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notey-test-\(UUID().uuidString)")
        store = JsonStore(basePath: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testCRUDAndAtomicPersistence() throws {
        var note = Note(
            title: "Sprint Planning",
            body: "- [ ] Review backlog\n- [ ] Assign tickets",
            color: .yellow
        )

        try store.saveNote(note)

        let loaded = try store.loadNote(id: note.id)
        XCTAssertEqual(loaded.title, "Sprint Planning")
        XCTAssertEqual(loaded.color, .yellow)
        XCTAssertFalse(loaded.isArchived)

        note.title = "Sprint Planning Updated"
        note.color = .mint
        try store.saveNote(note)

        let updated = try store.loadNote(id: note.id)
        XCTAssertEqual(updated.title, "Sprint Planning Updated")
        XCTAssertEqual(updated.color, .mint)

        let archived = try store.archiveNote(id: note.id)
        XCTAssertTrue(archived.isArchived)

        let restored = try store.restoreNote(id: note.id)
        XCTAssertFalse(restored.isArchived)

        let deleted = try store.deleteNote(id: note.id)
        XCTAssertTrue(deleted)
        XCTAssertThrowsError(try store.loadNote(id: note.id))
    }

    func testBatchCreationAndSearch() throws {
        let colors: [NoteColor] = [.yellow, .coral, .mint, .blue, .lavender]

        for i in 0..<10 {
            let note = Note(
                title: "Note Number \(i)",
                body: "Content markdown body for note index \(i)",
                color: colors[i % 5]
            )
            try store.saveNote(note)
        }

        let all = try store.loadAllNotes()
        XCTAssertEqual(all.count, 10)

        let searchTitle = try store.searchNotes(query: "Number 3")
        XCTAssertEqual(searchTitle.count, 1)
        XCTAssertEqual(searchTitle[0].title, "Note Number 3")

        let searchBody = try store.searchNotes(query: "markdown body")
        XCTAssertEqual(searchBody.count, 10)
    }

    func testEmptySearchReturnsAll() throws {
        let note = Note(title: "Test", body: "Body", color: .blue)
        try store.saveNote(note)

        let results = try store.searchNotes(query: "")
        XCTAssertEqual(results.count, 1)
    }

    func testDeleteNonexistentReturnsFalse() throws {
        let result = try store.deleteNote(id: UUID())
        XCTAssertFalse(result)
    }
}

final class MarkdownUtilitiesTests: XCTestCase {

    func testRoundTripChecklistMarkdown() {
        let markdown = "- [ ] Buy groceries\n- [x] Clean house\n- [ ] Write code"
        let items = MarkdownUtilities.markdownToChecklist(markdown)

        XCTAssertEqual(items.count, 3)
        XCTAssertFalse(items[0].isCompleted)
        XCTAssertEqual(items[0].text, "Buy groceries")
        XCTAssertTrue(items[1].isCompleted)
        XCTAssertEqual(items[1].text, "Clean house")
        XCTAssertFalse(items[2].isCompleted)

        let serialized = MarkdownUtilities.checklistToMarkdown(items)
        XCTAssertEqual(serialized, markdown)
    }

    func testEmptyMarkdownGivesSingleEmptyItem() {
        let items = MarkdownUtilities.markdownToChecklist("")
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].text, "")
    }

    func testSingleEmptyItemSerializesToEmptyString() {
        let items = [ChecklistItem(id: "test", text: "", isCompleted: false)]
        let markdown = MarkdownUtilities.checklistToMarkdown(items)
        XCTAssertEqual(markdown, "")
    }

    func testChecklistToPlainText() {
        let markdown = "- [ ] Task one\n- [x] Task two\nPlain line"
        let plain = MarkdownUtilities.checklistToPlainText(markdown)
        XCTAssertEqual(plain, "Task one\nTask two\nPlain line")
    }

    func testParseLines() {
        let markdown = "Hello world\n- [ ] Todo item\n- [x] Done item"
        let lines = MarkdownUtilities.parseLines(markdown)

        XCTAssertEqual(lines.count, 3)
        XCTAssertFalse(lines[0].isChecklist)
        XCTAssertEqual(lines[0].text, "Hello world")
        XCTAssertTrue(lines[1].isChecklist)
        XCTAssertFalse(lines[1].isCompleted)
        XCTAssertTrue(lines[2].isChecklist)
        XCTAssertTrue(lines[2].isCompleted)
    }

    func testSerializeLines() {
        let lines: [MarkdownUtilities.NoteLine] = [
            .init(id: "1", isChecklist: false, isCompleted: false, text: "Hello"),
            .init(id: "2", isChecklist: true, isCompleted: false, text: "Todo"),
            .init(id: "3", isChecklist: true, isCompleted: true, text: "Done"),
        ]
        let result = MarkdownUtilities.serializeLines(lines)
        XCTAssertEqual(result, "Hello\n- [ ] Todo\n- [x] Done")
    }
}

@MainActor
final class NoteStoreTests: XCTestCase {

    func testActiveDeckAndArchivedComputed() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notey-store-test-\(UUID().uuidString)")
        let jsonStore = JsonStore(basePath: tempDir)
        let store = NoteStore(jsonStore: jsonStore)

        store.createNote(title: "Active", body: "", color: .yellow)
        store.createNote(title: "Also Active", body: "", color: .blue)

        XCTAssertEqual(store.activeDeckNotes.count, 2)
        XCTAssertEqual(store.archivedNotes.count, 0)

        if let first = store.notes.first {
            store.archiveNote(id: first.id)
        }

        XCTAssertEqual(store.activeDeckNotes.count, 1)
        XCTAssertEqual(store.archivedNotes.count, 1)

        try? FileManager.default.removeItem(at: tempDir)
    }
}

@MainActor
final class DeckHoverTests: XCTestCase {
    func testDeckHoverCycle() {
        let windowManager = WindowModeManager()
        let deckState = DeckState()
        let note1 = UUID()

        XCTAssertFalse(deckState.isHovered)

        deckState.tabMouseEntered(noteId: note1, windowManager: windowManager)
        XCTAssertTrue(deckState.isHovered)

        deckState.panelMouseExited(windowManager: windowManager)
        XCTAssertTrue(deckState.isHovered)

        let exp = expectation(description: "deckIdle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertFalse(deckState.isHovered)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testDeckAppKitEvents() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notey-deck-test2-\(UUID().uuidString)")
        let jsonStore = JsonStore(basePath: tempDir)
        let store = NoteStore(jsonStore: jsonStore)
        store.createNote(title: "Note 1", body: "- [ ] Task 1", color: .yellow)

        let windowManager = WindowModeManager()
        let deckController = DeckPanelController(noteStore: store, windowManager: windowManager)
        windowManager.deckController = deckController

        deckController.show()

        let cv = deckController.panel.contentView!
        for ta in cv.trackingAreas {
            _ = ta.rect
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testSingleNoteHoverExclusivity() {
        let windowManager = WindowModeManager()
        let deckState = DeckState()
        let note1 = UUID()
        let note2 = UUID()

        deckState.tabMouseEntered(noteId: note1, windowManager: windowManager)
        XCTAssertEqual(deckState.activeHoverNoteId, note1)
        XCTAssertEqual(deckState.expandedNoteId, note1)

        deckState.tabMouseEntered(noteId: note2, windowManager: windowManager)
        XCTAssertEqual(deckState.activeHoverNoteId, note2)
        XCTAssertEqual(deckState.expandedNoteId, note2)

        deckState.tabMouseExited(noteId: note2)
        let exp = expectation(description: "note2 collapsed after debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            XCTAssertNil(deckState.expandedNoteId)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testDeckMinimumDeckOpeningCascade() {
        let windowManager = WindowModeManager()
        let deckState = DeckState()
        let note1 = UUID()

        XCTAssertFalse(deckState.isHovered)
        XCTAssertFalse(deckState.isDeckOpening)

        deckState.mouseEntered(windowManager: windowManager)
        XCTAssertTrue(deckState.isHovered)
        XCTAssertTrue(deckState.isDeckOpening)
        XCTAssertNil(deckState.expandedNoteId)

        deckState.tabMouseEntered(noteId: note1, windowManager: windowManager)
        XCTAssertEqual(deckState.activeHoverNoteId, note1)
        XCTAssertNil(deckState.expandedNoteId)

        let exp = expectation(description: "note1 expands after dwell")
        DispatchQueue.main.asyncAfter(deadline: .now() + DeckCascade.openingHold + 0.05) {
            XCTAssertFalse(deckState.isDeckOpening)
            XCTAssertEqual(deckState.expandedNoteId, note1)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

final class MarkdownBridgeTests: XCTestCase {
    func testMarkdownBridgeConversion() {
        let md = "haha testing\n- [ ] Unchecked item\n- [x] Completed item\n- Bullet point\n**bold text** and *italic*"
        let display = MarkdownBridge.toDisplay(md)
        XCTAssertTrue(display.contains("☐ Unchecked item"))
        XCTAssertTrue(display.contains("☑ Completed item"))
        XCTAssertTrue(display.contains("• Bullet point"))
        XCTAssertTrue(display.contains("bold text and italic"))
        XCTAssertFalse(display.contains("**"))
        XCTAssertFalse(display.contains("*italic*"))

        let base = NoteyFonts.noteNSFont(size: 14, weight: .regular)
        let bold = NoteyFonts.noteNSFont(size: 14, weight: .bold)
        let italic = NoteyFonts.noteNSFont(size: 14, weight: .regular, italic: true)
        let boldItalic = NoteyFonts.noteNSFont(size: 14, weight: .bold, italic: true)
        let color = NSColor.black
        let attr = MarkdownBridge.toAttributedString(md, baseFont: base, boldFont: bold, italicFont: italic, boldItalicFont: boldItalic, baseColor: color)
        let serialized = MarkdownBridge.attributedStringToMarkdown(attr)
        XCTAssertEqual(serialized, md)
    }

    func testMarkdownBridgeEmpty() {
        XCTAssertEqual(MarkdownBridge.toDisplay(""), "")
        XCTAssertEqual(MarkdownBridge.toMarkdown(""), "")
    }

    @MainActor
    func testChecklistToggleAndAutoTriggers() {
        let tv = MarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        tv.string = "First line"
        tv.setSelectedRange(NSRange(location: 0, length: 0))
        tv.toggleChecklistAtCursor()
        XCTAssertTrue(tv.string.hasPrefix("☐ First line"))

        tv.toggleChecklistAtCursor()
        XCTAssertTrue(tv.string.hasPrefix("First line"))

        tv.string = "• [ ] auto item"
        tv.setSelectedRange(NSRange(location: tv.string.count, length: 0))
        tv.insertText(" ", replacementRange: NSRange(location: tv.string.count, length: 0))
        XCTAssertTrue(tv.string.hasPrefix("☐ auto item"))

        tv.string = "- [ ] second item"
        tv.setSelectedRange(NSRange(location: tv.string.count, length: 0))
        tv.insertText(" ", replacementRange: NSRange(location: tv.string.count, length: 0))
        XCTAssertTrue(tv.string.hasPrefix("☐ second item"))
    }

    @MainActor
    func testInlineMarkdownAutoTriggers() {
        let tv = MarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        tv.string = ""
        tv.insertText("**bold**", replacementRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(tv.string, "bold")
        let font = tv.textStorage?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        XCTAssertTrue(font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false)

        tv.string = ""
        tv.insertText("*italic*", replacementRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(tv.string, "italic")

        tv.string = ""
        tv.insertText("__under__", replacementRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(tv.string, "under")
        let under = tv.textStorage?.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(under, NSUnderlineStyle.single.rawValue)
    }
}

final class MarkdownNSTextViewTests: XCTestCase {
    @MainActor
    func testMarkdownNSTextViewInitDoesNotCrash() {
        let tv1 = MarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        XCTAssertNotNil(tv1)
        XCTAssertNotNil(tv1.textContainer)
        let container = NSTextContainer(size: NSSize(width: 300, height: 400))
        let tv2 = MarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 400), textContainer: container)
        XCTAssertNotNil(tv2)
        XCTAssertEqual(tv2.textContainer, container)
    }

    @MainActor
    func testEditorOpenAndCloseLifecycle() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notey-editor-test-\(UUID().uuidString)")
        let jsonStore = JsonStore(basePath: tempDir)
        let store = NoteStore(jsonStore: jsonStore)
        let note = store.createNote(title: "Test Note", body: "- [ ] Task item\n• Bullet\n**Bold text**", color: .yellow)

        let windowManager = WindowModeManager()
        let editorController = EditorPanelController(noteStore: store, windowManager: windowManager)

        var closedCalled = false
        editorController.onClose = {
            closedCalled = true
        }

        editorController.openNote(note)
        XCTAssertEqual(editorController.currentNote?.id, note.id)
        XCTAssertNotNil(editorController.panel.contentView)

        editorController.close()
        XCTAssertNil(editorController.currentNote)
        XCTAssertTrue(closedCalled)

        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    func testActivationPolicyAndPanelKeyBehavior() {
        let panel = NoteyPanel(
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.configureAsEditor()

        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertTrue(panel.canBecomeMain)
        XCTAssertFalse(panel.becomesKeyOnlyIfNeeded)
        XCTAssertTrue(panel.acceptsMouseMovedEvents)
        XCTAssertTrue(panel.isMovable)
    }

    @MainActor
    func testEditorScrollViewViewportSizing() {
        let scrollView = EditorScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        let textView = MarkdownNSTextView(frame: .zero)
        scrollView.documentView = textView
        scrollView.textView = textView

        scrollView.layout()
        let clipHeight = scrollView.contentView.bounds.height
        XCTAssertGreaterThan(clipHeight, 0)
        XCTAssertGreaterThanOrEqual(textView.frame.height, clipHeight)
        XCTAssertEqual(textView.minSize.height, clipHeight)
    }

    @MainActor
    func testDragGripViewCursorTracking() {
        let grip = DragGripNSView(frame: NSRect(x: 0, y: 0, width: 28, height: 28))
        grip.updateTrackingAreas()
        XCTAssertNotNil(grip.trackingAreas.first)

        grip.resetCursorRects()
        let enterEvent = NSEvent.enterExitEvent(
            with: .mouseEntered,
            location: NSPoint(x: 14, y: 14),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 1,
            trackingNumber: 1,
            userData: nil
        )
        if let enter = enterEvent {
            grip.mouseEntered(with: enter)
        }
        let exitEvent = NSEvent.enterExitEvent(
            with: .mouseExited,
            location: NSPoint(x: 50, y: 50),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 2,
            trackingNumber: 1,
            userData: nil
        )
        if let exit = exitEvent {
            grip.mouseExited(with: exit)
        }
    }

    @MainActor
    func testCaveatFontLoads() {
        let font = NoteyFonts.noteNSFont(size: 24, weight: .regular)
        XCTAssertNotNil(font)
        XCTAssertTrue(font.fontName.contains("Caveat"))

        let boldFont = NoteyFonts.noteNSFont(size: 24, weight: .bold)
        XCTAssertNotNil(boldFont)
        XCTAssertTrue(boldFont.fontDescriptor.symbolicTraits.contains(.bold))
    }

    @MainActor
    func testChecklistAndBulletFontApplication() {
        let tv = MarkdownNSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        tv.string = "• Bullet point\n☐ Checklist item"
        tv.refreshFormatting()

        guard let storage = tv.textStorage else {
            XCTFail("No text storage")
            return
        }

        let bulletFont = storage.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        XCTAssertNotNil(bulletFont)
        XCTAssertGreaterThanOrEqual(bulletFont?.pointSize ?? 0, 20)

        let bulletTextFont = storage.attribute(.font, at: 2, effectiveRange: nil) as? NSFont
        XCTAssertNotNil(bulletTextFont)
        XCTAssertTrue(bulletTextFont?.fontName.contains("Caveat") ?? false)

        let checklistLineStart = ("• Bullet point\n" as NSString).length
        let checkTextIndex = checklistLineStart + 2
        let checkTextFont = storage.attribute(.font, at: checkTextIndex, effectiveRange: nil) as? NSFont
        XCTAssertNotNil(checkTextFont)
        XCTAssertTrue(checkTextFont?.fontName.contains("Caveat") ?? false)
    }
}

final class NoteColorAndPickerTests: XCTestCase {

    func testPresetNoteColors() throws {
        let presets: [NoteColor] = [.yellow, .coral, .mint, .blue, .lavender]
        for preset in presets {
            XCTAssertFalse(preset.isCustom)
            XCTAssertEqual(NoteColor(rawValue: preset.rawValue), preset)
            XCTAssertNotNil(preset.swiftUIColor)
            XCTAssertNotNil(preset.nsColor)
            XCTAssertTrue(preset.hexCode.hasPrefix("#"))
        }
    }

    func testCustomNoteColorParsingAndEquality() {
        let custom1 = NoteColor(rawValue: "#FF5722")
        let custom2 = NoteColor(rawValue: "ff5722")
        let custom3 = NoteColor.custom("#FF5722")

        XCTAssertTrue(custom1.isCustom)
        XCTAssertTrue(custom2.isCustom)
        XCTAssertEqual(custom1, custom2)
        XCTAssertEqual(custom1, custom3)
        XCTAssertEqual(custom1.hexCode, "#FF5722")
        XCTAssertEqual(custom2.hexCode, "#FF5722")
    }

    func testCustomColorPersistenceAndJsonRoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notey-custom-color-test-\(UUID().uuidString)")
        let store = JsonStore(basePath: tempDir)

        let customColor = NoteColor.custom("#3498DB")
        let note = Note(
            title: "Custom Blue Note",
            body: "Body with custom color",
            color: customColor
        )

        try store.saveNote(note)

        let loaded = try store.loadNote(id: note.id)
        XCTAssertEqual(loaded.color, customColor)
        XCTAssertTrue(loaded.color.isCustom)
        XCTAssertEqual(loaded.color.hexCode, "#3498DB")

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testHexColorHelpers() {
        let color = Color(hexString: "#FF8000")
        XCTAssertNotNil(color)

        let nsColor = NSColor(hexString: "#00FF00")
        XCTAssertNotNil(nsColor)
        XCTAssertEqual(nsColor?.hexString.uppercased(), "#00FF00")

        let invalid = Color(hexString: "not-a-color")
        XCTAssertNil(invalid)
    }
}

final class ScribbleEngineTests: XCTestCase {

    func testFNV1aHashConsistency() {
        let emptyHash = ScribbleEngine.fnv1aHash("")
        XCTAssertEqual(emptyHash, 2166136261)

        let hash1 = ScribbleEngine.fnv1aHash("Buy groceries")
        let hash2 = ScribbleEngine.fnv1aHash("Buy groceries")
        let hash3 = ScribbleEngine.fnv1aHash("Walk the dog")

        XCTAssertEqual(hash1, hash2)
        XCTAssertNotEqual(hash1, hash3)
    }

    func testScribbleRandomGenerator() {
        var rand1 = ScribbleEngine.Random(seed: 12345)
        var rand2 = ScribbleEngine.Random(seed: 12345)

        let val1 = rand1.nextDouble()
        let val2 = rand2.nextDouble()
        XCTAssertEqual(val1, val2, accuracy: 1e-9)
        XCTAssertGreaterThanOrEqual(val1, 0.0)
        XCTAssertLessThan(val1, 1.0)

        let between = rand1.between(10, 20)
        XCTAssertGreaterThanOrEqual(between, 10)
        XCTAssertLessThanOrEqual(between, 20)
    }

    func testPenEasingCurve() {
        XCTAssertEqual(ScribbleEngine.penEase(0.0), 0.0, accuracy: 1e-5)
        XCTAssertEqual(ScribbleEngine.penEase(1.0), 1.0, accuracy: 1e-5)

        let mid = ScribbleEngine.penEase(0.5)
        XCTAssertGreaterThan(mid, 0.0)
        XCTAssertLessThan(mid, 1.0)

        var prev: Double = 0.0
        for i in 1...10 {
            let t = Double(i) / 10.0
            let val = ScribbleEngine.penEase(t)
            XCTAssertGreaterThanOrEqual(val, prev)
            prev = val
        }
    }

    func testCheckmarkGenerationAndTrimming() {
        let check = ScribbleEngine.generateCheckmark(seed: 42)
        XCTAssertGreaterThanOrEqual(check.start.x, 3.5)
        XCTAssertLessThanOrEqual(check.start.x, 7.0)
        XCTAssertGreaterThanOrEqual(check.start.y, 10.0)
        XCTAssertLessThanOrEqual(check.start.y, 14.0)

        XCTAssertGreaterThanOrEqual(check.valley.y, 16.5)
        XCTAssertLessThanOrEqual(check.valley.y, 19.5)

        XCTAssertGreaterThanOrEqual(check.width, 1.75)
        XCTAssertLessThanOrEqual(check.width, 2.3)

        let box = CGRect(x: 10, y: 10, width: 20, height: 20)
        let fullPath = check.cgPath(in: box, progress: 1.0)
        XCTAssertFalse(fullPath.isEmpty)

        let emptyPath = check.cgPath(in: box, progress: 0.0)
        XCTAssertTrue(emptyPath.isEmpty)

        let halfPath = check.cgPath(in: box, progress: 0.5)
        XCTAssertFalse(halfPath.isEmpty)
    }

    func testStrikeGenerationAndDuration() {
        let strike = ScribbleEngine.generateStrike(x0: 10, x1: 150, y: 30, seed: 100)
        XCTAssertGreaterThanOrEqual(strike.width, 1.4)
        XCTAssertLessThanOrEqual(strike.width, 1.9)

        let fullPath = strike.cgPath(progress: 1.0)
        XCTAssertFalse(fullPath.isEmpty)

        let emptyPath = strike.cgPath(progress: 0.0)
        XCTAssertTrue(emptyPath.isEmpty)

        let shortDur = ScribbleEngine.strikeDuration(x0: 0, x1: 50)
        XCTAssertGreaterThanOrEqual(shortDur, 0.12)
        XCTAssertLessThanOrEqual(shortDur, 0.26)

        let longDur = ScribbleEngine.strikeDuration(x0: 0, x1: 500)
        XCTAssertEqual(longDur, 0.26, accuracy: 1e-4)
    }

    func testDeCasteljauCubicSplit() {
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 10, y: 20)
        let p2 = CGPoint(x: 30, y: 20)
        let p3 = CGPoint(x: 40, y: 0)

        let split = ScribbleEngine.splitCubic(p0: p0, p1: p1, p2: p2, p3: p3, at: 0.5)
        XCTAssertEqual(split.0, p0)
        XCTAssertEqual(split.3.x, 20.0, accuracy: 1e-4)
        XCTAssertEqual(split.3.y, 15.0, accuracy: 1e-4)
    }
}



@MainActor
final class NoteOrderTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notey-order-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeStore() -> NoteStore {
        NoteStore(jsonStore: JsonStore(basePath: tempDir))
    }

    func testNewNotesGoToTopAndMoveIsPersisted() {
        let store = makeStore()
        let first = store.createNote(title: "A", body: "", color: .yellow)
        let second = store.createNote(title: "B", body: "", color: .coral)
        let third = store.createNote(title: "C", body: "", color: .mint)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["C", "B", "A"])

        store.moveDeckNote(id: third.id, to: 2)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["B", "A", "C"])

        store.moveDeckNote(id: first.id, to: 0)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["A", "B", "C"])

        let reloaded = makeStore()
        reloaded.loadNotes()
        XCTAssertEqual(reloaded.activeDeckNotes.map(\.title), ["A", "B", "C"])
        XCTAssertEqual(second.title, "B")
    }

    func testMoveClampsAndArchivedNotesStayOutOfDeck() {
        let store = makeStore()
        let a = store.createNote(title: "A", body: "", color: .yellow)
        let b = store.createNote(title: "B", body: "", color: .coral)
        _ = store.createNote(title: "C", body: "", color: .mint)

        store.moveDeckNote(id: a.id, to: -5)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["A", "C", "B"])

        store.moveDeckNote(id: a.id, to: 99)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["C", "B", "A"])

        store.archiveNote(id: b.id)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["C", "A"])
        store.moveDeckNote(id: a.id, to: 0)
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["A", "C"])
    }

    func testLegacyNotesWithoutSortIndexKeepRecentFirstOrder() throws {
        let json = JsonStore(basePath: tempDir)
        let older = Note(title: "Old", body: "", color: .yellow, updatedAt: Date(timeIntervalSince1970: 1_000))
        let newer = Note(title: "New", body: "", color: .coral, updatedAt: Date(timeIntervalSince1970: 2_000))
        try json.saveNote(older)
        try json.saveNote(newer)

        let store = makeStore()
        store.loadNotes()
        XCTAssertEqual(store.activeDeckNotes.map(\.title), ["New", "Old"])
        XCTAssertEqual(store.activeDeckNotes.compactMap(\.sortIndex), [0, 1])
    }
}
