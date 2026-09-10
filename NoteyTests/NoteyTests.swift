import XCTest
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

        XCTAssertFalse(deckState.isHovered)

        deckState.mouseEntered(windowManager: windowManager)
        XCTAssertTrue(deckState.isHovered)

        deckState.mouseExited(windowManager: windowManager, isEditorOpen: false)
        // Before 0.22s, it's still hovered
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
        print("Initial panel frame: \(deckController.panel.frame)")

        // Check contentView and tracking areas
        let cv = deckController.panel.contentView!
        print("contentView frame: \(cv.frame), bounds: \(cv.bounds)")
        print("trackingAreas count: \(cv.trackingAreas.count)")
        for (i, ta) in cv.trackingAreas.enumerated() {
            print("  trackingArea[\(i)] rect: \(ta.rect), options: \(ta.options), inVisibleRect: \(ta.options.contains(.inVisibleRect))")
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testSingleNoteHoverExclusivity() {
        let deckState = DeckState()
        let note1 = UUID()
        let note2 = UUID()

        // Hover note 1
        deckState.tabMouseEntered(noteId: note1)
        XCTAssertEqual(deckState.activeHoverNoteId, note1)

        let exp1 = expectation(description: "note1 expanded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssertEqual(deckState.expandedNoteId, note1)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1.0)

        // Now hover note 2: note 1 MUST collapse immediately!
        deckState.tabMouseEntered(noteId: note2)
        XCTAssertEqual(deckState.activeHoverNoteId, note2)
        XCTAssertNil(deckState.expandedNoteId, "Note 1 must collapse immediately when hovering Note 2")

        let exp2 = expectation(description: "note2 expanded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssertEqual(deckState.expandedNoteId, note2)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1.0)

        // Exiting note 2 collapses it
        deckState.tabMouseExited(noteId: note2)
        XCTAssertNil(deckState.expandedNoteId)
    }
}
